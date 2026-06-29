extends ActionPickCards

func _get_editor_relevant_value_names() -> Array[String]:
	var relevant_value_names: Array[String] = super()
	relevant_value_names.append_array([ActionValueRegistry.CREATED_CARD_OBJECT_ID, "count_value_name", "count_multiplier"])
	return relevant_value_names

func _get_editor_description() -> String:
	return "Creates cards using a count read from the current card play values, then runs child cardset actions."

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor in action_interceptor_processors:
		var created_card_object_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CREATED_CARD_OBJECT_ID, "")
		var count_value_name: String = action_interceptor_processor.get_shadowed_action_values("count_value_name", "created_card_count")
		var count_multiplier: int = action_interceptor_processor.get_shadowed_action_values("count_multiplier", 1)
		var count_value: int = int(get_action_value(count_value_name, 0))
		if count_value_name == "picked_card_count" and parent_action is ActionBasePickCards:
			count_value = (parent_action as ActionBasePickCards).picked_cards.size()
		var number_of_cards: int = max(0, count_value * count_multiplier)
		if created_card_object_id == "":
			continue
		for _i in number_of_cards:
			var card_data: CardData = Global.get_card_data_from_prototype(created_card_object_id)
			if Global.player_data.has_party_members():
				if card_play_request != null and card_play_request.card_data != null:
					var source_party_member: PartyMemberData = Global.player_data.get_party_member_for_card(card_play_request.card_data)
					if source_party_member != null:
						Global.player_data.assign_card_owner(card_data, source_party_member.party_member_party_index)
					else:
						Global.player_data.ensure_card_has_owner(card_data)
				else:
					Global.player_data.ensure_card_has_owner(card_data)
			picked_cards.append(card_data)
	values["picked_cards"] = picked_cards
	await Global.get_tree().process_frame
	perform_async_action()
	for card_data: CardData in picked_cards:
		Signals.card_created.emit(card_data)
