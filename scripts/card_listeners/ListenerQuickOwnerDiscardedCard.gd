extends BaseQuickReactionListener

func _connect_signals() -> void:
	Signals.card_discarded.connect(_on_card_discarded)

func _on_card_discarded(discarded_card: CardData, _is_manual_discard: bool) -> void:
	if discarded_card == null or discarded_card == card_data:
		return
	if discarded_card.card_owner_party_index != card_data.card_owner_party_index:
		return
	var reaction_request: CardPlayRequest = _begin_reaction(null, null, {"discarded_card_data": discarded_card})
	if reaction_request == null:
		return
	_queue_reaction_actions(reaction_request)
	_finish_reaction(reaction_request)
