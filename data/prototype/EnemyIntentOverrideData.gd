extends SerializableData
class_name EnemyIntentOverrideData

@export var variant_index: int = -1
@export var intent_overrides: Dictionary[String, Variant] = {}
@export var priority_override_enabled: bool = false
@export var priority_override: int = 0
@export var conditions_patch_strategy: String = "overwrite"
@export var condition_overrides: Array[Dictionary] = []
