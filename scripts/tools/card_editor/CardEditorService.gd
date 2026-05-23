@tool
extends RefCounted
class_name CardEditorService

const DEFAULT_CONTENT_ROOT := CardEditorPathUtils.DEFAULT_CONTENT_ROOT

const CARD_ARRAY_PROPERTIES := {
	"card_play_actions": BaseAction.EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
	"card_discard_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_end_of_turn_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_exhaust_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_draw_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_retain_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_right_click_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_initial_combat_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_add_to_deck_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_remove_from_deck_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_transform_in_deck_actions": BaseAction.EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
	"card_play_validators": BaseValidator.EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
	"card_glow_validators": BaseValidator.EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
}

const TARGETED_ACTION_TOKENS := {
	Scripts.ACTION_ATTACK: true,
	Scripts.ACTION_ATTACK_GENERATOR: true,
	Scripts.ACTION_APPLY_STATUS: true,
	Scripts.ACTION_PLAY_CARDS: true,
}

var last_discovery_diagnostics: Array[Dictionary] = []

func list_cards(content_root: String = DEFAULT_CONTENT_ROOT) -> Array[Dictionary]:
	last_discovery_diagnostics.clear()
	var cards: Array[Dictionary] = []
	var cards_root: String = content_root.path_join("cards")
	_discover_cards_recursive(cards_root, cards)
	cards.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_name: String = str(left.get("card_name", left.get("object_id", "")))
		var right_name: String = str(right.get("card_name", right.get("object_id", "")))
		if left_name == right_name:
			return str(left.get("resource_path", "")) < str(right.get("resource_path", ""))
		return left_name < right_name
	)
	return cards

func get_discovery_diagnostics() -> Array[Dictionary]:
	return last_discovery_diagnostics.duplicate(true)

func create_blank_session(content_root: String = DEFAULT_CONTENT_ROOT) -> CardEditorSession:
	var card_data: CardData = CardData.new()
	var session := CardEditorSession.new(card_data, "", content_root)
	session.recompute_managed_path()
	session.refresh_diagnostics(self)
	return session

func load_session(resource_path: String, content_root: String = DEFAULT_CONTENT_ROOT) -> CardEditorSession:
	var resource: Resource = load(resource_path)
	if not (resource is CardData):
		push_error("CardEditorService: Resource is not CardData: %s" % resource_path)
		return null
	var session_card: CardData = (resource as CardData).duplicate(true)
	var session := CardEditorSession.new(session_card, resource_path, content_root)
	session.recompute_managed_path()
	session.refresh_diagnostics(self)
	return session

func duplicate_session(source: Variant, content_root: String = DEFAULT_CONTENT_ROOT) -> CardEditorSession:
	var source_session: CardEditorSession = null
	if source is CardEditorSession:
		source_session = source
	elif source is String:
		source_session = load_session(source, content_root)
	if source_session == null or source_session.working_card_data == null:
		return null
	var duplicated_card: CardData = source_session.working_card_data.duplicate(true)
	var session := CardEditorSession.new(duplicated_card, "", content_root)
	session.recompute_managed_path()
	session.mark_dirty()
	session.refresh_diagnostics(self)
	return session

func save_session(session: CardEditorSession) -> Dictionary:
	return _save_session_internal(session, "")

func save_session_as(session: CardEditorSession, target_path: String) -> Dictionary:
	return _save_session_internal(session, target_path)

