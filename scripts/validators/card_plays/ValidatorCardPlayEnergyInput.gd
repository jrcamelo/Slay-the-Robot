# Validator for checking a card play's input energy cost
# This may be useful for variable cost cards to allow different behaviors at different thresholds
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Play Energy Input"

func _get_editor_description() -> String:
	return "Compares the actual energy committed to the current card play."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Energy input to compare against."))
	return parameters

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:

	var operator: String = _get_validator_value("operator", values, action, ">") 	# whether to use turn or total stat for the fight
	var comparison_value: Variant = _get_validator_value("comparison_value", values, action, 0)
	
	if action == null:
		push_error("No card given")
		return false
	elif action.card_play_request == null:
		push_error("No card play given")
		return false
	else:
		var input_energy: int = action.card_play_request.input_energy
		return _compare(input_energy, comparison_value, operator)
