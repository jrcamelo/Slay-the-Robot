extends SerializableData
class_name EnemyStageOverrideData

@export var stage_id: String = ""
@export var property_overrides: Dictionary[String, Variant] = {}
@export var intent_overrides: Array[EnemyIntentOverrideData] = []
@export var extra_actions_patch_strategy: String = "overwrite"
@export var extra_actions: Array[Dictionary] = []
