## Defines the abstract interface of an action, which can be mapped to whenever a card needs to do
## something or some other effect needs to be invoked.
## These are simple actions like attacking, drawing cards, etc, that can be reused between many
## different parts of the code.
## They will be performed in order by ActionHandler.
extends RefCounted
class_name BaseAction

const EDITOR_CONTEXT_CARD_PLAY_ACTIONS := "card_play_actions"
const EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS := "card_trigger_actions"
const EDITOR_CONTEXT_ACTION_CHILDREN := "action_children"
const EDITOR_CONTEXT_ENEMY_ACTIONS := "enemy_custom_actions"
const EDITOR_CONTEXT_WORLD_ACTIONS := "world_actions"
const EDITOR_CONTEXT_REWARD_ACTIONS := "reward_actions"
const EDITOR_CONTEXT_SHOP_ACTIONS := "shop_actions"
const EDITOR_CONTEXT_RUN_ACTIONS := "run_actions"

## The owner of the action. Can be null.
var parent_combatant: BaseCombatant = null
## The card play that is responsible for the action. Can be null.
var card_play_request: CardPlayRequest = null
## The list of targets that this action will be invoked on, can be empty.
## NOTE: This is a raw list without filtering. Generally you should never directly touch this value.
## Either use get_adjusted_action_targets(), or better: use the result of _intercept_action().
var targets: Array[BaseCombatant] = []
## Any parameters used by the action itself. For each parameter, value handling happens in a hierarchy
## where the first entry found will be used.
## of Action -> CardPlayRequest -> CardData -> Default Value
## See: BaseAction.get_action_value() which applies this hierarchy,
## and ActionInterceptorProcessor.get_shadowed_action_values() which builds a layer on top of it.
var values: Dictionary[String, Variant] = {}
## Time this action takes to happen before the next action in the stack is invoked after this
## one is finished. Can be zero for instant or non blocking actions. See also: is_instant_action()
var time_delay: float = 0.0
## Optional tags that can be applied to an action. These are useful for if you want an interceptor
## to be able to discriminate actions of the same type.
var action_tags: Array[String] = []
## The action that directly generated this one. Can be null.
var parent_action: BaseAction = null

signal action_async_finished	# allows for async callbacks

## If target_override is provided in values, this can be used to redirect the action's target
## regardless of targets supplied.
## This allows for a card to target multiple combatants with different actions
enum TARGET_OVERRIDES {
	SELECTED_TARGETS,	# default. This will use the targets fed into the action
	PARENT,	# the parent combatant of the action is used as the target
	PLAYER,	# a single player target. Uses selected targets if supplied, otherwise the first living player.
	ALL_COMBATANTS, # enemies and players
	ALL_ENEMIES,
	LEFTMOST_ENEMY,	# the target fallback will be leftmost if possible
	ENEMY_ID,	# the targets will be enemies with given object ids
	RANDOM_ENEMY	# a random existing enemy is chosen
	}

func get_editor_metadata() -> Dictionary:
	return {
		"kind": "action",
		"script_type": get_editor_script_type(),
		"display_name": _get_editor_display_name(),
		"description": _get_editor_description(),
		"contexts": _get_editor_contexts(),
		"parameters": _get_editor_parameter_definitions(),
	}

func get_editor_script_type() -> String:
	return "action"

func _get_editor_display_name() -> String:
	var script := get_script() as Script
	if script == null:
		return "Action"
	var file_name: String = script.resource_path.get_file().trim_suffix(".gd")
	file_name = file_name.trim_prefix("Action")
	return file_name.to_snake_case().replace("_", " ").capitalize()

func _get_editor_description() -> String:
	return ""

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
	]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	return []

func _get_editor_relevant_value_names() -> Array[String]:
	return []

func _get_editor_common_parameter_definitions(parameter_names: Array[String]) -> Array[Dictionary]:
	var parameter_definitions: Array[Dictionary] = []
	for parameter_name: String in parameter_names:
		var parameter_definition: Dictionary = _get_editor_common_parameter_definition(parameter_name)
		if not parameter_definition.is_empty():
			parameter_definitions.append(parameter_definition)
	return parameter_definitions

