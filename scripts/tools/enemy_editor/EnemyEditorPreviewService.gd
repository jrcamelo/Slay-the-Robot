@tool
extends RefCounted
class_name EnemyEditorPreviewService

const SUPPORTED_PREVIEW_VALIDATORS := {
	"ValidatorEnemyBrokenPoise": true,
	"ValidatorEnemyHalfHealth": true,
	"ValidatorEnemyHalfPoise": true,
	"ValidatorPlayerCurrentEnergy": true,
	"ValidatorPreviousExecutedStageId": true,
	"ValidatorCurrentPlannedStageId": true,
	"ValidatorTurnsSinceCurrentStageStarted": true,
	"ValidatorStageExecutionCount": true,
	"ValidatorLivingAllyMinionCount": true,
	"ValidatorSourceCurrentHealth": true,
	"ValidatorSourceHealthPercent": true,
	"ValidatorSourceHasStatusEffect": true,
}

static func resolve_preview(enemy_data: EnemyData, preview_state_input: Variant = null) -> Dictionary:
	var diagnostics: Array[Dictionary] = []
	if enemy_data == null:
		return {
			"success": false,
			"diagnostics": [_make_diagnostic("enemy_missing", "error", "Preview could not run without EnemyData.", "enemy_data")],
		}

	var preview_enemy: EnemyData = enemy_data.duplicate(true)
	var preview_state: EnemyEditorPreviewState = _coerce_preview_state(preview_state_input)
	preview_state.ensure_defaults(preview_enemy)
	_apply_enemy_preview_state(preview_enemy, preview_state)
	preview_enemy.apply_enemy_difficulty_modifiers_for_level(preview_state.difficulty_level)
	preview_state.ensure_defaults(preview_enemy)

	var active_stage_resolution: Dictionary = _resolve_active_stage(preview_enemy, preview_state, diagnostics)
	var stage_data = active_stage_resolution.get("stage_data", null)
	var intent_variant_data: EnemyIntentVariantData = _resolve_intent_variant(stage_data, preview_enemy, preview_state, diagnostics)
	var resolved_targets: Array[Dictionary] = []
	if intent_variant_data != null:
		resolved_targets = _resolve_targets_for_intent(intent_variant_data.intent, preview_enemy, preview_state, str(active_stage_resolution.get("reactive_stage_id", "")))

	var preview_damage: int = 0
	var preview_attacks: int = 0
	var preview_block: int = 0
	var active_intent_data: EnemyIntentData = null
	if intent_variant_data != null:
		active_intent_data = intent_variant_data.intent
		preview_damage = max(0, active_intent_data.damage)
		preview_attacks = max(0, active_intent_data.number_of_attacks)
		preview_block = max(0, active_intent_data.block)

	var base_stage: EnemyStageData = active_stage_resolution.get("base_stage", null)
	var next_planned_stage_id: String = _resolve_next_planned_stage_id(preview_enemy, preview_state, active_stage_resolution)
	var target_party_indices: Array[int] = []
	for target_data: Dictionary in resolved_targets:
		target_party_indices.append(int(target_data.get("party_member_index", -1)))

	return {
		"success": true,
		"diagnostics": diagnostics,
		"preview_state": preview_state.to_dictionary(),
		"active_base_stage_id": "" if base_stage == null else base_stage.object_id,
		"active_stage_id": "" if stage_data == null else stage_data.object_id,
		"active_reactive_stage_id": str(active_stage_resolution.get("reactive_stage_id", "")),
		"active_stage_is_reactive": bool(active_stage_resolution.get("is_reactive", false)),
		"resolved_variant_index": -1 if stage_data == null else int(stage_data.get_meta("resolved_variant_index", -1)),
		"stage_summary": EnemyEditorSchema.summarize_stage(base_stage),
		"reactive_stage_summary": EnemyEditorSchema.summarize_reactive_stage(stage_data) if bool(active_stage_resolution.get("is_reactive", false)) else "",
		"variant_summary": EnemyEditorSchema.summarize_intent_variant(intent_variant_data),
		"intent_summary": EnemyEditorSchema.summarize_intent(active_intent_data),
		"target_summary": _format_target_summary(active_intent_data, resolved_targets),
		"target_party_member_indices": target_party_indices,
		"target_details": resolved_targets,
		"preview_attack_damage": preview_damage,
		"preview_number_of_attacks": preview_attacks,
		"preview_block": preview_block,
		"interception_applied": false,
		"next_planned_stage_id_after_execution": next_planned_stage_id,
		"cached_random_target_signature": preview_state.cached_random_target_signature,
		"cached_random_target_party_member_indices": preview_state.cached_random_target_party_member_indices.duplicate(true),
		"extra_actions": [] if stage_data == null else stage_data.extra_actions.duplicate(true),
	}

