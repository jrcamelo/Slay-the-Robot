# Validator for determining card location in combat (hand, draw, etc)
# see CardPlayRequest.CARD_PLAY_DESTINATIONS and CardData.get_card_location() for more
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Location"

func _get_editor_description() -> String:
	return "Checks whether a card is currently in one of the allowed combat locations."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
		EDITOR_CONTEXT_CARD_FILTER,
		EDITOR_CONTEXT_CARD_PICK,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("card_locations", "Card Locations", "enum_array", [CardPlayRequest.CARD_PLAY_DESTINATIONS.DRAW_TOP], "Allowed card locations."))
	return parameters

func _validation(card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	if card_data == null:
		push_error("No card given")
		return false
	
	var card_locations: Array = _get_validator_value("card_locations", values, _action, [CardPlayRequest.CARD_PLAY_DESTINATIONS.DRAW_TOP]) # acceptable locations for the card to be in
	var card_deck_location: int = card_data.get_card_deck_location()
	
	return card_locations.has(card_deck_location)
