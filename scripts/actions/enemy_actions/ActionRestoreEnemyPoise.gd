extends BaseAction
class_name ActionRestoreEnemyPoise

func _get_editor_description() -> String:
	return "Restores enemy poise, either by setting it to full or by applying direct poise changes."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	return [
		_editor_param("poise_amount", "Poise Amount", "int", 0, "Poise to add or remove when not filling to max."),
		_editor_param("poise_max_amount", "Max Poise Amount", "int", 0, "Max poise to add or remove when not filling to max."),
		_editor_param("fill_to_max", "Fill To Max", "bool", true, "If true, sets current poise to the target's current max poise."),
	]

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()

	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if not (target is Enemy):
			continue

		var target_enemy: Enemy = target
		var fill_to_max: bool = action_interceptor_processor.get_shadowed_action_values("fill_to_max", true)
		if fill_to_max:
			target_enemy.set_poise(target_enemy.get_poise_max(), target_enemy.get_poise_max())
			continue

		var poise_amount: int = action_interceptor_processor.get_shadowed_action_values("poise_amount", 0)
		var poise_max_amount: int = action_interceptor_processor.get_shadowed_action_values("poise_max_amount", 0)
		target_enemy.add_poise(poise_amount, poise_max_amount)

func _to_string():
	return "Restore Enemy Poise Action"
