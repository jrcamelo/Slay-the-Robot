extends SerializableData
class_name EnemyReactiveStageData

const RESUME_PREVIOUS := "resume_previous"
const JUMP_TO_STAGE := "jump_to_stage"
const START_NEW_SEQUENCE := "start_new_sequence"

const RESUME_MODES: Array[String] = [
	RESUME_PREVIOUS,
	JUMP_TO_STAGE,
	START_NEW_SEQUENCE,
]

@export var label: String = ""
@export var priority_override_enabled: bool = false
@export var priority: int = 0
@export var conditions: Array[Dictionary] = []
@export var intents: Array[EnemyIntentVariantData] = []
@export var extra_actions: Array[Dictionary] = []
@export var resume_mode: String = RESUME_PREVIOUS
@export var resume_stage_id: String = ""
