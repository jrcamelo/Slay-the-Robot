extends BaseCombatant
class_name Enemy

@onready var enemy_intent: Control = $Visible/Intent
@onready var enemy_intent_amount_text: Label = $Visible/Intent/IntentAmount
@onready var enemy_intent_texture: TextureRect = $Visible/Intent/IntentTexture

@onready var name_label = $Visible/Sprite/NameLabel

var enemy_data: EnemyData
var enemy_slot: int = 0 # the spawn slot the enemy is in

var planned_stage_id: String = ""
var previous_executed_stage_id: String = ""
var planned_stage_started_turn_count: int = 1
var stage_id_to_execution_count: Dictionary[String, int] = {}

var enemy_intent_attack_damage: int = 0
var enemy_intent_number_of_attacks: int = 0
var enemy_intent_block: int = 0
var enemy_intent_target_party_member_indices: Array[int] = []
var enemy_active_stage_id: String = ""
var enemy_active_base_stage_id: String = ""
var enemy_active_reactive_stage_id: String = ""
var enemy_active_stage_is_reactive: bool = false
var enemy_active_stage_extra_actions: Array[Dictionary] = []
var enemy_active_intent_data: EnemyIntentData = null
var intent_preview_hidden: bool = false
var cached_random_target_signature: String = ""
var cached_random_target_party_member_indices: Array[int] = []

func _ready():
	super()
	Signals.energy_added.connect(_on_intent_relevant_state_changed)
	Signals.card_played.connect(_on_intent_relevant_state_changed_card)
	Signals.card_queue_refunded.connect(_on_intent_relevant_state_changed)
	Signals.player_health_changed.connect(_on_intent_relevant_state_changed)
	Signals.combatant_damaged.connect(_on_combatant_damaged)
	Signals.player_death_animation_finished.connect(_on_intent_relevant_state_changed_player)
	Signals.enemy_death_animation_finished.connect(_on_intent_relevant_state_changed_enemy)
	Signals.party_member_removed.connect(_on_intent_relevant_state_changed_party)

func init(_enemy_data: EnemyData):
	enemy_data = _enemy_data

	selection_button.mouse_entered.connect(_on_mouse_entered)
	selection_button.mouse_exited.connect(_on_mouse_exited)

	sprite.texture = FileLoader.load_texture(enemy_data.enemy_texture_path)

	for status_effect_object_id in enemy_data.enemy_initial_status_effects.keys():
		var charge_amount: int = enemy_data.enemy_initial_status_effects[status_effect_object_id]
		add_status_effect_charges(status_effect_object_id, charge_amount)

	name_label.text = enemy_data.enemy_name
	layered_health_bar.init(enemy_data.enemy_health, enemy_data.enemy_health_max)
	_initialize_behavior_state()
	update_enemy_intent()

func _initialize_behavior_state() -> void:
	planned_stage_id = enemy_data.opening_stage_id
	previous_executed_stage_id = ""
	planned_stage_started_turn_count = _get_current_turn_count()
	stage_id_to_execution_count.clear()
	enemy_active_stage_id = ""
	enemy_active_base_stage_id = ""
	enemy_active_reactive_stage_id = ""
	enemy_active_stage_is_reactive = false
	enemy_active_stage_extra_actions.clear()
	enemy_active_intent_data = null
	intent_preview_hidden = false
	enemy_intent_target_party_member_indices.clear()
	cached_random_target_signature = ""
	cached_random_target_party_member_indices.clear()

func _get_current_turn_count() -> int:
	var combat_stats: CombatStatsData = Global.get_combat_stats()
	if combat_stats == null:
		return 1
	return combat_stats.turn_count

## Does damage to combatant and returns [unblocked damage dealt, damage to 0 (if enemy dies), overkill damage (if enemy dies)]
## eg 15 damage on 10 remaining health and 3 block will return [12, 10, 2].
## bypass_block = true will do damage directly to health.
func damage(_damage: int, bypass_block: bool = false) -> Array[int]:
	var bypassed_damage: int = _damage
	var bypassed_damage_capped: int = 0
	var overkill_damage: int = 0

	if enemy_data.enemy_block > 0 and not bypass_block:
		if enemy_data.enemy_block > _damage:
			enemy_data.enemy_block -= _damage
			bypassed_damage = 0
			create_block_text()
			Signals.combatant_blocked.emit(self, _damage)
		else:
			bypassed_damage = _damage - enemy_data.enemy_block
			enemy_data.enemy_block = 0
			Signals.combatant_block_broken.emit(self)

	block.visible = enemy_data.enemy_block > 0
	block_amount.text = str(enemy_data.enemy_block)

	if bypassed_damage <= 0:
		return [0,0,0]

	create_damage_text(bypassed_damage)

	overkill_damage = max(0, bypassed_damage - enemy_data.enemy_health)
	bypassed_damage_capped = bypassed_damage - overkill_damage

	if enemy_data.enemy_health > 0:
		enemy_data.enemy_health = max(0, enemy_data.enemy_health - bypassed_damage)
		Signals.combatant_damaged.emit(self, bypassed_damage)
		update_health_bar(true)
		if enemy_data.enemy_health <= 0:
			if not animation_player.is_playing():
				animation_player.play("death")
				remove_from_group("enemies")
				Signals.enemy_killed.emit(self)

	return [bypassed_damage, bypassed_damage_capped, overkill_damage]

