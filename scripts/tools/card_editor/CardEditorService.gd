@tool
extends RefCounted
class_name CardEditorService

const DEFAULT_CONTENT_ROOT := CardEditorPathUtils.DEFAULT_CONTENT_ROOT
const DEFAULT_TRIAGE_ROOT := CardEditorPathUtils.DEFAULT_TRIAGE_ROOT

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

const SUPPORTED_SESSION_POLICIES := {
	CardEditorSession.SAVE_POLICY_MANAGED_CONTENT: true,
	CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE: true,
	CardEditorSession.SAVE_POLICY_MANUAL: true,
}

var last_discovery_diagnostics: Array[Dictionary] = []

func list_cards(
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	include_triage: bool = true,
	include_content: bool = true
) -> Array[Dictionary]:
	var cards: Array[Dictionary] = list_library_cards(content_root, triage_root, include_triage, include_content)
	var compact_cards: Array[Dictionary] = []
	for entry: Dictionary in cards:
		compact_cards.append({
			"object_id": entry.get("object_id", ""),
			"card_name": entry.get("card_name", ""),
			"card_color_id": entry.get("card_color_id", ""),
			"card_rarity": entry.get("card_rarity", CardData.CARD_RARITIES.COMMON),
			"resource_path": entry.get("resource_path", ""),
			"source_bucket": entry.get("source_bucket", ""),
			"owner_bucket": entry.get("owner_bucket", ""),
		})
	return compact_cards

func list_library_cards(
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	include_triage: bool = true,
	include_content: bool = true
) -> Array[Dictionary]:
	last_discovery_diagnostics.clear()
	var cards: Array[Dictionary] = []
	if include_content:
		_discover_cards_in_root(content_root, "content", content_root, triage_root, cards)
	if include_triage:
		_discover_cards_in_root(triage_root, "triage", content_root, triage_root, cards)
	cards.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_name: String = str(left.get("card_name", left.get("object_id", "")))
		var right_name: String = str(right.get("card_name", right.get("object_id", "")))
		if left_name == right_name:
			return str(left.get("resource_path", "")) < str(right.get("resource_path", ""))
		return left_name < right_name
	)
	return cards

func filter_library_cards(entries: Array[Dictionary], filters: Dictionary = {}, search_text: String = "") -> Array[Dictionary]:
	var normalized_search: String = search_text.strip_edges().to_lower()
	var filtered_cards: Array[Dictionary] = []
	for entry: Dictionary in entries:
		if not _library_entry_matches_filters(entry, filters, normalized_search):
			continue
		filtered_cards.append(entry)
	return filtered_cards

func get_library_facets(entries: Array[Dictionary]) -> Dictionary:
	var facets: Dictionary = {
		"source_bucket": {},
		"owner_bucket": {},
		"card_color_id": {},
		"card_rarity": {},
		"card_type": {},
		"card_kind": {},
	}
	for entry: Dictionary in entries:
		for facet_name: String in facets.keys():
			var facet_value: Variant = entry.get(facet_name, null)
			if facet_value == null:
				continue
			var facet_bucket: Dictionary = facets[facet_name]
			facet_bucket[facet_value] = int(facet_bucket.get(facet_value, 0)) + 1
			facets[facet_name] = facet_bucket
	return facets

func find_cards_by_object_id(
	object_id: String,
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	include_triage: bool = true,
	include_content: bool = true
) -> Array[Dictionary]:
	var matching_cards: Array[Dictionary] = []
	if object_id.strip_edges() == "":
		return matching_cards
	for card_entry: Dictionary in list_library_cards(content_root, triage_root, include_triage, include_content):
		if str(card_entry.get("object_id", "")) == object_id:
			matching_cards.append(card_entry)
	return matching_cards

func get_discovery_diagnostics() -> Array[Dictionary]:
	return last_discovery_diagnostics.duplicate(true)

func create_blank_session(
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	save_policy: String = CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE
) -> CardEditorSession:
	var card_data := CardData.new()
	var session := CardEditorSession.new(card_data, "", content_root, triage_root, save_policy)
	session.recompute_managed_paths()
	session.refresh_diagnostics(self)
	return session

