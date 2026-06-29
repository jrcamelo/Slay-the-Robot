extends BaseAction

const STATUS_GRIT := "status_effect_grit"

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.HEALTH_AMOUNT]

func _get_editor_description() -> String:
	return "Applies HP loss directly, bypassing barrier, shield, and attack/damage interceptors."

func perform_action() -> void:
	var resolved_targets: Array[BaseCombatant] = get_adjusted_action_targets()
	if resolved_targets.is_empty():
		var fallback_target: BaseCombatant = parent_combatant
		if fallback_target == null and card_play_request != null and card_play_request.card_data != null:
			fallback_target = Global.get_card_owner_player(card_play_request.card_data)
		if fallback_target != null:
			resolved_targets = [fallback_target]

	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(resolved_targets)
	for action_interceptor_processor in action_interceptor_processors:
		var target: BaseCombatant = action_interceptor_processor.target
		if target == null or not target.is_alive():
			continue

		var health_loss_amount: int = max(0, action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.HEALTH_AMOUNT, 0))
		if health_loss_amount <= 0:
			continue

		if target is Player:
			_apply_player_hp_loss(target as Player, health_loss_amount)
			continue
		if target is Enemy:
			_apply_enemy_hp_loss(target as Enemy, health_loss_amount)

func _apply_player_hp_loss(player: Player, health_loss_amount: int) -> void:
	var current_health: int = player.get_health()
	if current_health <= 0:
		return
	var actual_loss: int = min(health_loss_amount, current_health)
	if actual_loss >= current_health and player.get_status_charges(STATUS_GRIT) > 0:
		actual_loss = max(0, current_health - 1)
		player.remove_status(STATUS_GRIT, 1)
	if actual_loss <= 0:
		return

	var party_member_data: PartyMemberData = player.get_party_member_data()
	if party_member_data != null:
		party_member_data.add_health(-actual_loss)
		player._sync_primary_member_state_if_needed()
		Signals.player_health_changed.emit()
	else:
		Global.player_data.add_health(-actual_loss)

func _apply_enemy_hp_loss(enemy: Enemy, health_loss_amount: int) -> void:
	var current_health: int = enemy.get_health()
	if current_health <= 0:
		return
	var actual_loss: int = min(health_loss_amount, current_health)
	if actual_loss >= current_health and enemy.get_status_charges(STATUS_GRIT) > 0:
		actual_loss = max(0, current_health - 1)
		enemy.remove_status(STATUS_GRIT, 1)
	if actual_loss <= 0:
		return

	enemy.set_health(current_health - actual_loss, enemy.get_health_max())

func _to_string() -> String:
	return "Lose Health Action: %s" % get_action_value(ActionValueRegistry.HEALTH_AMOUNT, 0)
