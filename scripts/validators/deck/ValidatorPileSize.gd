# Validator for checking the size of a given pile (deck, hand, etc)
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Pile Size"

func _get_editor_description() -> String:
	return "Compares the size of a selected pile against a threshold."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("card_pick_type", "Pile", "enum", ActionBasePickCards.CARD_PICK_TYPES.HAND, "Pile to measure."))
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Pile size to compare against."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var card_pick_type: int = _get_validator_value("card_pick_type", values, _action, ActionBasePickCards.CARD_PICK_TYPES.HAND)
	var operator: String = _get_validator_value("operator", values, _action, ">") 	# whether to use turn or total stat for the fight
	var comparison_value: Variant = _get_validator_value("comparison_value", values, _action, 0)
	
	var pile: Array[CardData] = Global.player_data.get_pile(card_pick_type)
	
	# if taking hand, use hand at time of card play if it exists
	if card_pick_type == ActionBasePickCards.CARD_PICK_TYPES.HAND:
		if _action != null:
			if _action.card_play_request != null:
				pile = _action.card_play_request.hand_at_play_time
	
	return _compare(len(pile), comparison_value, operator)
