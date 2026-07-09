extends BaseArtifact

func connect_signals() -> void:
	super()
	Signals.card_played.connect(_on_card_played)

func disconnect_signals() -> void:
	super()
	_disconnect_signal(Signals.card_played, _on_card_played)

func _on_card_played(card_play_request: CardPlayRequest) -> void:
	var card_data: CardData = card_play_request.card_data
	
	if card_data.card_type == CardData.CARD_TYPES.ATTACK and card_belongs_to_owner(card_data):
		artifact_data.create_artifact_counter_increment_action(1)
