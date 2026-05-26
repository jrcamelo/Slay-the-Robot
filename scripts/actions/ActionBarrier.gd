# Shared party-wide block action.
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.BLOCK]

func _get_editor_description() -> String:
	return "Adds shared barrier block to the party-wide barrier pool."

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	
	for action_interceptor_processor in action_interceptor_processors:
		var barrier_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.BLOCK, 0)
		Global.player_data.add_barrier(barrier_amount)

func _to_string():
	var barrier_amount: int = get_action_value(ActionValueRegistry.BLOCK, 0)
	return "Barrier Action: " + str(barrier_amount)
