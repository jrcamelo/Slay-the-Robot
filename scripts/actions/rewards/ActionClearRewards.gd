# Action which forces a clearing of combat rewards
# Can be specified to clear all rewards or a given reward group
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.REWARD_GROUP]

func _get_editor_description() -> String:
	return "Clears all rewards or only a specific reward group from the reward overlay."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_REWARD_ACTIONS,
		EDITOR_CONTEXT_WORLD_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
	]

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor in action_interceptor_processors:
		var reward_group: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.REWARD_GROUP, -1) # -1 for all rewards
		Signals.reward_clear_requested.emit(reward_group)

func _to_string():
	return "Clear Reward Action"
