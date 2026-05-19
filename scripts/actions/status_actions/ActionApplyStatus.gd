extends BaseAction

func _get_editor_description() -> String:
	return "Applies status charges to targets, or forcibly creates a fresh status instance when requested."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()
	
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			return
		
		var status_charge_amount: int = action_interceptor_processor.get_shadowed_action_values("status_charge_amount", 1)
		var status_secondary_charge_amount: int = action_interceptor_processor.get_shadowed_action_values("status_secondary_charge_amount", 0)
		var status_effect_object_id: String = action_interceptor_processor.get_shadowed_action_values("status_effect_object_id", "")
		var status_force_apply_new_effect: int = action_interceptor_processor.get_shadowed_action_values("status_force_apply_new_effect", false)
		# determine whether to apply charges or to force the application of an entirely new status effect
		if status_force_apply_new_effect:
			target.add_new_status_effect(status_effect_object_id, status_charge_amount, status_secondary_charge_amount)
		else:
			target.add_status_effect_charges(status_effect_object_id, status_charge_amount, status_secondary_charge_amount)

func is_action_short_circuited() -> bool:
	return get_action_value("action_short_circuits", true)

func _to_string():
	var status_charge_amount: int = get_action_value("status_charge_amount", 0)
	var status_effect_object_id: String = get_action_value("status_effect_object_id", "")
	return "Apply Status Action: " + status_effect_object_id + " " + str(status_charge_amount)
