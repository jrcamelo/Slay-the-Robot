# Retains all cards in hand at end of turn
extends BaseArtifact

func connect_signals() -> void:
	super()
	Signals.card_drawn.connect(_on_card_drawn)
	Signals.card_add_to_hand_requested.connect(_on_card_add_to_hand_requested)

func disconnect_signals() -> void:
	super()
	_disconnect_signal(Signals.card_drawn, _on_card_drawn)
	_disconnect_signal(Signals.card_add_to_hand_requested, _on_card_add_to_hand_requested)

func _on_player_turn_started():
	super()
	var owner_hand_cards: Array[CardData] = filter_owner_cards(Global.player_data.player_hand)
	if len(owner_hand_cards) > 0:
		Signals.card_retain_requested.emit(owner_hand_cards)

func _on_card_drawn(card_data: CardData):
	if card_belongs_to_owner(card_data):
		var card_retain_request: Array[CardData] = [card_data]	# formatting into card data array
		Signals.card_retain_requested.emit(card_retain_request)

func _on_card_add_to_hand_requested(cards: Array[CardData], _hand_card_count_max: int):
	var owner_cards: Array[CardData] = filter_owner_cards(cards)
	if len(owner_cards) > 0:
		Signals.card_retain_requested.emit(owner_cards)
