# Action remove given cards from your permanent deck
extends BaseCardsetAction

func _get_editor_relevant_value_names() -> Array[String]:
	return super()

func _get_editor_description() -> String:
	return "Removes selected cards from the player's permanent deck."

func perform_action() -> void:
	var picked_cards: Array[CardData] = _get_picked_cards()
	for card_data in picked_cards:
		Global.player_data.remove_card_from_deck(card_data)
