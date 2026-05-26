# Randomizes the energy cost values of given cards
extends BaseCardsetAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.CARD_COST_MAX, ActionValueRegistry.CARD_COST_MIN, ActionValueRegistry.PICK_PLAYED_CARD, ActionValueRegistry.RANDOMIZE_CARD_ENERGY_COST, ActionValueRegistry.RANDOMIZE_CARD_ENERGY_COST_UNTIL_COMBAT, ActionValueRegistry.RANDOMIZE_CARD_ENERGY_COST_UNTIL_PLAYED, ActionValueRegistry.RANDOMIZE_CARD_ENERGY_COST_UNTIL_TURN]

func _get_editor_description() -> String:
	return "Randomizes one or more energy cost layers on the selected cards."

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	
	for action_interceptor_processor in action_interceptor_processors:
		# flags for what card energies to randomize
		var randomize_card_energy_cost: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.RANDOMIZE_CARD_ENERGY_COST, false)
		var randomize_card_energy_cost_until_combat: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.RANDOMIZE_CARD_ENERGY_COST_UNTIL_COMBAT, false)
		var randomize_card_energy_cost_until_played: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.RANDOMIZE_CARD_ENERGY_COST_UNTIL_PLAYED, false)
		var randomize_card_energy_cost_until_turn: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.RANDOMIZE_CARD_ENERGY_COST_UNTIL_TURN, false)
		
		# card cost random bounds (inclusive)
		var card_cost_min: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CARD_COST_MIN, 0)
		var card_cost_max: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CARD_COST_MAX, 3)
		
		# get an energy rng
		var rng_energy_cost: RandomNumberGenerator = Global.player_data.get_player_rng("rng_energy_cost")
		
		# randomize all card costs in cardset
		var picked_cards: Array[CardData] = _get_picked_cards()
		for card_data in picked_cards:
			if randomize_card_energy_cost:
				var random_card_cost: int = rng_energy_cost.randi_range(card_cost_min, card_cost_max)
				card_data.set_card_energy_cost(random_card_cost)
			if randomize_card_energy_cost_until_combat:
				var random_card_cost: int = rng_energy_cost.randi_range(card_cost_min, card_cost_max)
				card_data.set_card_energy_cost_until_combat(random_card_cost)
			if randomize_card_energy_cost_until_played:
				var random_card_cost: int = rng_energy_cost.randi_range(card_cost_min, card_cost_max)
				card_data.set_card_energy_cost_until_played(random_card_cost)
			if randomize_card_energy_cost_until_turn:
				var random_card_cost: int = rng_energy_cost.randi_range(card_cost_min, card_cost_max)
				card_data.set_card_energy_cost_until_turn(random_card_cost)
