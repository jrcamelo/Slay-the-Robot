extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return ["owner_only"]

func _get_editor_description() -> String:
	return "Discards matching hand cards and draws the same number."

func perform_action() -> void:
	var owner_only: bool = get_action_value("owner_only", false)
	var owner_party_index: int = -1
	if card_play_request != null and card_play_request.card_data != null:
		owner_party_index = card_play_request.card_data.card_owner_party_index
	var discarded_cards: Array[CardData] = []
	for card_data: CardData in Global.player_data.player_hand.duplicate():
		if card_play_request != null and card_data == card_play_request.card_data:
			continue
		if owner_only and owner_party_index >= 0 and card_data.card_owner_party_index != owner_party_index:
			continue
		discarded_cards.append(card_data)
	var discard_count: int = discarded_cards.size()
	if discard_count <= 0:
		return
	Signals.card_discard_requested.emit(discarded_cards, true)
	Signals.card_draw_requested.emit(discard_count, PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
