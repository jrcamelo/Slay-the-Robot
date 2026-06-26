# Player UI element
extends BaseCombatant
class_name Player

const STATUS_BARRIER: String = "status_effect_barrier"

@onready var incoming_damage: Control = $Visible/IncomingDamage
@onready var incoming_damage_amount_text: Label = $Visible/IncomingDamage/IncomingDamageAmount
@onready var barrier: Sprite2D = $Visible/Barrier
@onready var barrier_amount: Label = $Visible/Barrier/BarrierAmount

const INTENT_UPDATES_LAZILY: bool = true	# batches intent updates
var _intent_is_updating: bool = false
@export var party_member_index: int = 0
var _death_reported: bool = false

func _ready():
	super()
	Signals.enemy_intent_changed.connect(_on_enemy_intent_changed)
	Signals.enemy_death_animation_finished.connect(_on_enemy_death_animation_finished)
	Signals.player_health_changed.connect(_on_player_health_changed)
	Signals.player_barrier_changed.connect(_on_player_barrier_changed)
	Signals.artifact_proc.connect(_on_artifact_proc)
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	selection_button.mouse_entered.connect(_on_mouse_entered)
	selection_button.mouse_exited.connect(_on_mouse_exited)

func _on_selection_button_up():
	if is_alive():
		Signals.player_clicked.emit(self)

func _on_mouse_entered():
	Signals.player_hovered.emit(self)

func _on_mouse_exited():
	Signals.player_hovered.emit(null)

## Does damage to combatant and returns [unblocked damage dealt, damage to 0 (if player dies), overkill damage (if player dies)].
## eg 15 damage on 10 remaining health and 3 block will return [12, 10, 2].
## bypass_block = true will do damage directly to health.
func damage(_damage: int, bypass_block: bool = false, source_action: BaseAction = null) -> Array[int]:
	var player_data: PlayerData = Global.player_data
	var party_member_data: PartyMemberData = get_party_member_data()
	
	var bypassed_damage: int = _damage # raw unblocked damage
	var bypassed_damage_capped: int = 0 # damage done that does not factor in overkill damage
	var overkill_damage: int = 0 # damage done past 0
	var blocked_by_barrier: int = 0
	var current_barrier: int = get_shared_status_amount(STATUS_BARRIER)
	if current_barrier > 0 and _damage > 0:
		blocked_by_barrier = min(current_barrier, _damage)
		if blocked_by_barrier > 0:
			Signals.combatant_blocked.emit(self, blocked_by_barrier)
			create_block_text()
	var remaining_damage: int = _damage - blocked_by_barrier
	if remaining_damage <= 0:
		return [0,0,0]
	var current_block: int = get_block()
	var current_health: int = _get_health()

	if current_block > 0 and not bypass_block:
		if current_block > remaining_damage:
			# damage less than block
			set_block(current_block - remaining_damage)
			bypassed_damage = 0
			create_block_text()
			Signals.combatant_blocked.emit(self, remaining_damage)
		else:
			# damage exceeds block
			bypassed_damage = remaining_damage - current_block
			set_block(0)
			Signals.combatant_block_broken.emit(self)
	else:
		bypassed_damage = remaining_damage
	
	if bypassed_damage <= 0:
		return [0,0,0]

	if current_health > 0 and bypassed_damage >= current_health and get_status_charges("status_effect_grit") > 0:
		bypassed_damage = max(0, current_health - 1)
		remove_status("status_effect_grit", 1)
	
	create_damage_text(bypassed_damage)
	overkill_damage = max(0, bypassed_damage - current_health)
	bypassed_damage_capped = bypassed_damage - overkill_damage
	
	if current_health > 0:
		if party_member_data != null:
			party_member_data.add_health(-bypassed_damage)
			_sync_primary_member_state_if_needed()
			Signals.player_health_changed.emit()
		else:
			player_data.add_health(-bypassed_damage)
		Signals.combatant_damaged.emit(self, bypassed_damage, source_action)
		
	return [bypassed_damage, bypassed_damage_capped, overkill_damage]

func set_block(amount: int) -> void:
	var party_member_data: PartyMemberData = get_party_member_data()
	if party_member_data != null:
		party_member_data.party_member_block = max(0, amount)
		_sync_primary_member_state_if_needed()
		block.visible = party_member_data.party_member_block > 0
		block_amount.text = str(party_member_data.party_member_block)
		if not _is_syncing_status_state:
			sync_shield_status_from_block()
		return
	Global.player_data.player_block = amount
	Global.player_data.player_block = max(0, Global.player_data.player_block)
	
	block.visible = Global.player_data.player_block > 0
	block_amount.text = str(Global.player_data.player_block)
	if not _is_syncing_status_state:
		sync_shield_status_from_block()

func get_block() -> int:
	var party_member_data: PartyMemberData = get_party_member_data()
	if party_member_data != null:
		return party_member_data.party_member_block
	return Global.player_data.player_block

func add_block(amount: int) -> void:
	set_block(get_block() + amount)
	if amount > 0:
		Signals.combatant_block_added.emit(self)

func update_health_bar(as_damage: bool = false) -> void:
	var player_health: int = _get_health()
	var player_health_max: int = _get_health_max()
	if as_damage:
		layered_health_bar.apply_damage(player_health, player_health_max, status_id_to_status_effects)
	else:
		layered_health_bar.update_health_layers(player_health, player_health_max, status_id_to_status_effects)

