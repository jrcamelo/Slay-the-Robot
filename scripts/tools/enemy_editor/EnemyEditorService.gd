@tool
extends RefCounted
class_name EnemyEditorService

const DEFAULT_CONTENT_ROOT := EnemyEditorPathUtils.DEFAULT_CONTENT_ROOT
const DEFAULT_TRIAGE_ROOT := EnemyEditorPathUtils.DEFAULT_TRIAGE_ROOT

const SUPPORTED_SESSION_POLICIES := {
	EnemyEditorSession.SAVE_POLICY_MANAGED_CONTENT: true,
	EnemyEditorSession.SAVE_POLICY_MANAGED_TRIAGE: true,
	EnemyEditorSession.SAVE_POLICY_MANUAL: true,
}

var last_discovery_diagnostics: Array[Dictionary] = []

func list_library_enemies(
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	include_triage: bool = true,
	include_content: bool = true
) -> Array[Dictionary]:
	last_discovery_diagnostics.clear()
	var enemies: Array[Dictionary] = []
	if include_content:
		_discover_enemies_in_root(content_root, "content", content_root, triage_root, enemies)
	if include_triage:
		_discover_enemies_in_root(triage_root, "triage", content_root, triage_root, enemies)
	enemies.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_name: String = str(left.get("enemy_name", left.get("object_id", "")))
		var right_name: String = str(right.get("enemy_name", right.get("object_id", "")))
		if left_name == right_name:
			return str(left.get("resource_path", "")) < str(right.get("resource_path", ""))
		return left_name < right_name
	)
	return enemies

func list_enemies(
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	include_triage: bool = true,
	include_content: bool = true
) -> Array[Dictionary]:
	var compact_enemies: Array[Dictionary] = []
	for entry: Dictionary in list_library_enemies(content_root, triage_root, include_triage, include_content):
		compact_enemies.append({
			"object_id": entry.get("object_id", ""),
			"enemy_name": entry.get("enemy_name", ""),
			"enemy_type": entry.get("enemy_type", EnemyData.ENEMY_TYPES.STANDARD),
			"enemy_is_minion": entry.get("enemy_is_minion", false),
			"resource_path": entry.get("resource_path", ""),
			"source_bucket": entry.get("source_bucket", ""),
			"owner_bucket": entry.get("owner_bucket", ""),
		})
	return compact_enemies

func filter_library_enemies(entries: Array[Dictionary], filters: Dictionary = {}, search_text: String = "") -> Array[Dictionary]:
	var normalized_search: String = search_text.strip_edges().to_lower()
	var filtered_entries: Array[Dictionary] = []
	for entry: Dictionary in entries:
		if not _library_entry_matches_filters(entry, filters, normalized_search):
			continue
		filtered_entries.append(entry)
	return filtered_entries

