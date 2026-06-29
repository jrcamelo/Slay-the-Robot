extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.STATUS_EFFECT_OBJECT_ID, ActionValueRegistry.STATUS_CHARGE_AMOUNT]

func _get_editor_description() -> String:
	return "Consumes status charges, writes derived values into the current card play, and can clear the status."

func perform_action() -> void:
	var resolved_targets: Array[BaseCombatant] = get_adjusted_action_targets()
	if resolved_targets.is_empty() and parent_combatant != null:
		resolved_targets = [parent_combatant]

	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(resolved_targets)
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			continue
		var status_effect_object_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_EFFECT_OBJECT_ID, "")
		if status_effect_object_id == "":
			continue
		var current_charges: int = max(0, target.get_status_charges(status_effect_object_id))
		var spend_all: bool = action_interceptor_processor.get_shadowed_action_values("spend_all", true)
		var requested_amount: int = max(0, action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STATUS_CHARGE_AMOUNT, current_charges))
		var spent_charges: int = current_charges if spend_all else min(current_charges, requested_amount)
		var value_per_status_charge: int = action_interceptor_processor.get_shadowed_action_values("value_per_status_charge", 1)
		var written_value: int = spent_charges * value_per_status_charge
		var write_value_names: Array[String] = []
		write_value_names.assign(action_interceptor_processor.get_shadowed_action_values("write_value_names", []))
		if card_play_request != null:
			for value_name: String in write_value_names:
				card_play_request.card_values[value_name] = written_value
			var spent_value_name: String = str(action_interceptor_processor.get_shadowed_action_values("write_spent_charges_value_name", "")).strip_edges()
			if spent_value_name != "":
				card_play_request.card_values[spent_value_name] = spent_charges
		if spent_charges > 0:
			target.remove_status(status_effect_object_id, spent_charges)

func _to_string() -> String:
	return "Spend Status Action"