static func _coerce_preview_state(preview_state_input: Variant) -> EnemyEditorPreviewState:
	if preview_state_input is EnemyEditorPreviewState:
		return (preview_state_input as EnemyEditorPreviewState).duplicate_state()
	if preview_state_input is Dictionary:
		return EnemyEditorPreviewState.new(preview_state_input)
	return EnemyEditorPreviewState.new()

static func _apply_enemy_preview_state(enemy_data: EnemyData, preview_state: EnemyEditorPreviewState) -> void:
	enemy_data.enemy_health = preview_state.enemy_health if preview_state.enemy_health >= 0 else enemy_data.enemy_health
	enemy_data.enemy_health_max = preview_state.enemy_health_max if preview_state.enemy_health_max >= 0 else enemy_data.enemy_health_max
	enemy_data.enemy_poise = preview_state.enemy_poise if preview_state.enemy_poise >= 0 else enemy_data.enemy_poise
	enemy_data.enemy_poise_max = preview_state.enemy_poise_max if preview_state.enemy_poise_max >= 0 else enemy_data.enemy_poise_max
	if preview_state.enemy_type >= 0:
		enemy_data.enemy_type = preview_state.enemy_type
	enemy_data.enemy_is_minion = preview_state.enemy_is_minion

static func _resolve_active_stage(enemy_data: EnemyData, preview_state: EnemyEditorPreviewState, diagnostics: Array[Dictionary]) -> Dictionary:
	var base_stage: EnemyStageData = enemy_data.get_stage(preview_state.planned_stage_id)
	if base_stage == null:
		diagnostics.append(_make_diagnostic("missing_planned_stage", "error", "Preview planned stage id does not exist.", "planned_stage_id", {"stage_id": preview_state.planned_stage_id}))
		return {"stage_data": null, "base_stage": null, "is_reactive": false, "reactive_stage_id": ""}

	var best_reactive_stage: EnemyReactiveStageData = null
	for reactive_stage: EnemyReactiveStageData in enemy_data.reactive_stages:
		if not _conditions_pass(reactive_stage.conditions, enemy_data, preview_state, diagnostics):
			continue
		if best_reactive_stage == null or reactive_stage.priority > best_reactive_stage.priority:
			best_reactive_stage = reactive_stage

	if best_reactive_stage != null:
		return {
			"stage_data": best_reactive_stage,
			"base_stage": base_stage,
			"is_reactive": true,
			"reactive_stage_id": best_reactive_stage.object_id,
		}

	return {
		"stage_data": base_stage,
		"base_stage": base_stage,
		"is_reactive": false,
		"reactive_stage_id": "",
	}

static func _resolve_intent_variant(stage_data, enemy_data: EnemyData, preview_state: EnemyEditorPreviewState, diagnostics: Array[Dictionary]) -> EnemyIntentVariantData:
	if stage_data == null:
		return null
	var best_variant: EnemyIntentVariantData = null
	var best_priority: int = -999999
	var best_index: int = -1
	for variant_index: int in range(len(stage_data.intents)):
		var intent_variant: EnemyIntentVariantData = stage_data.intents[variant_index]
		if not _conditions_pass(intent_variant.conditions, enemy_data, preview_state, diagnostics):
			continue
		if best_variant == null or intent_variant.priority > best_priority:
			best_variant = intent_variant
			best_priority = intent_variant.priority
			best_index = variant_index
	if best_variant != null:
		stage_data.set_meta("resolved_variant_index", best_index)
		return best_variant
	if len(stage_data.intents) > 0:
		stage_data.set_meta("resolved_variant_index", 0)
		return stage_data.intents[0]
	return null

