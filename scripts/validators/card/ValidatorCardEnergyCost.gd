# Validator for checking a card's energy cost
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Energy Cost"

func _get_editor_description() -> String:
	return "Compares a card's current effective energy cost against a value."

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
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Energy cost to compare against."))
	parameters.append(_editor_param("variable_cost_is_zero", "Variable Cost Is Zero", "bool", false, "Treats X-cost cards as zero for the comparison."))
	return parameters

func _validation(card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:

	var operator: String = _get_validator_value("operator", values, _action, ">") 	# whether to use turn or total stat for the fight
	var comparison_value: Variant = _get_validator_value("comparison_value", values, _action, 0)
	var variable_cost_is_zero: bool = _get_validator_value("variable_cost_is_zero", values, _action, false)
	
	if card_data == null:
		push_error("No card given")
		return false
	else:
		var card_energy: int = card_data.get_card_energy_cost(true, variable_cost_is_zero)
		return _compare(card_energy, comparison_value, operator)