func create_blank_session_from_preset(
	preset_id: String,
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	save_policy: String = CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE
) -> CardEditorSession:
	var session: CardEditorSession = create_blank_session(content_root, triage_root, save_policy)
	apply_preset_to_session(session, preset_id, false)
	session.mark_dirty()
	return session

func load_session(
	resource_path: String,
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	save_policy: String = ""
) -> CardEditorSession:
	var resource: Resource = load(resource_path)
	if not (resource is CardData):
		push_error("CardEditorService: Resource is not CardData: %s" % resource_path)
		return null
	var resolved_save_policy: String = save_policy
	if resolved_save_policy == "":
		if CardEditorPathUtils.path_is_within_root(resource_path, triage_root):
			resolved_save_policy = CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE
		else:
			resolved_save_policy = CardEditorSession.SAVE_POLICY_MANAGED_CONTENT
	var session_card: CardData = (resource as CardData).duplicate(true)
	var session := CardEditorSession.new(session_card, resource_path, content_root, triage_root, resolved_save_policy)
	session.recompute_managed_paths()
	session.refresh_diagnostics(self)
	return session

func duplicate_session(
	source: Variant,
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	save_policy: String = CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE
) -> CardEditorSession:
	var source_session: CardEditorSession = null
	if source is CardEditorSession:
		source_session = source
	elif source is String:
		source_session = load_session(source, content_root, triage_root)
	if source_session == null or source_session.working_card_data == null:
		return null
	var duplicated_card: CardData = source_session.working_card_data.duplicate(true)
	var session := CardEditorSession.new(duplicated_card, "", content_root, triage_root, save_policy)
	session.recompute_managed_paths()
	session.mark_dirty()
	session.refresh_diagnostics(self)
	return session

func set_session_save_policy(session: CardEditorSession, save_policy: String) -> bool:
	if session == null:
		return false
	if not SUPPORTED_SESSION_POLICIES.has(save_policy):
		return false
	session.set_save_policy(save_policy)
	session.refresh_diagnostics(self)
	return true

func save_session(session: CardEditorSession) -> Dictionary:
	return _save_session_internal(session, "")

func save_session_as(session: CardEditorSession, target_path: String) -> Dictionary:
	return _save_session_internal(session, target_path)

func save_session_to_triage(session: CardEditorSession) -> Dictionary:
	if session == null:
		return {"success": false, "path": "", "diagnostics": [_make_diagnostic("session_missing", "error", "No valid session was provided for saving.")]}
	session.set_save_policy(CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE)
	session.recompute_managed_paths()
	return _save_session_internal(session, session.managed_triage_save_path)

func promote_session_to_content(session: CardEditorSession) -> Dictionary:
	if session == null:
		return {"success": false, "path": "", "diagnostics": [_make_diagnostic("session_missing", "error", "No valid session was provided for promotion.")]}
	session.set_save_policy(CardEditorSession.SAVE_POLICY_MANAGED_CONTENT)
	session.recompute_managed_paths()
	return _save_session_internal(session, session.managed_save_path)

func apply_preset_to_session(session: CardEditorSession, preset_id: String, preserve_identity: bool = true) -> bool:
	if session == null or session.working_card_data == null:
		return false
	var applied: bool = CardEditorPresets.apply_preset(session.working_card_data, preset_id, preserve_identity)
	if applied:
		_after_card_mutation(session, "")
	return applied

func list_presets() -> Array[Dictionary]:
	return CardEditorPresets.list_presets()

func get_card_field_sections() -> Array[Dictionary]:
	return CardEditorSchema.get_card_field_sections()

func get_card_field_definitions() -> Dictionary[String, Dictionary]:
	return CardEditorSchema.get_card_field_definitions()

func get_card_value_definitions() -> Dictionary[String, Dictionary]:
	return CardEditorSchema.get_card_value_definitions()