static func _conditions_pass(conditions: Array[Dictionary], enemy_data: EnemyData, preview_state: EnemyEditorPreviewState, diagnostics: Array[Dictionary]) -> bool:
	for validator_data: Dictionary in conditions:
		if len(validator_data.keys()) != 1:
			diagnostics.append(_make_diagnostic("malformed_condition", "warning", "Condition payload must contain exactly one validator token.", "conditions", {"condition": validator_data}))
			return false
		var validator_token: String = str(validator_data.keys()[0])
		var validator_values: Dictionary = validator_data[validator_token]
		if not _evaluate_validator(validator_token, validator_values, enemy_data, preview_state, diagnostics):
			return false
	return true

static func _evaluate_validator(validator_token: String, validator_values: Dictionary, enemy_data: EnemyData, preview_state: EnemyEditorPreviewState, diagnostics: Array[Dictionary]) -> bool:
	var validator_script: Script = Scripts.resolve_script(validator_token)
	if validator_script == null:
		diagnostics.append(_make_diagnostic("unresolved_validator", "warning", "Preview could not resolve a validator token.", "conditions", {"token": validator_token}))
		return false
	var validator_class_name: String = validator_script.get_global_name()
	if not SUPPORTED_PREVIEW_VALIDATORS.has(validator_class_name):
		diagnostics.append(_make_diagnostic("unsupported_preview_validator", "warning", "Preview does not simulate this validator yet.", "conditions", {"token": validator_token, "validator_class": validator_class_name}))
		return false

	match validator_class_name:
		"ValidatorEnemyBrokenPoise":
			return enemy_data.enemy_poise <= 0
		"ValidatorEnemyHalfHealth":
			return enemy_data.enemy_health * 2 <= max(1, enemy_data.enemy_health_max)
		"ValidatorEnemyHalfPoise":
			return enemy_data.enemy_poise * 2 <= max(1, enemy_data.enemy_poise_max)
		"ValidatorPlayerCurrentEnergy":
			return _compare(preview_state.player_energy, int(validator_values.get("comparison_value", 0)), str(validator_values.get("operator", ">=")))
		"ValidatorPreviousExecutedStageId":
			return preview_state.previous_executed_stage_id == str(validator_values.get("stage_id", ""))
		"ValidatorCurrentPlannedStageId":
			return preview_state.planned_stage_id == str(validator_values.get("stage_id", ""))
		"ValidatorTurnsSinceCurrentStageStarted":
			var turns_since_stage_started: int = max(0, preview_state.turn_count - preview_state.planned_stage_started_turn_count)
			return _compare(turns_since_stage_started, int(validator_values.get("comparison_value", 0)), str(validator_values.get("operator", ">=")))
		"ValidatorStageExecutionCount":
			var stage_id: String = str(validator_values.get("stage_id", ""))
			if stage_id == "":
				stage_id = preview_state.planned_stage_id
			var execution_count: int = preview_state.stage_id_to_execution_count.get(stage_id, 0)
			return _compare(execution_count, int(validator_values.get("comparison_value", 0)), str(validator_values.get("operator", ">=")))
		"ValidatorLivingAllyMinionCount":
			return _evaluate_living_ally_minion_count(validator_values, preview_state)
		"ValidatorSourceCurrentHealth":
			return _compare(enemy_data.enemy_health, int(validator_values.get("comparison_value", 0)), str(validator_values.get("operator", ">=")))
		"ValidatorSourceHealthPercent":
			var percent: float = float(enemy_data.enemy_health) / float(max(1, enemy_data.enemy_health_max))
			return _compare(percent, float(validator_values.get("comparison_value", 0.0)), str(validator_values.get("operator", ">=")))
		"ValidatorSourceHasStatusEffect":
			var status_id: String = str(validator_values.get("status_effect_object_id", validator_values.get("status_effect_id", "")))
			var comparison_value: int = int(validator_values.get("comparison_value", 1))
			var operator: String = str(validator_values.get("operator", ">="))
			var charge_amount: int = int(preview_state.enemy_status_effects.get(status_id, 0))
			return _compare(charge_amount, comparison_value, operator)
		_:
			return false

