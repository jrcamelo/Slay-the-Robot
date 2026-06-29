extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return ["card_object_ids", "owner_only", "write_value_names", "write_multiplier"]

func _get_editor_description() -> String:
	return "Discards matching cards from hand and writes the discarded count into card play values."

func perform_action() -> void:
	var owner_only: bool = get_action_value("owner_only", false)
	var write_multiplier: int = get_action_value("write_multiplier", 1)
	var card_object_ids: Array[String] = []
	card_object_ids.assign(get_action_value("card_object_ids", []))
	var write_value_names: Array[String] = []
	write_value_names.assign(get_action_value("write_value_names", ["discarded_card_count"]))
	var owner_party_index: int = -1
	if card_play_request != null and card_play_request.card_data != null:
		owner_party_index = card_play_request.card_data.card_owner_party_index

	var discarded_cards: Array[CardData] = []
	for card_data: CardData in Global.player_data.player_hand.duplicate():
		if card_play_request != null and card_data == card_play_request.card_data:
			continue
		if owner_only and owner_party_index >= 0 and card_data.card_owner_party_index != owner_party_index:
			continue
		if not card_object_ids.is_empty() and not card_object_ids.has(card_data.object_id):
			continue
		discarded_cards.append(card_data)

	if card_play_request != null:
		var written_value: int = discarded_cards.size() * write_multiplier
		for value_name: String in write_value_names:
			card_play_request.card_values[value_name] = written_value
	if not discarded_cards.is_empty():
		Signals.card_discard_requested.emit(discarded_cards, true)
