extends BaseValidator

func _get_editor_display_name() -> String:
	return "Enemy Name Contains"

func _get_editor_description() -> String:
	return "Checks whether every resolved enemy target has a name containing the given text."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("search_text", "Search Text", "string", "", "Case-insensitive text required in the enemy name."))
	return parameters

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var targets: Array[BaseCombatant] = _get_context_targets(action, values)
	var search_text: String = str(_get_validator_value("search_text", values, action, "")).to_lower()
	if search_text == "":
		return false
	if targets.is_empty():
		return false
	for target: BaseCombatant in targets:
		if not (target is Enemy):
			return false
		var enemy: Enemy = target
		if not enemy.enemy_data.enemy_name.to_lower().contains(search_text):
			return false
	return true
