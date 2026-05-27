# Validator for checking whether a single targeted enemy has depleted poise
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Enemy Broken Poise"

func _get_editor_description() -> String:
	return "Checks whether a single targeted enemy has poise at 0."

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
		return combatant.is_poise_depleted()
	return false
