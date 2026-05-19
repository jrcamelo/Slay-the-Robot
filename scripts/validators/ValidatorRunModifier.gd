## Validator for checking if the current run has a run modifier
extends BaseValidator

func _get_editor_description() -> String:
	return "Checks whether the current run includes a given run modifier."

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("run_modifier_object_id", "Run Modifier ID", "string", "", "Run modifier object ID to check for."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var run_modifier_object_id: String = _get_validator_value("run_modifier_object_id", values, _action, "")
	return Global.player_data.player_run_modifier_object_ids.has(run_modifier_object_id)