func get_library_facets(entries: Array[Dictionary]) -> Dictionary:
	var facets: Dictionary = {
		"source_bucket": {},
		"owner_bucket": {},
		"enemy_type": {},
		"enemy_is_minion": {},
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

func find_enemies_by_object_id(
	object_id: String,
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	include_triage: bool = true,
	include_content: bool = true
) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	if object_id.strip_edges() == "":
		return matches
	for enemy_entry: Dictionary in list_library_enemies(content_root, triage_root, include_triage, include_content):
		if str(enemy_entry.get("object_id", "")) == object_id:
			matches.append(enemy_entry)
	return matches

func get_discovery_diagnostics() -> Array[Dictionary]:
	return last_discovery_diagnostics.duplicate(true)

func create_blank_session(
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	save_policy: String = EnemyEditorSession.SAVE_POLICY_MANAGED_TRIAGE
) -> EnemyEditorSession:
	var enemy_data := EnemyData.new()
	enemy_data.enemy_name = "New Enemy"
	enemy_data.object_id = "enemy_new"
	var opening_stage: EnemyStageData = EnemyStageData.new()
	opening_stage.object_id = "stage_open"
	opening_stage.label = "Open"
	opening_stage.next_stage_id = "stage_open"
	var opening_variant: EnemyIntentVariantData = EnemyIntentVariantData.new()
	opening_stage.intents.append(opening_variant)
	enemy_data.opening_stage_id = opening_stage.object_id
	enemy_data.stages.append(opening_stage)
	var session := EnemyEditorSession.new(enemy_data, "", content_root, triage_root, save_policy)
	session.refresh_diagnostics(self)
	return session

func load_session(
	resource_path: String,
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	save_policy: String = ""
) -> EnemyEditorSession:
	var resource: Resource = load(resource_path)
	if not (resource is EnemyData):
		push_error("EnemyEditorService: Resource is not EnemyData: %s" % resource_path)
		return null
	var resolved_save_policy: String = save_policy
	if resolved_save_policy == "":
		resolved_save_policy = EnemyEditorSession.SAVE_POLICY_MANAGED_TRIAGE if EnemyEditorPathUtils.path_is_within_root(resource_path, triage_root) else EnemyEditorSession.SAVE_POLICY_MANAGED_CONTENT
	var session_enemy: EnemyData = (resource as EnemyData).duplicate(true)
	var session := EnemyEditorSession.new(session_enemy, resource_path, content_root, triage_root, resolved_save_policy)
	session.refresh_diagnostics(self)
	return session

func duplicate_session(
	source: Variant,
	content_root: String = DEFAULT_CONTENT_ROOT,
	triage_root: String = DEFAULT_TRIAGE_ROOT,
	save_policy: String = EnemyEditorSession.SAVE_POLICY_MANAGED_TRIAGE
) -> EnemyEditorSession:
	var source_session: EnemyEditorSession = null
	if source is EnemyEditorSession:
		source_session = source
	elif source is String:
		source_session = load_session(source, content_root, triage_root)
	if source_session == null or source_session.working_enemy_data == null:
		return null
	var duplicated_enemy: EnemyData = source_session.working_enemy_data.duplicate(true)
	var session := EnemyEditorSession.new(duplicated_enemy, "", content_root, triage_root, save_policy)
	session.set_preferred_relative_directory(source_session.preferred_relative_directory)
	session.mark_dirty()
	session.refresh_diagnostics(self)
	return session

func set_session_save_policy(session: EnemyEditorSession, save_policy: String) -> bool:
	if session == null or not SUPPORTED_SESSION_POLICIES.has(save_policy):
		return false
	session.set_save_policy(save_policy)
	session.refresh_diagnostics(self)
	return true

func save_session(session: EnemyEditorSession) -> Dictionary:
	return _save_session_internal(session, "")

func save_session_as(session: EnemyEditorSession, target_path: String) -> Dictionary:
	return _save_session_internal(session, target_path)

func save_session_to_triage(session: EnemyEditorSession) -> Dictionary:
	if session == null:
		return {"success": false, "path": "", "diagnostics": [_make_diagnostic("session_missing", "error", "No valid session was provided for saving.")]}
	session.set_save_policy(EnemyEditorSession.SAVE_POLICY_MANAGED_TRIAGE)
	session.recompute_managed_paths()
	return _save_session_internal(session, session.managed_triage_save_path)

func promote_session_to_content(session: EnemyEditorSession) -> Dictionary:
	if session == null:
		return {"success": false, "path": "", "diagnostics": [_make_diagnostic("session_missing", "error", "No valid session was provided for promotion.")]}
	session.set_save_policy(EnemyEditorSession.SAVE_POLICY_MANAGED_CONTENT)
	session.recompute_managed_paths()
	return _save_session_internal(session, session.managed_save_path)

func get_top_level_field_definitions() -> Dictionary[String, Dictionary]:
	return EnemyEditorSchema.get_top_level_field_definitions()

func get_stage_field_definitions() -> Dictionary[String, Dictionary]:
	return EnemyEditorSchema.get_stage_field_definitions()

func get_reactive_stage_field_definitions() -> Dictionary[String, Dictionary]:
	return EnemyEditorSchema.get_reactive_stage_field_definitions()

func get_intent_variant_field_definitions() -> Dictionary[String, Dictionary]:
	return EnemyEditorSchema.get_intent_variant_field_definitions()

func get_intent_field_definitions() -> Dictionary[String, Dictionary]:
	return EnemyEditorSchema.get_intent_field_definitions()

func get_difficulty_override_field_definitions() -> Dictionary[String, Dictionary]:
	return EnemyEditorSchema.get_difficulty_override_field_definitions()

func get_library_filter_definitions() -> Array[Dictionary]:
	return EnemyEditorSchema.get_library_filter_definitions()

func list_action_options(context: String = "") -> Array[Dictionary]:
	var metadata: Array[Dictionary] = ScriptEditorMetadataRegistry.get_all_action_metadata()
	if context == "":
		return metadata
	var filtered: Array[Dictionary] = []
	for entry: Dictionary in metadata:
		var contexts: Array[String] = []
		contexts.assign(entry.get("contexts", []))
		if contexts.has(context):
			filtered.append(entry)
	return filtered

func list_validator_options(context: String = "") -> Array[Dictionary]:
	var metadata: Array[Dictionary] = ScriptEditorMetadataRegistry.get_all_validator_metadata()
	if context == "":
		return metadata
	var filtered: Array[Dictionary] = []
	for entry: Dictionary in metadata:
		var contexts: Array[String] = []
		contexts.assign(entry.get("contexts", []))
		if contexts.has(context):
			filtered.append(entry)
	return filtered

func get_action_metadata(token_or_path: String) -> Dictionary:
	return ScriptEditorMetadataRegistry.get_resolved_script_metadata(token_or_path)

func get_validator_metadata(token_or_path: String) -> Dictionary:
	return ScriptEditorMetadataRegistry.get_resolved_script_metadata(token_or_path)

func create_action_entry(token_or_path: String) -> Dictionary:
	return _create_metadata_default_entry(token_or_path)

func create_validator_entry(token_or_path: String) -> Dictionary:
	return _create_metadata_default_entry(token_or_path)

func resolve_preview(session: EnemyEditorSession, preview_state: Variant = null) -> Dictionary:
	if session == null or session.working_enemy_data == null:
		return {"success": false, "diagnostics": [_make_diagnostic("session_missing", "error", "No enemy session was available for preview.")]}
	return EnemyEditorPreviewService.resolve_preview(session.working_enemy_data, preview_state if preview_state != null else session.preview_state)

func get_enemy_summary(session: EnemyEditorSession) -> Dictionary:
	if session == null:
		return {}
	var summary: Dictionary = session.to_summary()
	if session.working_enemy_data == null:
		return summary
	summary["stage_summaries"] = _collect_stage_summaries(session.working_enemy_data.stages)
	summary["reactive_stage_summaries"] = _collect_reactive_stage_summaries(session.working_enemy_data.reactive_stages)
	summary["difficulty_summaries"] = _collect_difficulty_summaries(session.working_enemy_data.difficulty_overrides)
	return summary

func validate_session(session: EnemyEditorSession, include_library_collision_validation: bool = true) -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if session == null:
		diagnostics.append(_make_diagnostic("session_missing", "error", "No enemy editor session was provided."))
		return diagnostics
	var enemy_data: EnemyData = session.working_enemy_data
	if enemy_data == null:
		diagnostics.append(_make_diagnostic("enemy_missing", "error", "The session has no working EnemyData resource."))
		return diagnostics

	session.recompute_managed_paths()

	if enemy_data.object_id.strip_edges() == "":
		diagnostics.append(_make_diagnostic("empty_object_id", "error", "Enemy object_id cannot be empty.", "object_id"))
	elif not _is_object_id_well_formed(enemy_data.object_id):
		diagnostics.append(_make_diagnostic("object_id_format", "warning", "Enemy object_id should be lowercase snake_case and typically start with enemy_.", "object_id"))
	if enemy_data.enemy_name.strip_edges() == "":
		diagnostics.append(_make_diagnostic("empty_enemy_name", "error", "Enemy name cannot be empty.", "enemy_name"))
	if not SUPPORTED_SESSION_POLICIES.has(session.save_policy):
		diagnostics.append(_make_diagnostic("invalid_save_policy", "error", "Unknown enemy editor save policy.", "save_policy", {"save_policy": session.save_policy}))

	var active_save_path: String = session.get_active_save_path().strip_edges()
	if active_save_path == "":
		diagnostics.append(_make_diagnostic("empty_save_path", "error", "Enemy save path is empty.", "save_path"))
	elif not _is_supported_resource_path(active_save_path):
		diagnostics.append(_make_diagnostic("invalid_save_path", "error", "Enemy save path must point to a .tres or .res file under res://.", "save_path", {"path": active_save_path}))
	else:
		var collision_diagnostic: Dictionary = _validate_save_collision(session, active_save_path)
		if not collision_diagnostic.is_empty():
			diagnostics.append(collision_diagnostic)
		_validate_save_path_policy(session, active_save_path, diagnostics)

	for error_message: String in enemy_data.collect_enemy_behavior_validation_errors():
		diagnostics.append(_make_diagnostic("enemy_behavior_validation", "error", error_message, "behavior"))

	_validate_action_entries(enemy_data.enemy_actions_on_death, "enemy_actions_on_death", diagnostics)
	_validate_status_effect_dictionary(enemy_data.enemy_initial_status_effects, "enemy_initial_status_effects", diagnostics)
	_validate_stage_collection(enemy_data.stages, false, diagnostics)
	_validate_reactive_stage_collection(enemy_data.reactive_stages, diagnostics)
	_validate_difficulty_overrides(enemy_data, diagnostics)
	if include_library_collision_validation:
		_validate_library_object_id_collisions(session, diagnostics)

	session.diagnostics = diagnostics
	return diagnostics

func set_enemy_property(session: EnemyEditorSession, property_name: String, value: Variant) -> bool:
	if session == null or session.working_enemy_data == null:
		return false
	session.working_enemy_data.set(property_name, value)
	_after_enemy_mutation(session)
	return true

func create_stage(session: EnemyEditorSession, stage_id: String = "", insert_index: int = -1) -> EnemyStageData:
	if session == null or session.working_enemy_data == null:
		return null
	var stage_data := EnemyStageData.new()
	stage_data.object_id = stage_id if stage_id != "" else _generate_unique_stage_id(session.working_enemy_data, false)
	stage_data.label = stage_data.object_id.to_pascal_case().replace("Stage", "Stage ")
	stage_data.next_stage_id = stage_data.object_id
	stage_data.intents.append(EnemyIntentVariantData.new())
	var stages: Array[EnemyStageData] = session.working_enemy_data.stages.duplicate(true)
	if insert_index < 0 or insert_index >= len(stages):
		stages.append(stage_data)
	else:
		stages.insert(insert_index, stage_data)
	_assign_typed_array(session.working_enemy_data.stages, stages)
	session.working_enemy_data.stages = session.working_enemy_data.stages
	if session.working_enemy_data.opening_stage_id == "":
		session.working_enemy_data.opening_stage_id = stage_data.object_id
	_after_enemy_mutation(session)
	return stage_data

func remove_stage(session: EnemyEditorSession, stage_id: String) -> bool:
	if session == null or session.working_enemy_data == null:
		return false
	var stages: Array[EnemyStageData] = session.working_enemy_data.stages.duplicate(true)
	for index: int in range(len(stages)):
		if stages[index].object_id != stage_id:
			continue
		stages.remove_at(index)
		_assign_typed_array(session.working_enemy_data.stages, stages)
		session.working_enemy_data.stages = session.working_enemy_data.stages
		_after_enemy_mutation(session)
		return true
	return false

func move_stage(session: EnemyEditorSession, from_index: int, to_index: int) -> bool:
	return _move_stage_internal(session, false, from_index, to_index)

func create_reactive_stage(session: EnemyEditorSession, stage_id: String = "", insert_index: int = -1) -> EnemyReactiveStageData:
	if session == null or session.working_enemy_data == null:
		return null
	var stage_data := EnemyReactiveStageData.new()
	stage_data.object_id = stage_id if stage_id != "" else _generate_unique_stage_id(session.working_enemy_data, true)
	stage_data.label = stage_data.object_id.to_pascal_case().replace("Reactive", "Reactive ")
	stage_data.intents.append(EnemyIntentVariantData.new())
	var stages: Array[EnemyReactiveStageData] = session.working_enemy_data.reactive_stages.duplicate(true)
	if insert_index < 0 or insert_index >= len(stages):
		stages.append(stage_data)
	else:
		stages.insert(insert_index, stage_data)
	_assign_typed_array(session.working_enemy_data.reactive_stages, stages)
	session.working_enemy_data.reactive_stages = session.working_enemy_data.reactive_stages
	_after_enemy_mutation(session)
	return stage_data

func remove_reactive_stage(session: EnemyEditorSession, stage_id: String) -> bool:
	if session == null or session.working_enemy_data == null:
		return false
	var stages: Array[EnemyReactiveStageData] = session.working_enemy_data.reactive_stages.duplicate(true)
	for index: int in range(len(stages)):
		if stages[index].object_id != stage_id:
			continue
		stages.remove_at(index)
		_assign_typed_array(session.working_enemy_data.reactive_stages, stages)
		session.working_enemy_data.reactive_stages = session.working_enemy_data.reactive_stages
		_after_enemy_mutation(session)
		return true
	return false

func move_reactive_stage(session: EnemyEditorSession, from_index: int, to_index: int) -> bool:
	return _move_stage_internal(session, true, from_index, to_index)

func set_stage_property(session: EnemyEditorSession, stage_id: String, property_name: String, value: Variant, is_reactive: bool = false) -> bool:
	var stage_data: Variant = _get_stage_by_id(session, stage_id, is_reactive)
	if stage_data == null:
		return false
	stage_data.set(property_name, value)
	_after_enemy_mutation(session)
	return true

func create_intent_variant(session: EnemyEditorSession, stage_id: String, is_reactive: bool = false, insert_index: int = -1) -> EnemyIntentVariantData:
	var stage_data: Variant = _get_stage_by_id(session, stage_id, is_reactive)
	if stage_data == null:
		return null
	var intent_variant := EnemyIntentVariantData.new()
	var variants: Array[EnemyIntentVariantData] = stage_data.intents.duplicate(true)
	var insertion_index: int = len(variants) if insert_index < 0 or insert_index > len(variants) else insert_index
	if insertion_index >= len(variants):
		variants.append(intent_variant)
	else:
		variants.insert(insertion_index, intent_variant)
	_assign_typed_array(stage_data.intents, variants)
	stage_data.intents = stage_data.intents
	_shift_intent_override_indices(session, stage_id, is_reactive, insertion_index, 1)
	_after_enemy_mutation(session)
	return intent_variant

func remove_intent_variant(session: EnemyEditorSession, stage_id: String, variant_index: int, is_reactive: bool = false) -> bool:
	var stage_data: Variant = _get_stage_by_id(session, stage_id, is_reactive)
	if stage_data == null or variant_index < 0 or variant_index >= len(stage_data.intents):
		return false
	var variants: Array[EnemyIntentVariantData] = stage_data.intents.duplicate(true)
	variants.remove_at(variant_index)
	_assign_typed_array(stage_data.intents, variants)
	stage_data.intents = stage_data.intents
	_remove_intent_override_index(session, stage_id, is_reactive, variant_index)
	_after_enemy_mutation(session)
	return true

func move_intent_variant(session: EnemyEditorSession, stage_id: String, from_index: int, to_index: int, is_reactive: bool = false) -> bool:
	var stage_data: Variant = _get_stage_by_id(session, stage_id, is_reactive)
	if stage_data == null:
		return false
	var variants: Array[EnemyIntentVariantData] = stage_data.intents.duplicate(true)
	if from_index < 0 or from_index >= len(variants) or to_index < 0 or to_index >= len(variants):
		return false
	var index_mapping: Dictionary[int, int] = _reorder_index_mapping(len(variants), from_index, to_index)
	var intent_variant: EnemyIntentVariantData = variants[from_index]
	variants.remove_at(from_index)
	variants.insert(to_index, intent_variant)
	_assign_typed_array(stage_data.intents, variants)
	stage_data.intents = stage_data.intents
	_remap_intent_override_indices(session, stage_id, is_reactive, index_mapping)
	_after_enemy_mutation(session)
	return true

func set_intent_field(session: EnemyEditorSession, stage_id: String, variant_index: int, field_name: String, value: Variant, is_reactive: bool = false) -> bool:
	var intent_variant: EnemyIntentVariantData = _get_intent_variant(session, stage_id, variant_index, is_reactive)
	if intent_variant == null:
		return false
	intent_variant.intent.set(field_name, value)
	_after_enemy_mutation(session)
	return true

func set_variant_field(session: EnemyEditorSession, stage_id: String, variant_index: int, field_name: String, value: Variant, is_reactive: bool = false) -> bool:
	var intent_variant: EnemyIntentVariantData = _get_intent_variant(session, stage_id, variant_index, is_reactive)
	if intent_variant == null:
		return false
	if field_name == "intent":
		return false
	intent_variant.set(field_name, value)
	_after_enemy_mutation(session)
	return true

func patch_variant_conditions(session: EnemyEditorSession, stage_id: String, variant_index: int, condition_payloads: Array[Dictionary], patch_strategy: String = "overwrite", is_reactive: bool = false) -> bool:
	var intent_variant: EnemyIntentVariantData = _get_intent_variant(session, stage_id, variant_index, is_reactive)
	if intent_variant == null:
		return false
	intent_variant.conditions = SerializableData.patch_array(intent_variant.conditions, condition_payloads, patch_strategy)
	_after_enemy_mutation(session)
	return true

func patch_stage_extra_actions(session: EnemyEditorSession, stage_id: String, action_payloads: Array[Dictionary], patch_strategy: String = "overwrite", is_reactive: bool = false) -> bool:
	var stage_data: Variant = _get_stage_by_id(session, stage_id, is_reactive)
	if stage_data == null:
		return false
	stage_data.extra_actions = SerializableData.patch_array(stage_data.extra_actions, action_payloads, patch_strategy)
	_after_enemy_mutation(session)
	return true

func create_difficulty_override(session: EnemyEditorSession, difficulty_level: int = 0, insert_index: int = -1) -> EnemyDifficultyOverrideData:
	if session == null or session.working_enemy_data == null:
		return null
	var override_data := EnemyDifficultyOverrideData.new()
	override_data.difficulty_level = difficulty_level
	var overrides: Array[EnemyDifficultyOverrideData] = session.working_enemy_data.difficulty_overrides.duplicate(true)
	if insert_index < 0 or insert_index >= len(overrides):
		overrides.append(override_data)
	else:
		overrides.insert(insert_index, override_data)
	_assign_typed_array(session.working_enemy_data.difficulty_overrides, overrides)
	session.working_enemy_data.difficulty_overrides = session.working_enemy_data.difficulty_overrides
	_after_enemy_mutation(session)
	return override_data

func remove_difficulty_override(session: EnemyEditorSession, override_index: int) -> bool:
	if session == null or session.working_enemy_data == null:
		return false
	var overrides: Array[EnemyDifficultyOverrideData] = session.working_enemy_data.difficulty_overrides.duplicate(true)
	if override_index < 0 or override_index >= len(overrides):
		return false
	overrides.remove_at(override_index)
	_assign_typed_array(session.working_enemy_data.difficulty_overrides, overrides)
	session.working_enemy_data.difficulty_overrides = session.working_enemy_data.difficulty_overrides
	_after_enemy_mutation(session)
	return true

func move_difficulty_override(session: EnemyEditorSession, from_index: int, to_index: int) -> bool:
	if session == null or session.working_enemy_data == null:
		return false
	var overrides: Array[EnemyDifficultyOverrideData] = session.working_enemy_data.difficulty_overrides.duplicate(true)
	if from_index < 0 or from_index >= len(overrides) or to_index < 0 or to_index >= len(overrides):
		return false
	var override_data: EnemyDifficultyOverrideData = overrides[from_index]
	overrides.remove_at(from_index)
	overrides.insert(to_index, override_data)
	_assign_typed_array(session.working_enemy_data.difficulty_overrides, overrides)
	session.working_enemy_data.difficulty_overrides = session.working_enemy_data.difficulty_overrides
	_after_enemy_mutation(session)
	return true

func set_difficulty_top_level_override(session: EnemyEditorSession, override_index: int, property_name: String, value: Variant) -> bool:
	var override_data: EnemyDifficultyOverrideData = _get_difficulty_override(session, override_index)
	if override_data == null:
		return false
	override_data.top_level_overrides[property_name] = value
	_after_enemy_mutation(session)
	return true

func erase_difficulty_top_level_override(session: EnemyEditorSession, override_index: int, property_name: String) -> bool:
	var override_data: EnemyDifficultyOverrideData = _get_difficulty_override(session, override_index)
	if override_data == null:
		return false
	override_data.top_level_overrides.erase(property_name)
	_after_enemy_mutation(session)
	return true

func create_stage_override(session: EnemyEditorSession, override_index: int, stage_id: String = "", is_reactive: bool = false, insert_index: int = -1) -> Variant:
	var difficulty_override: EnemyDifficultyOverrideData = _get_difficulty_override(session, override_index)
	if difficulty_override == null:
		return null
	var target_array: Array = difficulty_override.reactive_stage_overrides if is_reactive else difficulty_override.stage_overrides
	var stage_override: Variant = EnemyReactiveStageOverrideData.new() if is_reactive else EnemyStageOverrideData.new()
	if is_reactive:
		stage_override.reactive_stage_id = stage_id
	else:
		stage_override.stage_id = stage_id
	if insert_index < 0 or insert_index >= len(target_array):
		target_array.append(stage_override)
	else:
		target_array.insert(insert_index, stage_override)
	if is_reactive:
		_assign_typed_array(difficulty_override.reactive_stage_overrides, target_array)
		difficulty_override.reactive_stage_overrides = difficulty_override.reactive_stage_overrides
	else:
		_assign_typed_array(difficulty_override.stage_overrides, target_array)
		difficulty_override.stage_overrides = difficulty_override.stage_overrides
	_after_enemy_mutation(session)
	return stage_override

func set_stage_override_target(session: EnemyEditorSession, override_index: int, stage_override_index: int, stage_id: String, is_reactive: bool = false) -> bool:
	var stage_override: Variant = _get_stage_override(session, override_index, stage_override_index, is_reactive)
	if stage_override == null:
		return false
	if is_reactive:
		stage_override.reactive_stage_id = stage_id
	else:
		stage_override.stage_id = stage_id
	_after_enemy_mutation(session)
	return true

func set_stage_override_property(session: EnemyEditorSession, override_index: int, stage_override_index: int, property_name: String, value: Variant, is_reactive: bool = false) -> bool:
	var stage_override: Variant = _get_stage_override(session, override_index, stage_override_index, is_reactive)
	if stage_override == null:
		return false
	stage_override.property_overrides[property_name] = value
	_after_enemy_mutation(session)
	return true

func patch_stage_override_extra_actions(session: EnemyEditorSession, override_index: int, stage_override_index: int, action_payloads: Array[Dictionary], patch_strategy: String = "overwrite", is_reactive: bool = false) -> bool:
	var stage_override: Variant = _get_stage_override(session, override_index, stage_override_index, is_reactive)
	if stage_override == null:
		return false
	stage_override.extra_actions_patch_strategy = patch_strategy
	stage_override.extra_actions = SerializableData.patch_array(stage_override.extra_actions, action_payloads, patch_strategy)
	_after_enemy_mutation(session)
	return true

func create_intent_override(session: EnemyEditorSession, override_index: int, stage_override_index: int, variant_index: int = 0, is_reactive: bool = false, insert_index: int = -1) -> EnemyIntentOverrideData:
	var stage_override: Variant = _get_stage_override(session, override_index, stage_override_index, is_reactive)
	if stage_override == null:
		return null
	var intent_override := EnemyIntentOverrideData.new()
	intent_override.variant_index = variant_index
	var overrides: Array[EnemyIntentOverrideData] = stage_override.intent_overrides.duplicate(true)
	if insert_index < 0 or insert_index >= len(overrides):
		overrides.append(intent_override)
	else:
		overrides.insert(insert_index, intent_override)
	_assign_typed_array(stage_override.intent_overrides, overrides)
	stage_override.intent_overrides = stage_override.intent_overrides
	_after_enemy_mutation(session)
	return intent_override

func set_intent_override_variant_index(session: EnemyEditorSession, override_index: int, stage_override_index: int, intent_override_index: int, variant_index: int, is_reactive: bool = false) -> bool:
	var intent_override: EnemyIntentOverrideData = _get_intent_override(session, override_index, stage_override_index, intent_override_index, is_reactive)
	if intent_override == null:
		return false
	intent_override.variant_index = variant_index
	_after_enemy_mutation(session)
	return true

func set_intent_override_field(session: EnemyEditorSession, override_index: int, stage_override_index: int, intent_override_index: int, field_name: String, value: Variant, is_reactive: bool = false) -> bool:
	var intent_override: EnemyIntentOverrideData = _get_intent_override(session, override_index, stage_override_index, intent_override_index, is_reactive)
	if intent_override == null:
		return false
	match field_name:
		"priority_override_enabled", "priority_override", "conditions_patch_strategy", "variant_index":
			intent_override.set(field_name, value)
		_:
			intent_override.intent_overrides[field_name] = value
	_after_enemy_mutation(session)
	return true

func patch_intent_override_conditions(session: EnemyEditorSession, override_index: int, stage_override_index: int, intent_override_index: int, condition_payloads: Array[Dictionary], patch_strategy: String = "overwrite", is_reactive: bool = false) -> bool:
	var intent_override: EnemyIntentOverrideData = _get_intent_override(session, override_index, stage_override_index, intent_override_index, is_reactive)
	if intent_override == null:
		return false
	intent_override.conditions_patch_strategy = patch_strategy
	intent_override.condition_overrides = SerializableData.patch_array(intent_override.condition_overrides, condition_payloads, patch_strategy)
	_after_enemy_mutation(session)
	return true

func _save_session_internal(session: EnemyEditorSession, save_as_path: String) -> Dictionary:
	if session == null or session.working_enemy_data == null:
		return {"success": false, "path": "", "diagnostics": [_make_diagnostic("session_missing", "error", "No valid session was provided for saving.")]}
	if save_as_path.strip_edges() != "":
		if save_as_path == session.managed_save_path:
			session.save_policy = EnemyEditorSession.SAVE_POLICY_MANAGED_CONTENT
		elif save_as_path == session.managed_triage_save_path:
			session.save_policy = EnemyEditorSession.SAVE_POLICY_MANAGED_TRIAGE
		else:
			session.save_policy = EnemyEditorSession.SAVE_POLICY_MANUAL
			session.manual_save_override_path = save_as_path
	session.recompute_managed_paths()
	_normalize_enemy_resource(session.working_enemy_data)
	var diagnostics: Array[Dictionary] = validate_session(session)
	if _has_error_diagnostics(diagnostics):
		return {"success": false, "path": session.get_active_save_path(), "diagnostics": diagnostics}

	var save_path: String = session.get_active_save_path()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_path.get_base_dir()))
	var save_result: Error = ResourceSaver.save(session.working_enemy_data, save_path)
	if save_result != OK:
		var save_diagnostic: Dictionary = _make_diagnostic("save_failed", "error", "Failed to save enemy resource.", "save_path", {"path": save_path, "error_code": save_result})
		session.diagnostics = diagnostics + [save_diagnostic]
		return {"success": false, "path": save_path, "diagnostics": session.diagnostics}

	session.original_resource_path = save_path
	session.preferred_relative_directory = EnemyEditorPathUtils.infer_preferred_relative_directory(save_path, session.content_root, session.triage_root)
	if save_path == session.managed_save_path:
		session.save_policy = EnemyEditorSession.SAVE_POLICY_MANAGED_CONTENT
	elif save_path == session.managed_triage_save_path:
		session.save_policy = EnemyEditorSession.SAVE_POLICY_MANAGED_TRIAGE
	else:
		session.save_policy = EnemyEditorSession.SAVE_POLICY_MANUAL
	session.clear_dirty()
	session.refresh_diagnostics(self)
	return {"success": true, "path": save_path, "diagnostics": session.diagnostics}

