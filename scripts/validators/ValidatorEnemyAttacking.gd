# Validator for checking if at least one remaining enemy is attacking
# NOTE: See ValidatorCardPlayEnemyAttacking
extends BaseValidator

func _get_editor_description() -> String:
	return "Checks whether at least one living enemy is currently attacking."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_VALIDATORS,
		EDITOR_CONTEXT_CARD_GLOW_VALIDATORS,
		EDITOR_CONTEXT_ACTION_VALIDATORS,
	]

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var enemies: Array[Node] = Global.get_tree().get_nodes_in_group("enemies")
	for enemy: Enemy in Global.get_tree().get_nodes_in_group("enemies"):
		if enemy.is_alive() and enemy.is_attacking():
			return true
	return false
