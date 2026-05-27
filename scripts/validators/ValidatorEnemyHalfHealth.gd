# Validator for checking whether a single targeted enemy is at or below half health
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Enemy Half Health"

func _get_editor_description() -> String:
	return "Checks whether a single targeted enemy has health at or below half of its maximum."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _validation(_card_data: CardData, action: BaseAction, _values: Dictionary[String, Variant]) -> bool:
	if action == null:
		return false

	var targets: Array[BaseCombatant] = _get_context_targets(action)
	if len(targets) != 1:
		return false

	var combatant: BaseCombatant = targets[0]
	if combatant is Enemy:
		return combatant.enemy_data.enemy_health * 2 <= combatant.enemy_data.enemy_health_max
	return false
