# Base abstract class for shared interface of player and enemies
extends Control
class_name BaseCombatant

const STATUS_BARRIER: String = "status_effect_barrier"
const STATUS_SHIELD: String = "status_effect_shield"
const STATUS_BURN: String = "status_effect_burn"
const STATUS_POISON: String = "status_effect_poison"
const STATUS_SLEEP: String = "status_effect_sleep"
const STATUS_PARALYZE: String = "status_effect_paralyze"

@onready var block: Sprite2D = $Visible/Block
@onready var block_amount: Label = $Visible/Block/BlockAmount

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var sprite: Sprite2D = $Visible/Sprite
@onready var layered_health_bar: LayeredHealthBar = $Visible/Sprite/LayeredHealthBar

@onready var fade_container = $Visible/FadeContainer
@onready var selection_button: Button = $Visible/Sprite/SelectionButton

@onready var status_container: GridContainer = $Visible/StatusContainer
@onready var custom_ui_container = $Visible/CustomUIContainer

var status_id_to_status_effects: Dictionary = {}	# maps status id to the array of ui element(s) it matches
var custom_ui_object_id_to_custom_ui: Dictionary = {} # maps a custom ui id to the ui component it matches. Duplicate registrations will be ignored
var _is_syncing_status_state: bool = false

func _ready():
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	Signals.player_turn_started.connect(_on_player_turn_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)
	
	selection_button.button_up.connect(_on_selection_button_up)

func _on_selection_button_up():
	pass

func play_attack_animation() -> void:
	animation_player.play("attack")

#region Block
func set_block(_amount: int) -> void:
	# override
	breakpoint

func get_block() -> int:
	# override
	breakpoint
	return 0

func add_block(_amount: int) -> void:
	# override
	breakpoint

func generate_reset_block_action() -> void:
	# generates a reset block action for this combatant and adds it to the action stack
	var actions_data: Array[Dictionary] = [
		{
		Scripts.ACTION_RESET_BLOCK:  {
			"target_override": BaseAction.TARGET_OVERRIDES.PARENT,
			"time_delay": 0.0
			}
		}
	]
	
	var generated_actions: Array = ActionGenerator.create_actions(self, null, [self], actions_data, null)
	ActionHandler.add_actions(generated_actions)

func reset_block() -> void:
	set_block(0)
#endregion

func get_living_allies() -> Array[BaseCombatant]:
	var allies: Array[BaseCombatant] = []
	if is_in_group("players"):
		allies.assign(Global.get_living_players())
	elif is_in_group("enemies"):
		allies.assign(Global.get_living_enemies())
	return allies

func get_shared_status_total(status_effect_object_id: String) -> int:
	var total_amount: int = 0
	for ally: BaseCombatant in get_living_allies():
		total_amount += max(0, ally.get_status_charges(status_effect_object_id))
	return total_amount

func sync_shield_status_from_block() -> void:
	if _is_syncing_status_state:
		return
	_is_syncing_status_state = true
	var current_block: int = max(0, get_block())
	var current_shield: int = max(0, get_status_charges(STATUS_SHIELD))
	if current_block <= 0:
		_remove_status_local(STATUS_SHIELD, -1)
	else:
		var shield_delta: int = current_block - current_shield
		if shield_delta > 0:
			_apply_status_internal(STATUS_SHIELD, shield_delta, 0, false, {}, false)
		elif shield_delta < 0:
			_remove_status_local(STATUS_SHIELD, -shield_delta)
	_is_syncing_status_state = false

func sync_block_from_shield_status() -> void:
	if _is_syncing_status_state:
		return
	_is_syncing_status_state = true
	set_block(max(0, get_status_charges(STATUS_SHIELD)))
	_is_syncing_status_state = false

#region Health
func update_health_bar(as_damage: bool = false) -> void:
	# as_damage will tell the healthbar to update as though the combatant took some kind of damage
	pass

func is_alive() -> bool:
	# override this
	return true

