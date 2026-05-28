extends PrototypeData
class_name EnemyData

@export var enemy_object_id: String = ""	# prototype id for this enemy type
@export var enemy_name: String = ""
@export var enemy_texture_path: String = "external/sprites/enemies/enemy_blue_small.png"

@export var enemy_health: int = 20
@export var enemy_health_max: int = 20
@export var enemy_poise: int = 10
@export var enemy_poise_max: int = 10

@export var enemy_block: int = 0

@export var enemy_actions_on_death: Array[Dictionary] = []

enum ENEMY_TYPES {STANDARD, MINIBOSS, BOSS}
@export var enemy_type: int = ENEMY_TYPES.STANDARD
@export var enemy_is_minion: bool = false	# minion enemies do not need to be killed for combat to end

### Stages
@export var opening_stage_id: String = ""
@export var stages: Array[EnemyStageData] = []
@export var reactive_stages: Array[EnemyReactiveStageData] = []

### Statuses
@export var enemy_initial_status_effects: Dictionary[String, int] = {}	# maps status effect ids to charge count at start of combat

#region Difficulty
@export var difficulty_overrides: Array[EnemyDifficultyOverrideData] = []

func apply_enemy_difficulty_modifiers():
	var player_run_difficulty_level: int = Global.player_data.player_run_difficulty_level
	apply_enemy_difficulty_modifiers_for_level(player_run_difficulty_level)

func apply_enemy_difficulty_modifiers_for_level(difficulty_level: int) -> void:
	for difficulty_override: EnemyDifficultyOverrideData in difficulty_overrides:
		if difficulty_override.difficulty_level > difficulty_level:
			continue
		_apply_single_difficulty_override(difficulty_override)

func _apply_single_difficulty_override(difficulty_override: EnemyDifficultyOverrideData) -> void:
	for property_name: String in difficulty_override.top_level_overrides.keys():
		set(property_name, difficulty_override.top_level_overrides[property_name])

	for stage_override: EnemyStageOverrideData in difficulty_override.stage_overrides:
		var stage_data: EnemyStageData = get_stage(stage_override.stage_id)
		if stage_data == null:
			continue
		for property_name: String in stage_override.property_overrides.keys():
			stage_data.set(property_name, stage_override.property_overrides[property_name])
		if len(stage_override.extra_actions) > 0:
			stage_data.extra_actions = SerializableData.patch_array(
				stage_data.extra_actions,
				stage_override.extra_actions,
				stage_override.extra_actions_patch_strategy
			)
		for intent_override: EnemyIntentOverrideData in stage_override.intent_overrides:
			_apply_intent_override(stage_data.intents, intent_override)

	for reactive_stage_override: EnemyReactiveStageOverrideData in difficulty_override.reactive_stage_overrides:
		var reactive_stage_data: EnemyReactiveStageData = get_reactive_stage(reactive_stage_override.reactive_stage_id)
		if reactive_stage_data == null:
			continue
		for property_name: String in reactive_stage_override.property_overrides.keys():
			reactive_stage_data.set(property_name, reactive_stage_override.property_overrides[property_name])
		if len(reactive_stage_override.extra_actions) > 0:
			reactive_stage_data.extra_actions = SerializableData.patch_array(
				reactive_stage_data.extra_actions,
				reactive_stage_override.extra_actions,
				reactive_stage_override.extra_actions_patch_strategy
			)
		for intent_override: EnemyIntentOverrideData in reactive_stage_override.intent_overrides:
			_apply_intent_override(reactive_stage_data.intents, intent_override)

func _apply_intent_override(intent_variants: Array[EnemyIntentVariantData], intent_override: EnemyIntentOverrideData) -> void:
	if intent_override.variant_index < 0 or intent_override.variant_index >= len(intent_variants):
		return
	var intent_variant: EnemyIntentVariantData = intent_variants[intent_override.variant_index]
	for property_name: String in intent_override.intent_overrides.keys():
		intent_variant.intent.set(property_name, intent_override.intent_overrides[property_name])
	if intent_override.priority_override_enabled:
		intent_variant.priority = intent_override.priority_override
	if len(intent_override.condition_overrides) > 0:
		intent_variant.conditions = SerializableData.patch_array(
			intent_variant.conditions,
			intent_override.condition_overrides,
			intent_override.conditions_patch_strategy
		)

#endregion

func get_stage(stage_id: String) -> EnemyStageData:
	for stage_data: EnemyStageData in stages:
		if stage_data.object_id == stage_id:
			return stage_data
	return null

func get_reactive_stage(stage_id: String) -> EnemyReactiveStageData:
	for stage_data: EnemyReactiveStageData in reactive_stages:
		if stage_data.object_id == stage_id:
			return stage_data
	return null

func set_poise(poise_amount: int, poise_max_amount: int = enemy_poise_max) -> void:
	enemy_poise_max = max(0, poise_max_amount)
	enemy_poise = clamp(poise_amount, 0, enemy_poise_max)

func add_poise(poise_amount: int, poise_max_amount: int = 0) -> void:
	set_poise(enemy_poise + poise_amount, enemy_poise_max + poise_max_amount)

func is_poise_depleted() -> bool:
	return enemy_poise <= 0

func is_poise_at_or_below_half() -> bool:
	return enemy_poise * 2 <= enemy_poise_max

