## Forces the visiting of a location, given a location id. This is primarily used by both UI
## but can be invoked elsewhere.
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.AUTOSAVE_BEFORE_VISIT, ActionValueRegistry.LOCATION_ID]

func _get_editor_description() -> String:
	return "Forces the player to visit a location by id, optionally autosaving first."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_WORLD_ACTIONS,
		EDITOR_CONTEXT_RUN_ACTIONS,
	]

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor: ActionInterceptorProcessor in action_interceptor_processors:
		var location_id: String = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.LOCATION_ID, "")
		var location_data: LocationData = Global.get_location_data(location_id)
		
		# set player location to new location
		Global.player_data.player_location_id = location_id
		# null out shop data
		Global.player_data.player_shop_data = null
		
		# autosave
		var autosave_before_visit: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.AUTOSAVE_BEFORE_VISIT, true)
		if autosave_before_visit:
			FileLoader.autosave()
			
		
		# simulate selecting the location, triggering a travel to it
		Signals.map_location_selected.emit(location_data)