func get_library_filter_definitions() -> Array[Dictionary]:
	return CardEditorSchema.get_library_filter_definitions()

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
	session.recompute_managed_paths()

	if card_data.object_id.strip_edges() == "":
		diagnostics.append(_make_diagnostic("empty_object_id", "error", "Card object_id cannot be empty.", "object_id"))
	elif not _is_object_id_well_formed(card_data.object_id):
		diagnostics.append(_make_diagnostic("object_id_format", "warning", "Card object_id should be lowercase snake_case and typically start with card_.", "object_id"))
	if card_data.card_name.strip_edges() == "":
		diagnostics.append(_make_diagnostic("empty_card_name", "error", "Card name cannot be empty.", "card_name"))

	if not SUPPORTED_SESSION_POLICIES.has(session.save_policy):
		diagnostics.append(_make_diagnostic("invalid_save_policy", "error", "Unknown card editor save policy.", "save_policy", {"save_policy": session.save_policy}))

	var active_save_path: String = session.get_active_save_path().strip_edges()
	if active_save_path == "":
		diagnostics.append(_make_diagnostic("empty_save_path", "error", "Card save path is empty.", "save_path"))
	elif not _is_supported_resource_path(active_save_path):
		diagnostics.append(_make_diagnostic("invalid_save_path", "error", "Card save path must point to a .tres or .res file under res://.", "save_path", {"path": active_save_path}))
	else:
		var collision_diagnostic: Dictionary = _validate_save_collision(session, active_save_path)
		if not collision_diagnostic.is_empty():
			diagnostics.append(collision_diagnostic)
		_validate_save_path_policy(session, active_save_path, diagnostics)

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

	_validate_string_array(card_data.card_keyword_object_ids, "card_keyword_object_ids", diagnostics, false)
	_validate_string_array(card_data.card_tags, "card_tags", diagnostics, true)
	_validate_dictionary_keys(card_data.card_values, "card_values", diagnostics)
	_validate_dictionary_keys(card_data.card_first_upgrade_property_changes, "card_first_upgrade_property_changes", diagnostics)
	_validate_dictionary_keys(card_data.card_upgrade_value_improvements, "card_upgrade_value_improvements", diagnostics)
	_validate_description_placeholders(card_data, diagnostics)
	_validate_card_upgrade_configuration(card_data, diagnostics)
	_validate_card_cost_configuration(card_data, diagnostics)
	_validate_library_object_id_collisions(session, diagnostics)

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

func rename_dictionary_key(session: CardEditorSession, property_name: String, from_key: String, to_key: String) -> bool:
	if session == null or session.working_card_data == null:
		return false
	var normalized_from_key: String = from_key.strip_edges()
	var normalized_to_key: String = to_key.strip_edges()
	if normalized_from_key == "" or normalized_to_key == "":
		return false
	if normalized_from_key == normalized_to_key:
		return true
	var current_dictionary: Dictionary = session.working_card_data.get(property_name)
	if not (current_dictionary is Dictionary):
		return false
	if not current_dictionary.has(normalized_from_key):
		return false
	if current_dictionary.has(normalized_to_key):
		return false
	var value: Variant = current_dictionary[normalized_from_key]
	current_dictionary.erase(normalized_from_key)
	current_dictionary[normalized_to_key] = value
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
		if save_as_path == session.managed_save_path:
			session.save_policy = CardEditorSession.SAVE_POLICY_MANAGED_CONTENT
		elif save_as_path == session.managed_triage_save_path:
			session.save_policy = CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE
		else:
			session.save_policy = CardEditorSession.SAVE_POLICY_MANUAL
	session.recompute_managed_paths()
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
	if save_path == session.managed_save_path:
		session.save_policy = CardEditorSession.SAVE_POLICY_MANAGED_CONTENT
	elif save_path == session.managed_triage_save_path:
		session.save_policy = CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE
	else:
		session.save_policy = CardEditorSession.SAVE_POLICY_MANUAL
	session.clear_dirty()
	session.refresh_diagnostics(self)
	return {
		"success": true,
		"path": save_path,
		"diagnostics": session.diagnostics,
	}

func _discover_cards_in_root(
	root_path: String,
	source_bucket: String,
	content_root: String,
	triage_root: String,
	output_cards: Array[Dictionary]
) -> void:
	var cards_root: String = root_path.path_join("cards")
	var directory: DirAccess = DirAccess.open(cards_root)
	if directory == null:
		last_discovery_diagnostics.append(_make_diagnostic("directory_open_failed", "warning", "Could not open card directory.", "resource_path", {"path": cards_root}))
		return
	_discover_cards_recursive(cards_root, source_bucket, content_root, triage_root, output_cards)

