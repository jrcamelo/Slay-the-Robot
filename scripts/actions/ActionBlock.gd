# Standard block action
# NOTE: If action does nothing, ensure a target override of PARENT is provded
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.BLOCK]

func _get_editor_description() -> String:
	return "Adds block to each resolved target, or to the parent when Target Override is set to Parent."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()
	
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null:
			return

		var block_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.BLOCK, 0)
		target.add_block(block_amount)

func _to_string():
	var block: int = get_action_value(ActionValueRegistry.BLOCK, 0)
	return "Block Action: " + str(block)