func _discover_enemies_in_root(root_path: String, source_bucket: String, content_root: String, triage_root: String, output_enemies: Array[Dictionary]) -> void:
	var enemies_root: String = root_path.path_join("enemies")
	var directory: DirAccess = DirAccess.open(enemies_root)
	if directory == null:
		return
	_discover_enemies_recursive(enemies_root, source_bucket, content_root, triage_root, output_enemies, {})

func _discover_enemies_recursive(
	directory_path: String,
	source_bucket: String,
	content_root: String,
	triage_root: String,
	output_enemies: Array[Dictionary],
	visited_directories: Dictionary[String, bool]
) -> void:
	var normalized_directory_path: String = directory_path.strip_edges().trim_suffix("/")
	if normalized_directory_path == "":
		return
	if visited_directories.has(normalized_directory_path):
		last_discovery_diagnostics.append(_make_diagnostic(
			"directory_cycle_skipped",
			"warning",
			"Skipped a directory that was already visited during enemy discovery.",
			"resource_path",
			{"path": normalized_directory_path}
		))
		return
	visited_directories[normalized_directory_path] = true

	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		last_discovery_diagnostics.append(_make_diagnostic("directory_open_failed", "warning", "Could not open enemy directory.", "resource_path", {"path": directory_path}))
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
			_discover_enemies_recursive(child_path, source_bucket, content_root, triage_root, output_enemies, visited_directories)
			continue
		if not entry_name.to_lower().ends_with(".tres") and not entry_name.to_lower().ends_with(".res"):
			continue
		var loaded_resource: Resource = load(child_path)
		if loaded_resource == null:
			last_discovery_diagnostics.append(_make_diagnostic("resource_load_failed", "warning", "Failed to load enemy resource during discovery.", "resource_path", {"path": child_path}))
			continue
		if not (loaded_resource is EnemyData):
			continue
		output_enemies.append(_make_enemy_library_entry(loaded_resource, child_path, source_bucket, content_root, triage_root))
	directory.list_dir_end()

