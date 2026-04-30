# Action add given cards to your permanent deck
extends BaseCardsetAction

func perform_action() -> void:
	var picked_cards: Array[CardData] = _get_picked_cards()
	for card_data in picked_cards:
		if Global.player_data.has_party_members():
			Global.player_data.ensure_card_has_owner(card_data)
		Global.player_data.add_card_to_deck(card_data)
