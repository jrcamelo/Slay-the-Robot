# Shared side-wide barrier action.
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.BLOCK]

func _get_editor_description() -> String:
	return "Adds side-wide barrier; the shared amount reduces each damage instance to all living allies."

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	
	for action_interceptor_processor in action_interceptor_processors:
		var barrier_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.BLOCK, 0)
		if parent_combatant != null and parent_combatant.is_alive():
			parent_combatant.apply_status("status_effect_barrier", barrier_amount, parent_combatant)

func _to_string():
	var barrier_amount: int = get_action_value(ActionValueRegistry.BLOCK, 0)
	return "Barrier Action: " + str(barrier_amount)
