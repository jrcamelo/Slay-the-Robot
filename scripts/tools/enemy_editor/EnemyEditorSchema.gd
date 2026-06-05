@tool
extends RefCounted
class_name EnemyEditorSchema

static func get_top_level_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"object_id": _field("Object ID", "string", "Stable enemy identifier used by content references and exports."),
		"enemy_object_id": _field("Legacy Enemy Object ID", "string", "Legacy prototype id field. Prefer object_id for new content."),
		"enemy_name": _field("Enemy Name", "string", "Display name shown in combat."),
		"enemy_texture_path_when_broken": _field("Texture Path When Broken", "resource_path", "Optional texture path used when the enemy is broken."),
		"enemy_texture_path": _field("Texture Path", "resource_path", "Texture path used by the enemy sprite."),
		"enemy_health": _field("Health", "int", "Current health value for the prototype."),
		"enemy_health_max": _field("Max Health", "int", "Maximum health value."),
		"enemy_poise": _field("Poise", "int", "Current poise value for the prototype."),
		"enemy_poise_max": _field("Max Poise", "int", "Maximum poise value."),
		"enemy_block": _field("Starting Block", "int", "Initial block value for the duplicated enemy."),
		"enemy_actions_on_death": _field("Actions On Death", "array", "Generic action payloads run when the enemy dies."),
		"enemy_type": _field("Enemy Type", "enum", "Standard, miniboss, or boss classification.", {"options": enemy_type_options()}),
		"enemy_is_minion": _field("Is Minion", "bool", "Minions do not need to die for combat to end."),
		"opening_stage_id": _field("Opening Stage ID", "string", "Base stage id used when combat starts."),
		"enemy_initial_status_effects": _field("Initial Status Effects", "dictionary", "Maps status effect ids to starting charge amounts.", {"key_type": "string", "item_value_type": "int"}),
	}

static func get_stage_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"object_id": _field("Stage ID", "string", "Stable stage id used by links and difficulty overrides."),
		"label": _field("Label", "string", "Human-friendly stage label."),
		"next_stage_id": _field("Next Stage ID", "string", "Base-sequence continuation after this stage executes."),
		"extra_actions": _field("Extra Actions", "array", "Generic action payloads run alongside the native intent."),
	}

static func get_reactive_stage_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"object_id": _field("Reactive Stage ID", "string", "Stable reactive stage id used by overrides."),
		"label": _field("Label", "string", "Human-friendly reactive-stage label."),
		"priority": _field("Priority", "int", "Higher numeric priority wins when multiple reactive stages match."),
		"conditions": _field("Conditions", "array", "Validator payload dictionaries evaluated with AND semantics."),
		"extra_actions": _field("Extra Actions", "array", "Generic action payloads run alongside the native intent."),
		"resume_mode": _field("Resume Mode", "enum", "Controls how sequence progression continues after the reactive stage executes.", {"options": resume_mode_options()}),
		"resume_stage_id": _field("Resume Stage ID", "string", "Required when resume mode jumps into a specific base stage."),
	}

static func get_intent_variant_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"priority": _field("Priority", "int", "Highest matching priority wins within a stage."),
		"conditions": _field("Conditions", "array", "Validator payload dictionaries evaluated with AND semantics."),
		"extra_actions": _field("Extra Actions", "array", "Generic action payloads run only when this variant resolves."),
	}

static func get_intent_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"damage": _field("Damage", "int", "Base attack damage of the native enemy intent."),
		"block": _field("Block", "int", "Raw block granted during execution."),
		"number_of_attacks": _field("Number Of Attacks", "int", "How many attacks the enemy performs."),
		"targeting_rule": _field("Targeting Rule", "enum", "Rule used to resolve PC targets.", {"options": targeting_rule_options()}),
		"target_count": _field("Target Count", "int", "How many PC targets the rule resolves."),
		"allow_repeat_targets": _field("Allow Repeat Targets", "bool", "If true, sorted targeting may repeat the top target."),
	}

static func get_difficulty_override_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"difficulty_level": _field("Difficulty Level", "int", "Minimum run difficulty level at which this patch applies."),
		"top_level_overrides": _field("Top-Level Overrides", "dictionary", "Property overrides applied directly to the duplicated enemy resource.", {"key_type": "string", "item_value_type": "variant"}),
		"stage_overrides": _field("Stage Overrides", "array", "Patches keyed by base stage id."),
		"reactive_stage_overrides": _field("Reactive Stage Overrides", "array", "Patches keyed by reactive stage id."),
	}

