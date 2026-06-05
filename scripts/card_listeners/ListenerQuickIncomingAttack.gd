extends BaseQuickReactionListener

func _connect_signals() -> void:
	Signals.combatant_targeted_by_attack.connect(_on_combatant_targeted_by_attack)

func _on_combatant_targeted_by_attack(base_combatant: BaseCombatant, attack_action: BaseAction) -> void:
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null or base_combatant != owner_player:
		return
	if owner_player.get_status_charges("status_effect_negate_damage") > 0:
		return

	var reaction_request: CardPlayRequest = _begin_reaction(null, attack_action)
	if reaction_request == null:
		return
	owner_player.add_status_effect_charges("status_effect_negate_damage", 1)
	_finish_reaction(reaction_request)
