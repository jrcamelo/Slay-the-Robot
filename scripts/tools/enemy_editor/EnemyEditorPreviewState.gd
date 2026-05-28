@tool
extends RefCounted
class_name EnemyEditorPreviewState

var planned_stage_id: String = ""
var previous_executed_stage_id: String = ""
var turn_count: int = 1
var planned_stage_started_turn_count: int = 1
var stage_id_to_execution_count: Dictionary[String, int] = {}

var enemy_health: int = -1
var enemy_health_max: int = -1
var enemy_poise: int = -1
var enemy_poise_max: int = -1
var enemy_type: int = -1
var enemy_is_minion: bool = false
var enemy_status_effects: Dictionary[String, int] = {}

var player_energy: int = 0
var player_party_members: Array[Dictionary] = []
var living_ally_enemy_states: Array[Dictionary] = []

var difficulty_level: int = 0
var random_seed: int = 0
var cached_random_target_signature: String = ""
var cached_random_target_party_member_indices: Array[int] = []

func _init(initial_values: Dictionary = {}) -> void:
	apply_dictionary(initial_values)

func apply_dictionary(initial_values: Dictionary) -> void:
	for property_name: String in initial_values.keys():
		if property_name in [
			"planned_stage_id",
			"previous_executed_stage_id",
			"turn_count",
			"planned_stage_started_turn_count",
			"stage_id_to_execution_count",
			"enemy_health",
			"enemy_health_max",
			"enemy_poise",
			"enemy_poise_max",
			"enemy_type",
			"enemy_is_minion",
			"enemy_status_effects",
			"player_energy",
			"player_party_members",
			"living_ally_enemy_states",
			"difficulty_level",
			"random_seed",
			"cached_random_target_signature",
			"cached_random_target_party_member_indices",
		]:
			set(property_name, initial_values[property_name])

func ensure_defaults(enemy_data: EnemyData) -> void:
	if enemy_data == null:
		return
	if planned_stage_id == "":
		planned_stage_id = enemy_data.opening_stage_id
	if enemy_health < 0:
		enemy_health = enemy_data.enemy_health
	if enemy_health_max < 0:
		enemy_health_max = enemy_data.enemy_health_max
	if enemy_poise < 0:
		enemy_poise = enemy_data.enemy_poise
	if enemy_poise_max < 0:
		enemy_poise_max = enemy_data.enemy_poise_max
	if enemy_type < 0:
		enemy_type = enemy_data.enemy_type
	enemy_is_minion = enemy_data.enemy_is_minion if enemy_is_minion == false and enemy_data.enemy_is_minion else enemy_is_minion
	if planned_stage_started_turn_count <= 0:
		planned_stage_started_turn_count = 1
	if turn_count <= 0:
		turn_count = 1

func duplicate_state() -> EnemyEditorPreviewState:
	var duplicated_state := EnemyEditorPreviewState.new()
	duplicated_state.planned_stage_id = planned_stage_id
	duplicated_state.previous_executed_stage_id = previous_executed_stage_id
	duplicated_state.turn_count = turn_count
	duplicated_state.planned_stage_started_turn_count = planned_stage_started_turn_count
	duplicated_state.stage_id_to_execution_count = stage_id_to_execution_count.duplicate(true)
	duplicated_state.enemy_health = enemy_health
	duplicated_state.enemy_health_max = enemy_health_max
	duplicated_state.enemy_poise = enemy_poise
	duplicated_state.enemy_poise_max = enemy_poise_max
	duplicated_state.enemy_type = enemy_type
	duplicated_state.enemy_is_minion = enemy_is_minion
	duplicated_state.enemy_status_effects = enemy_status_effects.duplicate(true)
	duplicated_state.player_energy = player_energy
	duplicated_state.player_party_members = player_party_members.duplicate(true)
	duplicated_state.living_ally_enemy_states = living_ally_enemy_states.duplicate(true)
	duplicated_state.difficulty_level = difficulty_level
	duplicated_state.random_seed = random_seed
	duplicated_state.cached_random_target_signature = cached_random_target_signature
	duplicated_state.cached_random_target_party_member_indices = cached_random_target_party_member_indices.duplicate(true)
	return duplicated_state

func to_dictionary() -> Dictionary:
	return {
		"planned_stage_id": planned_stage_id,
		"previous_executed_stage_id": previous_executed_stage_id,
		"turn_count": turn_count,
		"planned_stage_started_turn_count": planned_stage_started_turn_count,
		"stage_id_to_execution_count": stage_id_to_execution_count.duplicate(true),
		"enemy_health": enemy_health,
		"enemy_health_max": enemy_health_max,
		"enemy_poise": enemy_poise,
		"enemy_poise_max": enemy_poise_max,
		"enemy_type": enemy_type,
		"enemy_is_minion": enemy_is_minion,
		"enemy_status_effects": enemy_status_effects.duplicate(true),
		"player_energy": player_energy,
		"player_party_members": player_party_members.duplicate(true),
		"living_ally_enemy_states": living_ally_enemy_states.duplicate(true),
		"difficulty_level": difficulty_level,
		"random_seed": random_seed,
		"cached_random_target_signature": cached_random_target_signature,
		"cached_random_target_party_member_indices": cached_random_target_party_member_indices.duplicate(true),
	}
