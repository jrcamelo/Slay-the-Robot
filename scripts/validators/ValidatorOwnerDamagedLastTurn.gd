extends BaseValidator

func _get_editor_display_name() -> String:
	return "Owner Damaged Last Turn"

func _get_editor_description() -> String:
	return "Checks whether the card owner suffered any health damage last turn."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
	]

func _validation(card_data: CardData, _action: BaseAction, _values: Dictionary[String, Variant]) -> bool:
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null:
		return false
	var combat_stats: CombatStatsData = Global.get_combat_stats()
	if combat_stats == null:
		return false
	return combat_stats.was_player_damaged_last_turn(owner_player.get_party_member_index())