func _make_enemy_library_entry(enemy_data: EnemyData, resource_path: String, source_bucket: String, content_root: String, triage_root: String) -> Dictionary:
	var path_metadata: Dictionary = EnemyEditorPathUtils.analyze_enemy_resource_path(resource_path, content_root, triage_root)
	var temp_session := EnemyEditorSession.new((enemy_data as EnemyData).duplicate(true), resource_path, content_root, triage_root, EnemyEditorSession.SAVE_POLICY_MANAGED_CONTENT if source_bucket == "content" else EnemyEditorSession.SAVE_POLICY_MANAGED_TRIAGE)
	var diagnostics: Array[Dictionary] = validate_session(temp_session, false)
	var counts: Dictionary = _count_diagnostics(diagnostics)
	var search_blob_parts: Array[String] = [
		enemy_data.object_id,
		enemy_data.enemy_name,
		str(path_metadata.get("owner_bucket", "")),
		str(path_metadata.get("relative_path", "")),
	]
	for stage_data: EnemyStageData in enemy_data.stages:
		search_blob_parts.append(stage_data.object_id)
		search_blob_parts.append(stage_data.label)
	for reactive_stage_data: EnemyReactiveStageData in enemy_data.reactive_stages:
		search_blob_parts.append(reactive_stage_data.object_id)
		search_blob_parts.append(reactive_stage_data.label)
	return {
		"object_id": enemy_data.object_id,
		"enemy_name": enemy_data.enemy_name,
		"enemy_type": enemy_data.enemy_type,
		"enemy_is_minion": enemy_data.enemy_is_minion,
		"opening_stage_id": enemy_data.opening_stage_id,
		"resource_path": resource_path,
		"source_bucket": source_bucket,
		"source_root": path_metadata.get("source_root", ""),
		"relative_path": path_metadata.get("relative_path", ""),
		"path_segments": path_metadata.get("path_segments", []),
		"owner_bucket": path_metadata.get("owner_bucket", "unknown"),
		"file_name": path_metadata.get("file_name", ""),
		"stage_count": len(enemy_data.stages),
		"reactive_stage_count": len(enemy_data.reactive_stages),
		"difficulty_override_count": len(enemy_data.difficulty_overrides),
		"diagnostic_counts": counts,
		"stage_summaries": _collect_stage_summaries(enemy_data.stages),
		"reactive_stage_summaries": _collect_reactive_stage_summaries(enemy_data.reactive_stages),
		"difficulty_summaries": _collect_difficulty_summaries(enemy_data.difficulty_overrides),
		"search_blob": " ".join(search_blob_parts).to_lower(),
	}

