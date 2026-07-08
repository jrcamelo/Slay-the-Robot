# Base abstract class for shared interface of player and enemies
extends Control
class_name BaseCombatant

const STATUS_BARRIER: String = "status_effect_barrier"
const STATUS_CLOSED_CULTIVATION: String = "status_effect_character_passive_samurai_closed_cultivation"
const STATUS_DAMAGE_INCREASE: String = "status_effect_damage_increase"
const STATUS_MIGHT: String = "status_effect_might"
const STATUS_NEXT_ATTACK_DAMAGE_BONUS: String = "status_effect_next_attack_damage_bonus"
const STATUS_NEXT_ATTACK_DOUBLE_DAMAGE: String = "status_effect_next_attack_double_damage"
const STATUS_NEXT_JAB_DAMAGE_BONUS: String = "status_effect_next_jab_damage_bonus"
const STATUS_RANGER_KYR: String = "status_effect_character_passive_ranger_kyr"
const STATUS_SHIELD: String = "status_effect_shield"
const STATUS_BURN: String = "status_effect_burn"
const STATUS_POISON: String = "status_effect_poison"
const STATUS_SLEEP: String = "status_effect_sleep"
const STATUS_PARALYZE: String = "status_effect_paralyze"

const INTERCEPTOR_DAMAGE_INCREASE: String = "interceptor_damage_increase"
const INTERCEPTOR_NEXT_ATTACK_DAMAGE_BONUS: String = "interceptor_next_attack_damage_bonus"
const INTERCEPTOR_NEXT_ATTACK_DOUBLE_DAMAGE: String = "interceptor_next_attack_double_damage"
const INTERCEPTOR_NEXT_JAB_DAMAGE_BONUS: String = "interceptor_next_jab_damage_bonus"

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

func _is_shared_status(status_effect_object_id: String) -> bool:
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	return status_effect_data != null and status_effect_data.status_effect_is_party_shared

func get_living_allies() -> Array[BaseCombatant]:
	var allies: Array[BaseCombatant] = []
	if is_in_group("players"):
		allies.assign(Global.get_living_players())
	elif is_in_group("enemies"):
		allies.assign(Global.get_living_enemies())
	return allies

func get_shared_status_members(status_effect_object_id: String) -> Array[BaseCombatant]:
	if not _is_shared_status(status_effect_object_id):
		return [self]
	var living_allies: Array[BaseCombatant] = get_living_allies()
	if living_allies.is_empty():
		return [self]
	return living_allies

func get_shared_status_amount(status_effect_object_id: String) -> int:
	if not _is_shared_status(status_effect_object_id):
		return max(0, get_status_charges(status_effect_object_id))
	var authority: BaseCombatant = get_shared_status_authority(status_effect_object_id)
	return max(0, authority.get_status_charges(status_effect_object_id))

func get_shared_status_authority(status_effect_object_id: String) -> BaseCombatant:
	if not _is_shared_status(status_effect_object_id):
		return self
	return get_shared_status_members(status_effect_object_id)[0]

func _sync_shared_status_amount(status_effect_object_id: String, target_amount: int, secondary_amount: int = 0, custom_values: Dictionary = {}) -> void:
	for ally: BaseCombatant in get_shared_status_members(status_effect_object_id):
		var current_amount: int = max(0, ally.get_status_charges(status_effect_object_id))
		if target_amount <= 0:
			if current_amount > 0:
				ally._remove_status_local(status_effect_object_id, -1)
			continue
		if current_amount <= 0:
			ally._apply_status_internal(status_effect_object_id, target_amount, secondary_amount, false, custom_values, false)
			continue
		var amount_delta: int = target_amount - current_amount
		if amount_delta != 0 or secondary_amount != 0 or not custom_values.is_empty():
			ally._apply_status_internal(status_effect_object_id, amount_delta, secondary_amount, false, custom_values, false)

func is_shared_status_authority(status_effect_object_id: String) -> bool:
	return get_shared_status_authority(status_effect_object_id) == self

func apply_shared_status(status_effect_object_id: String, amount: int, source_combatant: BaseCombatant = null, secondary_amount: int = 0, custom_values: Dictionary = {}) -> void:
	var authority: BaseCombatant = get_shared_status_authority(status_effect_object_id)
	if authority != self:
		authority.apply_shared_status(status_effect_object_id, amount, source_combatant, secondary_amount, custom_values)
		return
	var shared_amount: int = get_shared_status_amount(status_effect_object_id)
	_sync_shared_status_amount(status_effect_object_id, max(0, shared_amount + amount), secondary_amount, custom_values)
	if source_combatant != null:
		for ally: BaseCombatant in get_shared_status_members(status_effect_object_id):
			ally._set_status_source(status_effect_object_id, source_combatant)

