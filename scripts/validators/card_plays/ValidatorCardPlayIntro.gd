extends BaseValidator

func _validation(_card_data: CardData, _action: BaseAction, _values: Dictionary[String, Variant]) -> bool:
	var combat_stats: CombatStatsData = Global.get_combat_stats()
	if combat_stats == null:
		return true
	
	for played_card_request: CardPlayRequest in combat_stats.cards_played_this_turn:
		if played_card_request == null or played_card_request.card_data == null:
			continue
		if not played_card_request.card_data.is_card_kind(CardData.CARD_KIND_INTRO):
			return false
	return true
