## Validator for determining if the card is in a given position in player's hand
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Position In Hand"

func _get_editor_description() -> String:
	return "Checks whether a card is on the left, center, or right side of the hand."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_CARD_PLAY_VALIDATORS, EDITOR_CONTEXT_CARD_GLOW_VALIDATORS, EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("position_in_hand", "Position In Hand", "enum", "center", "Required hand position.", {"options": ["left", "center", "right"]}))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var position_in_hand: String = _get_validator_value("position_in_hand", values, _action, "center")	# left, center, right
		
	var card_data: CardData = _card_data
	var hand: Array[CardData] = Global.player_data.player_hand
	
	# take the card and hand from action if one provided
	if _action != null:
		if _action.card_play_request != null:
			card_data = _action.card_play_request.card_data
			hand = _action.card_play_request.hand_at_play_time
	
	if card_data == null:
		push_error("No card given")
		return false
	
	var index_of_card: int = hand.find(card_data)
	var size_of_hand: int = len(hand)
	
	if index_of_card == -1:
		return false	# not in hand; fail validation
	
	match position_in_hand:
		"left":
			return index_of_card == 0
		"right":
			return index_of_card == size_of_hand - 1
		"center", _:
			var center_index: int = len(hand) / 2
			if size_of_hand % 2 == 0:
				return [center_index - 1, center_index].has(index_of_card)
			else:
				return index_of_card == center_index
