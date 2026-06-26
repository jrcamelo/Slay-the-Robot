extends BaseAction

func perform_action():
	var resolved_targets: Array[BaseCombatant] = get_adjusted_action_targets()
	if parent_combatant != null and parent_combatant.get_status_charges("status_effect_daze") > 0:
		var dazed_target: BaseCombatant = _get_daze_target(resolved_targets)
		if dazed_target != null:
			resolved_targets = [dazed_target]
		parent_combatant.consume_flag_status("status_effect_daze")
	for target in resolved_targets:
		if target != null:
			Signals.combatant_targeted_by_attack.emit(target, self)
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(resolved_targets)
	
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			return
		if not target.is_alive():
			return
		var damage: int = action_interceptor_processor.get_shadowed_action_values("damage", 0)
		var bypass_block: bool = action_interceptor_processor.get_shadowed_action_values("bypass_block", false)
		
		var damages: Array[int] = target.damage(damage, bypass_block)
		var unblocked_damage: int = damages[0]
		var unblocked_damage_capped: int = damages[1] # damage done that does not factor overkill
		var overkill_damage: int = damages[2] # damage done beyond killing target
		
		# store unblocked/overkill damage in the CardPlayRequest if it exists.
		# this will accumulate between *all* actions sharing the same CardPlayRequest, thus
		# allowing actions such as healing on damage dealt (unblocked_damage_capped), or
		# an action that provides block based on overkill_damage. These will require providing
		# custom_key_names into the subsequent actions.
		if card_play_request != null:
			var previous_unblocked_damage: int = get_action_value("unblocked_damage", 0)
			card_play_request.card_values["unblocked_damage"] = unblocked_damage + previous_unblocked_damage
			var previous_unblocked_damage_capped: int = get_action_value("unblocked_damage_capped", 0)
			card_play_request.card_values["unblocked_damage_capped"] = unblocked_damage_capped + previous_unblocked_damage_capped
			var previous_overkill_damage: int = get_action_value("overkill_damage", 0)
			card_play_request.card_values["overkill_damage"] = overkill_damage + previous_overkill_damage
			
		
		# target killed by attack
		if not target.is_alive():
			# apply actions on lethal
			var actions_on_lethal: Array[Dictionary] = []
			actions_on_lethal.assign(get_action_value("actions_on_lethal", []))
			if len(actions_on_lethal) > 0:
				var generated_on_lethal_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, [target], actions_on_lethal, self)
				ActionHandler.add_actions(generated_on_lethal_actions)

func is_action_short_circuited():
	return get_action_value("action_short_circuits", true)

func _to_string():
	var damage: int = get_action_value("damage", 0)
	return "Attack Action: " + str(damage)

func _get_daze_target(resolved_targets: Array[BaseCombatant]) -> BaseCombatant:
	if parent_combatant == null:
		return null
	if parent_combatant is Enemy and len(resolved_targets) > 0:
		return resolved_targets[0]
	var possible_targets: Array[BaseCombatant] = []
	if parent_combatant.is_in_group("players"):
		for enemy in Global.get_tree().get_nodes_in_group("enemies"):
			if enemy != null and enemy.is_alive():
				possible_targets.append(enemy)
	else:
		possible_targets.assign(Global.get_living_players())
	if possible_targets.is_empty():
		return null
	var rng_targeting: RandomNumberGenerator = Global.player_data.get_player_rng("rng_targeting")
	return possible_targets[rng_targeting.randi_range(0, possible_targets.size() - 1)]
