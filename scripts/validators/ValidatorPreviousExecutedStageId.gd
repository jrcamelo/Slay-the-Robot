extends BaseValidator

func _get_editor_display_name() -> String:
	return "Previous Executed Stage ID"

func _get_editor_description() -> String:
	return "Checks the previous executed stage id of the acting enemy."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("stage_id", "Stage ID", "string", "", "Previous stage id required for the validator to pass."))
	return parameters

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var combatant: BaseCombatant = _get_context_source_combatant(card_data, action, values)
	if not combatant is Enemy:
		return false
	var stage_id: String = _get_validator_value("stage_id", values, action, "")
	return stage_id != "" and combatant.get_previous_executed_stage_id() == stage_id