static func _evaluate_living_ally_minion_count(validator_values: Dictionary, preview_state: EnemyEditorPreviewState) -> bool:
	var count_mode: String = str(validator_values.get("count_mode", "living_allies"))
	var operator: String = str(validator_values.get("operator", ">="))
	var comparison_value: int = int(validator_values.get("comparison_value", 0))
	var current_count: int = 0
	for ally_data: Dictionary in preview_state.living_ally_enemy_states:
		var is_alive: bool = bool(ally_data.get("alive", true))
		if not is_alive:
			continue
		var is_minion: bool = bool(ally_data.get("enemy_is_minion", false))
		match count_mode:
			"living_minions":
				if is_minion:
					current_count += 1
			"living_non_minions":
				if not is_minion:
					current_count += 1
			_:
				current_count += 1
	return _compare(current_count, comparison_value, operator)

static func _resolve_targets_for_intent(intent_data: EnemyIntentData, enemy_data: EnemyData, preview_state: EnemyEditorPreviewState, reactive_stage_id: String = "") -> Array[Dictionary]:
	var living_players: Array[Dictionary] = _get_living_players(preview_state)
	if living_players.is_empty():
		return []
	var target_count: int = max(1, intent_data.target_count)
	var target_signature: String = "%s|%s|%s|%s|%s" % [
		preview_state.planned_stage_id,
		intent_data.targeting_rule,
		target_count,
		intent_data.allow_repeat_targets,
		reactive_stage_id,
	]
	match intent_data.targeting_rule:
		EnemyIntentData.TARGETING_ALL_LIVING_PLAYERS:
			return living_players
		EnemyIntentData.TARGETING_LOWEST_CURRENT_HEALTH_PLAYER:
			return _resolve_sorted_targets(living_players, target_count, intent_data.allow_repeat_targets, true, false)
		EnemyIntentData.TARGETING_HIGHEST_CURRENT_HEALTH_PLAYER:
			return _resolve_sorted_targets(living_players, target_count, intent_data.allow_repeat_targets, false, false)
		EnemyIntentData.TARGETING_LOWEST_HEALTH_PERCENT_PLAYER:
			return _resolve_sorted_targets(living_players, target_count, intent_data.allow_repeat_targets, true, true)
		EnemyIntentData.TARGETING_HIGHEST_HEALTH_PERCENT_PLAYER:
			return _resolve_sorted_targets(living_players, target_count, intent_data.allow_repeat_targets, false, true)
		EnemyIntentData.TARGETING_RANDOM_DISTINCT_PLAYERS:
			return _resolve_random_targets(living_players, target_count, true, target_signature, enemy_data, preview_state)
		EnemyIntentData.TARGETING_RANDOM_LIVING_PLAYER, _:
			return _resolve_random_targets(living_players, target_count, not intent_data.allow_repeat_targets, target_signature, enemy_data, preview_state)

static func _resolve_sorted_targets(players: Array[Dictionary], target_count: int, allow_repeat_targets: bool, ascending: bool, use_percent: bool) -> Array[Dictionary]:
	var sorted_players: Array[Dictionary] = players.duplicate(true)
	sorted_players.sort_custom(func(player_a: Dictionary, player_b: Dictionary):
		var value_a: float = float(player_a.get("health", 0))
		var value_b: float = float(player_b.get("health", 0))
		if use_percent:
			value_a = float(player_a.get("health", 0)) / float(max(1, int(player_a.get("health_max", 1))))
			value_b = float(player_b.get("health", 0)) / float(max(1, int(player_b.get("health_max", 1))))
		if is_equal_approx(value_a, value_b):
			return int(player_a.get("party_member_index", 0)) < int(player_b.get("party_member_index", 0))
		return value_a < value_b if ascending else value_a > value_b
	)
	var targets: Array[Dictionary] = []
	if allow_repeat_targets and not sorted_players.is_empty():
		for _i: int in range(target_count):
			targets.append(sorted_players[0].duplicate(true))
		return targets
	for player_data: Dictionary in sorted_players:
		if len(targets) >= target_count:
			break
		targets.append(player_data.duplicate(true))
	return targets

