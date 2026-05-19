## Action that forces targeted enemies to cycle their attack intent
extends BaseAction

func _get_editor_description() -> String:
	return "Forces targeted enemies to reroll and refresh their intent."

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
		if not target.is_alive():
			continue
		if not target is Enemy:
			continue
			
		var enemy: Enemy = target # typecast
		enemy.cycle_enemy_intent()

func is_action_short_circuited():
	return get_action_value("action_short_circuits", true)

func _to_string():
	return "Cycle Enemy Intent Action"
