# Validator for checking if a card play has been duplicated
# Can be inverted with "invert_validation" flag to prevent certain behaviors
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Card Play Is Duplicated"

func _get_editor_description() -> String:
	return "Checks whether the current card play was created as a duplicate play. Can be used with Invert Validation for uniqueness."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	if action == null:
		push_error("No action given")
		return false
	if action.card_play_request == null:
		push_error("No card play given")
		return false
	return action.card_play_request.is_duplicate_play
