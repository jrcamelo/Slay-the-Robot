extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.BYPASS_BLOCK, ActionValueRegistry.DAMAGE]

func _get_editor_description() -> String:
	return "Deals attack damage and reduces enemy poise in the same action, with optional overflow-to-damage conversion."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	return [
		_editor_param("poise_amount", "Poise Amount", "int", 0, "Enemy poise removed by the attack."),
		_editor_param("overwhelming", "Overwhelming", "bool", false, "Converts excess poise damage into extra health damage."),
		_editor_param("actions_on_lethal", "Actions On Lethal", "array", [], "Additional actions triggered if this attack kills the target."),
	]

func perform_action() -> void:
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
		if target == null or not target.is_alive():
			continue

		var damage: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.DAMAGE, 0)
		if parent_combatant != null:
			damage = parent_combatant.get_outgoing_damage_after_passive_filters(action_interceptor_processor)
		var bypass_block: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.BYPASS_BLOCK, false)
		var poise_amount: int = max(0, action_interceptor_processor.get_shadowed_action_values("poise_amount", 0))
		var overwhelming: bool = action_interceptor_processor.get_shadowed_action_values("overwhelming", false)
		var total_damage: int = damage

		if target is Enemy and poise_amount > 0:
			var target_enemy: Enemy = target
			var current_poise: int = target_enemy.get_poise()
			target_enemy.add_poise(-poise_amount)
			if current_poise > 0 and target_enemy.is_poise_depleted():
				Signals.combatant_poise_depleted.emit(target_enemy, self)
			if overwhelming and poise_amount > current_poise:
				total_damage += poise_amount - current_poise

		var damages: Array[int] = target.damage(total_damage, bypass_block, self)
		var unblocked_damage: int = damages[0]
		var unblocked_damage_capped: int = damages[1]
		var overkill_damage: int = damages[2]

		if card_play_request != null:
			var previous_unblocked_damage: int = get_action_value(ActionValueRegistry.UNBLOCKED_DAMAGE, 0)
			card_play_request.card_values[ActionValueRegistry.UNBLOCKED_DAMAGE] = unblocked_damage + previous_unblocked_damage
			var previous_unblocked_damage_capped: int = get_action_value(ActionValueRegistry.UNBLOCKED_DAMAGE_CAPPED, 0)
			card_play_request.card_values[ActionValueRegistry.UNBLOCKED_DAMAGE_CAPPED] = unblocked_damage_capped + previous_unblocked_damage_capped
			var previous_overkill_damage: int = get_action_value(ActionValueRegistry.OVERKILL_DAMAGE, 0)
			card_play_request.card_values[ActionValueRegistry.OVERKILL_DAMAGE] = overkill_damage + previous_overkill_damage

		if not target.is_alive():
			var actions_on_lethal: Array[Dictionary] = []
			actions_on_lethal.assign(get_action_value("actions_on_lethal", []))
			if len(actions_on_lethal) > 0:
				var generated_on_lethal_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, [target], actions_on_lethal, self)
				generated_on_lethal_actions.reverse()
				ActionHandler.add_actions(generated_on_lethal_actions)

func is_action_short_circuited() -> bool:
	return get_action_value("action_short_circuits", true)

func _to_string() -> String:
	var damage: int = get_action_value(ActionValueRegistry.DAMAGE, 0)
	var poise_amount: int = get_action_value("poise_amount", 0)
	return "Attack Poise Action: %s / %s" % [damage, poise_amount]

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
