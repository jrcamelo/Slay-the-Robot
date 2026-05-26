extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.SHUFFLE_DISCARD_INTO_DRAW]

func _get_editor_description() -> String:
	return "Reshuffles the player's draw/discard piles, optionally merging discard back into draw."

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	
	for action_interceptor_processor in action_interceptor_processors:
		var shuffle_discard_into_draw: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.SHUFFLE_DISCARD_INTO_DRAW, true)
		Signals.reshuffle_requested.emit(shuffle_discard_into_draw)

func _to_string():
	return "Reshuffle Action"
