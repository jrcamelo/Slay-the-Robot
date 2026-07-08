# Generates a card a number of times; intended for cards that make other cards
# Functions like an ActionPickCards that generates the cards rather than have the user pick them
# Make sure to have child BaseCardSetAction(s) to actually do something such as add to hand
extends ActionPickCards

func _get_editor_relevant_value_names() -> Array[String]:
	var relevant_value_names: Array[String] = super()
	relevant_value_names.append_array([ActionValueRegistry.CREATED_CARD_OBJECT_ID, ActionValueRegistry.NUMBER_OF_CARDS])
	return relevant_value_names

func _get_editor_description() -> String:
	return "Generates fresh card instances instead of prompting the user, then passes them through the normal pick-card child action flow."

func perform_action():
	# overrides user card selection with generating cards
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor in action_interceptor_processors:
		var created_card_object_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CREATED_CARD_OBJECT_ID, "")
		var number_of_cards: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.NUMBER_OF_CARDS, 0)
		var created_cards: Array[CardData] = []
		if created_card_object_id != "":
			for i in number_of_cards:
				var card_data: CardData = Global.get_card_data_from_prototype(created_card_object_id)
				created_cards.append(card_data)
		_assign_generated_card_owners(created_cards)
		picked_cards.append_array(created_cards)
	
	# overwrite picked_cards action value with the generated cards, for child cardset actions
	# as this action doesn't require user input, "picked_cards" action value and picked_cards are the same
	values["picked_cards"] = picked_cards
	
	await Global.get_tree().process_frame # add a delay to allow ActionHandler to catch up with async to avoid infinite hang
	perform_async_action()
	
	# emit signals for each created card
	for card_data: CardData in picked_cards:
		Signals.card_created.emit(card_data)
