extends BaseValidator

const COUNT_ALLIES := "living_allies"
const COUNT_MINIONS := "living_minions"
const COUNT_NON_MINIONS := "living_non_minions"

func _get_editor_display_name() -> String:
	return "Living Ally Minion Count"

func _get_editor_description() -> String:
	return "Checks how many living allied enemies or minions the acting enemy currently has."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("count_mode", "Count Mode", "enum", COUNT_ALLIES, "Which living allies to count.", {"options": [COUNT_ALLIES, COUNT_MINIONS, COUNT_NON_MINIONS]}))
	parameters.append(_editor_param("operator", "Operator", "enum", ">=", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Count to compare against."))
	return parameters

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var combatant: BaseCombatant = _get_context_source_combatant(card_data, action, values)
	if not combatant is Enemy:
		return false
	var count_mode: String = _get_validator_value("count_mode", values, action, COUNT_ALLIES)
	var operator: String = _get_validator_value("operator", values, action, ">=")
	var comparison_value: int = _get_validator_value("comparison_value", values, action, 0)
	var current_count: int = 0
	for node: Node in Global.get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node
		if enemy == combatant or not enemy.is_alive():
			continue
		match count_mode:
			COUNT_MINIONS:
				if enemy.enemy_data.enemy_is_minion:
					current_count += 1
			COUNT_NON_MINIONS:
				if not enemy.enemy_data.enemy_is_minion:
					current_count += 1
			COUNT_ALLIES, _:
				current_count += 1
	return _compare(current_count, comparison_value, operator)
