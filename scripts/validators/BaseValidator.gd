## Abstract validation script, override _validation() to implement and call validate() externally.
## These scripts are mainly used in Card, CardFilter, and ActionValidator to perform data
## driven logical operations without strict hardcoding.

## These can be attached to a card to prevent it from
## being manually played by the player, restrict certain card actions, or highlight cards
## See CardData.card_play_validators and card_glow_validators.

## These are not stored, and instead created and destroyed as needed
extends RefCounted
class_name BaseValidator

const EDITOR_CONTEXT_CARD_PLAY_VALIDATORS := "card_play_validators"
const EDITOR_CONTEXT_CARD_GLOW_VALIDATORS := "card_glow_validators"
const EDITOR_CONTEXT_ACTION_VALIDATORS := "action_validator"
const EDITOR_CONTEXT_CARD_FILTER := "card_filter"
const EDITOR_CONTEXT_CARD_PICK := "card_pick"

### Override

## Override this for validation logic
## Depending on type of validation, card data or action can be null
## Generally Card/CardFilter will use _card_data and Actions use _action.
## Other sources will use neither and likely pass the needed references into values or derive
## from global state.
func _validation(_card_data: CardData, _action: BaseAction, _values: Dictionary[String, Variant]) -> bool:
	return true

func get_editor_metadata() -> Dictionary:
	return {
		"kind": "validator",
		"script_type": "validator",
		"display_name": _get_editor_display_name(),
		"description": _get_editor_description(),
		"contexts": _get_editor_contexts(),
		"parameters": _get_editor_parameter_definitions(),
	}

func _get_editor_display_name() -> String:
	var script := get_script() as Script
	if script == null:
		return "Validator"
	var file_name: String = script.resource_path.get_file().trim_suffix(".gd")
	file_name = file_name.trim_prefix("Validator")
	return file_name.to_snake_case().replace("_", " ").capitalize()

func _get_editor_description() -> String:
	return ""

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
		EDITOR_CONTEXT_CARD_FILTER,
		EDITOR_CONTEXT_CARD_PICK,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	return [
		_editor_param(
			"invert_validation",
			"Invert Validation",
			"bool",
			false,
			"Negates the final validator result."
		)
	]

func _editor_param(
	name: String,
	label: String,
	value_type: String,
	default_value: Variant,
	description: String = "",
	extra: Dictionary = {}
) -> Dictionary:
	var parameter_data: Dictionary = {
		"name": name,
		"label": label,
		"value_type": value_type,
		"default_value": default_value,
		"description": description,
	}
	for key: Variant in extra.keys():
		parameter_data[key] = extra[key]
	return parameter_data

### Keep

## External wrapper for calling validation. Allows for inverting validation result via flag for NOT
## style logic
func validate(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var invert_validation: bool = values.get("invert_validation", false)
	return _validation(card_data, action, values) != invert_validation

## Internal helper method for running a generic comparison. Typically
## only numbers should be passed into this for values; use other types at your own risk.
func _compare(value: Variant, comparison_value: Variant, operator: String = "<"):
	match operator:
		"<":	return value < comparison_value
		"<=":	return value <= comparison_value
		">":	return value > comparison_value
		">=":	return value >= comparison_value
		"==":	return value == comparison_value
		"!=":	return value != comparison_value
		_:	return value < comparison_value

## Runs down the key:value values passed into the validator. If an action is passed into the validator
## it will attempt to use its values first
func _get_validator_value(key_name: String, values: Dictionary[String, Variant], action: BaseAction, default_value: Variant) -> Variant:
	if action != null:
		if values.has(key_name):
			return values[key_name]
		return action.get_action_value(key_name, default_value)
	else:
		return values.get(key_name, default_value)

func _get_context_source_combatant(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant] = {}) -> BaseCombatant:
	if values.has("_source_combatant"):
		return values["_source_combatant"]
	if action != null:
		if action.parent_combatant != null:
			return action.parent_combatant
		if action.card_play_request != null and action.card_play_request.card_data != null:
			return Global.get_card_owner_player(action.card_play_request.card_data)
	if card_data != null:
		return Global.get_card_owner_player(card_data)
	return null

func _get_context_targets(action: BaseAction, values: Dictionary[String, Variant] = {}) -> Array[BaseCombatant]:
	if values.has("_targets"):
		var explicit_targets: Array[BaseCombatant] = []
		for target in values["_targets"]:
			if target is BaseCombatant:
				explicit_targets.append(target)
		return explicit_targets
	if action == null:
		return []
	if action.card_play_request != null and action.card_play_request.selected_target != null:
		return [action.card_play_request.selected_target]
	return action.get_adjusted_action_targets()
