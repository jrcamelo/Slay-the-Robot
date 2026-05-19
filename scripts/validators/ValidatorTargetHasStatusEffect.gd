# Validator for checking whether the selected or resolved action target(s) have a specific status effect.
# If multiple targets are resolved, every target must pass.
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Target Has Status Effect"

func _get_editor_description() -> String:
	return "Checks whether the selected target, or every resolved target, has status charges matching the comparison."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("status_effect_object_id", "Status Effect ID", "string", "", "Status effect object id to inspect on the target."))
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Charge amount to compare against."))
	return parameters

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var status_effect_object_id: String = _get_validator_value("status_effect_object_id", values, action, "")
	var operator: String = _get_validator_value("operator", values, action, ">")
	var comparison_value: int = _get_validator_value("comparison_value", values, action, 0)

	if action == null:
		return false
	if status_effect_object_id == "":
		push_error("Missing status_effect_object_id")
		return false

	var targets: Array[BaseCombatant] = _get_context_targets(action)
	if len(targets) == 0:
		return false

	for target: BaseCombatant in targets:
		if target == null:
			return false
		var status_charges: int = target.get_status_charges(status_effect_object_id)
		if not _compare(status_charges, comparison_value, operator):
			return false
	return true
