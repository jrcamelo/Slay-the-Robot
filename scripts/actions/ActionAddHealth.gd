# adds health and max health to the player
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.HEALTH_AMOUNT, ActionValueRegistry.HEALTH_MAX_AMOUNT]

func _get_editor_description() -> String:
	return "Heals the relevant player or party member and can also increase max health."

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	var party_member_data: PartyMemberData = null
	if Global.player_data.has_party_members():
		if parent_combatant is Player:
			party_member_data = parent_combatant.get_party_member_data()
		if party_member_data == null and card_play_request != null and card_play_request.card_data != null:
			party_member_data = Global.player_data.get_party_member_for_card(card_play_request.card_data)
	# TODO: Generalize health actions to target specific allies once ally-targeting UI exists.
	
	for action_interceptor_processor in action_interceptor_processors:
		var health_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.HEALTH_AMOUNT, 0)
		var health_max_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.HEALTH_MAX_AMOUNT, 0)
		if party_member_data != null:
			party_member_data.add_health(health_amount, health_max_amount)
			if party_member_data.party_member_party_index == 0:
				Global.player_data.synchronize_legacy_primary_member_state()
			Signals.player_health_changed.emit()
		else:
			Global.player_data.add_health(health_amount, health_max_amount)
	

func _to_string():
	var health_amount: int = get_action_value(ActionValueRegistry.HEALTH_AMOUNT, 0)
	var health_max_amount: int = get_action_value(ActionValueRegistry.HEALTH_MAX_AMOUNT, 0)
	return "Add Health Action: %s %s" % [health_amount, health_max_amount]
