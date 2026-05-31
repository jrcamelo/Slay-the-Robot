extends BaseValidator

func _get_editor_display_name() -> String:
	return "Source Broken Poise"

func _get_editor_description() -> String:
	return "Checks whether the acting combatant has poise at 0."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_ACTION_VALIDATORS,
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
	]

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var combatant: BaseCombatant = _get_context_source_combatant(card_data, action, values)
	if combatant is Enemy:
		return combatant.is_poise_depleted()
	return false
