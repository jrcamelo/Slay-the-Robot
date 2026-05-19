# Validator for checking any combat stats using comparison operators
# See: CombatStatsData for stat_enum values
extends BaseValidator

func _get_editor_description() -> String:
	return "Compares a combat stat against a threshold."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("stat_enum", "Stat", "enum", CombatStatsData.STATS.ENEMIES_KILLED, "Combat stat to inspect."))
	parameters.append(_editor_param("is_total_stat", "Use Total Stat", "bool", false, "Uses the whole-combat value instead of the current turn value."))
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Value to compare against."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var combat_stats_data: CombatStatsData = Global.get_combat_stats()
	
	var stat_enum: int = _get_validator_value("stat_enum", values, _action, CombatStatsData.STATS.ENEMIES_KILLED)
	var is_total_stat: bool = _get_validator_value("is_total_stat", values, _action, false) 	# whether to use turn or total stat for the fight
	var operator: String = _get_validator_value("operator", values, _action, ">") 	# whether to use turn or total stat for the fight
	var comparison_value: int = _get_validator_value("comparison_value", values, _action, 0)
	
	var stat_value: int = 0
	if is_total_stat:
		stat_value = combat_stats_data.get_total_stat(stat_enum)
	else:
		stat_value = combat_stats_data.get_turn_stat(stat_enum)
	
	return _compare(stat_value, comparison_value, operator)