func _validate_stage_collection(stages: Array[EnemyStageData], _is_reactive: bool, diagnostics: Array[Dictionary]) -> void:
	for stage_data: EnemyStageData in stages:
		_validate_action_entries(stage_data.extra_actions, "stage_extra_actions", diagnostics, {"stage_id": stage_data.object_id})
		for variant_index: int in range(len(stage_data.intents)):
			var intent_variant: EnemyIntentVariantData = stage_data.intents[variant_index]
			_validate_condition_entries(intent_variant.conditions, "stage_conditions", diagnostics, {"stage_id": stage_data.object_id, "variant_index": variant_index})

func _validate_reactive_stage_collection(stages: Array[EnemyReactiveStageData], diagnostics: Array[Dictionary]) -> void:
	for stage_data: EnemyReactiveStageData in stages:
		_validate_condition_entries(stage_data.conditions, "reactive_stage_conditions", diagnostics, {"reactive_stage_id": stage_data.object_id})
		_validate_action_entries(stage_data.extra_actions, "reactive_stage_extra_actions", diagnostics, {"reactive_stage_id": stage_data.object_id})
		for variant_index: int in range(len(stage_data.intents)):
			var intent_variant: EnemyIntentVariantData = stage_data.intents[variant_index]
			_validate_condition_entries(intent_variant.conditions, "reactive_stage_variant_conditions", diagnostics, {"reactive_stage_id": stage_data.object_id, "variant_index": variant_index})

