# Wraps child actions, modifying their values
# Amount based on a given combat stat
# NOTE: As this is an action and not a listener, its wrapped value(s) are calculated on runtime
# and cannot be previewed on a card
# If you want the value to be seen in the description, use a listener such as ListenerCardValueModifier
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.IS_TOTAL_STAT, ActionValueRegistry.MULTIPLIED_VALUES, ActionValueRegistry.MULTIPLIED_VALUES_BASES, ActionValueRegistry.STAT_ENUM]

func _get_editor_description() -> String:
	return "Wraps child actions and scales selected values from a combat stat."

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	return [
		_editor_param("action_data", "Action Data", "array", [], "Additional actions generated after scaling their configured values."),
	]

func is_instant_action() -> bool:
	return true

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	
	for action_interceptor_processor in action_interceptor_processors:
		var modified_action_data: Array[Dictionary] = []
		var action_data = action_interceptor_processor.get_shadowed_action_values("action_data", [])
		
		# wrapper values
		var multiplied_values: Array = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.MULTIPLIED_VALUES, [])	# the key names of the values of child actions multiplied by this action
		var multiplied_values_bases: Dictionary = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.MULTIPLIED_VALUES_BASES, {})	# allows for a base value on top of modified values. eg Base + (X x Value)
		
		# get combat stat muliplier
		var combat_stats_data: CombatStatsData = Global.get_combat_stats()
		var stat_enum: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.STAT_ENUM, CombatStatsData.STATS.ENEMIES_KILLED)
		var is_total_stat: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.IS_TOTAL_STAT, false)
		
		var stat_value: int = 0
		if is_total_stat:
			stat_value = combat_stats_data.get_total_stat(stat_enum)
		else:
			stat_value = combat_stats_data.get_turn_stat(stat_enum)
		
		# creates a duplicate of the child action data, then modifies any keys with a multiple of the card play's input energy
		for action in action_data.duplicate(true):
			for action_script_path in action:
				for action_path in action:
					var action_values: Dictionary = action[action_script_path]
					for value_key in action_values.keys():
						if value_key in multiplied_values:
							var base_value: int = multiplied_values_bases.get(value_key, 0)
							var value: int = action_values[value_key]
							action_values[value_key] = base_value + (value * stat_value)
			
			modified_action_data.append(action)
		
		# also modifies any card play values
		for value_key in card_play_request.card_values.keys():
			if value_key in multiplied_values:
				var base_value: int = multiplied_values_bases.get(value_key, 0)
				var value: int = card_play_request.card_values[value_key]
				card_play_request.card_values[value_key] = base_value + (value * stat_value)
		
		var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, targets, modified_action_data, self)
		ActionHandler.add_actions(generated_actions)