static func get_stage_override_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"stage_id": _field("Stage ID", "string", "Base stage id to patch."),
		"property_overrides": _field("Property Overrides", "dictionary", "Property overrides applied directly to the target stage.", {"key_type": "string", "item_value_type": "variant"}),
		"intent_overrides": _field("Intent Overrides", "array", "Intent-variant patches keyed by variant index."),
		"extra_actions_patch_strategy": _field("Extra Actions Patch Strategy", "enum", "How the extra-actions array should be patched.", {"options": array_patch_strategy_options()}),
		"extra_actions": _field("Extra Actions", "array", "Action payloads used by the patch strategy."),
	}

static func get_reactive_stage_override_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"reactive_stage_id": _field("Reactive Stage ID", "string", "Reactive stage id to patch."),
		"property_overrides": _field("Property Overrides", "dictionary", "Property overrides applied directly to the target reactive stage.", {"key_type": "string", "item_value_type": "variant"}),
		"intent_overrides": _field("Intent Overrides", "array", "Intent-variant patches keyed by variant index."),
		"extra_actions_patch_strategy": _field("Extra Actions Patch Strategy", "enum", "How the extra-actions array should be patched.", {"options": array_patch_strategy_options()}),
		"extra_actions": _field("Extra Actions", "array", "Action payloads used by the patch strategy."),
	}

static func get_intent_override_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"variant_index": _field("Variant Index", "int", "Variant index inside the target stage or reactive stage."),
		"intent_overrides": _field("Intent Overrides", "dictionary", "Overrides applied directly to the native intent payload.", {"key_type": "string", "item_value_type": "variant"}),
		"priority_override_enabled": _field("Priority Override Enabled", "bool", "Whether this patch replaces the variant priority."),
		"priority_override": _field("Priority Override", "int", "Replacement priority when enabled."),
		"conditions_patch_strategy": _field("Conditions Patch Strategy", "enum", "How the conditions array should be patched.", {"options": array_patch_strategy_options()}),
		"condition_overrides": _field("Condition Overrides", "array", "Condition payloads used by the patch strategy."),
	}

static func get_library_filter_definitions() -> Array[Dictionary]:
	return [
		{"id": "source_bucket", "label": "Source", "value_type": "enum", "options": [{"label": "Content", "value": "content"}, {"label": "Triage", "value": "triage"}]},
		{"id": "owner_bucket", "label": "Group", "value_type": "string"},
		{"id": "enemy_type", "label": "Type", "value_type": "enum", "options": enemy_type_options()},
	]

static func enemy_type_options() -> Array[Dictionary]:
	return _enum_options(EnemyData.ENEMY_TYPES)

static func targeting_rule_options() -> Array[Dictionary]:
	return [
		{"label": "Random Living PC", "value": EnemyIntentData.TARGETING_RANDOM_LIVING_PLAYER},
		{"label": "Lowest Current HP PC", "value": EnemyIntentData.TARGETING_LOWEST_CURRENT_HEALTH_PLAYER},
		{"label": "Highest Current HP PC", "value": EnemyIntentData.TARGETING_HIGHEST_CURRENT_HEALTH_PLAYER},
		{"label": "Lowest HP Percent PC", "value": EnemyIntentData.TARGETING_LOWEST_HEALTH_PERCENT_PLAYER},
		{"label": "Highest HP Percent PC", "value": EnemyIntentData.TARGETING_HIGHEST_HEALTH_PERCENT_PLAYER},
		{"label": "All Living PCs", "value": EnemyIntentData.TARGETING_ALL_LIVING_PLAYERS},
		{"label": "Random Distinct PCs", "value": EnemyIntentData.TARGETING_RANDOM_DISTINCT_PLAYERS},
	]

static func resume_mode_options() -> Array[Dictionary]:
	return _enum_options_from_strings(EnemyReactiveStageData.RESUME_MODES)

static func array_patch_strategy_options() -> Array[Dictionary]:
	return _enum_options_from_strings(["overwrite", "append", "append_uniques", "erase"])

static func summarize_intent(intent_data: EnemyIntentData) -> String:
	if intent_data == null:
		return "No intent"
	var parts: Array[String] = []
	if intent_data.damage > 0:
		var attack_text: String = "Attack %s" % intent_data.damage
		if intent_data.number_of_attacks > 1:
			attack_text += " x %s" % intent_data.number_of_attacks
		parts.append(attack_text)
	if intent_data.block > 0:
		parts.append("Block %s" % intent_data.block)
	parts.append("Target: %s" % format_targeting_summary(intent_data))
	return " | ".join(parts)