func _validate_difficulty_overrides(enemy_data: EnemyData, diagnostics: Array[Dictionary]) -> void:
	for override_index: int in range(len(enemy_data.difficulty_overrides)):
		var difficulty_override: EnemyDifficultyOverrideData = enemy_data.difficulty_overrides[override_index]
		for stage_override in difficulty_override.stage_overrides:
			_validate_action_entries(stage_override.extra_actions, "difficulty_stage_extra_actions", diagnostics, {"difficulty_index": override_index, "stage_id": stage_override.stage_id})
			for intent_override: EnemyIntentOverrideData in stage_override.intent_overrides:
				_validate_condition_entries(intent_override.condition_overrides, "difficulty_stage_conditions", diagnostics, {"difficulty_index": override_index, "stage_id": stage_override.stage_id, "variant_index": intent_override.variant_index})
		for reactive_stage_override in difficulty_override.reactive_stage_overrides:
			_validate_action_entries(reactive_stage_override.extra_actions, "difficulty_reactive_stage_extra_actions", diagnostics, {"difficulty_index": override_index, "reactive_stage_id": reactive_stage_override.reactive_stage_id})
			for intent_override: EnemyIntentOverrideData in reactive_stage_override.intent_overrides:
				_validate_condition_entries(intent_override.condition_overrides, "difficulty_reactive_stage_conditions", diagnostics, {"difficulty_index": override_index, "reactive_stage_id": reactive_stage_override.reactive_stage_id, "variant_index": intent_override.variant_index})

func _validate_action_entries(entries: Array, field_name: String, diagnostics: Array[Dictionary], extra_data: Dictionary = {}) -> void:
	for entry_index: int in range(len(entries)):
		var entry: Variant = entries[entry_index]
		if not (entry is Dictionary):
			diagnostics.append(_make_diagnostic("malformed_action_entry", "error", "Action entry must be a Dictionary.", field_name, _merge_diagnostic_data(extra_data, {"index": entry_index})))
			continue
		var entry_dict: Dictionary = entry
		if len(entry_dict.keys()) != 1:
			diagnostics.append(_make_diagnostic("malformed_action_entry", "error", "Action entry must contain exactly one token key.", field_name, _merge_diagnostic_data(extra_data, {"index": entry_index})))
			continue
		var token_or_path: String = str(entry_dict.keys()[0])
		if Scripts.resolve_script(token_or_path) == null:
			diagnostics.append(_make_diagnostic("unresolved_action_token", "error", "Action token could not be resolved.", field_name, _merge_diagnostic_data(extra_data, {"index": entry_index, "token": token_or_path})))
		var values: Variant = entry_dict[token_or_path]
		if not (values is Dictionary):
			diagnostics.append(_make_diagnostic("malformed_action_entry", "error", "Action payload must be a Dictionary.", field_name, _merge_diagnostic_data(extra_data, {"index": entry_index, "token": token_or_path})))
			continue
		_validate_metadata_payload(token_or_path, values, field_name, diagnostics, _merge_diagnostic_data(extra_data, {"index": entry_index}))

func _validate_condition_entries(entries: Array, field_name: String, diagnostics: Array[Dictionary], extra_data: Dictionary = {}) -> void:
	for entry_index: int in range(len(entries)):
		var entry: Variant = entries[entry_index]
		if not (entry is Dictionary):
			diagnostics.append(_make_diagnostic("malformed_validator_entry", "error", "Condition validator entry must be a Dictionary.", field_name, _merge_diagnostic_data(extra_data, {"index": entry_index})))
			continue
		var entry_dict: Dictionary = entry
		if len(entry_dict.keys()) != 1:
			diagnostics.append(_make_diagnostic("malformed_validator_entry", "error", "Condition validator entry must contain exactly one token key.", field_name, _merge_diagnostic_data(extra_data, {"index": entry_index})))
			continue
		var token_or_path: String = str(entry_dict.keys()[0])
		if Scripts.resolve_script(token_or_path) == null:
			diagnostics.append(_make_diagnostic("unresolved_validator_token", "error", "Validator token could not be resolved.", field_name, _merge_diagnostic_data(extra_data, {"index": entry_index, "token": token_or_path})))
		var values: Variant = entry_dict[token_or_path]
		if not (values is Dictionary):
			diagnostics.append(_make_diagnostic("malformed_validator_entry", "error", "Validator payload must be a Dictionary.", field_name, _merge_diagnostic_data(extra_data, {"index": entry_index, "token": token_or_path})))
			continue
		_validate_metadata_payload(token_or_path, values, field_name, diagnostics, _merge_diagnostic_data(extra_data, {"index": entry_index}))

