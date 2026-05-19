# Generic validator for checking any card's properties using CardData.get() and _compare()
# Properties and comparison values pulled will be treated as variants until compared, so this can possibly cause runtime errors
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Property"

func _get_editor_description() -> String:
	return "Compares any exported card property against a value."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
		EDITOR_CONTEXT_CARD_FILTER,
		EDITOR_CONTEXT_CARD_PICK,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("card_property_name", "Card Property Name", "string", "card_name", "CardData property to inspect."))
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "variant", 0, "Value compared against the property."))
	return parameters

func _validation(card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var card_property_name: String = _get_validator_value("card_property_name", values, _action, "card_name")
	var operator: String = _get_validator_value("operator", values, _action, ">") 	# whether to use turn or total stat for the fight
	var comparison_value: Variant = _get_validator_value("comparison_value", values, _action, 0)
	
	if card_data == null:
		push_error("No card given")
		return false
	else:
		var card_property_value: Variant = card_data.get(card_property_name)
		return _compare(card_property_value, comparison_value, operator)