func set_block(amount: int) -> void:
	enemy_data.enemy_block = max(0, amount)
	block.visible = enemy_data.enemy_block > 0
	block_amount.text = str(enemy_data.enemy_block)

func get_block() -> int:
	return enemy_data.enemy_block

func add_block(amount: int) -> void:
	set_block(enemy_data.enemy_block + amount)
	if amount > 0:
		Signals.combatant_block_added.emit(self)

func set_poise(poise_amount: int, poise_max_amount: int = enemy_data.enemy_poise_max) -> void:
	enemy_data.set_poise(poise_amount, poise_max_amount)

func add_poise(poise_amount: int, poise_max_amount: int = 0) -> void:
	enemy_data.add_poise(poise_amount, poise_max_amount)

func get_poise() -> int:
	return enemy_data.enemy_poise

func get_poise_max() -> int:
	return enemy_data.enemy_poise_max

func is_poise_depleted() -> bool:
	return enemy_data.is_poise_depleted()

func is_poise_at_or_below_half() -> bool:
	return enemy_data.is_poise_at_or_below_half()

func update_health_bar(as_damage: bool = false) -> void:
	if as_damage:
		layered_health_bar.apply_damage(enemy_data.enemy_health, enemy_data.enemy_health_max, status_id_to_status_effects)
	else:
		layered_health_bar.update_health_layers(enemy_data.enemy_health, enemy_data.enemy_health_max, status_id_to_status_effects)

func update_enemy_intent() -> void:
	var active_stage_resolution: Dictionary = _resolve_active_stage()
	var stage_data = active_stage_resolution.get("stage_data", null)
	var base_stage: EnemyStageData = active_stage_resolution.get("base_stage", null)
	var intent_variant: EnemyIntentVariantData = _resolve_intent_variant(stage_data)
	var targets: Array[Player] = []
	if intent_variant != null:
		targets = _resolve_targets_for_intent(intent_variant.intent)
	_apply_active_stage_resolution(active_stage_resolution, intent_variant, targets)

func refresh_enemy_intent() -> void:
	update_enemy_intent()
	Signals.enemy_intent_changed.emit()

func cycle_enemy_intent():
	refresh_enemy_intent()

func hide_intent_preview() -> void:
	intent_preview_hidden = true
	enemy_intent.visible = false
	Signals.enemy_intent_changed.emit()

func _resolve_active_stage() -> Dictionary:
	var base_stage: EnemyStageData = enemy_data.get_stage(planned_stage_id)
	var best_reactive_stage: EnemyReactiveStageData = null

	for reactive_stage: EnemyReactiveStageData in enemy_data.reactive_stages:
		if not _conditions_pass(reactive_stage.conditions):
			continue
		if best_reactive_stage == null or reactive_stage.priority > best_reactive_stage.priority:
			best_reactive_stage = reactive_stage

	if best_reactive_stage != null:
		return {
			"stage_data": best_reactive_stage,
			"base_stage": base_stage,
			"is_reactive": true,
		}

	return {
		"stage_data": base_stage,
		"base_stage": base_stage,
		"is_reactive": false,
	}

func _resolve_intent_variant(stage_data) -> EnemyIntentVariantData:
	if stage_data == null:
		return null
	var best_variant: EnemyIntentVariantData = null
	var best_priority: int = -999999
	for intent_variant: EnemyIntentVariantData in stage_data.intents:
		if not _conditions_pass(intent_variant.conditions):
			continue
		if best_variant == null or intent_variant.priority > best_priority:
			best_variant = intent_variant
			best_priority = intent_variant.priority
	if best_variant != null:
		return best_variant
	if len(stage_data.intents) > 0:
		return stage_data.intents[0]
	return null

