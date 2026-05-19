# Validator for if the given card can be removed from permanent deck or not
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Removable From Deck"

func _get_editor_description() -> String:
	return "Checks whether a card may be removed from the permanent deck."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS, EDITOR_CONTEXT_CARD_FILTER, EDITOR_CONTEXT_CARD_PICK]

func _validation(card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	if card_data == null:
		push_error("No card given")
		return false
	
	return not card_data.card_unremovable_from_deck
