## Performs if/else logic, generating actions if all validations pass.
## NOTE: This does not prevent a card being played. See: CardData.card_play_validators
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return []

func _get_editor_description() -> String:
	return "Runs validators at action time and generates either the passed or failed child actions."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	return [
		_editor_param("passed_action_data", "Passed Actions", "array", [], "Additional actions generated when every validator passes."),
		_editor_param("failed_action_data", "Failed Actions", "array", [], "Additional actions generated when any validator fails."),
	]

func perform_action():
	var action_data: Array[Dictionary] = []
	if _validate():
		var passed_action_data = get_action_value("passed_action_data", [])
		for passed_action in passed_action_data:
			action_data.append(passed_action)
	else:
		var failed_action_data = get_action_value("failed_action_data", [])
		for failed_action in failed_action_data:
			action_data.append(failed_action)
	
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, targets, action_data, self)
	generated_actions.reverse()
	ActionHandler.add_actions(generated_actions)

func _validate() -> bool:
	# checks if action passes all validators
	var validators: Array[Dictionary] = []
	validators.assign(get_action_value("validator_data", []))
	return Global.validate(validators, card_play_request.card_data, self)

func is_instant_action() -> bool:
	return true
