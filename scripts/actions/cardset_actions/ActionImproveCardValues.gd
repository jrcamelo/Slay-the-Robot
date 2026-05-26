# Improves cards' values by a given amount
# This can target a list of cards, or their parent cards (making it permanent if in player's deck)
# See ActionChangeCardProperties for setter version
extends BaseCardsetAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.IMPROVE_PARENT_CARD, ActionValueRegistry.PICK_PLAYED_CARD]

func _get_editor_description() -> String:
	return "Improves entries in card_values for the selected cards, optionally on their parent deck copies."

func perform_action():
	var improve_parent_card: bool = get_action_value(ActionValueRegistry.IMPROVE_PARENT_CARD, true)
	var picked_cards: Array[CardData] = _get_picked_cards()
	
	# iterate over the cards, improving them and/or their parent
	for card_data in picked_cards:
		# get parent card if improving that
		var parent_card_data: CardData = null
		if improve_parent_card:
			if card_data.parent_card == null:
				push_error("No parent card found")
			else:
				parent_card_data = card_data.parent_card
		
		# iterate over the card's values, adding to them where necessary
		var card_value_improvements: Dictionary[String, int] = {}
		card_value_improvements.assign(get_action_value("card_value_improvements", {})) # assign to force typed dict
		
		if card_data != null:
			card_data.improve_card_values(card_value_improvements)
		if parent_card_data != null:
			parent_card_data.improve_card_values(card_value_improvements)

func _to_string():
	return "Improve Card Action"
