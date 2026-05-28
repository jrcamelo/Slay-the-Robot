extends BaseValidator

func _get_editor_display_name() -> String:
	return "Stage Execution Count"

func _get_editor_description() -> String:
	return "Checks how many times a given stage has been executed by the acting enemy."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("stage_id", "Stage ID", "string", "", "Stage id to inspect. Leave empty to inspect the current planned stage."))
	parameters.append(_editor_param("operator", "Operator", "enum", ">=", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Execution count to compare against."))
	return parameters

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var combatant: BaseCombatant = _get_context_source_combatant(card_data, action, values)
	if not combatant is Enemy:
		return false
	var stage_id: String = _get_validator_value("stage_id", values, action, "")
	if stage_id == "":
		stage_id = combatant.get_planned_stage_id()
	var operator: String = _get_validator_value("operator", values, action, ">=")
	var comparison_value: int = _get_validator_value("comparison_value", values, action, 0)
	return _compare(combatant.get_stage_execution_count(stage_id), comparison_value, operator)
