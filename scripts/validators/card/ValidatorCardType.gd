# Validator for checking a card's type
# useful for filtering cards down for pick 
# This will fail (result in banish) if used on a card currently in play
extends BaseValidator

func _get_editor_description() -> String:
	return "Checks whether a card matches one of the given card types."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS, EDITOR_CONTEXT_CARD_FILTER, EDITOR_CONTEXT_CARD_PICK]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("card_types", "Card Types", "enum_array", [], "Allowed card types."))
	return parameters

func _validation(card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	if card_data == null:
		return false
	
	var card_types: Array[int] = []
	card_types.assign(_get_validator_value("card_types", values, _action, []))
	return card_types.has(card_data.card_type)
