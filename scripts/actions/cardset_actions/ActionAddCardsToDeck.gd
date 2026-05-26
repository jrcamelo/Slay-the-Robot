# Action add given cards to your permanent deck
extends BaseCardsetAction

func _get_editor_relevant_value_names() -> Array[String]:
	return super()

func _get_editor_description() -> String:
	return "Adds the selected cards to the player's permanent deck."

func perform_action() -> void:
	var picked_cards: Array[CardData] = _get_picked_cards()
	for card_data in picked_cards:
		if Global.player_data.has_party_members():
			_assign_cardset_owner(card_data)
		Global.player_data.add_card_to_deck(card_data)