func _discover_cards_recursive(
	directory_path: String,
	source_bucket: String,
	content_root: String,
	triage_root: String,
	output_cards: Array[Dictionary]
) -> void:
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
			_discover_cards_recursive(child_path, source_bucket, content_root, triage_root, output_cards)
			continue
		if not entry_name.to_lower().ends_with(".tres") and not entry_name.to_lower().ends_with(".res"):
			continue
		var loaded_resource: Resource = load(child_path)
		if loaded_resource == null:
			last_discovery_diagnostics.append(_make_diagnostic("resource_load_failed", "warning", "Failed to load card resource during discovery.", "resource_path", {"path": child_path}))
			continue
		if not (loaded_resource is CardData):
			continue
		output_cards.append(_make_card_library_entry(loaded_resource, child_path, source_bucket, content_root, triage_root))
	directory.list_dir_end()

func _make_card_library_entry(
	card_data: CardData,
	resource_path: String,
	source_bucket: String,
	content_root: String,
	triage_root: String
) -> Dictionary:
	var path_metadata: Dictionary = CardEditorPathUtils.analyze_card_resource_path(resource_path, content_root, triage_root)
	var search_blob_parts: Array[String] = [
		card_data.object_id,
		card_data.card_name,
		card_data.card_description,
		str(path_metadata.get("owner_bucket", "")),
		str(path_metadata.get("relative_path", "")),
	]
	for keyword_id: String in card_data.card_keyword_object_ids:
		search_blob_parts.append(keyword_id)
	for card_tag: String in card_data.card_tags:
		search_blob_parts.append(card_tag)
	return {
		"object_id": card_data.object_id,
		"card_name": card_data.card_name,
		"card_color_id": card_data.card_color_id,
		"card_rarity": card_data.card_rarity,
		"card_type": card_data.card_type,
		"card_kind": card_data.get_effective_card_kind(),
		"card_requires_target": card_data.card_requires_target,
		"resource_path": resource_path,
		"source_bucket": source_bucket,
		"source_root": path_metadata.get("source_root", ""),
		"relative_path": path_metadata.get("relative_path", ""),
		"path_segments": path_metadata.get("path_segments", []),
		"owner_bucket": path_metadata.get("owner_bucket", "unknown"),
		"file_name": path_metadata.get("file_name", ""),
		"keyword_ids": card_data.card_keyword_object_ids.duplicate(true),
		"card_tags": card_data.card_tags.duplicate(true),
		"search_blob": " ".join(search_blob_parts).to_lower(),
	}

func _validate_token_entries(entries: Array, property_name: String, is_action: bool, diagnostics: Array[Dictionary]) -> void:
	for index: int in range(len(entries)):
		var entry: Variant = entries[index]
		if not (entry is Dictionary):
			diagnostics.append(_make_diagnostic("malformed_action_entry" if is_action else "malformed_validator_entry", "error", "Entry must be a Dictionary.", property_name, {"index": index}))
			continue
		var entry_dict: Dictionary = entry
		if len(entry_dict.keys()) != 1:
			diagnostics.append(_make_diagnostic("malformed_action_entry" if is_action else "malformed_validator_entry", "error", "Entry must contain exactly one token key.", property_name, {"index": index}))
			continue
		var token_or_path: String = str(entry_dict.keys()[0])
		var resolved_script: Script = Scripts.resolve_script(token_or_path)
		if resolved_script == null:
			diagnostics.append(_make_diagnostic("unresolved_action_token" if is_action else "unresolved_validator_token", "error", "Token could not be resolved.", property_name, {"index": index, "token": token_or_path}))
		var values: Variant = entry_dict[token_or_path]
		if not (values is Dictionary):
			diagnostics.append(_make_diagnostic("malformed_action_entry" if is_action else "malformed_validator_entry", "error", "Entry payload must be a Dictionary.", property_name, {"index": index, "token": token_or_path}))
			continue
		_validate_entry_payload(token_or_path, values, property_name, index, diagnostics)

