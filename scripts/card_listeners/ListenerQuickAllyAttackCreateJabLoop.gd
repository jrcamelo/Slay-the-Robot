extends BaseQuickReactionListener

func _connect_signals() -> void:
	Signals.card_play_started.connect(_on_card_play_started)

func _on_card_play_started(card_play_request: CardPlayRequest) -> void:
	if card_play_request == null or card_play_request.card_data == null:
		return
	if card_play_request.card_data == card_data:
		return
	if card_play_request.card_data.card_type != CardData.CARD_TYPES.ATTACK:
		return
	if card_play_request.card_data.card_owner_party_index == card_data.card_owner_party_index:
		return
	var reaction_request: CardPlayRequest = _begin_reaction(null, null, {"triggering_card_data": card_play_request.card_data})
	if reaction_request == null:
		return
	_queue_reaction_actions(reaction_request)
	_finish_reaction(reaction_request)
