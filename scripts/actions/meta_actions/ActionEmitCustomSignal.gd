## Takes a CustomSignal defined by custom_signal_object_id and emits it with a given custom_signal_value value
## Typically you'll combine this with an action modifier such as ActionVariableCardsetModifier or
## ActionVariableCostModifier etc
## modifying the ActionValueRegistry.CUSTOM_SIGNAL_VALUE action value.
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.CUSTOM_SIGNAL_OBJECT_ID, ActionValueRegistry.CUSTOM_SIGNAL_VALUE]

func _get_editor_description() -> String:
	return "Emits a custom signal defined in content, optionally with a numeric payload."

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	
	for action_interceptor_processor in action_interceptor_processors:
		var custom_signal_object_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CUSTOM_SIGNAL_OBJECT_ID, "")
		if custom_signal_object_id == "":
			DebugLogger.log_error("No signal object id defined")
		else:
			# get the intercepted action value you'd like to attach to the signal
			var custom_signal_value: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CUSTOM_SIGNAL_VALUE, 0)
			var custom_signal_values: Dictionary[String, Variant] = {
				"value_amount": custom_signal_value
			}
			Signals.emit_custom_signal(custom_signal_object_id, custom_signal_values)

func _to_string():
	return "Emit Custom Signal Action"
