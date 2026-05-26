# applies a turn of temporary retain to cards that wears off end of turn
extends BaseCardsetAction

func _get_editor_relevant_value_names() -> Array[String]:
	return super()

func _get_editor_description() -> String:
	return "Applies temporary retain to the selected cards until end of turn."

func perform_action() -> void:
	var picked_cards: Array[CardData] = _get_picked_cards()
	Signals.card_retain_requested.emit(picked_cards)
