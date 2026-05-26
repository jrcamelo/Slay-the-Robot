# Action to exhaust selected cards
extends BaseCardsetAction

func _get_editor_relevant_value_names() -> Array[String]:
	return super()

func _get_editor_description() -> String:
	return "Exhausts the selected cards."

func perform_action() -> void:
	var picked_cards: Array[CardData] = _get_picked_cards()
	Signals.card_exhaust_requested.emit(picked_cards)
