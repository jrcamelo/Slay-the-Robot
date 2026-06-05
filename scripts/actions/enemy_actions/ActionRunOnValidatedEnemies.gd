extends BaseAction
class_name ActionRunOnValidatedEnemies

func _get_editor_description() -> String:
	return "Filters living enemies with validators, optionally randomizes the result, then runs child actions on the matched targets."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	return [
		_editor_param("action_data", "Action Data", "array", [], "Actions generated for the matched enemies."),
		_editor_param("validator_data", "Validator Data", "validator_array", [], "Validators used to filter living enemies."),
		_editor_param("exclude_parent", "Exclude Parent", "bool", false, "Skips the acting enemy when collecting targets."),
		_editor_param("random_selection", "Random Selection", "bool", false, "Shuffles matching enemies before truncating them."),
		_editor_param("max_target_amount", "Max Target Amount", "int", -1, "Maximum matched enemies to keep. Negative means all."),
	]

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])

	for action_interceptor_processor in action_interceptor_processors:
		var action_data: Array[Dictionary] = []
		action_data.assign(action_interceptor_processor.get_shadowed_action_values("action_data", []))
		if action_data.is_empty():
			continue

		var validator_data: Array[Dictionary] = []
		validator_data.assign(action_interceptor_processor.get_shadowed_action_values("validator_data", []))
		var exclude_parent: bool = action_interceptor_processor.get_shadowed_action_values("exclude_parent", false)
		var random_selection: bool = action_interceptor_processor.get_shadowed_action_values("random_selection", false)
		var max_target_amount: int = action_interceptor_processor.get_shadowed_action_values("max_target_amount", -1)

		var matched_enemies: Array[BaseCombatant] = []
		for node: Node in Global.get_tree().get_nodes_in_group("enemies"):
			var enemy: Enemy = node
			if not enemy.is_alive():
				continue
			if exclude_parent and enemy == parent_combatant:
				continue
			if not _passes_validators(enemy, validator_data):
				continue
			matched_enemies.append(enemy)

		if random_selection and matched_enemies.size() > 1:
			var rng_enemy_targeting: RandomNumberGenerator = Global.player_data.get_player_rng("rng_enemy_targeting")
			matched_enemies = Random.shuffle_array(rng_enemy_targeting, matched_enemies)

		if max_target_amount >= 0 and matched_enemies.size() > max_target_amount:
			matched_enemies = matched_enemies.slice(0, max_target_amount)

		if matched_enemies.is_empty():
			continue

		var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, matched_enemies, action_data, self)
		ActionHandler.add_actions(generated_actions)

func _passes_validators(enemy: Enemy, validators: Array[Dictionary]) -> bool:
	for validator_entry: Dictionary in validators:
		for validator_token: String in validator_entry.keys():
			var validator_script_asset: Script = Scripts.resolve_script(validator_token)
			if validator_script_asset == null:
				push_error("ActionRunOnValidatedEnemies failed to resolve validator %s" % validator_token)
				return false
			var validator: BaseValidator = validator_script_asset.new()
			var validator_values: Dictionary[String, Variant] = {}
			validator_values.assign(validator_entry[validator_token])
			validator_values["_source_combatant"] = parent_combatant
			validator_values["_targets"] = [enemy]
			if not validator.validate(card_play_request.card_data if card_play_request != null else null, self, validator_values):
				return false
	return true

func is_instant_action() -> bool:
	return true

func _to_string():
	return "Run On Validated Enemies Action"