func remove_shared_status(status_effect_object_id: String, amount: int = -1) -> void:
	var authority: BaseCombatant = get_shared_status_authority(status_effect_object_id)
	if authority != self:
		authority.remove_shared_status(status_effect_object_id, amount)
		return
	var shared_amount: int = get_shared_status_amount(status_effect_object_id)
	if amount < 0:
		_sync_shared_status_amount(status_effect_object_id, 0)
	else:
		_sync_shared_status_amount(status_effect_object_id, max(0, shared_amount - amount))

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
func damage(_damage: int, _bypass_block: bool = false, _source_action: BaseAction = null) -> Array[int]:
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
	if _is_shared_status(status_effect_object_id):
		apply_shared_status(status_effect_object_id, amount, source_combatant, secondary_amount, custom_values)
		return
	_apply_status_internal(status_effect_object_id, amount, secondary_amount, force_new_effect, custom_values)
	if source_combatant != null:
		_set_status_source(status_effect_object_id, source_combatant)

func remove_status(status_effect_object_id: String, amount: int = -1) -> void:
	if _is_shared_status(status_effect_object_id):
		remove_shared_status(status_effect_object_id, amount)
		return
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
	if _is_shared_status(status_effect_object_id):
		apply_shared_status(status_effect_object_id, charge_amount, null, secondary_charge_amount)
		return
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
	Signals.combatant_status_changed.emit(self, status_effect_object_id)

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

func get_status_effects(status_effect_object_id: String) -> Array[StatusEffect]:
	return status_id_to_status_effects.get(status_effect_object_id, [])

func has_closed_cultivation_passive() -> bool:
	return get_status_charges(STATUS_CLOSED_CULTIVATION) > 0

func get_outgoing_damage_after_passive_filters(action_interceptor_processor: ActionInterceptorProcessor) -> int:
	var damage: int = int(action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.DAMAGE, 0))
	if not has_closed_cultivation_passive():
		return damage
	var filtered_damage: int = int(_get_parent_action_value(action_interceptor_processor, ActionValueRegistry.DAMAGE, damage))
	for damage_entry: Dictionary in action_interceptor_processor.damage_history:
		if not _should_apply_closed_cultivation_damage_entry(damage_entry):
			continue
		filtered_damage = _apply_closed_cultivation_damage_entry(filtered_damage, damage_entry)
	return max(0, filtered_damage)

func _get_parent_action_value(action_interceptor_processor: ActionInterceptorProcessor, key: String, default_value: Variant) -> Variant:
	if action_interceptor_processor == null or action_interceptor_processor.parent_action == null:
		return default_value
	return action_interceptor_processor.parent_action.get_action_value(key, default_value)

func _should_apply_closed_cultivation_damage_entry(damage_entry: Dictionary) -> bool:
	if not bool(damage_entry.get("modifies_parent", true)):
		return true
	var previous_damage: int = int(damage_entry.get("previous_damage", 0))
	var current_damage: int = int(damage_entry.get("damage", previous_damage))
	if current_damage <= previous_damage:
		return true
	var action_interceptor_data: ActionInterceptorData = damage_entry.get("action_interceptor_data", null) as ActionInterceptorData
	if action_interceptor_data == null:
		return false
	return action_interceptor_data.action_interceptor_closed_cultivation_allow_self_benefit

func _apply_closed_cultivation_damage_entry(current_damage: int, damage_entry: Dictionary) -> int:
	var action_interceptor_object_id: String = damage_entry.get("action_interceptor_object_id", "")
	if bool(damage_entry.get("modifies_parent", true)):
		match action_interceptor_object_id:
			INTERCEPTOR_DAMAGE_INCREASE:
				return current_damage + _get_self_sourced_positive_status_charges(STATUS_MIGHT, STATUS_DAMAGE_INCREASE)
			INTERCEPTOR_NEXT_ATTACK_DAMAGE_BONUS:
				return current_damage + _get_self_sourced_status_secondary_charges(STATUS_NEXT_ATTACK_DAMAGE_BONUS)
			INTERCEPTOR_NEXT_ATTACK_DOUBLE_DAMAGE:
				if _has_self_sourced_status_effect(STATUS_NEXT_ATTACK_DOUBLE_DAMAGE):
					return current_damage * 2
				return current_damage
			INTERCEPTOR_NEXT_JAB_DAMAGE_BONUS:
				return current_damage + _get_self_sourced_status_secondary_charges(STATUS_NEXT_JAB_DAMAGE_BONUS)
			_:
				return current_damage
	var operation_type: String = damage_entry.get("operation_type", "unknown")
	var operation_data: Dictionary = damage_entry.get("operation_data", {})
	match operation_type:
		"add":
			return max(0, current_damage + int(operation_data.get("amount", 0)))
		"multiply":
			return max(0, int(round(current_damage * float(operation_data.get("multiplier", 1.0)))))
		"set", "unknown":
			return max(0, int(damage_entry.get("damage", current_damage)))
	return max(0, int(damage_entry.get("damage", current_damage)))

