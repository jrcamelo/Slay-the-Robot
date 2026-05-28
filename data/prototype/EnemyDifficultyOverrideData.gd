extends SerializableData
class_name EnemyDifficultyOverrideData

@export var difficulty_level: int = 0
@export var top_level_overrides: Dictionary[String, Variant] = {}
@export var stage_overrides: Array[EnemyStageOverrideData] = []
@export var reactive_stage_overrides: Array[EnemyReactiveStageOverrideData] = []