## Does damage to combatant and returns [unblocked damage dealt, overkill damage (if combatant dies)]
func damage(_damage: int, _bypass_block: bool = false) -> Array[int]:
	breakpoint
	return [0,0,0]
#endregion

#region Custom UI
func register_custom_ui(custom_ui_object_id: String) -> void:
	# generates a custom ui element and attaches it to the combatant if it doesn't already exist
	if not custom_ui_object_id_to_custom_ui.has(custom_ui_object_id):
		var custom_ui_data: CustomUIData = Global.get_custom_ui_data(custom_ui_object_id)
		if custom_ui_data != null:
			if custom_ui_data.custom_ui_asset_path != "":
				var custom_ui_asset: PackedScene = load(custom_ui_data.custom_ui_asset_path)
				var custom_ui: BaseCustomUI = custom_ui_asset.instantiate()
				custom_ui_container.add_child(custom_ui)
				custom_ui_object_id_to_custom_ui[custom_ui_object_id] = custom_ui
				custom_ui.init(custom_ui_object_id, self)

func unregister_custom_ui(custom_ui_object_id: String) -> void:
	var custom_ui: BaseCustomUI = custom_ui_object_id_to_custom_ui.get(custom_ui_object_id, null)
	if custom_ui != null:
		custom_ui.queue_free()
		custom_ui_object_id_to_custom_ui.erase(custom_ui_object_id)
		
func unregister_all_custom_ui() -> void:
	for custom_ui_object_id: String in custom_ui_object_id_to_custom_ui.keys().duplicate():
		unregister_custom_ui(custom_ui_object_id)
#endregion

#region Fades

func create_block_text() -> void:
	var text_fade: TextFade = Scenes.TEXT_FADE.instantiate()
	fade_container.add_child(text_fade)
	text_fade.init("Blocked")

func create_damage_text(damage_amount: int) -> void:
	var text_fade: TextFade = Scenes.TEXT_FADE.instantiate()
	fade_container.add_child(text_fade)
	text_fade.init(str(damage_amount))

#endregion

#region Statuses

func apply_status(status_effect_object_id: String, amount: int, source_combatant: BaseCombatant = null, secondary_amount: int = 0, force_new_effect: bool = false, custom_values: Dictionary = {}) -> void:
	_apply_status_internal(status_effect_object_id, amount, secondary_amount, force_new_effect, custom_values)
	if source_combatant != null:
		_set_status_source(status_effect_object_id, source_combatant)

func remove_status(status_effect_object_id: String, amount: int = -1) -> void:
	_remove_status_local(status_effect_object_id, amount)

func remove_by_disposition(status_disposition: int) -> void:
	for status_effect_object_id: String in status_id_to_status_effects.keys().duplicate():
		var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
		if status_effect_data == null:
			continue
		if status_effect_data.status_effect_disposition == status_disposition:
			remove_status(status_effect_object_id, -1)

func cleanse() -> void:
	remove_by_disposition(StatusEffectData.STATUS_DISPOSITIONS.NEGATIVE)

func dispel() -> void:
	remove_by_disposition(StatusEffectData.STATUS_DISPOSITIONS.POSITIVE)

func consume_flag_status(status_effect_object_id: String) -> bool:
	if get_status_charges(status_effect_object_id) <= 0:
		return false
	remove_status(status_effect_object_id, 1)
	return true

func tick_status(status_effect_object_id: String) -> void:
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	if status_effect_data == null:
		return
	if status_effect_data.status_effect_decay_type_v2 == StatusEffectData.STATUS_DECAY_TYPES_V2.PER_TICK:
		remove_status(status_effect_object_id, 1)

func turn_decay_statuses(status_effect_process_time: int) -> void:
	for status_effect_object_id: String in _get_status_effects_with_process_time(status_id_to_status_effects.keys(), status_effect_process_time):
		var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
		if status_effect_data == null:
			continue
		if status_effect_data.status_effect_decay_type_v2 == StatusEffectData.STATUS_DECAY_TYPES_V2.PER_TURN:
			remove_status(status_effect_object_id, 1)