func _get_self_sourced_positive_status_charges(primary_status_effect_id: String, legacy_status_effect_id: String = "") -> int:
	var primary_amount: int = _get_self_sourced_status_charges(primary_status_effect_id)
	if primary_amount > 0 or legacy_status_effect_id == "":
		return primary_amount
	return _get_self_sourced_status_charges(legacy_status_effect_id)

func _get_self_sourced_status_charges(status_effect_object_id: String) -> int:
	var total_amount: int = 0
	for status_effect: StatusEffect in get_status_effects(status_effect_object_id):
		if status_effect == null or status_effect.status_effect_script == null:
			continue
		var amount: int = max(0, status_effect.status_effect_script.status_charges)
		if amount <= 0:
			continue
		if _is_status_effect_self_sourced(status_effect):
			total_amount += amount
	return total_amount

func _get_self_sourced_status_secondary_charges(status_effect_object_id: String) -> int:
	var maximum_secondary_amount: int = 0
	for status_effect: StatusEffect in get_status_effects(status_effect_object_id):
		if status_effect == null or status_effect.status_effect_script == null:
			continue
		if status_effect.status_effect_script.status_charges <= 0:
			continue
		if not _is_status_effect_self_sourced(status_effect):
			continue
		maximum_secondary_amount = max(maximum_secondary_amount, max(0, status_effect.status_effect_script.status_secondary_charges))
	return maximum_secondary_amount

func _has_self_sourced_status_effect(status_effect_object_id: String) -> bool:
	for status_effect: StatusEffect in get_status_effects(status_effect_object_id):
		if status_effect == null or status_effect.status_effect_script == null:
			continue
		if status_effect.status_effect_script.status_charges <= 0:
			continue
		if _is_status_effect_self_sourced(status_effect):
			return true
	return false

func get_ranger_kyr_status() -> StatusEffect:
	var status_effects: Array[StatusEffect] = get_status_effects(STATUS_RANGER_KYR)
	if status_effects.is_empty():
		return null
	return status_effects[0]

func get_ranger_kyr_health() -> int:
	var status_effect: StatusEffect = get_ranger_kyr_status()
	if status_effect == null or status_effect.status_effect_script == null:
		return 0
	return max(0, status_effect.status_effect_script.status_secondary_charges)

func get_ranger_kyr_health_max() -> int:
	var status_effect: StatusEffect = get_ranger_kyr_status()
	if status_effect == null or status_effect.status_effect_script == null:
		return 10
	if status_effect.status_effect_script.has_method("get_companion_health_max"):
		return int(status_effect.status_effect_script.call("get_companion_health_max"))
	return 10

func has_active_ranger_kyr() -> bool:
	return get_ranger_kyr_health() > 0

func add_ranger_kyr_health(health_amount: int) -> int:
	var status_effect: StatusEffect = get_ranger_kyr_status()
	if status_effect == null or status_effect.status_effect_script == null:
		return 0
	var old_health: int = max(0, status_effect.status_effect_script.status_secondary_charges)
	var new_health: int = clamp(old_health + health_amount, 0, get_ranger_kyr_health_max())
	var health_delta: int = new_health - old_health
	if health_delta == 0:
		return 0
	status_effect.status_effect_script.status_secondary_charges = new_health
	status_effect.update_status_charge_display()
	update_health_bar(false)
	Signals.combatant_status_changed.emit(self, STATUS_RANGER_KYR)
	if self is Player:
		Signals.player_health_changed.emit()
	else:
		Signals.enemy_intent_changed.emit()
	return health_delta

func _is_status_effect_self_sourced(status_effect: StatusEffect) -> bool:
	if status_effect == null or status_effect.status_effect_script == null:
		return true
	var custom_values: Dictionary = status_effect.status_effect_script.status_custom_values
	var source_instance_id: int = int(custom_values.get("source_instance_id", -1))
	if source_instance_id == get_instance_id():
		return true
	if self is Player:
		var source_party_member_index: int = int(custom_values.get("source_party_member_index", -1))
		return source_party_member_index == get_party_member_index()
	return source_instance_id < 0

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
	Signals.combatant_status_changed.emit(self, status_effect_object_id)

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
		var status_effect_script_asset: Script = status_effect_data.status_effect_script
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

func perform_combat_started_status_effect_actions(status_effect_object_ids: Array = []) -> void:
	if status_effect_object_ids.is_empty():
		status_effect_object_ids = status_id_to_status_effects.keys()
	var sorted_status_effect_ids: Array[String] = []
	for status_effect_object_id: String in status_effect_object_ids:
		if status_id_to_status_effects.has(status_effect_object_id):
			sorted_status_effect_ids.append(status_effect_object_id)
	sorted_status_effect_ids.sort_custom(_sort_status_effect_priorities)
	for status_effect_object_id: String in sorted_status_effect_ids:
		var status_effects: Array[StatusEffect] = status_id_to_status_effects.get(status_effect_object_id, [])
		for status_effect: StatusEffect in status_effects:
			status_effect.status_effect_script.perform_combat_started_actions()


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