static func summarize_intent_variant(intent_variant: EnemyIntentVariantData) -> String:
	if intent_variant == null:
		return "No variant"
	var summary: String = summarize_intent(intent_variant.intent)
	if len(intent_variant.conditions) == 0:
		return "%s | Default | Priority %s" % [summary, intent_variant.priority]
	return "%s | %s condition(s) | Priority %s" % [summary, len(intent_variant.conditions), intent_variant.priority]

static func summarize_stage(stage_data: EnemyStageData) -> String:
	if stage_data == null:
		return "Missing stage"
	return "%s ⇒ %s | %s variant(s)" % [stage_data.object_id, stage_data.next_stage_id, len(stage_data.intents)]

static func summarize_reactive_stage(stage_data: EnemyReactiveStageData) -> String:
	if stage_data == null:
		return "Missing reactive stage"
	var resume_summary: String = format_resume_mode(stage_data.resume_mode, stage_data.resume_stage_id)
	return "%s | Priority %s | %s condition(s) | %s" % [stage_data.object_id, stage_data.priority, len(stage_data.conditions), resume_summary]

static func summarize_difficulty_override(override_data: EnemyDifficultyOverrideData) -> String:
	if override_data == null:
		return "Missing difficulty override"
	return "Difficulty %s | %s top-level override(s) | %s stage patch(es) | %s reactive patch(es)" % [
		override_data.difficulty_level,
		len(override_data.top_level_overrides),
		len(override_data.stage_overrides),
		len(override_data.reactive_stage_overrides),
	]

static func format_targeting_summary(intent_data: EnemyIntentData) -> String:
	if intent_data == null:
		return "none"
	match intent_data.targeting_rule:
		EnemyIntentData.TARGETING_ALL_LIVING_PLAYERS:
			return "all living PCs"
		EnemyIntentData.TARGETING_LOWEST_CURRENT_HEALTH_PLAYER:
			return "lowest current HP PC"
		EnemyIntentData.TARGETING_HIGHEST_CURRENT_HEALTH_PLAYER:
			return "highest current HP PC"
		EnemyIntentData.TARGETING_LOWEST_HEALTH_PERCENT_PLAYER:
			return "lowest HP percent PC"
		EnemyIntentData.TARGETING_HIGHEST_HEALTH_PERCENT_PLAYER:
			return "highest HP percent PC"
		EnemyIntentData.TARGETING_RANDOM_DISTINCT_PLAYERS:
			return "%s random distinct PC(s)" % max(1, intent_data.target_count)
		EnemyIntentData.TARGETING_RANDOM_LIVING_PLAYER, _:
			if intent_data.allow_repeat_targets:
				return "%s random PC target(s), repeats allowed" % max(1, intent_data.target_count)
			return "%s random living PC(s)" % max(1, intent_data.target_count)

static func format_resume_mode(resume_mode: String, resume_stage_id: String = "") -> String:
	match resume_mode:
		EnemyReactiveStageData.JUMP_TO_STAGE:
			return "Jump to %s" % resume_stage_id
		EnemyReactiveStageData.START_NEW_SEQUENCE:
			return "Start new sequence at %s" % resume_stage_id
		EnemyReactiveStageData.RESUME_PREVIOUS, _:
			return "Resume previous"

static func _field(label: String, value_type: String, description: String, extra: Dictionary = {}) -> Dictionary:
	var field_data: Dictionary = {
		"label": label,
		"value_type": value_type,
		"description": description,
	}
	for key: Variant in extra.keys():
		field_data[key] = extra[key]
	return field_data

static func _enum_options(enum_map: Dictionary) -> Array[Dictionary]:
	var enum_values: Array[int] = []
	var enum_labels_by_value: Dictionary[int, String] = {}
	for enum_key: String in enum_map.keys():
		var enum_value: int = enum_map[enum_key]
		enum_values.append(enum_value)
		enum_labels_by_value[enum_value] = enum_key.to_snake_case().replace("_", " ").capitalize()
	enum_values.sort()
	var options: Array[Dictionary] = []
	for enum_value: int in enum_values:
		options.append({"label": enum_labels_by_value.get(enum_value, str(enum_value)), "value": enum_value})
	return options

static func _enum_options_from_strings(values: Array[String]) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for value: String in values:
		options.append({"label": value.to_snake_case().replace("_", " ").capitalize(), "value": value})
	return options
