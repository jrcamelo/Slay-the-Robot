## Validator for checking if a card has given tags.
## Almost always used in an ActionPickCards action with a CardFilter.
## May also be used in a CardPackData to filter by tag.
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Tags"

func _get_editor_description() -> String:
	return "Filters cards by required and excluded tags."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS, EDITOR_CONTEXT_CARD_FILTER, EDITOR_CONTEXT_CARD_PICK]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("card_tags", "Required Tags", "string_array", [], "Tags the card must contain."))
	parameters.append(_editor_param("require_all_tags", "Require All Tags", "bool", true, "If true, the card must contain every required tag."))
	parameters.append(_editor_param("card_tags_exclude", "Excluded Tags", "string_array", [], "Tags that automatically fail validation."))
	return parameters

func _validation(card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	if card_data == null:
		return false
	
	var card_tags: Array = _get_validator_value("card_tags", values, _action, [])
	var require_all_tags: bool = _get_validator_value("require_all_tags", values, _action, true)
	var card_tags_exclude: Array = _get_validator_value("card_tags_exclude", values, _action, [])
	
	# whitelist; empty whitelist counts ALL cards
	if len(card_tags) > 0:
		var card_tag_counter: int = 0
		for card_tag: String in card_tags:
			if card_data.card_tags.has(card_tag):
				card_tag_counter += 1
		# must have at least one tag
		if card_tag_counter == 0:
			return false
		# card must have all flags if require_all_tags = true
		if require_all_tags and len(card_tags) > card_tag_counter:
			return false
	
	# blacklist
	for card_tag: String in card_tags_exclude:
		if card_data.card_tags.has(card_tag):
			return false
	
	return true