func validate_session(session: CardEditorSession) -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if session == null:
		diagnostics.append(_make_diagnostic("session_missing", "error", "No card editor session was provided."))
		return diagnostics
	var card_data: CardData = session.working_card_data
	if card_data == null:
		diagnostics.append(_make_diagnostic("card_missing", "error", "The session has no working CardData resource."))
		return diagnostics

	card_data.synchronize_card_kind_rules()
	session.recompute_managed_path()

	if card_data.object_id.strip_edges() == "":
		diagnostics.append(_make_diagnostic("empty_object_id", "error", "Card object_id cannot be empty.", "object_id"))
	if card_data.card_name.strip_edges() == "":
		diagnostics.append(_make_diagnostic("empty_card_name", "error", "Card name cannot be empty.", "card_name"))

	var active_save_path: String = session.get_active_save_path().strip_edges()
	if active_save_path == "":
		diagnostics.append(_make_diagnostic("empty_save_path", "error", "Card save path is empty.", "save_path"))
	elif not _is_supported_resource_path(active_save_path):
		diagnostics.append(_make_diagnostic("invalid_save_path", "error", "Card save path must point to a .tres or .res file under res://.", "save_path", {"path": active_save_path}))
	else:
		var collision_diagnostic: Dictionary = _validate_save_collision(session, active_save_path)
		if not collision_diagnostic.is_empty():
			diagnostics.append(collision_diagnostic)

	_validate_token_entries(card_data.card_play_actions, "card_play_actions", true, diagnostics)
	_validate_token_entries(card_data.card_discard_actions, "card_discard_actions", true, diagnostics)
	_validate_token_entries(card_data.card_end_of_turn_actions, "card_end_of_turn_actions", true, diagnostics)
	_validate_token_entries(card_data.card_exhaust_actions, "card_exhaust_actions", true, diagnostics)
	_validate_token_entries(card_data.card_draw_actions, "card_draw_actions", true, diagnostics)
	_validate_token_entries(card_data.card_retain_actions, "card_retain_actions", true, diagnostics)
	_validate_token_entries(card_data.card_right_click_actions, "card_right_click_actions", true, diagnostics)
	_validate_token_entries(card_data.card_initial_combat_actions, "card_initial_combat_actions", true, diagnostics)
	_validate_token_entries(card_data.card_add_to_deck_actions, "card_add_to_deck_actions", true, diagnostics)
	_validate_token_entries(card_data.card_remove_from_deck_actions, "card_remove_from_deck_actions", true, diagnostics)
	_validate_token_entries(card_data.card_transform_in_deck_actions, "card_transform_in_deck_actions", true, diagnostics)
	_validate_token_entries(card_data.card_play_validators, "card_play_validators", false, diagnostics)
	_validate_token_entries(card_data.card_glow_validators, "card_glow_validators", false, diagnostics)

	if card_data.card_texture_path.strip_edges() != "" and not _texture_path_exists(card_data.card_texture_path):
		diagnostics.append(_make_diagnostic("missing_texture", "warning", "Card texture path could not be resolved.", "card_texture_path", {"path": card_data.card_texture_path}))

	var target_usage: Dictionary = _analyze_target_requirement(card_data.card_play_actions)
	if card_data.card_requires_target and not target_usage["needs_target"]:
		diagnostics.append(_make_diagnostic("target_requirement_mismatch", "warning", "Card requires a target, but no play action appears to use a target.", "card_requires_target"))
	elif not card_data.card_requires_target and target_usage["needs_target"]:
		diagnostics.append(_make_diagnostic("target_requirement_mismatch", "warning", "Card does not require a target, but one or more play actions appear to target enemies.", "card_requires_target"))

	session.diagnostics = diagnostics
	return diagnostics

func get_action_options(context: String) -> Array[Dictionary]:
	return CardEditorMetadataAdapter.list_actions_for_context(context)

func get_validator_options(context: String) -> Array[Dictionary]:
	return CardEditorMetadataAdapter.list_validators_for_context(context)

func get_action_metadata(token_or_path: String) -> Dictionary:
	return CardEditorMetadataAdapter.get_action_metadata(token_or_path)

func get_validator_metadata(token_or_path: String) -> Dictionary:
	return CardEditorMetadataAdapter.get_validator_metadata(token_or_path)

func create_action_entry(token_or_path: String) -> Dictionary:
	return CardEditorMetadataAdapter.create_default_entry(token_or_path)

func create_validator_entry(token_or_path: String) -> Dictionary:
	return CardEditorMetadataAdapter.create_default_entry(token_or_path)

func get_entry_context(property_name: String) -> String:
	return str(CARD_ARRAY_PROPERTIES.get(property_name, ""))

