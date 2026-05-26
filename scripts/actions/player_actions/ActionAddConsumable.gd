# attempts to grant a consumable to the player, if slots are available
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.CONSUMABLE_BLACKLIST_IDS, ActionValueRegistry.CONSUMABLE_OBJECT_ID, ActionValueRegistry.CONSUMABLE_WHITELIST_IDS, ActionValueRegistry.FILL_ALL_SLOTS, ActionValueRegistry.RANDOM_CONSUMABLE]

func _get_editor_description() -> String:
	return "Adds a consumable to the player, either directly or by random selection with whitelist and blacklist support."

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	
	for action_interceptor_processor in action_interceptor_processors:
		var consumable_object_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CONSUMABLE_OBJECT_ID, "")
		var fill_all_slots: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.FILL_ALL_SLOTS, false)	# fills all empty slots
		# for random selection
		var random_consumable: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.RANDOM_CONSUMABLE, false)	# use a random consumable from the pool of them
		var consumable_whitelist_ids: Array[String] = []
		consumable_whitelist_ids.assign(action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CONSUMABLE_WHITELIST_IDS, []))
		var consumable_blacklist_ids: Array[String] = []
		consumable_blacklist_ids.assign(action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CONSUMABLE_BLACKLIST_IDS, []))
		
		var slot_count: int = 1
		
		if fill_all_slots:
			slot_count = Global.player_data.get_empty_consumable_slot_count()
		
		for _i in slot_count:
			if random_consumable:
				var rng_consumables: RandomNumberGenerator = Global.player_data.get_player_rng("rng_consumables")

				consumable_object_id = Random.get_random_consumable_object_id(rng_consumables, consumable_whitelist_ids, consumable_blacklist_ids)
			
			Signals.add_consumable_requested.emit(consumable_object_id)

func _to_string():
	var consumable_object_id: String = get_action_value(ActionValueRegistry.CONSUMABLE_OBJECT_ID, "")
	return "Add Consumable Action: " + consumable_object_id
