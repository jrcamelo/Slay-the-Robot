# Validator for checking whether the acting combatant has a specific status effect.
# For cards, this resolves to the card owner. For action validators, it resolves to the parent combatant.
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Playing Character Has Status Effect"

func _get_editor_description() -> String:
	return "Checks the acting combatant's status charges. For cards this means the owner; for enemy actions it means the enemy performing the action."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("status_effect_object_id", "Status Effect ID", "string", "", "Status effect object id to inspect."))
	parameters.append(_editor_param("operator", "Operator", "enum", ">", "Comparison operator.", {"options": ["<", "<=", ">", ">=", "==", "!="]}))
	parameters.append(_editor_param("comparison_value", "Comparison Value", "int", 0, "Charge amount to compare against."))
	return parameters

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var status_effect_object_id: String = _get_validator_value("status_effect_object_id", values, action, "")
	var operator: String = _get_validator_value("operator", values, action, ">")
	var comparison_value: int = _get_validator_value("comparison_value", values, action, 0)
	var combatant: BaseCombatant = _get_context_source_combatant(card_data, action)

	if combatant == null:
		return false
	if status_effect_object_id == "":
		push_error("Missing status_effect_object_id")
		return false

	var status_charges: int = combatant.get_status_charges(status_effect_object_id)
	return _compare(status_charges, comparison_value, operator)
