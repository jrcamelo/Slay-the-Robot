extends BaseValidator

func _get_editor_display_name() -> String:
	return "Action Value"

func _get_editor_description() -> String:
	return "Compares a resolved action/card-play value against a threshold."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_ACTION_VALIDATORS,
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("value_name", "Value Name", "string", "", "Action/card value key to inspect."))
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Value to compare against."))
	return parameters

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var value_name: String = str(_get_validator_value("value_name", values, action, "")).strip_edges()
	if value_name == "":
		return false
	var operator: String = _get_validator_value("operator", values, action, ">")
	var comparison_value: int = _get_validator_value("comparison_value", values, action, 0)
	var resolved_value: int = 0
	if action != null:
		resolved_value = int(action.get_action_value(value_name, 0))
	elif card_data != null:
		resolved_value = int(card_data.card_values.get(value_name, 0))
	return _compare(resolved_value, comparison_value, operator)
