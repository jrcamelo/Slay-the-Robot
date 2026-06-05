extends BaseValidator

func _get_editor_display_name() -> String:
	return "Living Ally Count"

func _get_editor_description() -> String:
	return "Counts living allied enemies that pass nested validators and compares the total."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Living ally count required for the validator to pass."))
	parameters.append(_editor_param("exclude_source", "Exclude Source", "bool", false, "Ignores the acting enemy when counting allies."))
	parameters.append(_editor_param("validator_data", "Validator Data", "validator_array", [], "Additional validators each ally must satisfy to be counted."))
	return parameters

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var source_combatant: BaseCombatant = _get_context_source_combatant(null, action, values)
	if not (source_combatant is Enemy):
		return false

	var operator: String = _get_validator_value("operator", values, action, ">")
	var comparison_value: int = _get_validator_value("comparison_value", values, action, 0)
	var exclude_source: bool = _get_validator_value("exclude_source", values, action, false)
	var validator_data: Array[Dictionary] = []
	validator_data.assign(_get_validator_value("validator_data", values, action, []))

	var count: int = 0
	for node: Node in Global.get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node
		if not enemy.is_alive():
			continue
		if exclude_source and enemy == source_combatant:
			continue
		if not _passes_nested_validators(enemy, source_combatant, action, validator_data):
			continue
		count += 1

	return _compare(count, comparison_value, operator)

func _passes_nested_validators(enemy: Enemy, source_combatant: BaseCombatant, action: BaseAction, validators: Array[Dictionary]) -> bool:
	for validator_entry: Dictionary in validators:
		for validator_token: String in validator_entry.keys():
			var validator_script_asset: Script = Scripts.resolve_script(validator_token)
			if validator_script_asset == null:
				push_error("ValidatorLivingAllyCount failed to resolve validator %s" % validator_token)
				return false
			var validator: BaseValidator = validator_script_asset.new()
			var validator_values: Dictionary[String, Variant] = {}
			validator_values.assign(validator_entry[validator_token])
			validator_values["_source_combatant"] = source_combatant
			validator_values["_targets"] = [enemy]
			if not validator.validate(null, action, validator_values):
				return false
	return true
