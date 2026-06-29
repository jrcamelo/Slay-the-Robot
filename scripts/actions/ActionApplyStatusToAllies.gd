extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.STATUS_EFFECT_OBJECT_ID, ActionValueRegistry.STATUS_CHARGE_AMOUNT]

func _get_editor_description() -> String:
	return "Applies a status to every living player ally."

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor in action_interceptor_processors:
		var status_effect_object_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_EFFECT_OBJECT_ID, "")
		var status_charge_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_CHARGE_AMOUNT, 1)
		var status_secondary_charge_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_SECONDARY_CHARGE_AMOUNT, 0)
		if status_effect_object_id == "":
			continue
		for player: Player in Global.get_living_players():
			player.apply_status(status_effect_object_id, status_charge_amount, parent_combatant, status_secondary_charge_amount)
