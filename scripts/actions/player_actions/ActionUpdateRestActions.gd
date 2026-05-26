## Enables/disables rest actions to player
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.ADD_REST_ACTION_OBJECT_IDS, ActionValueRegistry.REMOVE_REST_ACTION_OBJECT_IDS]

func _get_editor_description() -> String:
	return "Enables or disables rest actions for the current run."

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor: ActionInterceptorProcessor in action_interceptor_processors:
		# adding rest actions
		var add_rest_action_object_ids: Array[String] = []
		add_rest_action_object_ids.assign(action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.ADD_REST_ACTION_OBJECT_IDS, []))
		
		for rest_action_object_id: String in add_rest_action_object_ids:
			Global.player_data.enable_rest_action(rest_action_object_id)
		
		# removing rest actions
		var remove_rest_action_object_ids: Array[String] = []
		remove_rest_action_object_ids.assign(action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.REMOVE_REST_ACTION_OBJECT_IDS, []))
		
		for rest_action_object_id: String in remove_rest_action_object_ids:
			Global.player_data.disable_rest_action(rest_action_object_id)
		
