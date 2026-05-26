## A simplified interceptable clone of ActionApplyStatus that's intended for use in BaseCombatant._decay_status_effect()
## Used as an instant intercepted action and not put onto the ActionHandler stack.
## To intercept, extend InterceptorBaseNegateStatusDecay and provide a check for status_object_id.
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.STATUS_CHARGE_AMOUNT, ActionValueRegistry.STATUS_EFFECT_OBJECT_ID]

func _get_editor_description() -> String:
	return "Applies negative status charges to decay an existing status effect in an interceptable way."

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
		
		var status_charge_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_CHARGE_AMOUNT, 1)
		var status_effect_object_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_EFFECT_OBJECT_ID, "")
		target.add_status_effect_charges(status_effect_object_id, status_charge_amount, 0)

func is_instant_action() -> bool:
	return true

func is_action_short_circuited() -> bool:
	return get_action_value("action_short_circuits", true)

func _to_string():
	var status_charge_amount: int = get_action_value(ActionValueRegistry.STATUS_CHARGE_AMOUNT, 0)
	var status_effect_object_id: String = get_action_value(ActionValueRegistry.STATUS_EFFECT_OBJECT_ID, "")
	return "Decay Status Action: " + status_effect_object_id + " " + str(status_charge_amount)
