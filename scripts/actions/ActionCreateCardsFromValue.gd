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
		var created_cards: Array[CardData] = []
		for _i in number_of_cards:
			var card_data: CardData = Global.get_card_data_from_prototype(created_card_object_id)
			created_cards.append(card_data)
		_assign_generated_card_owners(created_cards)
		picked_cards.append_array(created_cards)
	values["picked_cards"] = picked_cards
	await Global.get_tree().process_frame
	perform_async_action()
	for card_data: CardData in picked_cards:
		Signals.card_created.emit(card_data)
