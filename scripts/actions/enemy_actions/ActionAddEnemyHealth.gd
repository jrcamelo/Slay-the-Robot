extends BaseAction
class_name ActionAddEnemyHealth

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.HEALTH_AMOUNT, ActionValueRegistry.HEALTH_MAX_AMOUNT]

func _get_editor_description() -> String:
	return "Heals enemy targets and can optionally scale the heal amount by the player's current energy."

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
		"multiply_health_amount_by_player_current_energy",
		"Scale Heal By Player Energy",
		"bool",
		false,
		"If true, health_amount is multiplied by the player's current energy before being applied."
	))
	return parameters

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action()

	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if not (target is Enemy):
			continue

		var health_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.HEALTH_AMOUNT, 0)
		var health_max_amount: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.HEALTH_MAX_AMOUNT, 0)
		var multiply_health_amount_by_player_current_energy: bool = action_interceptor_processor.get_shadowed_action_values("multiply_health_amount_by_player_current_energy", false)
		if multiply_health_amount_by_player_current_energy:
			health_amount *= max(0, Global.player_data.player_energy)

		(target as Enemy).add_health(health_amount, health_max_amount)

func _to_string():
	var health_amount: int = get_action_value(ActionValueRegistry.HEALTH_AMOUNT, 0)
	return "Add Enemy Health Action: %s" % health_amount
