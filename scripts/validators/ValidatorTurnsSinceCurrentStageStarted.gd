extends BaseValidator

func _get_editor_display_name() -> String:
	return "Turns Since Current Stage Started"

func _get_editor_description() -> String:
	return "Checks how many turns have elapsed since the acting enemy's current planned stage began."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("operator", "Operator", "enum", ">=", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Turn count to compare against."))
	return parameters

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var combatant: BaseCombatant = _get_context_source_combatant(card_data, action, values)
	if not combatant is Enemy:
		return false
	var operator: String = _get_validator_value("operator", values, action, ">=")
	var comparison_value: int = _get_validator_value("comparison_value", values, action, 0)
	return _compare(combatant.get_turns_since_planned_stage_started(), comparison_value, operator)
