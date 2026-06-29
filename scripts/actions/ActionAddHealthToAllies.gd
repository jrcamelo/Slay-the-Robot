extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.HEALTH_AMOUNT, ActionValueRegistry.HEALTH_MAX_AMOUNT]

func _get_editor_description() -> String:
	return "Heals every living player ally."

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor in action_interceptor_processors:
		var health_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.HEALTH_AMOUNT, 0)
		var health_max_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.HEALTH_MAX_AMOUNT, 0)
		for player: Player in Global.get_living_players():
			var party_member_data: PartyMemberData = player.get_party_member_data()
			if party_member_data != null:
				party_member_data.add_health(health_amount, health_max_amount)
				if party_member_data.party_member_party_index == 0:
					Global.player_data.synchronize_legacy_primary_member_state()
			else:
				Global.player_data.add_health(health_amount, health_max_amount)
		Signals.player_health_changed.emit()
