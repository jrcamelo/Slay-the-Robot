extends BaseAction
class_name ActionReduceEnemyMaxHealth

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.HEALTH_MAX_AMOUNT]

func _get_editor_description() -> String:
	return "Reduces an enemy's max health and clamps current health down to the new maximum. It can also copy the parent enemy's current max health onto the target."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param(
		ActionValueRegistry.HEALTH_MAX_AMOUNT,
		"Max Health Reduction",
		"int",
		10,
		"Amount to subtract from the target enemy's max health."
	))
	parameters.append(_editor_param(
		"copy_parent_current_health_max",
		"Copy Parent Current Max Health",
		"bool",
		false,
		"If true, the target enemy's current and max health are both set to the parent enemy's current max health instead of subtracting a fixed amount."
	))
	return parameters

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()

	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if not (target is Enemy):
			continue

		var target_enemy: Enemy = target
		var next_health_max: int = target_enemy.get_health_max()
		var copy_parent_current_health_max: bool = action_interceptor_processor.get_shadowed_action_values("copy_parent_current_health_max", false)

		if copy_parent_current_health_max:
			if not (parent_combatant is Enemy):
				continue
			next_health_max = max(1, (parent_combatant as Enemy).get_health_max())
		else:
			var health_max_reduction: int = max(0, action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.HEALTH_MAX_AMOUNT, 0))
			if health_max_reduction <= 0:
				continue
			next_health_max = max(1, target_enemy.get_health_max() - health_max_reduction)

		var next_health: int = min(target_enemy.get_health(), next_health_max)
		target_enemy.set_health(next_health, next_health_max)

func _to_string():
	var health_max_reduction: int = get_action_value(ActionValueRegistry.HEALTH_MAX_AMOUNT, 0)
	return "Reduce Enemy Max Health Action: %s" % health_max_reduction