func add_status_effect_charges(status_effect_object_id: String, charge_amount: int, secondary_charge_amount: int = 0) -> void:
	_apply_status_internal(status_effect_object_id, charge_amount, secondary_charge_amount, false, {})

func _apply_status_internal(status_effect_object_id: String, charge_amount: int, secondary_charge_amount: int = 0, force_new_effect: bool = false, custom_values: Dictionary = {}, emit_source_update: bool = true) -> void:
	# general method for adding status effects and charge amounts
	# adds charges and secondary charges to ALL instances of a given status
	# if no status exists, create one and apply charges
	# will remove statuses that become zero'd out
	
	if charge_amount == 0 and secondary_charge_amount == 0 and custom_values.is_empty():
		return # charge applications of zero have no effect
	
	# get status data
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	if status_effect_data == null:
		# status effect of given id does not exist
		push_error("Status effect \"", status_effect_object_id,"\" does not exist")
		return
	
	#  get status effect ui elements corresponding to the status
	var status_effects: Array[StatusEffect] = []
	if status_id_to_status_effects.has(status_effect_object_id):
		status_effects = status_id_to_status_effects[status_effect_object_id]
	
	# create a new status if none exists
	if len(status_effects) == 0 and not (force_new_effect and status_effect_data.status_effect_allows_multiples):
		var _status_effect: StatusEffect = _create_status_effect(status_effect_object_id)
		status_effects = status_id_to_status_effects[status_effect_object_id]
	
	if force_new_effect and status_effect_data.status_effect_allows_multiples:
		var forced_status_effect: StatusEffect = _create_status_effect(status_effect_object_id)
		if forced_status_effect != null:
			status_effects = [forced_status_effect]

	# iterate over all statuses and apply charges
	for status_effect in status_effects.duplicate():
		var status_effect_script: BaseStatusEffect = status_effect.status_effect_script
		
		# apply charges and secondary charges
		status_effect_script.add_status_charges(charge_amount)
		status_effect_script.status_secondary_charges += secondary_charge_amount
		for key: Variant in custom_values.keys():
			status_effect_script.status_custom_values[key] = custom_values[key]
		if status_effect_object_id == STATUS_POISON and emit_source_update:
			status_effect_script.status_custom_values["last_applied_turn"] = Global.get_combat_stats().turn_count if Global.get_combat_stats() != null else 1
		
		# delete the effect if zero charges
		if (status_effect_script.status_charges == 0):
			_remove_status_effect(status_effect)
		else:
			# update ui with charge count
			status_effect.update_status_charge_display()
	
	if status_effect_object_id == STATUS_SHIELD:
		sync_block_from_shield_status()
	if self is Player and status_effect_object_id == STATUS_BARRIER:
		self._update_barrier_display()
	
	update_health_bar(false)
	
	Signals.enemy_intent_changed.emit()	# update enemy intent in case statuses affect them

func add_new_status_effect(status_effect_object_id: String, charge_amount: int, secondary_charge_amount: int = 0, custom_values: Dictionary = {}) -> void:
	apply_status(status_effect_object_id, charge_amount, null, secondary_charge_amount, true, custom_values)

func clear_all_status_effects():
	for status_effect_object_id in status_id_to_status_effects.keys().duplicate():
		var status_effects: Array[StatusEffect] = status_id_to_status_effects[status_effect_object_id] 
		for status_effect in status_effects.duplicate():
			_remove_status_effect(status_effect)
	
	status_id_to_status_effects.clear()
	update_health_bar(false)