func _conditions_pass(conditions: Array[Dictionary]) -> bool:
	for validator_data: Dictionary in conditions:
		for validator_token: String in validator_data.keys():
			var validator_script_asset: Script = Scripts.resolve_script(validator_token)
			if validator_script_asset == null:
				push_error("Enemy condition failed to resolve validator %s" % validator_token)
				return false
			var validator: BaseValidator = validator_script_asset.new()
			var validator_values: Dictionary[String, Variant] = {}
			validator_values.assign(validator_data[validator_token])
			validator_values["_source_combatant"] = self
			if not validator.validate(null, null, validator_values):
				return false
	return true

func _resolve_targets_for_intent(intent_data: EnemyIntentData) -> Array[Player]:
	var living_players: Array[Player] = Global.get_living_players()
	if len(living_players) == 0:
		return []

	var target_count: int = max(1, intent_data.target_count)
	var returned_targets: Array[Player] = []
	var target_signature: String = "%s|%s|%s|%s|%s" % [
		planned_stage_id,
		intent_data.targeting_rule,
		target_count,
		intent_data.allow_repeat_targets,
		enemy_active_reactive_stage_id,
	]
	match intent_data.targeting_rule:
		EnemyIntentData.TARGETING_ALL_LIVING_PLAYERS:
			returned_targets.assign(living_players)
			return returned_targets
		EnemyIntentData.TARGETING_LOWEST_CURRENT_HEALTH_PLAYER:
			returned_targets = _resolve_sorted_targets(living_players, target_count, intent_data.allow_repeat_targets, true, false)
		EnemyIntentData.TARGETING_HIGHEST_CURRENT_HEALTH_PLAYER:
			returned_targets = _resolve_sorted_targets(living_players, target_count, intent_data.allow_repeat_targets, false, false)
		EnemyIntentData.TARGETING_LOWEST_HEALTH_PERCENT_PLAYER:
			returned_targets = _resolve_sorted_targets(living_players, target_count, intent_data.allow_repeat_targets, true, true)
		EnemyIntentData.TARGETING_HIGHEST_HEALTH_PERCENT_PLAYER:
			returned_targets = _resolve_sorted_targets(living_players, target_count, intent_data.allow_repeat_targets, false, true)
		EnemyIntentData.TARGETING_RANDOM_DISTINCT_PLAYERS:
			returned_targets = _resolve_random_targets(living_players, target_count, false, target_signature)
		EnemyIntentData.TARGETING_RANDOM_LIVING_PLAYER, _:
			returned_targets = _resolve_random_targets(living_players, target_count, not intent_data.allow_repeat_targets, target_signature)
	return returned_targets

func _resolve_sorted_targets(players: Array[Player], target_count: int, allow_repeat_targets: bool, ascending: bool, use_percent: bool) -> Array[Player]:
	var sorted_players: Array[Player] = []
	sorted_players.assign(players)
	sorted_players.sort_custom(func(player_a: Player, player_b: Player):
		var value_a: float = float(player_a.get_health())
		var value_b: float = float(player_b.get_health())
		if use_percent:
			value_a = float(player_a.get_health()) / float(max(1, player_a.get_health_max()))
			value_b = float(player_b.get_health()) / float(max(1, player_b.get_health_max()))
		if is_equal_approx(value_a, value_b):
			return player_a.get_party_member_index() < player_b.get_party_member_index()
		if ascending:
			return value_a < value_b
		return value_a > value_b
	)

	var returned_targets: Array[Player] = []
	if allow_repeat_targets and len(sorted_players) > 0:
		for _i in target_count:
			returned_targets.append(sorted_players[0])
		return returned_targets

	for player: Player in sorted_players:
		if len(returned_targets) >= target_count:
			break
		returned_targets.append(player)
	return returned_targets

func _resolve_random_targets(players: Array[Player], target_count: int, require_distinct: bool, target_signature: String) -> Array[Player]:
	if cached_random_target_signature == target_signature:
		var cached_targets: Array[Player] = []
		var all_cached_targets_alive: bool = true
		for party_member_index: int in cached_random_target_party_member_indices:
			var cached_player: Player = Global.get_player_by_party_index(party_member_index)
			if cached_player == null or not cached_player.is_alive():
				all_cached_targets_alive = false
				break
			cached_targets.append(cached_player)
		if all_cached_targets_alive and len(cached_targets) == target_count:
			return cached_targets

	var rng_targeting: RandomNumberGenerator = Global.player_data.get_player_rng("rng_enemy_targeting")
	var returned_targets: Array[Player] = []
	if require_distinct:
		var shuffled_players: Array[Player] = Random.shuffle_array(rng_targeting, players)
		for player: Player in shuffled_players:
			if len(returned_targets) >= target_count:
				break
			returned_targets.append(player)
	else:
		for _i in target_count:
			var random_index: int = rng_targeting.randi_range(0, len(players) - 1)
			returned_targets.append(players[random_index])

	cached_random_target_signature = target_signature
	cached_random_target_party_member_indices.clear()
	for player: Player in returned_targets:
		cached_random_target_party_member_indices.append(player.get_party_member_index())
	return returned_targets

