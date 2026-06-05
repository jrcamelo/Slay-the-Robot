extends BaseQuickReactionListener

func _connect_signals() -> void:
	Signals.combatant_damaged.connect(_on_combatant_damaged)

func _on_combatant_damaged(base_combatant: BaseCombatant, _unblocked_damage: int, source_action: BaseAction = null) -> void:
	if source_action == null or source_action.parent_combatant == null:
		return
	if not (base_combatant is Player):
		return
	if not (source_action.parent_combatant is Enemy):
		return

	var damaged_player: Player = base_combatant
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null or damaged_player == owner_player:
		return
	if card_data.card_owner_party_index == damaged_player.get_party_member_index():
		return
	if not source_action.parent_combatant.is_alive():
		return

	var reaction_request: CardPlayRequest = _begin_reaction(
		source_action.parent_combatant,
		source_action,
		{"damaged_player": damaged_player}
	)
	if reaction_request == null:
		return
	_queue_reaction_actions(reaction_request)
	_finish_reaction(reaction_request)