## Decrements statuses by the decay rate and potentially removes them.
func _decay_status_effect(status_effect_object_id: String) -> void:
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	if status_effect_data != null:
		# get the first status effect of the given type
		# and use it to determine the decay ratw of all the statuses
		var status_effects: Array[StatusEffect] = []
		if status_id_to_status_effects.has(status_effect_object_id):
			status_effects = status_id_to_status_effects[status_effect_object_id]
		if len(status_effects) > 0:
			var status_effect: StatusEffect = status_effects[0]
			var status_effect_script: BaseStatusEffect = status_effect.status_effect_script
			var decay_amount: int = status_effect_script.get_status_decay_amount()
			
			# generate an instant intercepted action to decay the status
			ActionGenerator.generate_decay_status_effect(self, status_effect_object_id, decay_amount)
			# 
			# add_status_effect_charges(status_effect_object_id, decay_amount, 0)

## DEPRECATED Left in for being potentially useful, but not used anywhere
func _decay_all_status_effects():
	for status_effect_object_id in status_id_to_status_effects.keys().duplicate():
		_decay_status_effect(status_effect_object_id)

func get_status_charges(status_effect_object_id: String) -> int:
	# returns the amount of status effect charges of a given effect
	# zero if no status applied, if multiple statuses returns absolute maximum
	var status_effects: Array = status_id_to_status_effects.get(status_effect_object_id, [])
	var absolute_maximum: int = 0
	for s_e in status_effects:
		var status_effect: StatusEffect = s_e
		if abs(status_effect.status_effect_script.status_charges) > abs(absolute_maximum):
			absolute_maximum = status_effect.status_effect_script.status_charges
	return absolute_maximum

func _remove_status_local(status_effect_object_id: String, amount: int = -1) -> void:
	var status_effects: Array[StatusEffect] = status_id_to_status_effects.get(status_effect_object_id, [])
	if status_effects.is_empty():
		if status_effect_object_id == STATUS_SHIELD:
			sync_block_from_shield_status()
		return
	for status_effect: StatusEffect in status_effects.duplicate():
		if amount < 0:
			_remove_status_effect(status_effect)
			continue
		status_effect.status_effect_script.add_status_charges(-amount)
		if status_effect.status_effect_script.status_charges <= 0:
			_remove_status_effect(status_effect)
		else:
			status_effect.update_status_charge_display()
	if status_effect_object_id == STATUS_SHIELD:
		sync_block_from_shield_status()
	if self is Player and status_effect_object_id == STATUS_BARRIER:
		self._update_barrier_display()
	update_health_bar(false)
	Signals.enemy_intent_changed.emit()

func _set_status_source(status_effect_object_id: String, source_combatant: BaseCombatant) -> void:
	if source_combatant == null:
		return
	var source_party_member_index: int = -1
	if source_combatant is Player:
		source_party_member_index = source_combatant.get_party_member_index()
	for status_effect: StatusEffect in status_id_to_status_effects.get(status_effect_object_id, []):
		status_effect.status_effect_script.status_custom_values["source_instance_id"] = source_combatant.get_instance_id()
		status_effect.status_effect_script.status_custom_values["source_party_member_index"] = source_party_member_index
		status_effect.status_effect_script.status_custom_values["source_turn_count"] = Global.get_combat_stats().turn_count if Global.get_combat_stats() != null else 1

func _remove_status_effect(status_effect: StatusEffect) -> void:
	var status_effect_data: StatusEffectData = status_effect.status_effect_script.status_effect_data
	var status_effect_object_id: String = status_effect_data.object_id
	status_effect.status_effect_script._disconnect_signals()
	
	# get status list
	var status_effects: Array[StatusEffect] = status_id_to_status_effects[status_effect_object_id]
	# remove from lists
	status_effects.erase(status_effect)
	
	if len(status_effects) == 0:
		# remove the status keys if no other effects of that type
		status_id_to_status_effects.erase(status_effect_object_id)	
		# unregister action interceptors
		for interceptor_id in status_effect_data.status_effect_interceptor_ids:
			ActionHandler.unregister_action_interceptor(self, interceptor_id)
	
	status_effect.queue_free()

