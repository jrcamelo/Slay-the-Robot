## Validator for checking if a card belongs to a certain color.
## Almost always used in an ActionPickCards action with a CardFilter.
extends BaseValidator

func _get_editor_description() -> String:
	return "Filters cards by allowed and excluded color IDs."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS, EDITOR_CONTEXT_CARD_FILTER, EDITOR_CONTEXT_CARD_PICK]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("card_color_ids", "Allowed Color IDs", "string_array", [], "If not empty, the card must match one of these color IDs."))
	parameters.append(_editor_param("card_color_ids_exclude", "Excluded Color IDs", "string_array", [], "Cards with these color IDs always fail validation."))
	return parameters

func _validation(card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	if card_data == null:
		return false
	
	var card_color_ids: Array = _get_validator_value("card_color_ids", values, _action, [])
	var card_color_ids_exclude: Array = _get_validator_value("card_color_ids_exclude", values, _action, [])
	
	# whitelist; empty whitelist counts ALL cards
	if len(card_color_ids) > 0:
		if not card_color_ids.has(card_data.card_color_id):
			return false
	# blacklist
	if card_color_ids_exclude.has(card_data.card_color_id):
		return false
	
	return true