func _validate_entry_payload(token_or_path: String, values: Dictionary, property_name: String, index: int, diagnostics: Array[Dictionary]) -> void:
	var metadata: Dictionary = ScriptEditorMetadataRegistry.get_resolved_script_metadata(token_or_path)
	if metadata.is_empty():
		return
	var parameter_definitions: Array[Dictionary] = []
	parameter_definitions.assign(metadata.get("parameters", []))
	var parameters_by_name: Dictionary[String, Dictionary] = {}
	for parameter_definition: Dictionary in parameter_definitions:
		var parameter_name: String = str(parameter_definition.get("name", ""))
		if parameter_name == "":
			continue
		parameters_by_name[parameter_name] = parameter_definition
	for value_key: Variant in values.keys():
		var parameter_name_str: String = str(value_key)
		if not parameters_by_name.has(parameter_name_str):
			diagnostics.append(_make_diagnostic("unknown_parameter", "warning", "Entry includes a parameter that the editor metadata does not recognize.", property_name, {"index": index, "token": token_or_path, "parameter": parameter_name_str}))
			continue
		var parameter_definition: Dictionary = parameters_by_name[parameter_name_str]
		var value_type: String = str(parameter_definition.get("value_type", "variant"))
		var value: Variant = values[value_key]
		if not _value_matches_editor_type(value, value_type, parameter_definition):
			diagnostics.append(_make_diagnostic("parameter_type_mismatch", "warning", "Entry parameter type does not match editor metadata.", property_name, {"index": index, "token": token_or_path, "parameter": parameter_name_str, "value_type": value_type}))

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

func _validate_save_path_policy(session: CardEditorSession, save_path: String, diagnostics: Array[Dictionary]) -> void:
	match session.save_policy:
		CardEditorSession.SAVE_POLICY_MANAGED_CONTENT:
			if save_path != session.managed_save_path:
				diagnostics.append(_make_diagnostic("save_policy_path_mismatch", "warning", "Managed content save policy points at a custom path.", "save_path", {"path": save_path}))
		CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE:
			if save_path != session.managed_triage_save_path:
				diagnostics.append(_make_diagnostic("save_policy_path_mismatch", "warning", "Managed triage save policy points at a custom path.", "save_path", {"path": save_path}))
		CardEditorSession.SAVE_POLICY_MANUAL:
			if not CardEditorPathUtils.path_is_within_root(save_path, session.content_root) and not CardEditorPathUtils.path_is_within_root(save_path, session.triage_root):
				diagnostics.append(_make_diagnostic("manual_path_external", "warning", "Manual save path is outside the configured content and triage roots.", "save_path", {"path": save_path}))

func _validate_library_object_id_collisions(session: CardEditorSession, diagnostics: Array[Dictionary]) -> void:
	if session == null or session.working_card_data == null:
		return
	var duplicate_entries: Array[Dictionary] = find_cards_by_object_id(session.working_card_data.object_id, session.content_root, session.triage_root, true, true)
	var duplicate_paths: Array[String] = []
	for entry: Dictionary in duplicate_entries:
		var entry_path: String = str(entry.get("resource_path", ""))
		if entry_path == "":
			continue
		if entry_path == session.original_resource_path:
			continue
		if entry_path == session.get_active_save_path():
			continue
		duplicate_paths.append(entry_path)
	if len(duplicate_paths) > 0:
		diagnostics.append(_make_diagnostic("duplicate_object_id", "warning", "Another card with the same object_id already exists in the library roots.", "object_id", {"paths": duplicate_paths}))

func _validate_description_placeholders(card_data: CardData, diagnostics: Array[Dictionary]) -> void:
	var regex := RegEx.new()
	if regex.compile("\\[([A-Za-z0-9_]+)\\]") != OK:
		return
	var missing_placeholders: Array[String] = []
	for result: RegExMatch in regex.search_all(card_data.card_description):
		var placeholder_name: String = result.get_string(1)
		if placeholder_name == "energy_icon":
			continue
		if not card_data.card_values.has(placeholder_name):
			if not missing_placeholders.has(placeholder_name):
				missing_placeholders.append(placeholder_name)
	if len(missing_placeholders) > 0:
		diagnostics.append(_make_diagnostic("missing_description_values", "warning", "Card description references values that are missing from card_values.", "card_description", {"missing_placeholders": missing_placeholders}))