static func _resolve_random_targets(players: Array[Dictionary], target_count: int, require_distinct: bool, target_signature: String, enemy_data: EnemyData, preview_state: EnemyEditorPreviewState) -> Array[Dictionary]:
	if preview_state.cached_random_target_signature == target_signature:
		var cached_targets: Array[Dictionary] = []
		var all_cached_targets_alive: bool = true
		for party_member_index: int in preview_state.cached_random_target_party_member_indices:
			var cached_target: Dictionary = _get_player_by_party_index(preview_state, party_member_index)
			if cached_target.is_empty():
				all_cached_targets_alive = false
				break
			cached_targets.append(cached_target)
		if all_cached_targets_alive and len(cached_targets) == target_count:
			return cached_targets

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(preview_state.random_seed if preview_state.random_seed != 0 else hash("%s|%s" % [enemy_data.object_id, target_signature]))
	var targets: Array[Dictionary] = []
	if require_distinct:
		var shuffled_players: Array = players.duplicate(true)
		for index: int in range(shuffled_players.size() - 1, 0, -1):
			var swap_index: int = rng.randi_range(0, index)
			var temp: Variant = shuffled_players[index]
			shuffled_players[index] = shuffled_players[swap_index]
			shuffled_players[swap_index] = temp
		for player_data: Dictionary in shuffled_players:
			if len(targets) >= target_count:
				break
			targets.append(player_data.duplicate(true))
	else:
		for _i: int in range(target_count):
			var random_index: int = rng.randi_range(0, len(players) - 1)
			targets.append(players[random_index].duplicate(true))

	preview_state.cached_random_target_signature = target_signature
	preview_state.cached_random_target_party_member_indices.clear()
	for target_data: Dictionary in targets:
		preview_state.cached_random_target_party_member_indices.append(int(target_data.get("party_member_index", -1)))
	return targets

static func _resolve_next_planned_stage_id(enemy_data: EnemyData, preview_state: EnemyEditorPreviewState, active_stage_resolution: Dictionary) -> String:
	var base_stage: EnemyStageData = active_stage_resolution.get("base_stage", null)
	if base_stage == null:
		return preview_state.planned_stage_id
	var next_stage_id: String = base_stage.next_stage_id
	if bool(active_stage_resolution.get("is_reactive", false)):
		var reactive_stage: EnemyReactiveStageData = active_stage_resolution.get("stage_data", null)
		if reactive_stage != null:
			match reactive_stage.resume_mode:
				EnemyReactiveStageData.JUMP_TO_STAGE, EnemyReactiveStageData.START_NEW_SEQUENCE:
					next_stage_id = reactive_stage.resume_stage_id
				EnemyReactiveStageData.RESUME_PREVIOUS, _:
					next_stage_id = base_stage.next_stage_id
	return next_stage_id

static func _get_living_players(preview_state: EnemyEditorPreviewState) -> Array[Dictionary]:
	var players: Array[Dictionary] = []
	for player_data: Dictionary in preview_state.player_party_members:
		if int(player_data.get("health", 0)) <= 0:
			continue
		players.append(player_data.duplicate(true))
	return players

static func _get_player_by_party_index(preview_state: EnemyEditorPreviewState, party_member_index: int) -> Dictionary:
	for player_data: Dictionary in preview_state.player_party_members:
		if int(player_data.get("party_member_index", -1)) == party_member_index and int(player_data.get("health", 0)) > 0:
			return player_data.duplicate(true)
	return {}

static func _format_target_summary(intent_data: EnemyIntentData, resolved_targets: Array[Dictionary]) -> String:
	if intent_data == null:
		return "No intent"
	var summary: String = EnemyEditorSchema.format_targeting_summary(intent_data)
	if resolved_targets.is_empty():
		return "%s | No living targets" % summary
	var target_labels: Array[String] = []
	for target_data: Dictionary in resolved_targets:
		target_labels.append("P%s" % target_data.get("party_member_index", "?"))
	return "%s | %s" % [summary, ", ".join(target_labels)]

static func _compare(value: Variant, comparison_value: Variant, operator: String = "<") -> bool:
	match operator:
		"<": return value < comparison_value
		"<=": return value <= comparison_value
		">": return value > comparison_value
		">=": return value >= comparison_value
		"==": return value == comparison_value
		"!=": return value != comparison_value
		_: return value < comparison_value

static func _make_diagnostic(code: String, severity: String, message: String, field: String = "", data: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"severity": severity,
		"message": message,
		"field": field,
		"data": data,
	}
