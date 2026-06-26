extends BaseAction

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()
	
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			return
		
		var status_charge_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_CHARGE_AMOUNT, 1)
		var status_secondary_charge_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_SECONDARY_CHARGE_AMOUNT, 0)
		var status_effect_object_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_EFFECT_OBJECT_ID, "")
		var status_force_apply_new_effect: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_FORCE_APPLY_NEW_EFFECT, false)
		target.apply_status(status_effect_object_id, status_charge_amount, parent_combatant, status_secondary_charge_amount, status_force_apply_new_effect)

func is_action_short_circuited() -> bool:
	return get_action_value("action_short_circuits", true)

func _to_string():
	var status_charge_amount: int = get_action_value("status_charge_amount", 0)
	var status_effect_object_id: String = get_action_value("status_effect_object_id", "")
	return "Apply Status Action: " + status_effect_object_id + " " + str(status_charge_amount)
