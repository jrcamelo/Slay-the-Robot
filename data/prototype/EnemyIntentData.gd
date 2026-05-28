extends SerializableData
class_name EnemyIntentData

const TARGETING_RANDOM_LIVING_PLAYER := "random_living_player"
const TARGETING_LOWEST_CURRENT_HEALTH_PLAYER := "lowest_current_health_player"
const TARGETING_HIGHEST_CURRENT_HEALTH_PLAYER := "highest_current_health_player"
const TARGETING_LOWEST_HEALTH_PERCENT_PLAYER := "lowest_health_percent_player"
const TARGETING_HIGHEST_HEALTH_PERCENT_PLAYER := "highest_health_percent_player"
const TARGETING_ALL_LIVING_PLAYERS := "all_living_players"
const TARGETING_RANDOM_DISTINCT_PLAYERS := "random_distinct_players"

const TARGETING_RULES: Array[String] = [
	TARGETING_RANDOM_LIVING_PLAYER,
	TARGETING_LOWEST_CURRENT_HEALTH_PLAYER,
	TARGETING_HIGHEST_CURRENT_HEALTH_PLAYER,
	TARGETING_LOWEST_HEALTH_PERCENT_PLAYER,
	TARGETING_HIGHEST_HEALTH_PERCENT_PLAYER,
	TARGETING_ALL_LIVING_PLAYERS,
	TARGETING_RANDOM_DISTINCT_PLAYERS,
]

@export var damage: int = 0
@export var block: int = 0
@export var number_of_attacks: int = 0
@export var targeting_rule: String = TARGETING_RANDOM_LIVING_PLAYER
@export var target_count: int = 1
@export var allow_repeat_targets: bool = false

func validate_intent() -> Array[String]:
	var errors: Array[String] = []
	if damage < 0:
		errors.append("Intent damage cannot be negative")
	if block < 0:
		errors.append("Intent block cannot be negative")
	if number_of_attacks < 0:
		errors.append("Intent number_of_attacks cannot be negative")
	if not TARGETING_RULES.has(targeting_rule):
		errors.append("Unsupported targeting_rule: %s" % targeting_rule)
	if targeting_rule != TARGETING_ALL_LIVING_PLAYERS and target_count <= 0:
		errors.append("Intent target_count must be positive unless targeting all living players")
	return errors
