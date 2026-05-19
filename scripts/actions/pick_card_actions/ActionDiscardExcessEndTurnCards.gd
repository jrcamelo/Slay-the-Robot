extends ActionBasePickCards
class_name ActionDiscardExcessEndTurnCards

func _get_editor_description() -> String:
	return "Async helper that discards the cards selected for end-of-turn overflow handling."

func perform_async_action() -> void:
	if len(picked_cards) > 0:
		Signals.card_discard_requested.emit(picked_cards, true)
	action_async_finished.emit()

func _to_string():
	return "Discard Excess End Turn Cards"
