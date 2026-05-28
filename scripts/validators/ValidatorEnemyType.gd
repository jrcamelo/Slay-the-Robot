# Validator for checking the enemy target type
# fails when used on player or cannot narrow down to one target
extends BaseValidator

func _get_editor_description() -> String:
	return "Checks whether a single targeted enemy matches a specific enemy type."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("enemy_type", "Enemy Type", "enum", EnemyData.ENEMY_TYPES.STANDARD, "Enemy type required for the validator to pass."))
	return parameters

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var enemy_type: int = _get_validator_value("enemy_type", values, action, EnemyData.ENEMY_TYPES.STANDARD)
	var targets: Array[BaseCombatant] = _get_context_targets(action, values)
	if len(targets) != 1:
		return false
	var combatant: BaseCombatant = targets[0]
	if combatant is Enemy:
		return enemy_type == combatant.enemy_data.enemy_type
	else:
		return false