func add_entry(session: CardEditorSession, property_name: String, token_or_path: String, values: Dictionary = {}, insert_index: int = -1) -> Dictionary:
	var entries: Array = _get_card_array_property(session, property_name)
	if entries.is_empty() and not CARD_ARRAY_PROPERTIES.has(property_name):
		return {}
	var entry: Dictionary = CardEditorMetadataAdapter.create_default_entry(token_or_path)
	if entry.is_empty():
		return {}
	var entry_key: String = entry.keys()[0]
	var entry_values: Dictionary = entry[entry_key]
	entry_values.merge(values, true)
	entry[entry_key] = entry_values
	if insert_index < 0 or insert_index >= len(entries):
		entries.append(entry)
	else:
		entries.insert(insert_index, entry)
	_set_card_array_property(session, property_name, entries)
	return entry

func replace_entry(session: CardEditorSession, property_name: String, index: int, token_or_path: String, values: Dictionary = {}) -> Dictionary:
	var entries: Array = _get_card_array_property(session, property_name)
	if index < 0 or index >= len(entries):
		return {}
	var entry: Dictionary = CardEditorMetadataAdapter.create_default_entry(token_or_path)
	if entry.is_empty():
		return {}
	var entry_key: String = entry.keys()[0]
	var entry_values: Dictionary = entry[entry_key]
	entry_values.merge(values, true)
	entry[entry_key] = entry_values
	entries[index] = entry
	_set_card_array_property(session, property_name, entries)
	return entry

func update_entry_values(session: CardEditorSession, property_name: String, index: int, values: Dictionary, merge_values: bool = true) -> Dictionary:
	var entries: Array = _get_card_array_property(session, property_name)
	if index < 0 or index >= len(entries):
		return {}
	var current_entry: Dictionary = entries[index]
	if len(current_entry.keys()) != 1:
		return {}
	var token: String = current_entry.keys()[0]
	var current_values: Dictionary = current_entry[token]
	if not merge_values:
		current_values.clear()
	current_values.merge(values, true)
	current_entry[token] = current_values
	entries[index] = current_entry
	_set_card_array_property(session, property_name, entries)
	return current_entry

func remove_entry(session: CardEditorSession, property_name: String, index: int) -> bool:
	var entries: Array = _get_card_array_property(session, property_name)
	if index < 0 or index >= len(entries):
		return false
	entries.remove_at(index)
	_set_card_array_property(session, property_name, entries)
	return true

func move_entry(session: CardEditorSession, property_name: String, from_index: int, to_index: int) -> bool:
	var entries: Array = _get_card_array_property(session, property_name)
	if from_index < 0 or from_index >= len(entries):
		return false
	if to_index < 0 or to_index >= len(entries):
		return false
	var entry: Variant = entries[from_index]
	entries.remove_at(from_index)
	entries.insert(to_index, entry)
	_set_card_array_property(session, property_name, entries)
	return true

func set_card_property(session: CardEditorSession, property_name: String, value: Variant) -> bool:
	if session == null or session.working_card_data == null:
		return false
	var card_data: CardData = session.working_card_data
	var current_properties: Array[String] = card_data.get_serializable_property_names()
	if not current_properties.has(property_name):
		return false
	card_data.set(property_name, value)
	_after_card_mutation(session, property_name)
	return true

func set_dictionary_value(session: CardEditorSession, property_name: String, key: String, value: Variant) -> bool:
	if session == null or session.working_card_data == null:
		return false
	var current_dictionary: Dictionary = session.working_card_data.get(property_name)
	if not (current_dictionary is Dictionary):
		return false
	current_dictionary[key] = value
	session.working_card_data.set(property_name, current_dictionary)
	_after_card_mutation(session, property_name)
	return true

func remove_dictionary_value(session: CardEditorSession, property_name: String, key: String) -> bool:
	if session == null or session.working_card_data == null:
		return false
	var current_dictionary: Dictionary = session.working_card_data.get(property_name)
	if not (current_dictionary is Dictionary):
		return false
	if not current_dictionary.has(key):
		return false
	current_dictionary.erase(key)
	session.working_card_data.set(property_name, current_dictionary)
	_after_card_mutation(session, property_name)
	return true

func add_string_array_value(session: CardEditorSession, property_name: String, value: String, allow_duplicates: bool = false) -> bool:
	if session == null or session.working_card_data == null:
		return false
	var current_array: Array = session.working_card_data.get(property_name)
	if not (current_array is Array):
		return false
	if not allow_duplicates and current_array.has(value):
		return true
	current_array.append(value)
	session.working_card_data.set(property_name, current_array)
	_after_card_mutation(session, property_name)
	return true

