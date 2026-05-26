## General use pick cards action that generates cardset related sub actions.
## Use this for making child cardset actions with action_data and they can use this as their parent to access picked_cards
extends ActionBasePickCards
class_name ActionPickCards

func _get_editor_relevant_value_names() -> Array[String]:
	return super()

func _get_editor_description() -> String:
	return "Prompts for or auto-selects cards, then generates child cardset actions that operate on the picked cards."

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameter_definitions: Array[Dictionary] = super()
	parameter_definitions.append(_editor_param("action_data", "Action Data", "array", [], "Additional actions generated after the card pick completes."))
	return parameter_definitions

func perform_async_action() -> void:
	_generate_child_actions()
	action_async_finished.emit()

func _generate_child_actions() -> void:
	var action_data: Array[Dictionary] = []
	
	var child_action_data: Array = get_action_value("action_data", [])
	action_data.assign(child_action_data)
	
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, targets, action_data, self)
	ActionHandler.add_actions(generated_actions)