func validate_enemy_behavior(push_errors: bool = true) -> bool:
	var errors: Array[String] = collect_enemy_behavior_validation_errors()
	if push_errors:
		for error_message: String in errors:
			push_error(error_message)
	return len(errors) == 0

func collect_enemy_behavior_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	var stage_ids: Dictionary[String, bool] = {}
	var reactive_stage_ids: Dictionary[String, bool] = {}

	if opening_stage_id == "":
		errors.append("Enemy %s is missing opening_stage_id" % object_id)

	for stage_data: EnemyStageData in stages:
		if stage_data.object_id == "":
			errors.append("Enemy %s has a stage with an empty id" % object_id)
			continue
		if stage_ids.has(stage_data.object_id):
			errors.append("Enemy %s has duplicate stage id %s" % [object_id, stage_data.object_id])
		stage_ids[stage_data.object_id] = true

	for reactive_stage_data: EnemyReactiveStageData in reactive_stages:
		if reactive_stage_data.object_id == "":
			errors.append("Enemy %s has a reactive stage with an empty id" % object_id)
			continue
		if reactive_stage_ids.has(reactive_stage_data.object_id) or stage_ids.has(reactive_stage_data.object_id):
			errors.append("Enemy %s has duplicate reactive stage id %s" % [object_id, reactive_stage_data.object_id])
		reactive_stage_ids[reactive_stage_data.object_id] = true

	if opening_stage_id != "" and not stage_ids.has(opening_stage_id):
		errors.append("Enemy %s opening_stage_id %s does not exist" % [object_id, opening_stage_id])

	for stage_data: EnemyStageData in stages:
		if stage_data.next_stage_id == "":
			errors.append("Enemy %s stage %s is missing next_stage_id" % [object_id, stage_data.object_id])
		elif not stage_ids.has(stage_data.next_stage_id):
			errors.append("Enemy %s stage %s points to missing next stage %s" % [object_id, stage_data.object_id, stage_data.next_stage_id])
		_validate_intent_variants(errors, stage_data.object_id, stage_data.intents)

	for reactive_stage_data: EnemyReactiveStageData in reactive_stages:
		if not EnemyReactiveStageData.RESUME_MODES.has(reactive_stage_data.resume_mode):
			errors.append("Enemy %s reactive stage %s has invalid resume mode %s" % [object_id, reactive_stage_data.object_id, reactive_stage_data.resume_mode])
		if reactive_stage_data.resume_mode != EnemyReactiveStageData.RESUME_PREVIOUS:
			if reactive_stage_data.resume_stage_id == "":
				errors.append("Enemy %s reactive stage %s requires resume_stage_id" % [object_id, reactive_stage_data.object_id])
			elif not stage_ids.has(reactive_stage_data.resume_stage_id):
				errors.append("Enemy %s reactive stage %s points to missing resume stage %s" % [object_id, reactive_stage_data.object_id, reactive_stage_data.resume_stage_id])
		_validate_intent_variants(errors, reactive_stage_data.object_id, reactive_stage_data.intents)

	for difficulty_override: EnemyDifficultyOverrideData in difficulty_overrides:
		for stage_override: EnemyStageOverrideData in difficulty_override.stage_overrides:
			if not stage_ids.has(stage_override.stage_id):
				errors.append("Enemy %s difficulty override references missing stage %s" % [object_id, stage_override.stage_id])
			else:
				_validate_override_indices(errors, "stage", stage_override.stage_id, stage_override.intent_overrides, get_stage(stage_override.stage_id).intents)
		for reactive_stage_override: EnemyReactiveStageOverrideData in difficulty_override.reactive_stage_overrides:
			if not reactive_stage_ids.has(reactive_stage_override.reactive_stage_id):
				errors.append("Enemy %s difficulty override references missing reactive stage %s" % [object_id, reactive_stage_override.reactive_stage_id])
			else:
				_validate_override_indices(errors, "reactive stage", reactive_stage_override.reactive_stage_id, reactive_stage_override.intent_overrides, get_reactive_stage(reactive_stage_override.reactive_stage_id).intents)

	return errors

func _validate_intent_variants(errors: Array[String], owner_id: String, intent_variants: Array[EnemyIntentVariantData]) -> void:
	if len(intent_variants) == 0:
		errors.append("Enemy %s stage %s has no intent variants" % [object_id, owner_id])
		return

	var has_default_variant: bool = false
	var priorities_seen: Dictionary[int, int] = {}
	for intent_variant: EnemyIntentVariantData in intent_variants:
		if len(intent_variant.conditions) == 0:
			has_default_variant = true
		priorities_seen[intent_variant.priority] = priorities_seen.get(intent_variant.priority, 0) + 1
		for intent_error: String in intent_variant.intent.validate_intent():
			errors.append("Enemy %s stage %s: %s" % [object_id, owner_id, intent_error])
	if not has_default_variant:
		errors.append("Enemy %s stage %s has no unconditional default intent variant" % [object_id, owner_id])

func _validate_override_indices(errors: Array[String], owner_type: String, owner_id: String, intent_overrides: Array[EnemyIntentOverrideData], intent_variants: Array[EnemyIntentVariantData]) -> void:
	for intent_override: EnemyIntentOverrideData in intent_overrides:
		if intent_override.variant_index < 0 or intent_override.variant_index >= len(intent_variants):
			errors.append("Enemy %s difficulty override for %s %s references invalid intent variant index %s" % [object_id, owner_type, owner_id, intent_override.variant_index])
