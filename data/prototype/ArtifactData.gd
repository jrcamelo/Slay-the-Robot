extends PrototypeData
class_name ArtifactData

@export var artifact_name: String = ""
@export var artifact_description: String = ""
@export var artifact_texture_path: String = "external/sprites/artifacts/artifact_white.png"
@export var artifact_script: Script = preload("res://scripts/artifacts/BaseArtifact.gd")
@export var artifact_counter: int = 0 # do not adjust directly
@export var artifact_counter_max: int = 1
@export var artifact_counter_reset_on_turn_start: int = -1 # the value to reset the counter to on the start of player's turn. Negative for no reset
@export var artifact_counter_reset_on_combat_end: int = -1 # the value to reset the counter to on combat end. Negative for no reset
@export var artifact_owner_party_index: int = -1
@export var artifact_owner_character_object_id: String = ""
## If enabled, incrementing the artifact's charges to max or decrementing to negative will loop the value
## around. This can in turn allow for multiple procs of artifact_max_counter_actions.
## eg counter_max of 3 with increment of 9 will trigger 3 procs, if false only 1 proc.
## Generally you'll use false for single use artifacts that can only ever trigger one time.
@export var artifact_counter_wraparound: bool = true

## The color the artifact belongs to. Mainly used for ArtifactPackData and ArtifactFilter.
@export var artifact_color_id: String = "color_white" # Artifacts are assumed common pool (white) unless otherwise specified

## If false this artifact will not show up in packs regardless of rarity
@export var artifact_appears_in_artifact_packs: bool = true

enum ARTIFACT_RARITIES {BASIC, COMMON, UNCOMMON, RARE, BOSS, SHOP, EVENT}
const STANDARD_ARTIFACT_RARITIES: Array[int] = [ARTIFACT_RARITIES.COMMON, ARTIFACT_RARITIES.UNCOMMON, ARTIFACT_RARITIES.RARE]
@export var artifact_rarity: int = ARTIFACT_RARITIES.COMMON

## Actions take when the artifact counter equals the max charge amount. See artifact_counter_wraparound.
@export var artifact_max_counter_actions: Array[Dictionary] = []

## Actions taken when the artifact is equipped.
@export var artifact_add_actions: Array[Dictionary] = []
## Actions taken when the artifact is removed.
@export var artifact_remove_actions: Array[Dictionary] = []

## Actions taken when the user right clicks the action.
@export var artifact_right_click_actions: Array[Dictionary] = []

## Validators needed to right click the action.
@export var artifact_right_click_validators: Array[Dictionary] = [
	{Scripts.VALIDATOR_PLAYER_TURN: {}},
]

### Actions that happen at the start of the player's first turn.
@export var artifact_first_turn_actions: Array[Dictionary] = []
@export var artifact_end_of_combat_actions: Array[Dictionary] = []
## Actions that happen at the start of every player's turn.
@export var artifact_turn_start_actions: Array[Dictionary] = []
@export var artifact_turn_end_actions: Array[Dictionary] = []

## sets the artifact counter to a given amount. Does not trigger artifact actions.
func set_artifact_counter(value: int) -> void:
	var new_value: int = clamp(value, 0, artifact_counter_max)
	if new_value != artifact_counter:
		artifact_counter = new_value
		Signals.artifact_counter_changed.emit(self)

## Increases the charge amount on the artifact by this amount. Will trigger counter artifact_max_counter_actions.
## See also create_artifact_counter_increment_action().
func increment_artifact_counter(increment: int) -> void:
	var proc_counter: int = 0
	var new_value: int = artifact_counter
	
	if not artifact_counter_wraparound:
		new_value = clamp(artifact_counter + increment, 0, artifact_counter_max)
		if new_value == artifact_counter_max and artifact_counter != artifact_counter_max:
			proc_counter = 1 
	else:
		if increment != 0:
			proc_counter = (artifact_counter + increment) / artifact_counter_max
			new_value = (artifact_counter + increment) % artifact_counter_max
	
	for i: int in proc_counter:
		perform_artifact_actions(artifact_max_counter_actions)
	
	set_artifact_counter(new_value)

## Helper method to cut down on code reuse. Pass in an action payload from the artifact.
## Automatically includes itself and the counter in the payload.
func perform_artifact_actions(action_data: Array[Dictionary]) -> void:
	if len(action_data) > 0:
		var player: Player = _get_artifact_owner_player()
		var card_play_request: CardPlayRequest = CardPlayRequest.new() # dummy card play request
		# You can use custom_key_names in the artifact's action payloads to convert
		# artifact_counter into a parameter of the action
		card_play_request.card_values = {
			"artifact_data": self,
			"artifact_counter": artifact_counter
		}
		
		var artifact_action_groups: Dictionary = _split_artifact_actions_by_player_target(action_data)
		var actions: Array[BaseAction] = []
		var untargeted_actions: Array[Dictionary] = artifact_action_groups["untargeted_actions"]
		if len(untargeted_actions) > 0:
			actions.append_array(ActionGenerator.create_actions(player, card_play_request, [], untargeted_actions, null))
		var player_targeted_actions: Array[Dictionary] = artifact_action_groups["player_targeted_actions"]
		if len(player_targeted_actions) > 0:
			var player_targets: Array[BaseCombatant] = []
			if player != null and player.is_alive():
				player_targets.append(player)
			elif player != null:
				# TODO: Decide whether owner-bound artifact effects should fizzle or retarget if the owner is dead.
				player_targets.append(player)
			actions.append_array(ActionGenerator.create_actions(player, card_play_request, player_targets, player_targeted_actions, null))
		ActionHandler.add_actions(actions, true)
		
		Signals.artifact_proc.emit(self)

func _split_artifact_actions_by_player_target(action_data: Array[Dictionary]) -> Dictionary:
	var player_targeted_actions: Array[Dictionary] = []
	var untargeted_actions: Array[Dictionary] = []
	for action_data_entry: Dictionary in action_data:
		for action_path: String in action_data_entry:
			var action_values: Dictionary = action_data_entry[action_path]
			var target_override: int = action_values.get("target_override", BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS)
			if target_override == BaseAction.TARGET_OVERRIDES.PLAYER:
				player_targeted_actions.append(action_data_entry)
			else:
				untargeted_actions.append(action_data_entry)
	return {
		"player_targeted_actions": player_targeted_actions,
		"untargeted_actions": untargeted_actions,
	}

## Creates an interceptable artifact increment action which is added to the action stack.
## This provides an alternate way of changing the counter in a way that can be manipulated and
## consistent with the stack, compared to increment_artifact_counter()
func create_artifact_counter_increment_action(increment_amount: int) -> void:
	var player: Player = _get_artifact_owner_player()
	var card_play_request: CardPlayRequest = CardPlayRequest.new() # dummy card play request
	var action_data: Array[Dictionary] = [{Scripts.ACTION_INCREASE_ARTIFACT_CHARGE: {}}]
	# You can use custom_key_names in the artifact's action payloads to convert
	# artifact_counter into a parameter of the action
	card_play_request.card_values = {
		"artifact_data": self,
		"artifact_charge_increase": increment_amount
	}
	
	var actions: Array[BaseAction] = ActionGenerator.create_actions(player, card_play_request, [], action_data, null)
	ActionHandler.add_actions(actions, true)

func _get_artifact_owner_player() -> Player:
	if artifact_owner_party_index >= 0:
		var owner_player: Player = Global.get_player_by_party_index(artifact_owner_party_index)
		if owner_player != null:
			return owner_player
	return Global.get_default_player_combatant()
