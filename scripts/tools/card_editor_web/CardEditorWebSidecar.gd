extends Node

const CardEditorWebDocumentAdapter = preload("res://scripts/tools/card_editor_web/CardEditorWebDocumentAdapter.gd")

var service := CardEditorService.new()
var adapter := CardEditorWebDocumentAdapter.new()
var sessions: Dictionary = {}
var next_session_index: int = 1
var bootstrapped: bool = false

func _global() -> Node:
	return get_tree().root.get_node("Global")

func _ready() -> void:
	print("CardEditorWebSidecar: boot")
	_bootstrap_runtime()
	print("CardEditorWebSidecar: ready")
	while true:
		var raw_line: String = OS.read_string_from_stdin()
		if raw_line == "":
			get_tree().quit()
			return
		for line: String in raw_line.split("\n", false):
			var trimmed: String = line.strip_edges()
			if trimmed == "":
				continue
			_handle_request_line(trimmed)

func _handle_request_line(raw_line: String) -> void:
	var request: Variant = JSON.parse_string(raw_line)
	if not (request is Dictionary):
		return
	var request_dict: Dictionary = request
	var request_id: Variant = request_dict.get("id", null)
	var method: String = str(request_dict.get("method", ""))
	var params: Dictionary = request_dict.get("params", {})
	var response := {"id": request_id}
	var result: Variant = null
	var error_message: String = ""
	match method:
		"ping":
			result = {"ok": true}
		"library.list":
			result = _handle_library_list()
		"metadata.actions":
			result = _handle_metadata_list(true)
		"metadata.validators":
			result = _handle_metadata_list(false)
		"presets.list":
			result = _handle_preset_list()
		"session.new":
			result = _handle_session_new(params)
		"session.load":
			result = _handle_session_load(params)
		"session.duplicate":
			result = _handle_session_duplicate(params)
		"session.apply_preset":
			result = _handle_session_apply_preset(params)
		"session.update_document":
			result = _handle_session_update_document(params)
		"session.validate":
			result = _handle_session_validate(params)
		"session.save_triage":
			result = _handle_session_save(params, true)
		"session.save_content":
			result = _handle_session_save(params, false)
		"session.rescan_library":
			result = _handle_library_list()
		_:
			error_message = "Unknown sidecar method: %s" % method
	if error_message != "":
		response["error"] = {"message": error_message}
	else:
		response["result"] = result
	print(JSON.stringify(response))

func _bootstrap_runtime() -> void:
	if bootstrapped:
		return
	var global := _global()
	if global.CLASS_NAME_TO_CLASS.is_empty():
		global._generate_schema()
	if SerializableData._serializable_data_script_cache.is_empty():
		SerializableData.build_serializable_script_cache()
	if len(global._id_to_color_data) == 0:
		global.add_test_colors()
	if len(global._id_to_card_data) == 0:
		global._load_core_content_from_resources()
		global._apply_card_kind_rules()
	bootstrapped = true

func _handle_library_list() -> Dictionary:
	var entries: Array[Dictionary] = []
	for entry: Dictionary in service.list_library_cards():
		entries.append(adapter.library_entry_to_api(entry))
	return {
		"entries": entries,
		"discoveryDiagnostics": adapter._diagnostics_to_api(service.get_discovery_diagnostics()),
	}

func _handle_metadata_list(is_action: bool) -> Dictionary:
	var metadata_payloads: Array[Dictionary] = []
	var metadata_entries: Array[Dictionary] = ScriptEditorMetadataRegistry.get_all_action_metadata() if is_action else ScriptEditorMetadataRegistry.get_all_validator_metadata()
	for metadata: Dictionary in metadata_entries:
		metadata_payloads.append(adapter.metadata_to_api(metadata))
	return {"entries": metadata_payloads}

func _handle_preset_list() -> Dictionary:
	var presets: Array[Dictionary] = []
	for preset: Dictionary in service.list_presets():
		presets.append({
			"id": str(preset.get("id", "")),
			"displayName": str(preset.get("display_name", "")),
			"description": str(preset.get("description", "")),
		})
	return {"entries": presets}

func _handle_session_new(params: Dictionary) -> Dictionary:
	var preset_id: String = str(params.get("presetId", ""))
	var session: CardEditorSession = service.create_blank_session_from_preset(preset_id) if preset_id != "" else service.create_blank_session()
	return _register_session(session)

func _handle_session_load(params: Dictionary) -> Dictionary:
	var resource_path: String = str(params.get("resourcePath", ""))
	var session: CardEditorSession = service.load_session(resource_path)
	if session == null:
		return {}
	return _register_session(session)

func _handle_session_duplicate(params: Dictionary) -> Dictionary:
	var session: CardEditorSession = _get_session(str(params.get("sessionId", "")))
	if session == null:
		return {}
	var duplicated: CardEditorSession = service.duplicate_session(session)
	if duplicated == null:
		return {}
	return _register_session(duplicated)

func _handle_session_apply_preset(params: Dictionary) -> Dictionary:
	var session: CardEditorSession = _get_session(str(params.get("sessionId", "")))
	if session == null:
		return {}
	service.apply_preset_to_session(session, str(params.get("presetId", "")), bool(params.get("preserveIdentity", true)))
	return _session_envelope(_session_id_for(session), session)

func _handle_session_update_document(params: Dictionary) -> Dictionary:
	var session: CardEditorSession = _get_session(str(params.get("sessionId", "")))
	if session == null:
		return {}
	adapter.apply_document_to_session(session, params.get("document", {}))
	session.refresh_diagnostics(service)
	return {
		"diagnostics": adapter._diagnostics_to_api(session.diagnostics),
		"save": adapter._save_to_api(session.to_summary()),
	}

func _handle_session_validate(params: Dictionary) -> Dictionary:
	var session: CardEditorSession = _get_session(str(params.get("sessionId", "")))
	if session == null:
		return {}
	session.refresh_diagnostics(service)
	return {
		"diagnostics": adapter._diagnostics_to_api(session.diagnostics),
		"save": adapter._save_to_api(session.to_summary()),
	}

func _handle_session_save(params: Dictionary, save_to_triage: bool) -> Dictionary:
	var session: CardEditorSession = _get_session(str(params.get("sessionId", "")))
	if session == null:
		return {}
	var result: Dictionary = service.save_session_to_triage(session) if save_to_triage else service.promote_session_to_content(session)
	return {
		"success": bool(result.get("success", false)),
		"path": str(result.get("path", "")),
		"diagnostics": adapter._diagnostics_to_api(result.get("diagnostics", [])),
		"document": adapter.session_to_document(session),
	}

func _register_session(session: CardEditorSession) -> Dictionary:
	var session_id: String = "session_%s" % next_session_index
	next_session_index += 1
	sessions[session_id] = session
	return _session_envelope(session_id, session)

func _session_envelope(session_id: String, session: CardEditorSession) -> Dictionary:
	return {
		"sessionId": session_id,
		"document": adapter.session_to_document(session),
	}

func _get_session(session_id: String) -> CardEditorSession:
	if session_id == "":
		return null
	return sessions.get(session_id, null)

func _session_id_for(target_session: CardEditorSession) -> String:
	for session_id: String in sessions.keys():
		if sessions[session_id] == target_session:
			return session_id
	return ""
