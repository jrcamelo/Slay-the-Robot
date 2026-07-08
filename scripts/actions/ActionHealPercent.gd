# Heals the player by a percentage
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.PERCENTAGE_HEAL_AMOUNT]

func _get_editor_description() -> String:
	return "Heals the relevant player or party member by a percentage of max health."

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	var party_member_data: PartyMemberData = null
	if Global.player_data.has_party_members():
		if parent_combatant is Player:
			party_member_data = parent_combatant.get_party_member_data()
		if party_member_data == null and card_play_request != null and card_play_request.card_data != null:
			party_member_data = Global.player_data.get_party_member_for_card(card_play_request.card_data)
	# TODO: Generalize percentage healing to target specific allies once ally-targeting UI exists.
	
	for action_interceptor_processor in action_interceptor_processors:
		var percentage_heal_amount: float = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.PERCENTAGE_HEAL_AMOUNT, 1.0)
		if party_member_data != null:
			var player: Player = Global.get_player_by_party_index(party_member_data.party_member_party_index)
			if player != null:
				var percentage_health: int = int(ceil(float(player.get_health_max()) * percentage_heal_amount))
				player.add_health(percentage_health, 0)
			else:
				var percentage_health: int = int(ceil(float(party_member_data.party_member_health_max) * percentage_heal_amount))
				party_member_data.add_health(percentage_health, 0)
				if party_member_data.party_member_party_index == 0:
					Global.player_data.synchronize_legacy_primary_member_state()
				Signals.player_health_changed.emit()
		else:
			var default_player: Player = Global.get_default_player_combatant(false)
			if default_player != null:
				var percentage_health: int = int(ceil(float(default_player.get_health_max()) * percentage_heal_amount))
				default_player.add_health(percentage_health, 0)
			else:
				Global.player_data.heal_percentage(percentage_heal_amount)
	

func _to_string():
	var percentage_heal_amount: float = get_action_value(ActionValueRegistry.PERCENTAGE_HEAL_AMOUNT, 1.0)
	return "Percent Heal Action %s%" % (percentage_heal_amount * 100)
