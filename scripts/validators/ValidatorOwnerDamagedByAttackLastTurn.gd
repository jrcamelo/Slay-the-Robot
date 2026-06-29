extends BaseValidator

func _get_editor_display_name() -> String:
	return "Owner Damaged By Attack Last Turn"

func _get_editor_description() -> String:
	return "Checks whether the card owner was damaged by one or more enemy attacks last turn, optionally restricting the selected target to those attackers."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
	]

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null:
		return false
	var combat_stats: CombatStatsData = Global.get_combat_stats()
	if combat_stats == null:
		return false
	var attacker_ids: Array[int] = combat_stats.get_last_turn_attackers_for_player(owner_player.get_party_member_index())
	if attacker_ids.is_empty():
		return false
	var target: BaseCombatant = null
	if action != null and action.card_play_request != null:
		target = action.card_play_request.selected_target
	if target == null and values.has("_selected_target") and values["_selected_target"] is BaseCombatant:
		target = values["_selected_target"]
	if target == null:
		return true
	return attacker_ids.has(target.get_instance_id())