func _validate_metadata_payload(token_or_path: String, values: Dictionary, field_name: String, diagnostics: Array[Dictionary], extra_data: Dictionary = {}) -> void:
	var metadata: Dictionary = ScriptEditorMetadataRegistry.get_resolved_script_metadata(token_or_path)
	if metadata.is_empty():
		return
	var parameter_definitions: Array[Dictionary] = []
	parameter_definitions.assign(metadata.get("parameters", []))
	var parameters_by_name: Dictionary[String, Dictionary] = {}
	for parameter_definition: Dictionary in parameter_definitions:
		var parameter_name: String = str(parameter_definition.get("name", ""))
		if parameter_name != "":
			parameters_by_name[parameter_name] = parameter_definition
	for value_key: Variant in values.keys():
		var parameter_name_str: String = str(value_key)
		if parameter_name_str.begins_with("_"):
			continue
		if not parameters_by_name.has(parameter_name_str):
			diagnostics.append(_make_diagnostic("unknown_parameter", "warning", "Payload includes a parameter the editor metadata does not recognize.", field_name, _merge_diagnostic_data(extra_data, {"token": token_or_path, "parameter": parameter_name_str})))
			continue
		var parameter_definition: Dictionary = parameters_by_name[parameter_name_str]
		var value_type: String = str(parameter_definition.get("value_type", "variant"))
		if not _value_matches_editor_type(values[value_key], value_type, parameter_definition):
			diagnostics.append(_make_diagnostic("parameter_type_mismatch", "warning", "Payload parameter type does not match editor metadata.", field_name, _merge_diagnostic_data(extra_data, {"token": token_or_path, "parameter": parameter_name_str, "value_type": value_type})))

func _validate_status_effect_dictionary(values: Dictionary, field_name: String, diagnostics: Array[Dictionary]) -> void:
	for key: Variant in values.keys():
		var status_id: String = str(key)
		if status_id.strip_edges() == "":
			diagnostics.append(_make_diagnostic("empty_status_effect_id", "warning", "Status-effect dictionary contains an empty key.", field_name))
		if not (values[key] is int):
			diagnostics.append(_make_diagnostic("invalid_status_effect_charge", "warning", "Status-effect charges should be ints.", field_name, {"status_id": status_id}))

func _validate_save_collision(session: EnemyEditorSession, save_path: String) -> Dictionary:
	if not ResourceLoader.exists(save_path):
		return {}
	if save_path == session.original_resource_path:
		return {}
	var existing_resource: Resource = load(save_path)
	if existing_resource == null:
		return _make_diagnostic("path_collision", "error", "A resource already exists at the target path and could not be loaded.", "save_path", {"path": save_path})
	if not (existing_resource is EnemyData):
		return _make_diagnostic("path_collision", "error", "The target path already contains a non-enemy resource.", "save_path", {"path": save_path})
	var existing_enemy: EnemyData = existing_resource
	if existing_enemy.object_id != session.working_enemy_data.object_id:
		return _make_diagnostic("path_collision", "error", "The target path already belongs to a different enemy.", "save_path", {"path": save_path, "existing_object_id": existing_enemy.object_id})
	return {}

func _validate_save_path_policy(session: EnemyEditorSession, save_path: String, diagnostics: Array[Dictionary]) -> void:
	match session.save_policy:
		EnemyEditorSession.SAVE_POLICY_MANAGED_CONTENT:
			if save_path != session.managed_save_path:
				diagnostics.append(_make_diagnostic("save_policy_path_mismatch", "warning", "Managed content save policy points at a custom path.", "save_path", {"path": save_path}))
		EnemyEditorSession.SAVE_POLICY_MANAGED_TRIAGE:
			if save_path != session.managed_triage_save_path:
				diagnostics.append(_make_diagnostic("save_policy_path_mismatch", "warning", "Managed triage save policy points at a custom path.", "save_path", {"path": save_path}))
		EnemyEditorSession.SAVE_POLICY_MANUAL:
			if not EnemyEditorPathUtils.path_is_within_root(save_path, session.content_root) and not EnemyEditorPathUtils.path_is_within_root(save_path, session.triage_root):
				diagnostics.append(_make_diagnostic("manual_path_external", "warning", "Manual save path is outside the configured content and triage roots.", "save_path", {"path": save_path}))

func _validate_library_object_id_collisions(session: EnemyEditorSession, diagnostics: Array[Dictionary]) -> void:
	var duplicate_entries: Array[Dictionary] = find_enemies_by_object_id(session.working_enemy_data.object_id, session.content_root, session.triage_root, true, true)
	var duplicate_paths: Array[String] = []
	for entry: Dictionary in duplicate_entries:
		var entry_path: String = str(entry.get("resource_path", ""))
		if entry_path == "" or entry_path == session.original_resource_path or entry_path == session.get_active_save_path():
			continue
		duplicate_paths.append(entry_path)
	if len(duplicate_paths) > 0:
		diagnostics.append(_make_diagnostic("duplicate_object_id", "warning", "Another enemy with the same object_id already exists in the library roots.", "object_id", {"paths": duplicate_paths}))

func _get_stage_by_id(session: EnemyEditorSession, stage_id: String, is_reactive: bool) -> Variant:
	if session == null or session.working_enemy_data == null:
		return null
	return session.working_enemy_data.get_reactive_stage(stage_id) if is_reactive else session.working_enemy_data.get_stage(stage_id)

func _get_intent_variant(session: EnemyEditorSession, stage_id: String, variant_index: int, is_reactive: bool) -> EnemyIntentVariantData:
	var stage_data: Variant = _get_stage_by_id(session, stage_id, is_reactive)
	if stage_data == null or variant_index < 0 or variant_index >= len(stage_data.intents):
		return null
	return stage_data.intents[variant_index]

func _get_difficulty_override(session: EnemyEditorSession, override_index: int) -> EnemyDifficultyOverrideData:
	if session == null or session.working_enemy_data == null:
		return null
	if override_index < 0 or override_index >= len(session.working_enemy_data.difficulty_overrides):
		return null
	return session.working_enemy_data.difficulty_overrides[override_index]

func _get_stage_override(session: EnemyEditorSession, override_index: int, stage_override_index: int, is_reactive: bool) -> Variant:
	var difficulty_override: EnemyDifficultyOverrideData = _get_difficulty_override(session, override_index)
	if difficulty_override == null:
		return null
	var target_array: Array = difficulty_override.reactive_stage_overrides if is_reactive else difficulty_override.stage_overrides
	if stage_override_index < 0 or stage_override_index >= len(target_array):
		return null
	return target_array[stage_override_index]

func _get_intent_override(session: EnemyEditorSession, override_index: int, stage_override_index: int, intent_override_index: int, is_reactive: bool) -> EnemyIntentOverrideData:
	var stage_override: Variant = _get_stage_override(session, override_index, stage_override_index, is_reactive)
	if stage_override == null or intent_override_index < 0 or intent_override_index >= len(stage_override.intent_overrides):
		return null
	return stage_override.intent_overrides[intent_override_index]

func _move_stage_internal(session: EnemyEditorSession, is_reactive: bool, from_index: int, to_index: int) -> bool:
	if session == null or session.working_enemy_data == null:
		return false
	var stages: Array = session.working_enemy_data.reactive_stages.duplicate(true) if is_reactive else session.working_enemy_data.stages.duplicate(true)
	if from_index < 0 or from_index >= len(stages) or to_index < 0 or to_index >= len(stages):
		return false
	var stage_data = stages[from_index]
	stages.remove_at(from_index)
	stages.insert(to_index, stage_data)
	if is_reactive:
		_assign_typed_array(session.working_enemy_data.reactive_stages, stages)
		session.working_enemy_data.reactive_stages = session.working_enemy_data.reactive_stages
	else:
		_assign_typed_array(session.working_enemy_data.stages, stages)
		session.working_enemy_data.stages = session.working_enemy_data.stages
	_after_enemy_mutation(session)
	return true

