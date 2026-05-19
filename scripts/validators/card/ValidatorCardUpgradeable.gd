# Validator for if the given card can be upgraded or not
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Upgradeable"

func _get_editor_description() -> String:
	return "Checks whether a card still has upgrades remaining."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS, EDITOR_CONTEXT_CARD_FILTER, EDITOR_CONTEXT_CARD_PICK]

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	if card_data == null:
		push_error("No card given")
		return false
	
	return card_data.card_upgrade_amount < card_data.card_upgrade_amount_max
