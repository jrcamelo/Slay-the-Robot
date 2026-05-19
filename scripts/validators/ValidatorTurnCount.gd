# Validator for checking the turn count in combat
extends BaseValidator

func _get_editor_description() -> String:
	return "Compares the current combat turn count against a threshold."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Turn count to compare against."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var combat_stats_data: CombatStatsData = Global.get_combat_stats()
	var operator: String = _get_validator_value("operator", values, _action, ">") 	# whether to use turn or total stat for the fight
	var comparison_value: int = _get_validator_value("comparison_value", values, _action, 0)

	return _compare(combat_stats_data.turn_count, comparison_value, operator)
