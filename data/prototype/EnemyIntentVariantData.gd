extends SerializableData
class_name EnemyIntentVariantData

@export var conditions: Array[Dictionary] = []
@export var extra_actions: Array[Dictionary] = []
@export var intent: EnemyIntentData = EnemyIntentData.new()
@export var priority_override_enabled: bool = false
@export var priority: int = 0
