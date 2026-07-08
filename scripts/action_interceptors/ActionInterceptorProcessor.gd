## Utility object for processing a chain of interceptors, see: BaseAction.intercept_action().
## Iterates over all interceptors of a given action-parent-target pairing, in order of interceptor priority
## defined by ActionInterceptorData.action_interceptor_priority.
## After the chain is finished, shadowed_action_values will be populated with modified values
## and the processor ultimately accepted/rejected.
## A rejected processsor will be discarded in the final returned result.
extends Node
class_name ActionInterceptorProcessor

var parent_action: BaseAction = null	# the action tied to this processor
var target: BaseCombatant = null	# the sub target to use for interception processing. Can be null

var shadowed_action_values: Dictionary = {}	# this will contain any modified values for the parent action after processing has taken place. Use get_shadowed_action_values()
var damage_history: Array[Dictionary] = []
var _current_action_interceptor_data: ActionInterceptorData = null
var _current_action_interceptor_object_id: String = ""

func _init(_parent_action: BaseAction, _target: BaseCombatant):
	parent_action = _parent_action
	target = _target

## Called via BaseAction.intercept_action().
## iterates over all interceptors, returning if the chain was accepted or rejected for further processing the action
## preview_mode flag is used for things like displaying cards in hand after modifiers or hovering cards over enemies. This tells interceptors to not create actual side effects
func process_interceptor_chain(preview_mode: bool = false) -> bool:
	var action_interceptor_data_list: Array[ActionInterceptorData] = _get_action_interceptors_modifying_pair(parent_action, parent_action.parent_combatant, target)
	for action_interceptor_data: ActionInterceptorData in action_interceptor_data_list:
		var action_interceptor: BaseActionInterceptor = action_interceptor_data.action_interceptor_script.new()
		var previous_damage: int = int(get_shadowed_action_values(ActionValueRegistry.DAMAGE, 0))
		var previous_damage_history_count: int = damage_history.size()
		_current_action_interceptor_data = action_interceptor_data
		_current_action_interceptor_object_id = action_interceptor_data.object_id
		var result: int = action_interceptor.process_action_interception(self, preview_mode)
		_current_action_interceptor_data = null
		_current_action_interceptor_object_id = ""
		var current_damage: int = int(get_shadowed_action_values(ActionValueRegistry.DAMAGE, 0))
		if current_damage != previous_damage and damage_history.size() == previous_damage_history_count:
			_record_damage_history("unknown", {}, previous_damage, current_damage)
		if result == BaseActionInterceptor.ACTION_ACCEPTENCES.STOPPED:
			break
		if result == BaseActionInterceptor.ACTION_ACCEPTENCES.REJECTED:
			return false
	
	return true

## Used by both interceptors during processing, then by the action after processing has taken place.
## this will shadow the parent action's values, allowing for interceptors to "modify" an action's
## values without actually changing them by standing above them in the action value hierarchy.
## First getting the original value, then shadowing with a value that will be continually modified.
func get_shadowed_action_values(key: String, default_value: Variant) -> Variant:
	var custom_action_value_keys: Dictionary = parent_action.values.get("custom_key_names", {})	# allows for having cards/actions use custom key names that convert to regular action key names. Useful for having cards with 2 of the same action but different values
	var key_name: String = custom_action_value_keys.get(key, key)
	if shadowed_action_values.has(key_name):
		return shadowed_action_values[key_name]
	else:
		return parent_action.get_action_value(key, default_value)

func add_damage(delta: int) -> void:
	var current_damage: int = int(get_shadowed_action_values(ActionValueRegistry.DAMAGE, 0))
	set_damage(current_damage + delta, "add", {"amount": delta})

func multiply_damage(multiplier: float) -> void:
	var current_damage: int = int(get_shadowed_action_values(ActionValueRegistry.DAMAGE, 0))
	set_damage(int(round(current_damage * multiplier)), "multiply", {"multiplier": multiplier})

func set_damage(new_damage: int, operation_type: String = "set", operation_data: Dictionary = {}) -> void:
	var previous_damage: int = int(get_shadowed_action_values(ActionValueRegistry.DAMAGE, 0))
	var clamped_damage: int = max(0, new_damage)
	shadowed_action_values[ActionValueRegistry.DAMAGE] = clamped_damage
	if previous_damage != clamped_damage:
		_record_damage_history(operation_type, operation_data, previous_damage, clamped_damage)

func _record_damage_history(operation_type: String, operation_data: Dictionary, previous_damage: int, current_damage: int) -> void:
	damage_history.append({
		"action_interceptor_data": _current_action_interceptor_data,
		"action_interceptor_object_id": _current_action_interceptor_object_id,
		"modifies_parent": _current_action_interceptor_data != null and _current_action_interceptor_data.action_interceptor_modifies_parent,
		"operation_type": operation_type,
		"operation_data": operation_data.duplicate(),
		"previous_damage": previous_damage,
		"damage": current_damage,
	})

