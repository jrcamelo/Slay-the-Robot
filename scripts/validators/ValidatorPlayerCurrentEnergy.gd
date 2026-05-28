extends BaseValidator

func _get_editor_display_name() -> String:
	return "Player Current Energy"

func _get_editor_description() -> String:
	return "Checks the player's current energy."

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("operator", "Operator", "enum", ">=", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Energy value to compare against."))
	return parameters

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var operator: String = _get_validator_value("operator", values, action, ">=")
	var comparison_value: int = _get_validator_value("comparison_value", values, action, 0)
	return _compare(Global.player_data.player_energy, comparison_value, operator)
