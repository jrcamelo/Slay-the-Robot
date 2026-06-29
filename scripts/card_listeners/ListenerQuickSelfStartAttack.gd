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
	if card_play_request.card_data.card_owner_party_index != card_data.card_owner_party_index:
		return

	var selected_target: BaseCombatant = card_play_request.selected_target
	if selected_target == null or not selected_target.is_alive():
		selected_target = Global.get_tree().get_first_node_in_group("enemies")
	if selected_target == null or not selected_target.is_alive():
		return

	var reaction_request: CardPlayRequest = _begin_reaction(selected_target, null)
	if reaction_request == null:
		return
	_queue_reaction_actions(reaction_request)
	_finish_reaction(reaction_request)