func _get_editor_common_parameter_definition(parameter_name: String) -> Dictionary:
	match parameter_name:
		"time_delay":
			return _editor_param("time_delay", "Time Delay", "float", 0.0, "Delay before the next action executes.")
		"action_tags":
			return _editor_param("action_tags", "Action Tags", "string_array", [], "Optional tags used by interceptors and editor tooling.")
		"action_short_circuits":
			return _editor_param("action_short_circuits", "Short Circuits", "bool", false, "Skips the action when combat is already over.")
		"target_override":
			return _editor_param(
				"target_override",
				"Target Override",
				"enum",
				TARGET_OVERRIDES.SELECTED_TARGETS,
				"Overrides how the action resolves its targets.",
				{
					"options": [
						{"label": "Selected Targets", "value": TARGET_OVERRIDES.SELECTED_TARGETS},
						{"label": "Parent", "value": TARGET_OVERRIDES.PARENT},
						{"label": "Player", "value": TARGET_OVERRIDES.PLAYER},
						{"label": "All Combatants", "value": TARGET_OVERRIDES.ALL_COMBATANTS},
						{"label": "All Enemies", "value": TARGET_OVERRIDES.ALL_ENEMIES},
						{"label": "Leftmost Enemy", "value": TARGET_OVERRIDES.LEFTMOST_ENEMY},
						{"label": "Enemy ID", "value": TARGET_OVERRIDES.ENEMY_ID},
						{"label": "Random Enemy", "value": TARGET_OVERRIDES.RANDOM_ENEMY},
					]
				}
			)
		_:
			return {}

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

func init(_parent_combatant: BaseCombatant = null, _card_play_request: CardPlayRequest = null, _targets: Array[BaseCombatant] = [], _values: Dictionary[String, Variant] = {}, _parent_action: BaseAction = null):
	# constructor method for the action
	parent_combatant = _parent_combatant
	card_play_request = _card_play_request
	targets = _targets
	values = _values
	time_delay = get_action_value("time_delay", 0.0)
	action_tags.assign(get_action_value("action_tags", []))
	parent_action = _parent_action

### Override

## The logic of the action should be performed here.
## For async actions, see perform_async_action() and BaseAsyncAction
func perform_action() -> void:
	# 1) _intercept_action()
	# 2) iterate over results
	# 3) get shadowed values
	# 4) perform action logic
	breakpoint

## See BaseAsyncAction
func perform_async_action() -> void:
	# override this
	# if the action requires an async request, perform it here then emit the action_async_finished signal
	action_async_finished.emit()

func is_instant_action() -> bool:
	# optional override
	# useful for forcing some actions to process instantly regardless of time_delay
	return false

## Override in subclasses to provide default values
## Short cirtcuited actions will be ignored by ActionHandler if combat is over (no enemies)
## this can be bypassed with the given flag for individual actions if desired.
## This is useful for things like attacks, blocking, and card picking to be ignored entirely since
## even an attack action with no targets produces a delay which looks bad,
## while leaving other things like a healing or upgrade actions untouched.
func is_action_short_circuited() -> bool:
	return get_action_value("action_short_circuits", false)

func _to_string():
	# Optional Override
	# Useful for print() debugging
	return "Base Action"

### Keep

func is_async_action() -> bool:
	# override true if the action is async and requires some kind of user input or indefinite wait
	# ActionHandler will stop until action_async_finished is emitted
	# See BaseAsyncAction
	return false