func _create_status_effect(status_effect_object_id: String) -> StatusEffect:
	# creates a status on the combatant and creates bindings and back references for it
	# does not allow duplicate statuses that do not allow multiples
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	# check if existing status and if duplicates aren't allowed
	var status_exists: bool = len(status_id_to_status_effects.get(status_effect_object_id, [])) > 0
	if (not status_exists) or status_effect_data.status_effect_allows_multiples:
		# create the status
		var status_effect: StatusEffect = Scenes.STATUS_EFFECT.instantiate()
		var status_effect_script_asset: Resource = load(status_effect_data.status_effect_script_path)
		var status_effect_script: BaseStatusEffect = status_effect_script_asset.new()
		
		# set bindings for ui elements
		if status_id_to_status_effects.has(status_effect_object_id):
			status_id_to_status_effects[status_effect_object_id].append(status_effect)
		else:
			var statuses: Array[StatusEffect] = [status_effect] # ensures typed array passed in
			status_id_to_status_effects[status_effect_object_id] = statuses
		
		# initialize status effect
		status_effect.status_effect_script = status_effect_script
		status_container.add_child(status_effect)
		# initialize status effect script
		status_effect_script.init(status_effect_data, self)
		
		# register interceptors when creating first instance of effect
		if not status_exists:
			for interceptor_id in status_effect_data.status_effect_interceptor_ids:
				ActionHandler.register_action_interceptor(self, interceptor_id)
		
		return status_effect
	return null
#endregion

#region Turns/Combat

func _on_combat_started(_event_id: String):
	pass

func _on_combat_ended():
	pass

func _on_player_turn_started():
	pass

func _on_player_turn_ended():
	pass


## Processes and then decays all status effects belonging to a given process type (turn phase)
func perform_status_effect_actions(status_effect_process_time: int = StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.PRE_DRAW_PLAYER_START_TURN):
	var status_effect_ids: Array = _get_status_effects_with_process_time(status_id_to_status_effects.keys(), status_effect_process_time)
	
	# sort the statuses by their process priority
	status_effect_ids.sort_custom(_sort_status_effect_priorities)
	
	for status_effect_object_id in status_effect_ids:
		var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)	
		# perform the status effect
		var status_effects: Array[StatusEffect] = status_id_to_status_effects[status_effect_object_id]
		for status_effect in status_effects:
			status_effect.status_effect_script.current_process_time = status_effect_process_time
			status_effect.status_effect_script.perform_status_effect_actions()
		
		# NOTE: Uncommenting this will make status related code more stable by forcing
		# all actions to process before decaying, but
		# doesn't look as good as statuses decaying instantly.
		#if ActionHandler.actions_being_performed:
			#await ActionHandler.actions_ended
		
		# decay all status effects of given type
		if status_effect_data.status_effect_use_legacy_process_decay:
			_decay_status_effect(status_effect_object_id)


## Helper method. Gets all status effects with a given status_effect_process_time.
func _get_status_effects_with_process_time(status_effect_object_ids: Array, status_effect_process_time: int = StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.PRE_DRAW_PLAYER_START_TURN) -> Array[String]:
	var returned_status_effect_ids: Array[String] = []
	for status_effect_object_id: String in status_effect_object_ids:
		var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
		if status_effect_data == null:
			continue
		if not status_effect_data.status_effect_action_process_times.has(status_effect_process_time):
			continue
		returned_status_effect_ids.append(status_effect_object_id)
		
	return returned_status_effect_ids

## Helper method. Custom sort method for sorting the priorities of a given list of status effects.
## Used to ensure status effects fire in a consistent order.
func _sort_status_effect_priorities(status_effect_object_id_1: String, status_effect_object_id_2: String) -> bool:
	var status_effect_data_1: StatusEffectData = Global.get_status_effect_data(status_effect_object_id_1)
	var status_effect_data_2: StatusEffectData = Global.get_status_effect_data(status_effect_object_id_2)
	if status_effect_data_1.status_effect_priority == status_effect_data_2.status_effect_priority:
		return status_effect_data_1.object_id > status_effect_data_2.object_id
	else:
		return status_effect_data_1.status_effect_priority > status_effect_data_2.status_effect_priority


#endregion