## Returns a priority-sorted array of all interceptors involving an action, its parent, and its target.
## Both parent and target can be the same, and one or both can be null.
## Additional flags ignore_all_interceptors, ignored_interceptor_ids, and forced_interceptor_ids can
## be provided through the action's values to alter which interceptors are allowed to be populated.
func _get_action_interceptors_modifying_pair(action: BaseAction, parent_combatant: BaseCombatant, target_combatant: BaseCombatant) -> Array[ActionInterceptorData]:
	var interceptor_data_list: Array[ActionInterceptorData] = [] # used to sort by priority before creating returned interceptors
	
	### Get interceptor flags from action data
	# Use ignore_all_interceptors = true for actions which should always be performed unmodified
	var ignore_all_interceptors: bool = get_shadowed_action_values("ignore_all_interceptors", false)
	if ignore_all_interceptors:
		return []
	
	# InterceptorData IDs for specific interceptors to not use for this action.
	var ignored_interceptor_ids: Array[String] = []
	ignored_interceptor_ids.assign(get_shadowed_action_values("ignored_interceptor_ids", []))
	
	# InterceptorData IDs for specific interceptors to always use for this action.
	var forced_interceptor_ids: Array[String] = []
	forced_interceptor_ids.assign(get_shadowed_action_values("forced_interceptor_ids", []))
	
	### Parent Interceptors
	# get ids of all interceptors the parent has
	var parent_action_interceptor_object_ids: Array[String] = []
	parent_action_interceptor_object_ids.assign(ActionHandler._registered_action_interceptor_object_ids.get(parent_combatant, []))
	
	# get data objects of all corresponding interceptors affecting the parent
	for action_interceptor_object_id in parent_action_interceptor_object_ids:
		var action_interceptor_data: ActionInterceptorData = Global.get_action_interceptor_data(action_interceptor_object_id)
		# filter ignored interceptors
		if ignored_interceptor_ids.has(action_interceptor_object_id):
			continue
		# must modifiy parent
		if action_interceptor_data.action_interceptor_modifies_parent:
			# must modifiy this action
			var action_script_path: String = action.get_script().resource_path
			if action_interceptor_data.action_intercepted_action_paths.has(action_script_path):
				interceptor_data_list.append(action_interceptor_data)
				forced_interceptor_ids.erase(action_interceptor_object_id)
	
	### Target Interceptors
	# get ids of all interceptors the target has
	var target_action_interceptor_object_ids: Array[String] = []
	target_action_interceptor_object_ids.assign(ActionHandler._registered_action_interceptor_object_ids.get(target_combatant, []))
	
	# get data objects of all corresponding affecting the target
	for action_interceptor_object_id in target_action_interceptor_object_ids:
		var action_interceptor_data: ActionInterceptorData = Global.get_action_interceptor_data(action_interceptor_object_id)
		# filter ignored interceptors
		if ignored_interceptor_ids.has(action_interceptor_object_id):
			continue
		
		# must modifiy target
		if not action_interceptor_data.action_interceptor_modifies_parent:
			# must modifiy this action
			var action_script_path: String = action.get_script().resource_path
			if action_interceptor_data.action_intercepted_action_paths.has(action_script_path):
				interceptor_data_list.append(action_interceptor_data)
				forced_interceptor_ids.erase(action_interceptor_object_id)
	
	### Forced Interceptors
	# apply forced parent interceptors from action data
	for forced_interceptor_id: String in forced_interceptor_ids:
		if parent_action_interceptor_object_ids.has(forced_interceptor_id):
			continue # ignore duplicates
		if target_action_interceptor_object_ids.has(forced_interceptor_id):
			continue # ignore duplicates
		var action_interceptor_data: ActionInterceptorData = Global.get_action_interceptor_data(forced_interceptor_id)
		interceptor_data_list.append(action_interceptor_data)
	
	### Return
	# sort interceptor data by their priority
	interceptor_data_list.sort_custom(_sort_action_interceptor_priorities)
	return interceptor_data_list

func _sort_action_interceptor_priorities(action_interceptor_data_1: ActionInterceptorData, action_interceptor_data_2: ActionInterceptorData) -> bool:
	# custom sort method for sorting the priorities of a given list of interceptors
	if action_interceptor_data_1.action_interceptor_priority == action_interceptor_data_2.action_interceptor_priority:
		return action_interceptor_data_1.object_id > action_interceptor_data_2.object_id
	else:
		return action_interceptor_data_1.action_interceptor_priority > action_interceptor_data_2.action_interceptor_priority
