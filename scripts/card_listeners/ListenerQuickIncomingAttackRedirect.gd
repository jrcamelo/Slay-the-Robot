extends BaseQuickReactionListener

func _connect_signals() -> void:
	Signals.combatant_targeted_by_attack.connect(_on_combatant_targeted_by_attack)

func _on_combatant_targeted_by_attack(base_combatant: BaseCombatant, attack_action: BaseAction) -> void:
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null or base_combatant != owner_player:
		return
	if owner_player.get_status_charges("status_effect_negate_damage") > 0:
		return
	if attack_action == null or attack_action.parent_combatant == null or not attack_action.parent_combatant.is_alive():
		return

	var redirect_targets: Array[BaseCombatant] = []
	for ally: BaseCombatant in owner_player.get_living_allies():
		if ally is Player and ally != owner_player:
			redirect_targets.append(ally)
	if redirect_targets.is_empty():
		return

	var reaction_request: CardPlayRequest = _begin_reaction(attack_action.parent_combatant, attack_action)
	if reaction_request == null:
		return

	owner_player.add_status_effect_charges("status_effect_negate_damage", 1)
	_queue_reaction_actions(reaction_request)
	_queue_redirected_attack(attack_action, redirect_targets)
	_finish_reaction(reaction_request)

func _queue_redirected_attack(attack_action: BaseAction, redirect_targets: Array[BaseCombatant]) -> void:
	var rng_targeting: RandomNumberGenerator = Global.player_data.get_player_rng("rng_targeting")
	var redirected_target: BaseCombatant = redirect_targets[rng_targeting.randi_range(0, redirect_targets.size() - 1)]
	var action_path: String = attack_action.get_script().resource_path
	var action_reference: String = Scripts.get_token_for_path(action_path)
	if action_reference == "":
		action_reference = action_path

	var redirected_actions: Array[BaseAction] = ActionGenerator.create_actions(
		attack_action.parent_combatant,
		attack_action.card_play_request,
		[redirected_target],
		[{action_reference: attack_action.values.duplicate(true)}],
		attack_action.parent_action
	)
	ActionHandler.add_actions(redirected_actions, true, true)