func update_player_display(_player_data: PlayerData):
	update_health_bar(false)
	_update_barrier_display()

func update_incoming_damage_amount(recalculate_enemy_intent: bool = true) -> void:
	# updates the damage preview above the player's head
	# flag to force recalculation of all enemy intents as well
	
	# optional lazy updating
	if _intent_is_updating:
		return
	if INTENT_UPDATES_LAZILY:
		_intent_is_updating = true
		await get_tree().process_frame
		_intent_is_updating = false
	
	var incoming_damage_amount = 0 # totaled value
	for en in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = en # typecast
		
		if recalculate_enemy_intent:
			enemy.update_enemy_intent()
		for targeted_player: Player in enemy.get_intent_target_players():
			if targeted_player == self:
				incoming_damage_amount += enemy.enemy_intent_attack_damage * enemy.enemy_intent_number_of_attacks

	incoming_damage_amount_text.text = str(incoming_damage_amount)
	incoming_damage.visible = incoming_damage_amount > 0

func is_alive() -> bool:
	return _get_health() > 0

func get_party_member_index() -> int:
	return party_member_index

func set_party_member_index(new_party_member_index: int) -> void:
	party_member_index = max(0, new_party_member_index)

func get_party_member_data() -> PartyMemberData:
	if Global.player_data.has_party_members():
		return Global.player_data.get_party_member(party_member_index)
	return null

func _get_health() -> int:
	var party_member_data: PartyMemberData = get_party_member_data()
	if party_member_data != null:
		return party_member_data.party_member_health
	return Global.player_data.player_health

func _get_health_max() -> int:
	var party_member_data: PartyMemberData = get_party_member_data()
	if party_member_data != null:
		return party_member_data.party_member_health_max
	return Global.player_data.player_health_max

func get_health() -> int:
	return _get_health()

func get_health_max() -> int:
	return _get_health_max()

func _sync_primary_member_state_if_needed() -> void:
	if Global.player_data.has_party_members() and party_member_index == 0:
		Global.player_data.synchronize_legacy_primary_member_state()

func create_artifact_fade(artifact_id: String) -> void:
	var artifact_fade: ArtifactFade = Scenes.ARTIFACT_FADE.instantiate()
	fade_container.add_child(artifact_fade)
	artifact_fade.init(artifact_id)

func _update_barrier_display() -> void:
	var held_barrier: int = max(0, get_status_charges(STATUS_BARRIER))
	barrier.visible = held_barrier > 0
	barrier_amount.text = str(held_barrier)

### Run Modifiers

func register_run_modifier_interceptors() -> void:
	# attaches intercepotors from modifiers to the player
	for run_modifier_object_id in Global.player_data.player_run_modifier_object_ids:
		var run_modifier_data: RunModifierData = Global.get_run_modifier_data(run_modifier_object_id)
		if run_modifier_data == null:
			push_error("No RunData with id of ", run_modifier_object_id)
		else:
			for interceptor_id in run_modifier_data.run_modifier_interceptor_script_paths:
				ActionHandler.register_action_interceptor(self, interceptor_id)


func _on_run_started():
	var character_data: CharacterData = Global.get_player_character_data()
	var party_member_data: PartyMemberData = get_party_member_data()
	if party_member_data != null:
		character_data = Global.get_character_data(party_member_data.party_member_character_object_id)
	sprite.texture = FileLoader.load_texture(character_data.character_texture_path)
	visible = true
	
	reset_block()
	clear_all_status_effects()
	unregister_all_custom_ui()
	_death_reported = false
	
	# reinitialize healthbar
	layered_health_bar.init(_get_health(), _get_health_max())
	update_health_bar(false)
	
	update_incoming_damage_amount(true)
	_update_barrier_display()
	# run modifiers
	register_run_modifier_interceptors()
	
	# reset animation and state
	var location_data: LocationData = Global.get_player_location_data()
	if location_data.location_type == LocationData.LOCATION_TYPES.STARTING:
		animation_player.play("run_start")

func _on_run_ended():
	reset_block()
	clear_all_status_effects()
	unregister_all_custom_ui()
	_death_reported = false
	visible = true
	_update_barrier_display()

func _on_combat_started(_event_id: String):
	clear_all_status_effects()
	_death_reported = false
	_update_barrier_display()
	
func _on_combat_ended():
	clear_all_status_effects()
	reset_block()
	update_incoming_damage_amount()
	_death_reported = false
	_update_barrier_display()

func _on_enemy_intent_changed():
	update_incoming_damage_amount(true)

func _on_enemy_death_animation_finished(_enemy: Enemy):
	update_incoming_damage_amount()

func _on_player_health_changed():
	update_health_bar(true)
	if is_alive():
		_death_reported = false
		return
	if not _death_reported:
		_death_reported = true
		if not animation_player.is_playing():
			animation_player.play("death")
			Signals.player_killed.emit(self)

func _on_artifact_proc(artifact_data: ArtifactData):
	create_artifact_fade(artifact_data.object_id)

func _on_player_barrier_changed():
	_update_barrier_display()

func _on_death_animtation_finished():
	# called from animation player
	Signals.player_death_animation_finished.emit(self)
