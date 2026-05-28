extends BaseValidator

func _get_editor_display_name() -> String:
	return "Source Current Health"

func _get_editor_description() -> String:
	return "Checks the current health of the acting combatant."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_ACTION_VALIDATORS,
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("operator", "Operator", "enum", ">=", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Health value to compare against."))
	return parameters

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var combatant: BaseCombatant = _get_context_source_combatant(card_data, action, values)
	if combatant == null:
		return false
	var operator: String = _get_validator_value("operator", values, action, ">=")
	var comparison_value: int = _get_validator_value("comparison_value", values, action, 0)
	var current_health: int = 0
	if combatant is Enemy:
		current_health = combatant.enemy_data.enemy_health
	elif combatant is Player:
		current_health = combatant.get_health()
	return _compare(current_health, comparison_value, operator)
