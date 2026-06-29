extends BaseValidator

func _get_editor_display_name() -> String:
	return "Selected Target Not Owner"

func _get_editor_description() -> String:
	return "Checks that the selected target is not the card owner."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
	]

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null:
		return false
	var target: BaseCombatant = null
	if action != null and action.card_play_request != null:
		target = action.card_play_request.selected_target
	if target == null and values.has("_selected_target") and values["_selected_target"] is BaseCombatant:
		target = values["_selected_target"]
	if target == null:
		return true
	return target != owner_player
