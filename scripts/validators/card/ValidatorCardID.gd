## Validator for checking a card's specific ID (eg only getting basic attack cards)
## useful for filtering cards down for pick actions
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Object ID"

func _get_editor_description() -> String:
	return "Checks whether a card matches one of the given object IDs."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS, EDITOR_CONTEXT_CARD_FILTER, EDITOR_CONTEXT_CARD_PICK]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("card_object_ids", "Card Object IDs", "string_array", [], "Allowed card object IDs."))
	return parameters

func _validation(card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	if card_data == null:
		return false
	
	var card_object_ids: Array = _get_validator_value("card_object_ids", values, _action, [])
	return card_object_ids.has(card_data.object_id)
