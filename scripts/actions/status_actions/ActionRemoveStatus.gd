extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.STATUS_CHARGE_AMOUNT, ActionValueRegistry.STATUS_EFFECT_OBJECT_ID]

func _get_editor_description() -> String:
	return "Removes a status from each resolved target. Negative charge amount removes the entire status."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			return
		var status_charge_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_CHARGE_AMOUNT, -1)
		var status_effect_object_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_EFFECT_OBJECT_ID, "")
		target.remove_status(status_effect_object_id, status_charge_amount)

func _to_string() -> String:
	return "Remove Status Action"