func _validate_string_array(values: Array[String], property_name: String, diagnostics: Array[Dictionary], allow_empty_strings: bool) -> void:
	var seen_values: Dictionary[String, bool] = {}
	for index: int in range(len(values)):
		var string_value: String = values[index]
		if string_value.strip_edges() == "" and not allow_empty_strings:
			diagnostics.append(_make_diagnostic("empty_string_array_value", "warning", "Array contains an empty string.", property_name, {"index": index}))
		if seen_values.has(string_value):
			diagnostics.append(_make_diagnostic("duplicate_string_array_value", "warning", "Array contains duplicate values.", property_name, {"index": index, "value": string_value}))
		seen_values[string_value] = true

func _validate_dictionary_keys(values: Dictionary, property_name: String, diagnostics: Array[Dictionary]) -> void:
	for key: Variant in values.keys():
		if str(key).strip_edges() == "":
			diagnostics.append(_make_diagnostic("empty_dictionary_key", "warning", "Dictionary contains an empty key.", property_name))

func _validate_card_upgrade_configuration(card_data: CardData, diagnostics: Array[Dictionary]) -> void:
	if card_data.card_upgrade_amount_max < 0:
		diagnostics.append(_make_diagnostic("negative_upgrade_max", "error", "Max upgrades cannot be negative.", "card_upgrade_amount_max"))
	if card_data.card_upgrade_amount < 0:
		diagnostics.append(_make_diagnostic("negative_upgrade_amount", "error", "Upgrade amount cannot be negative.", "card_upgrade_amount"))
	if card_data.card_upgrade_amount > card_data.card_upgrade_amount_max:
		diagnostics.append(_make_diagnostic("upgrade_amount_exceeds_max", "warning", "Current upgrade amount exceeds max upgrades.", "card_upgrade_amount"))

func _validate_card_cost_configuration(card_data: CardData, diagnostics: Array[Dictionary]) -> void:
	if card_data.card_energy_cost < 0:
		diagnostics.append(_make_diagnostic("negative_energy_cost", "error", "Card energy cost cannot be negative.", "card_energy_cost"))
	if not card_data.card_energy_cost_is_variable and card_data.card_energy_cost_variable_upper_bound >= 0:
		diagnostics.append(_make_diagnostic("unused_variable_cost_cap", "warning", "Variable cost upper bound is set, but variable cost is disabled.", "card_energy_cost_variable_upper_bound"))

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
	session.recompute_managed_paths()
	session.mark_dirty()
	session.refresh_diagnostics(self)

func _normalize_card_resource(card_data: CardData) -> void:
	if card_data == null:
		return
	card_data.synchronize_card_kind_rules()
	ContentExporter._normalize_resource_script_references(card_data)

func _value_matches_editor_type(value: Variant, value_type: String, parameter_definition: Dictionary = {}) -> bool:
	match value_type:
		"variant":
			return true
		"bool":
			return value is bool
		"int":
			return value is int and not (value is bool)
		"float":
			return value is float or (value is int and not (value is bool))
		"string", "resource_path", "multiline_string":
			return value is String
		"string_array":
			if not (value is Array):
				return false
			for item: Variant in value:
				if not (item is String):
					return false
			return true
		"array":
			return value is Array
		"dictionary":
			return value is Dictionary
		"enum":
			var options: Array = parameter_definition.get("options", [])
			if len(options) == 0:
				return value is int or value is String
			for option: Dictionary in options:
				if option.get("value", null) == value:
					return true
			return false
		_:
			return true

func _library_entry_matches_filters(entry: Dictionary, filters: Dictionary, normalized_search: String) -> bool:
	for filter_name: String in filters.keys():
		var expected_value: Variant = filters[filter_name]
		if expected_value == null:
			continue
		if expected_value is String and str(expected_value).strip_edges() == "":
			continue
		if entry.get(filter_name, null) != expected_value:
			return false
	if normalized_search != "":
		var search_blob: String = str(entry.get("search_blob", ""))
		if not search_blob.contains(normalized_search):
			return false
	return true

func _is_object_id_well_formed(object_id: String) -> bool:
	var regex := RegEx.new()
	if regex.compile("^card_[a-z0-9_]+$") != OK:
		return true
	return regex.search(object_id) != null

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
