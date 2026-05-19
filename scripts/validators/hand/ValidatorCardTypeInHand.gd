## Validator for determining if there are any cards in hand of a certain type.
## ex checking that there are no attack cards, or exactly 3 attacks/skills.
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Type Count In Hand"

func _get_editor_description() -> String:
	return "Checks whether the number of cards of given types in hand falls within a range."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_CARD_PLAY_VALIDATORS, EDITOR_CONTEXT_CARD_GLOW_VALIDATORS, EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("card_type_minimum", "Minimum Count", "int", 0, "Minimum matching cards required in hand."))
	parameters.append(_editor_param("card_type_maximum", "Maximum Count", "int", 10, "Maximum matching cards allowed in hand."))
	parameters.append(_editor_param("card_types", "Card Types", "enum_array", [], "Card types counted in hand."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var card_type_minimum: int = _get_validator_value("card_type_minimum", values, _action, 0)
	var card_type_maximum: int = _get_validator_value("card_type_maximum", values, _action, 10)
	var card_types: Array[int] = []
	card_types.assign(_get_validator_value("card_types", values, _action, []))
	
	# take the card and hand from action if one provided
	var card_data: CardData = _card_data
	var hand: Array[CardData] = Global.player_data.player_hand
	if _action != null:
		if _action.card_play_request != null:
			card_data = _action.card_play_request.card_data
			hand = _action.card_play_request.hand_at_play_time
	
	# count cards matching criteria
	var card_count: int = 0
	for card: CardData in hand:
		var card_type: int = card.card_type
		if card_types.has(card_type):
			card_count += 1
	
	return (card_type_minimum <= card_count) and (card_count <= card_type_maximum)
