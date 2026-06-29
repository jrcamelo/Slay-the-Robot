extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return ["card_object_id", "owner_only", "count_multiplier", "write_value_names"]

func _get_editor_description() -> String:
	return "Counts played cards matching an object id and writes the scaled count into card play values."

func perform_action() -> void:
	if card_play_request == null:
		return
	var combat_stats: CombatStatsData = Global.get_combat_stats()
	if combat_stats == null:
		return
	var card_object_id: String = get_action_value("card_object_id", "")
	var owner_only: bool = get_action_value("owner_only", false)
	var count_multiplier: int = get_action_value("count_multiplier", 1)
	var write_value_names: Array[String] = []
	write_value_names.assign(get_action_value("write_value_names", []))
	var owner_party_index: int = -1
	if card_play_request.card_data != null:
		owner_party_index = card_play_request.card_data.card_owner_party_index
	var count: int = 0
	var requests: Array[CardPlayRequest] = []
	requests.assign(combat_stats.cards_played_this_turn)
	for turn_requests: Array in combat_stats.cards_played_this_combat:
		for played_request: CardPlayRequest in turn_requests:
			requests.append(played_request)
	for played_request: CardPlayRequest in requests:
		if played_request == null or played_request.card_data == null:
			continue
		if card_object_id != "" and played_request.card_data.object_id != card_object_id:
			continue
		if owner_only and owner_party_index >= 0 and played_request.card_data.card_owner_party_index != owner_party_index:
			continue
		count += 1
	var written_value: int = count * count_multiplier
	for value_name: String in write_value_names:
		card_play_request.card_values[value_name] = written_value