func _shift_intent_override_indices(session: EnemyEditorSession, stage_id: String, is_reactive: bool, insertion_index: int, delta: int) -> void:
	for difficulty_override: EnemyDifficultyOverrideData in session.working_enemy_data.difficulty_overrides:
		var override_array: Array = difficulty_override.reactive_stage_overrides if is_reactive else difficulty_override.stage_overrides
		for stage_override in override_array:
			var target_stage_id: String = stage_override.reactive_stage_id if is_reactive else stage_override.stage_id
			if target_stage_id != stage_id:
				continue
			for intent_override: EnemyIntentOverrideData in stage_override.intent_overrides:
				if intent_override.variant_index >= insertion_index:
					intent_override.variant_index += delta

func _remove_intent_override_index(session: EnemyEditorSession, stage_id: String, is_reactive: bool, removed_index: int) -> void:
	for difficulty_override: EnemyDifficultyOverrideData in session.working_enemy_data.difficulty_overrides:
		var override_array: Array = difficulty_override.reactive_stage_overrides if is_reactive else difficulty_override.stage_overrides
		for stage_override in override_array:
			var target_stage_id: String = stage_override.reactive_stage_id if is_reactive else stage_override.stage_id
			if target_stage_id != stage_id:
				continue
			var next_overrides: Array[EnemyIntentOverrideData] = []
			for intent_override: EnemyIntentOverrideData in stage_override.intent_overrides:
				if intent_override.variant_index == removed_index:
					continue
				if intent_override.variant_index > removed_index:
					intent_override.variant_index -= 1
				next_overrides.append(intent_override)
			_assign_typed_array(stage_override.intent_overrides, next_overrides)
			stage_override.intent_overrides = stage_override.intent_overrides

func _remap_intent_override_indices(session: EnemyEditorSession, stage_id: String, is_reactive: bool, index_mapping: Dictionary[int, int]) -> void:
	for difficulty_override: EnemyDifficultyOverrideData in session.working_enemy_data.difficulty_overrides:
		var override_array: Array = difficulty_override.reactive_stage_overrides if is_reactive else difficulty_override.stage_overrides
		for stage_override in override_array:
			var target_stage_id: String = stage_override.reactive_stage_id if is_reactive else stage_override.stage_id
			if target_stage_id != stage_id:
				continue
			for intent_override: EnemyIntentOverrideData in stage_override.intent_overrides:
				if index_mapping.has(intent_override.variant_index):
					intent_override.variant_index = index_mapping[intent_override.variant_index]

func _collect_stage_summaries(stages: Array[EnemyStageData]) -> Array[String]:
	var summaries: Array[String] = []
	for stage_data: EnemyStageData in stages:
		summaries.append(EnemyEditorSchema.summarize_stage(stage_data))
	return summaries

func _collect_reactive_stage_summaries(stages: Array[EnemyReactiveStageData]) -> Array[String]:
	var summaries: Array[String] = []
	for stage_data: EnemyReactiveStageData in stages:
		summaries.append(EnemyEditorSchema.summarize_reactive_stage(stage_data))
	return summaries

func _collect_difficulty_summaries(overrides: Array[EnemyDifficultyOverrideData]) -> Array[String]:
	var summaries: Array[String] = []
	for override_data: EnemyDifficultyOverrideData in overrides:
		summaries.append(EnemyEditorSchema.summarize_difficulty_override(override_data))
	return summaries

func _create_metadata_default_entry(token_or_path: String) -> Dictionary:
	var metadata: Dictionary = ScriptEditorMetadataRegistry.get_resolved_script_metadata(token_or_path)
	if metadata.is_empty():
		return {}
	var resolved_token: String = str(metadata.get("resolved_token", ""))
	if resolved_token == "":
		resolved_token = str(metadata.get("resolved_path", token_or_path))
	var default_values: Dictionary[String, Variant] = {}
	for parameter_data: Dictionary in metadata.get("parameters", []):
		var parameter_name: String = str(parameter_data.get("name", ""))
		if parameter_name != "":
			default_values[parameter_name] = parameter_data.get("default_value", null)
	return {resolved_token: default_values}

func _reorder_index_mapping(item_count: int, from_index: int, to_index: int) -> Dictionary[int, int]:
	var indices: Array[int] = []
	for item_index: int in range(item_count):
		indices.append(item_index)
	var moved_index: int = indices[from_index]
	indices.remove_at(from_index)
	indices.insert(to_index, moved_index)
	var mapping: Dictionary[int, int] = {}
	for new_index: int in range(len(indices)):
		mapping[indices[new_index]] = new_index
	return mapping

func _generate_unique_stage_id(enemy_data: EnemyData, is_reactive: bool) -> String:
	var base_prefix: String = "reactive_stage_" if is_reactive else "stage_"
	var max_unique_stage_id_attempts: int = 100000
	var next_index: int = 1
	while next_index <= max_unique_stage_id_attempts:
		var candidate: String = "%s%s" % [base_prefix, next_index]
		if enemy_data.get_stage(candidate) == null and enemy_data.get_reactive_stage(candidate) == null:
			return candidate
		next_index += 1
	push_error("EnemyEditorService: Could not generate a unique stage id for prefix %s after %s attempts." % [base_prefix, max_unique_stage_id_attempts])
	return "%soverflow" % base_prefix

func _assign_typed_array(target_array: Variant, next_values: Array) -> void:
	target_array.clear()
	target_array.assign(next_values)

func _after_enemy_mutation(session: EnemyEditorSession) -> void:
	if session == null:
		return
	session.recompute_managed_paths()
	session.reset_preview_state()
	session.mark_dirty()
	session.refresh_diagnostics(self)

func _normalize_enemy_resource(enemy_data: EnemyData) -> void:
	if enemy_data == null:
		return
	ContentExporter._normalize_resource_script_references(enemy_data)

func _count_diagnostics(diagnostics: Array[Dictionary]) -> Dictionary:
	var counts := {"errors": 0, "warnings": 0}
	for diagnostic: Dictionary in diagnostics:
		var severity: String = str(diagnostic.get("severity", ""))
		if severity == "error":
			counts["errors"] += 1
		elif severity == "warning":
			counts["warnings"] += 1
	return counts

func _merge_diagnostic_data(base_data: Dictionary, next_data: Dictionary) -> Dictionary:
	var merged_data: Dictionary = base_data.duplicate(true)
	merged_data.merge(next_data, true)
	return merged_data

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
			for option: Variant in options:
				if option is Dictionary and option.get("value", null) == value:
					return true
				if not (option is Dictionary) and option == value:
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
	if regex.compile("^enemy_[a-z0-9_]+$") != OK:
		return true
	return regex.search(object_id) != null

func _is_supported_resource_path(path: String) -> bool:
	if path == "" or not path.begins_with("res://"):
		return false
	var normalized_path: String = path.to_lower()
	return normalized_path.ends_with(".tres") or normalized_path.ends_with(".res")

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
