# Registers/unregisters a custom ui element with a target
extends BaseAction

func _get_editor_description() -> String:
	return "Registers or unregisters a custom UI element on the resolved target."

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
		var enable_custom_ui: bool = action_interceptor_processor.get_shadowed_action_values("enable_custom_ui", true)	# true to enable, false to disable
		var custom_ui_object_id: String = action_interceptor_processor.get_shadowed_action_values("custom_ui_object_id", true)
		var target: BaseCombatant = action_interceptor_processor.target
		if target != null:
			if enable_custom_ui:
				target.register_custom_ui(custom_ui_object_id)
			else:
				target.unregister_custom_ui(custom_ui_object_id)

func _to_string():
	return "Custom UI Action"
