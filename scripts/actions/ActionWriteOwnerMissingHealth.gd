extends BaseAction

func _get_editor_description() -> String:
	return "Writes the card owner's current missing health into one or more card values."

func perform_action() -> void:
	if card_play_request == null:
		return
	var owner_player: Player = null
	if parent_combatant is Player:
		owner_player = parent_combatant as Player
	elif card_play_request.card_data != null:
		owner_player = Global.get_card_owner_player(card_play_request.card_data)
	if owner_player == null:
		return

	var missing_health: int = max(0, owner_player.get_health_max() - owner_player.get_health())
	var multiplier: int = get_action_value("value_per_missing_health", 1)
	var base_value: int = get_action_value("base_value", 0)
	var written_value: int = base_value + (missing_health * multiplier)

	var write_value_names: Array[String] = []
	write_value_names.assign(get_action_value("write_value_names", []))
	for value_name: String in write_value_names:
		card_play_request.card_values[value_name] = written_value

func _to_string() -> String:
	return "Write Owner Missing Health Action"