func _apply_active_stage_resolution(active_stage_resolution: Dictionary, intent_variant: EnemyIntentVariantData, targets: Array[Player]) -> void:
	var stage_data = active_stage_resolution.get("stage_data", null)
	var base_stage: EnemyStageData = active_stage_resolution.get("base_stage", null)
	enemy_active_stage_extra_actions.clear()
	enemy_intent_target_party_member_indices.clear()
	enemy_intent_attack_damage = 0
	enemy_intent_number_of_attacks = 0
	enemy_intent_block = 0
	enemy_intent.visible = false
	enemy_active_stage_id = ""
	enemy_active_base_stage_id = ""
	enemy_active_reactive_stage_id = ""
	enemy_active_stage_is_reactive = bool(active_stage_resolution.get("is_reactive", false))

	if base_stage != null:
		enemy_active_base_stage_id = base_stage.object_id
	if stage_data != null:
		enemy_active_stage_id = stage_data.object_id
	if enemy_active_stage_is_reactive and stage_data != null:
		enemy_active_reactive_stage_id = stage_data.object_id
	if stage_data != null:
		enemy_active_stage_extra_actions.assign(stage_data.extra_actions)

	if intent_variant == null or len(targets) == 0:
		return

	var intent_data: EnemyIntentData = intent_variant.intent
	enemy_active_intent_data = intent_data
	enemy_intent_block = intent_data.block
	for player: Player in targets:
		enemy_intent_target_party_member_indices.append(player.get_party_member_index())

	var preview_attack_values: Array[int] = _preview_intent_attack(intent_data, targets)
	enemy_intent_attack_damage = preview_attack_values[0]
	enemy_intent_number_of_attacks = preview_attack_values[1]

	var preview_player: Player = targets[0]
	if preview_player != null:
		enemy_intent_texture.set_texture(
			FileLoader.load_texture(Global.get_character_data(
				preview_player.get_party_member_data().party_member_character_object_id
			).character_texture_path)
		)

	if not intent_preview_hidden and enemy_intent_attack_damage * enemy_intent_number_of_attacks > 0:
		enemy_intent.visible = true
		enemy_intent_amount_text.text = str(enemy_intent_attack_damage)
		if enemy_intent_number_of_attacks > 1:
			enemy_intent_amount_text.text += " x " + str(enemy_intent_number_of_attacks)

func _preview_intent_attack(intent_data: EnemyIntentData, targets: Array[Player]) -> Array[int]:
	if len(targets) == 0:
		return [0, 0]
	var preview_target: Player = targets[0]

	var action_data: Array[Dictionary] = [{
		Scripts.ACTION_ATTACK: {
			"damage": intent_data.damage,
			"target_override": BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS,
		}
	}]
	var generated_action: BaseAction = ActionGenerator.create_actions(self, null, [preview_target], action_data, null)[0]
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = generated_action._intercept_action([preview_target], true)

	var preview_damage: int = intent_data.damage
	if len(action_interceptor_processors) == 1:
		var action_interceptor_processor: ActionInterceptorProcessor = action_interceptor_processors[0]
		preview_damage = max(0, action_interceptor_processor.get_shadowed_action_values("damage", 0))

	action_data = [{
		Scripts.ACTION_ATTACK_GENERATOR: {
			"damage": intent_data.damage,
			"number_of_attacks": intent_data.number_of_attacks,
			"target_override": BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS,
		}
	}]
	generated_action = ActionGenerator.create_actions(self, null, [preview_target], action_data, null)[0]
	action_interceptor_processors = generated_action._intercept_action([preview_target], true)

	var preview_attacks: int = intent_data.number_of_attacks
	if len(action_interceptor_processors) == 1:
		var attack_generator_processor: ActionInterceptorProcessor = action_interceptor_processors[0]
		preview_attacks = max(0, attack_generator_processor.get_shadowed_action_values("number_of_attacks", 0))

	return [preview_damage, preview_attacks]

