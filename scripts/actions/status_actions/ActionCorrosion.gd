extends BaseAction

func _get_editor_description() -> String:
	return "Deals bypass-block damage to each resolved target, intended for corrosion-style status processing."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func perform_action():
	var damage: int = get_action_value("damage", 0)
	var adjusted_targets: Array[BaseCombatant] = get_adjusted_action_targets()
	for target in adjusted_targets:
		var _damages: Array[int] = target.damage(damage, true)

func _to_string():
	var damage: int = get_action_value("damage", 0)
	return "Attack Corrosion: " + str(damage)