func remove_array_value(session: CardEditorSession, property_name: String, value: Variant) -> bool:
	if session == null or session.working_card_data == null:
		return false
	var current_array: Array = session.working_card_data.get(property_name)
	if not (current_array is Array):
		return false
	current_array.erase(value)
	session.working_card_data.set(property_name, current_array)
	_after_card_mutation(session, property_name)
	return true

func get_card_summary(session: CardEditorSession) -> Dictionary:
	if session == null:
		return {}
	return session.to_summary()

func _save_session_internal(session: CardEditorSession, save_as_path: String) -> Dictionary:
	if session == null or session.working_card_data == null:
		return {
			"success": false,
			"path": "",
			"diagnostics": [_make_diagnostic("session_missing", "error", "No valid session was provided for saving.")],
		}

	if save_as_path.strip_edges() != "":
		session.manual_save_override_path = save_as_path.strip_edges()
	session.recompute_managed_path()
	_normalize_card_resource(session.working_card_data)
	var diagnostics: Array[Dictionary] = validate_session(session)
	if _has_error_diagnostics(diagnostics):
		return {
			"success": false,
			"path": session.get_active_save_path(),
			"diagnostics": diagnostics,
		}

	var save_path: String = session.get_active_save_path()
	var target_directory: String = ProjectSettings.globalize_path(save_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(target_directory)
	var save_result: Error = ResourceSaver.save(session.working_card_data, save_path)
	if save_result != OK:
		var save_diagnostic: Dictionary = _make_diagnostic("save_failed", "error", "Failed to save card resource.", "save_path", {"path": save_path, "error_code": save_result})
		session.diagnostics = diagnostics + [save_diagnostic]
		return {
			"success": false,
			"path": save_path,
			"diagnostics": session.diagnostics,
		}

	session.original_resource_path = save_path
	session.clear_dirty()
	session.refresh_diagnostics(self)
	return {
		"success": true,
		"path": save_path,
		"diagnostics": session.diagnostics,
	}

func _discover_cards_recursive(directory_path: String, output_cards: Array[Dictionary]) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		last_discovery_diagnostics.append(_make_diagnostic("directory_open_failed", "warning", "Could not open card directory.", "resource_path", {"path": directory_path}))
		return
	directory.list_dir_begin()
	while true:
		var entry_name: String = directory.get_next()
		if entry_name == "":
			break
		if entry_name.begins_with("."):
			continue
		var child_path: String = directory_path.path_join(entry_name)
		if directory.current_is_dir():
			_discover_cards_recursive(child_path, output_cards)
			continue
		if not entry_name.to_lower().ends_with(".tres") and not entry_name.to_lower().ends_with(".res"):
			continue
		var loaded_resource: Resource = load(child_path)
		if loaded_resource == null:
			last_discovery_diagnostics.append(_make_diagnostic("resource_load_failed", "warning", "Failed to load card resource during discovery.", "resource_path", {"path": child_path}))
			continue
		if not (loaded_resource is CardData):
			continue
		var card_data: CardData = loaded_resource
		output_cards.append({
			"object_id": card_data.object_id,
			"card_name": card_data.card_name,
			"card_color_id": card_data.card_color_id,
			"card_rarity": card_data.card_rarity,
			"resource_path": child_path,
		})
	directory.list_dir_end()

func _validate_token_entries(entries: Array, property_name: String, is_action: bool, diagnostics: Array[Dictionary]) -> void:
	for index: int in range(len(entries)):
		var entry: Variant = entries[index]
		if not (entry is Dictionary):
			diagnostics.append(_make_diagnostic(is_action ? "malformed_action_entry" : "malformed_validator_entry", "error", "Entry must be a Dictionary.", property_name, {"index": index}))
			continue
		var entry_dict: Dictionary = entry
		if len(entry_dict.keys()) != 1:
			diagnostics.append(_make_diagnostic(is_action ? "malformed_action_entry" : "malformed_validator_entry", "error", "Entry must contain exactly one token key.", property_name, {"index": index}))
			continue
		var token_or_path: String = str(entry_dict.keys()[0])
		var resolved_script: Script = Scripts.resolve_script(token_or_path)
		if resolved_script == null:
			diagnostics.append(_make_diagnostic(is_action ? "unresolved_action_token" : "unresolved_validator_token", "error", "Token could not be resolved.", property_name, {"index": index, "token": token_or_path}))
		var values: Variant = entry_dict[token_or_path]
		if not (values is Dictionary):
			diagnostics.append(_make_diagnostic(is_action ? "malformed_action_entry" : "malformed_validator_entry", "error", "Entry payload must be a Dictionary.", property_name, {"index": index, "token": token_or_path}))

func _validate_save_collision(session: CardEditorSession, save_path: String) -> Dictionary:
	if not ResourceLoader.exists(save_path):
		return {}
	if save_path == session.original_resource_path:
		return {}
	var existing_resource: Resource = load(save_path)
	if existing_resource == null:
		return _make_diagnostic("path_collision", "error", "A resource already exists at the target path and could not be loaded.", "save_path", {"path": save_path})
	if not (existing_resource is CardData):
		return _make_diagnostic("path_collision", "error", "The target path already contains a non-card resource.", "save_path", {"path": save_path})
	var existing_card: CardData = existing_resource
	if existing_card.object_id != session.working_card_data.object_id:
		return _make_diagnostic("path_collision", "error", "The target path already belongs to a different card.", "save_path", {"path": save_path, "existing_object_id": existing_card.object_id})
	return {}

func _analyze_target_requirement(action_entries: Array[Dictionary]) -> Dictionary:
	var needs_target: bool = false
	for action_entry: Dictionary in action_entries:
		if len(action_entry.keys()) != 1:
			continue
		var token_or_path: String = str(action_entry.keys()[0])
		var normalized_token: String = Scripts.normalize_script_reference(token_or_path)
		if not TARGETED_ACTION_TOKENS.has(normalized_token):
			continue
		var action_values: Dictionary = action_entry[token_or_path]
		var target_override: int = action_values.get("target_override", BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS)
		if target_override == BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS:
			needs_target = true
			break
	return {
		"needs_target": needs_target
	}

func _texture_path_exists(texture_path: String) -> bool:
	if texture_path.begins_with("res://"):
		return ResourceLoader.exists(texture_path) or FileAccess.file_exists(ProjectSettings.globalize_path(texture_path))
	if texture_path.begins_with("user://"):
		return FileAccess.file_exists(ProjectSettings.globalize_path(texture_path))
	return FileAccess.file_exists(ProjectSettings.globalize_path("res://" + texture_path))

func _is_supported_resource_path(path: String) -> bool:
	if path == "":
		return false
	if not path.begins_with("res://"):
		return false
	var normalized_path: String = path.to_lower()
	return normalized_path.ends_with(".tres") or normalized_path.ends_with(".res")

func _get_card_array_property(session: CardEditorSession, property_name: String) -> Array:
	if session == null or session.working_card_data == null:
		return []
	if not CARD_ARRAY_PROPERTIES.has(property_name):
		return []
	var current_array: Array = session.working_card_data.get(property_name)
	return current_array

func _set_card_array_property(session: CardEditorSession, property_name: String, values: Array) -> void:
	if session == null or session.working_card_data == null:
		return
	var typed_array: Array = session.working_card_data.get(property_name)
	typed_array.clear()
	typed_array.assign(values)
	session.working_card_data.set(property_name, typed_array)
	_after_card_mutation(session, property_name)

func _after_card_mutation(session: CardEditorSession, property_name: String) -> void:
	if session == null:
		return
	if property_name == "card_kind":
		session.working_card_data.synchronize_card_kind_rules()
	session.recompute_managed_path()
	session.mark_dirty()
	session.refresh_diagnostics(self)

func _normalize_card_resource(card_data: CardData) -> void:
	if card_data == null:
		return
	card_data.synchronize_card_kind_rules()
	ContentExporter._normalize_resource_script_references(card_data)

func _has_error_diagnostics(diagnostics: Array[Dictionary]) -> bool:
	for diagnostic: Dictionary in diagnostics:
		if str(diagnostic.get("severity", "")) == "error":
			return true
	return false

func _make_diagnostic(code: String, severity: String, message: String, field: String = "", data: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"severity": severity,
		"message": message,
		"field": field,
		"data": data,
	}