func build_enemy_turn_actions_data() -> Array[Dictionary]:
	var action_data: Array[Dictionary] = []
	action_data.assign(enemy_active_stage_extra_actions)
	if enemy_active_intent_data != null and enemy_active_intent_data.damage > 0 and enemy_active_intent_data.number_of_attacks > 0:
		action_data.append({
			Scripts.ACTION_ATTACK_GENERATOR: {
				"damage": enemy_active_intent_data.damage,
				"number_of_attacks": enemy_active_intent_data.number_of_attacks,
				"time_delay": 0.5,
			}
		})
	if enemy_active_intent_data != null and enemy_active_intent_data.block > 0:
		action_data.append({
			Scripts.ACTION_BLOCK: {
				"block": enemy_active_intent_data.block,
				"target_override": BaseAction.TARGET_OVERRIDES.PARENT,
				"time_delay": 0.0,
			}
		})
	return action_data

func get_intent_target_players() -> Array[Player]:
	var returned_targets: Array[Player] = []
	for party_member_index: int in enemy_intent_target_party_member_indices:
		var player: Player = Global.get_player_by_party_index(party_member_index)
		if player != null and player.is_alive():
			returned_targets.append(player)
	return returned_targets

func get_intent_target_player() -> Player:
	var targets: Array[Player] = get_intent_target_players()
	if len(targets) == 0:
		return null
	return targets[0]

func get_planned_stage_id() -> String:
	return planned_stage_id

func get_previous_executed_stage_id() -> String:
	return previous_executed_stage_id

func get_turns_since_planned_stage_started() -> int:
	return max(0, _get_current_turn_count() - planned_stage_started_turn_count)

func get_stage_execution_count(stage_id: String) -> int:
	return stage_id_to_execution_count.get(stage_id, 0)

func advance_planned_stage_after_execution() -> void:
	var current_base_stage: EnemyStageData = enemy_data.get_stage(enemy_active_base_stage_id)
	if current_base_stage == null:
		return

	var next_stage_id: String = current_base_stage.next_stage_id
	if enemy_active_stage_is_reactive:
		var reactive_stage: EnemyReactiveStageData = enemy_data.get_reactive_stage(enemy_active_reactive_stage_id)
		if reactive_stage != null:
			match reactive_stage.resume_mode:
				EnemyReactiveStageData.JUMP_TO_STAGE, EnemyReactiveStageData.START_NEW_SEQUENCE:
					next_stage_id = reactive_stage.resume_stage_id
				EnemyReactiveStageData.RESUME_PREVIOUS, _:
					next_stage_id = current_base_stage.next_stage_id

	stage_id_to_execution_count[enemy_active_stage_id] = stage_id_to_execution_count.get(enemy_active_stage_id, 0) + 1
	previous_executed_stage_id = enemy_active_stage_id
	planned_stage_id = next_stage_id
	planned_stage_started_turn_count = _get_current_turn_count() + 1
	cached_random_target_signature = ""
	cached_random_target_party_member_indices.clear()

func is_alive() -> bool:
	return enemy_data.enemy_health > 0

func is_attacking() -> bool:
	return enemy_intent_attack_damage > 0 and enemy_intent_number_of_attacks > 0

func _on_combat_started(_event_id: String):
	intent_preview_hidden = false
	update_enemy_intent()

func _on_combat_ended():
	queue_free()

func _on_player_turn_started():
	intent_preview_hidden = false
	refresh_enemy_intent()

func _on_selection_button_up():
	if is_alive():
		Signals.enemy_clicked.emit(self)

func _on_mouse_entered():
	Signals.enemy_hovered.emit(self)
	name_label.visible = true

func _on_mouse_exited():
	Signals.enemy_hovered.emit(null)
	name_label.visible = false

func _on_death_animtation_finished():
	Signals.enemy_death_animation_finished.emit(self)

func _on_intent_relevant_state_changed(_value = null):
	if Global.is_player_turn() and is_alive():
		refresh_enemy_intent()

func _on_intent_relevant_state_changed_card(_card_play_request: CardPlayRequest):
	_on_intent_relevant_state_changed()

func _on_combatant_damaged(base_combatant: BaseCombatant, _unblocked_damage: int):
	if not Global.is_player_turn() or not is_alive():
		return
	if base_combatant is Enemy or base_combatant is Player:
		refresh_enemy_intent()

func _on_intent_relevant_state_changed_player(_player: Player):
	_on_intent_relevant_state_changed()

func _on_intent_relevant_state_changed_enemy(_enemy: Enemy):
	_on_intent_relevant_state_changed()

func _on_intent_relevant_state_changed_party(_party_member_index: int):
	_on_intent_relevant_state_changed()
