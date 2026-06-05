extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.BYPASS_BLOCK, ActionValueRegistry.DAMAGE, ActionValueRegistry.OVERKILL_DAMAGE, ActionValueRegistry.UNBLOCKED_DAMAGE, ActionValueRegistry.UNBLOCKED_DAMAGE_CAPPED]

func _get_editor_description() -> String:
	return "Deals standard intercepted attack damage and records unblocked, capped, and overkill totals for follow-up actions."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	return [
		_editor_param("actions_on_lethal", "Actions On Lethal", "array", [], "Additional actions triggered if this attack kills the target."),
	]

func perform_action():
	for target in get_adjusted_action_targets():
		if target != null:
			Signals.combatant_targeted_by_attack.emit(target, self)
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()
	
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			return
		if not target.is_alive():
			return
		var damage: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.DAMAGE, 0)
		var bypass_block: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.BYPASS_BLOCK, false)
		
		var damages: Array[int] = target.damage(damage, bypass_block, self)
		var unblocked_damage: int = damages[0]
		var unblocked_damage_capped: int = damages[1] # damage done that does not factor overkill
		var overkill_damage: int = damages[2] # damage done beyond killing target
		
		# store unblocked/overkill damage in the CardPlayRequest if it exists.
		# this will accumulate between *all* actions sharing the same CardPlayRequest, thus
		# allowing actions such as healing on damage dealt (unblocked_damage_capped), or
		# an action that provides block based on overkill_damage. These will require providing
		# custom_key_names into the subsequent actions.
		if card_play_request != null:
			var previous_unblocked_damage: int = get_action_value(ActionValueRegistry.UNBLOCKED_DAMAGE, 0)
			card_play_request.card_values[ActionValueRegistry.UNBLOCKED_DAMAGE] = unblocked_damage + previous_unblocked_damage
			var previous_unblocked_damage_capped: int = get_action_value(ActionValueRegistry.UNBLOCKED_DAMAGE_CAPPED, 0)
			card_play_request.card_values[ActionValueRegistry.UNBLOCKED_DAMAGE_CAPPED] = unblocked_damage_capped + previous_unblocked_damage_capped
			var previous_overkill_damage: int = get_action_value(ActionValueRegistry.OVERKILL_DAMAGE, 0)
			card_play_request.card_values[ActionValueRegistry.OVERKILL_DAMAGE] = overkill_damage + previous_overkill_damage
			
		
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
	var damage: int = get_action_value(ActionValueRegistry.DAMAGE, 0)
	return "Attack Action: " + str(damage)
