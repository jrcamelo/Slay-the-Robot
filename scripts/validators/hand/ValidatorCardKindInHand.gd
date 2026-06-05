extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Kind Count In Hand"

func _get_editor_description() -> String:
	return "Checks whether the number of cards of given kinds in hand falls within a range."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_CARD_PLAY_VALIDATORS, EDITOR_CONTEXT_CARD_GLOW_VALIDATORS, EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("card_kind_minimum", "Minimum Count", "int", 0, "Minimum matching cards required in hand."))
	parameters.append(_editor_param("card_kind_maximum", "Maximum Count", "int", 10, "Maximum matching cards allowed in hand."))
	parameters.append(_editor_param("card_kinds", "Card Kinds", "string_array", [], "Card kinds counted in hand."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var card_kind_minimum: int = _get_validator_value("card_kind_minimum", values, _action, 0)
	var card_kind_maximum: int = _get_validator_value("card_kind_maximum", values, _action, 10)
	var card_kinds: Array[String] = []
	card_kinds.assign(_get_validator_value("card_kinds", values, _action, []))

	var card_data: CardData = _card_data
	var hand: Array[CardData] = Global.player_data.player_hand
	if _action != null and _action.card_play_request != null:
		card_data = _action.card_play_request.card_data
		hand = _action.card_play_request.hand_at_play_time

	var card_count: int = 0
	for card: CardData in hand:
		if card == card_data:
			continue
		for card_kind: String in card_kinds:
			if card.is_card_kind(card_kind):
				card_count += 1
				break

	return (card_kind_minimum <= card_count) and (card_count <= card_kind_maximum)