func get_adjusted_action_targets() -> Array[BaseCombatant]:
	# Gets the targets of the action at time of execution, based on the supplied targets and the target override
	# this will also validate if any of the targets are alive
	var target_override: int = get_action_value("target_override", TARGET_OVERRIDES.SELECTED_TARGETS)
	var returned_targets: Array[BaseCombatant] = []
	
	match target_override:
		TARGET_OVERRIDES.SELECTED_TARGETS:
			for target in targets:
				if is_instance_valid(target):
					if target.is_alive():
						returned_targets.append(target)
		TARGET_OVERRIDES.PARENT:
			return [parent_combatant]
		TARGET_OVERRIDES.PLAYER:
			for target in targets:
				if is_instance_valid(target) and target is Player and target.is_alive():
					if parent_combatant is Enemy and not (target as Player).is_targetable_by_enemy():
						continue
					returned_targets.append(target)
			if len(returned_targets) == 0:
				var player: Player = Global.get_primary_living_player()
				if parent_combatant is Enemy:
					player = Global.get_primary_targetable_living_player()
				if player != null:
					returned_targets.append(player)
		TARGET_OVERRIDES.ALL_COMBATANTS:
			for player in Global.get_living_players():
				if player.is_alive():
					returned_targets.append(player)
			for enemy in Global.get_tree().get_nodes_in_group("enemies"):
				if enemy.is_alive():
					returned_targets.append(enemy)
		TARGET_OVERRIDES.ALL_ENEMIES:
			for enemy in Global.get_tree().get_nodes_in_group("enemies"):
				if enemy.is_alive():
					returned_targets.append(enemy)
		TARGET_OVERRIDES.LEFTMOST_ENEMY:
			var enemy: Enemy = Global.get_tree().get_first_node_in_group("enemies")
			if enemy != null:
				returned_targets.append(enemy)
		TARGET_OVERRIDES.ENEMY_ID:
			var enemies: Array[Node] = Global.get_tree().get_nodes_in_group("enemies")
			var enemy_ids: Array[String] = []
			enemy_ids.assign(get_action_value("enemy_ids", []))
			for enemy: Enemy in enemies:
				if enemy_ids.has(enemy.enemy_data.object_id):
					returned_targets.append(enemy)
		TARGET_OVERRIDES.RANDOM_ENEMY:
			var enemies: Array[Node] = Global.get_tree().get_nodes_in_group("enemies")
			
			var rng_targeting: RandomNumberGenerator = Global.player_data.get_player_rng("rng_targeting")
			
			enemies = Random.shuffle_array(rng_targeting, enemies)
			if len(enemies) > 0:
				returned_targets.append(enemies[0])
			
	return returned_targets

func get_action_value(key: String, default_value: Variant) -> Variant:
	# searches down an action's value hierarchy to find a corresponding value
	# returns given given default if none found
	# if a custom key is used it will be converted into a proper key then searched
	var custom_action_value_keys: Dictionary = values.get("custom_key_names", {})	# allows for having cards/actions use custom key names that convert to regular action key names. Useful for having cards with 2 of the same action but different values
	var key_name: String = custom_action_value_keys.get(key, key)
	if values.has(key_name):
		return values[key_name]
	if card_play_request != null:
		if card_play_request.card_values.has(key_name):
			return card_play_request.card_values.get(key_name, default_value)
		
		if card_play_request.card_data != null:
			return card_play_request.card_data.card_values.get(key_name, default_value)
	if Global.player_data.player_values.has(key_name):
		return Global.player_data.player_values.get(key_name, default_value)
	return default_value

## This method is used during perform_action() or perform_async_action() to gather the combination
## of this action and its targets, parents, and interceptors
## and perform any modifications/logic that those combinations would produce.
## Returns an array of intercepted action results for each target, which will contain information
## on how to process the actual action for that target.
## See ActionInterceptorProcessor, BaseActionInterceptor, and ActionInterceptorData and for more details.
## NOTE: If a target does NOT appear in the returned array, it likely means that interceptor chain
## was rejected or the target is dead.
## NOTE: preview_mode is used to calculate things like enemy inent and displaying card values
## after modifiers by using dummy actions which are then intercepted. Interceptors that produce
## side effects should check for preview_mode to ensure this does not happen.
## NOTE: Pass [] or [null] for _targets if you want interception processed only for the parent. This
## is useful for actions like adding money where you still want things to affect it but they
## have no actual targets. In which case an array of a single ActionInterceptorProcessor will be
## returned.
func _intercept_action(_targets: Array[BaseCombatant] = get_adjusted_action_targets(), preview_mode: bool = false) -> Array[ActionInterceptorProcessor]:
	
	var accepted_interceptor_processors: Array[ActionInterceptorProcessor] = []	# the returned interceptor chains
	
	# get the targets to process
	# pass [] or [null] for _targets if you want interception processed only for the parent
	var interceptor_targets: Array[BaseCombatant] = []
	if len(_targets) == 0:
		interceptor_targets = [null] 	# there must always be a target, even if its null
	else:
		interceptor_targets = _targets
	
	# iterate over each target, processing a chain of interceptors
	for target in interceptor_targets:
		var action_interceptor_processor: ActionInterceptorProcessor = ActionInterceptorProcessor.new(self, target) 
		var interceptor_chain_accepted: bool = action_interceptor_processor.process_interceptor_chain(preview_mode)
		# only accepted chains will be returned for processing
		if interceptor_chain_accepted:
			accepted_interceptor_processors.append(action_interceptor_processor)
	
	return accepted_interceptor_processors
