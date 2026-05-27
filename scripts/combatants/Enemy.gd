extends BaseCombatant
class_name Enemy

@onready var enemy_intent: Control = $Visible/Intent
@onready var enemy_intent_amount_text: Label = $Visible/Intent/IntentAmount
@onready var enemy_intent_texture: TextureRect = $Visible/Intent/IntentTexture

@onready var name_label = $Visible/Sprite/NameLabel


var enemy_data: EnemyData
var enemy_slot: int = 0 # the spawn slot the enemy is in

var enemy_intent_attack_damage: int = 0
var enemy_intent_number_of_attacks: int = 0
var enemy_intent_target_party_member_index: int = 0

func init(_enemy_data: EnemyData):
	enemy_data = _enemy_data
	
	selection_button.mouse_entered.connect(_on_mouse_entered)
	selection_button.mouse_exited.connect(_on_mouse_exited)
	
	sprite.texture = FileLoader.load_texture(enemy_data.enemy_texture_path)
	
	# apply initial effects
	for status_effect_object_id in enemy_data.enemy_initial_status_effects.keys():
		var charge_amount: int = enemy_data.enemy_initial_status_effects[status_effect_object_id]
		add_status_effect_charges(status_effect_object_id, charge_amount)
	
	name_label.text = enemy_data.enemy_name
	
	# update_health_bar()
	layered_health_bar.init(enemy_data.enemy_health, enemy_data.enemy_health_max)

## Does damage to combatant and returns [unblocked damage dealt, damage to 0 (if enemy dies), overkill damage (if enemy dies)]
## eg 15 damage on 10 remaining health and 3 block will return [12, 10, 2].
## bypass_block = true will do damage directly to health.
func damage(_damage: int, bypass_block: bool = false) -> Array[int]:
	var bypassed_damage: int = _damage # raw unblocked damage
	var bypassed_damage_capped: int = 0 # damage done that does not factor in overkill damage
	var overkill_damage: int = 0 # damage done past 0

	if enemy_data.enemy_block > 0 and not bypass_block:
		if enemy_data.enemy_block > _damage:
			# damage less than block
			enemy_data.enemy_block -= _damage
			bypassed_damage = 0
			create_block_text()
			Signals.combatant_blocked.emit(self, _damage)
		else:
			# damage exceeds block
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
	enemy_data.enemy_block = amount
	enemy_data.enemy_block = max(0, enemy_data.enemy_block)
	
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

func cycle_enemy_intent():
	enemy_data.cycle_next_attack_state()
	roll_intent_target()
	update_enemy_intent()
	Signals.enemy_intent_changed.emit()

func update_enemy_intent():
	# displays the enemy's attack
	
	
	# get current intent's attack
	var attack_damages: Array = enemy_data.get_current_attack_damages()
	var attack_damage: int = attack_damages[0]
	var number_of_attacks: int = attack_damages[1]
	
	var player: Player = get_intent_target_player()
	if player == null:
		enemy_intent_attack_damage = 0
		enemy_intent_number_of_attacks = 0
		enemy_intent.visible = false
		return
	
	enemy_intent_texture.set_texture(
		FileLoader.load_texture(Global.get_character_data(
			player.get_party_member_data().party_member_character_object_id)
			.character_texture_path))
	
	### damage
	# intercept an attack action in preview mode
	var action_data: Array[Dictionary] = [{
			Scripts.ACTION_ATTACK: 
				{
				"damage": attack_damage,
				"target_override": BaseAction.TARGET_OVERRIDES.PLAYER
				}}]
	var generated_action: BaseAction = ActionGenerator.create_actions(self, null, [player], action_data, null)[0]
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = generated_action._intercept_action([player], true)
	
	if len(action_interceptor_processors) == 1:
		var action_interceptor_processor: ActionInterceptorProcessor = action_interceptor_processors[0]
		# get intercepted attack values
		enemy_intent_attack_damage = max(0, action_interceptor_processor.get_shadowed_action_values("damage", 0))

	
	### number of attacks
	# intercept an attack action generator in preview mode
	action_data = [{
		Scripts.ACTION_ATTACK_GENERATOR: 
			{
			"damage": attack_damage,
			"number_of_attacks": number_of_attacks,
			"target_override": BaseAction.TARGET_OVERRIDES.PLAYER
			}}]
	generated_action = ActionGenerator.create_actions(self, null, [player], action_data, null)[0]
	action_interceptor_processors = generated_action._intercept_action([player], true)
	
	if len(action_interceptor_processors) == 1:
		var action_interceptor_processor: ActionInterceptorProcessor = action_interceptor_processors[0]
		# get intercepted attack values
		enemy_intent_number_of_attacks = max(0, action_interceptor_processor.get_shadowed_action_values("number_of_attacks", 0))
	
	### Display intent
	enemy_intent.visible = false
	if enemy_intent_attack_damage * enemy_intent_number_of_attacks > 0:
		enemy_intent.visible = true
		enemy_intent_amount_text.text = str(enemy_intent_attack_damage)
		if enemy_intent_number_of_attacks > 1:
			enemy_intent_amount_text.text += " x " + str(enemy_intent_number_of_attacks)

func is_alive() -> bool:
	return enemy_data.enemy_health > 0

func roll_intent_target() -> void:
	var living_players: Array[Player] = Global.get_living_players()
	if len(living_players) == 0:
		enemy_intent_target_party_member_index = 0
		return
	var rng_targeting: RandomNumberGenerator = Global.player_data.get_player_rng("rng_enemy_targeting")
	living_players = Random.shuffle_array(rng_targeting, living_players)
	var selected_player: Player = living_players[0]
	enemy_intent_target_party_member_index = selected_player.get_party_member_index()

func get_intent_target_player() -> Player:
	var target_player: Player = Global.get_player_by_party_index(enemy_intent_target_party_member_index)
	if target_player == null or not target_player.is_alive():
		roll_intent_target()
		target_player = Global.get_player_by_party_index(enemy_intent_target_party_member_index)
	return target_player

func is_attacking() -> bool:
	return enemy_intent_number_of_attacks > 0

func _on_combat_started(_event_id: String):
	roll_intent_target()

func _on_combat_ended():
	queue_free()

func _on_player_turn_started():
	cycle_enemy_intent()

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
	# called from animation player
	Signals.enemy_death_animation_finished.emit(self)
