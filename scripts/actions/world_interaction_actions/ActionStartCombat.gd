## Starts/Forces combat in a given event id.
## If event_object_id is empty, uses the current location's event.
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.EVENT_OBJECT_ID]

func _get_editor_description() -> String:
	return "Starts combat for a specific event id or the current location's event."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_WORLD_ACTIONS,
		EDITOR_CONTEXT_RUN_ACTIONS,
	]

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor in action_interceptor_processors:
		var event_object_id: String = get_action_value(ActionValueRegistry.EVENT_OBJECT_ID, "")
		
		# simulate combat starting for the given event
		Signals.combat_started.emit(event_object_id)
