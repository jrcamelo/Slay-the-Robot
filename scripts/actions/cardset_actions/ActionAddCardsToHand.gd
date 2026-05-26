## Action to add cards to your hand.
## Intercept hand_card_count_max to change hand size
extends BaseCardsetAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.HAND_CARD_COUNT_MAX, ActionValueRegistry.PICK_PLAYED_CARD]

func _get_editor_description() -> String:
	return "Adds selected cards into the hand, respecting the hand size limit."

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor in action_interceptor_processors:
		var hand_card_count_max: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.HAND_CARD_COUNT_MAX, PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
	
		var picked_cards: Array[CardData] = _get_picked_cards()
		if Global.player_data.has_party_members():
			for card_data: CardData in picked_cards:
				_assign_cardset_owner(card_data)
		Signals.card_add_to_hand_requested.emit(picked_cards, hand_card_count_max)
