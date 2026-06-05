extends BaseValidator

func _get_editor_display_name() -> String:
	return "Ally Has Incoming Attack"

func _get_editor_description() -> String:
	return "Checks whether any living ally other than the card owner is currently being attacked."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_CARD_PLAY_VALIDATORS, EDITOR_CONTEXT_CARD_GLOW_VALIDATORS]

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null:
		return false
	var damaged_player: Player = values.get("damaged_player", null)
	if damaged_player != null:
		return damaged_player.is_alive() and damaged_player != owner_player
	if action != null:
		for target: BaseCombatant in _get_context_targets(action, values):
			if target is Player and target.is_alive() and target != owner_player:
				return true
		return false
	for node: Node in Global.get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node
		if not enemy.is_alive() or not enemy.is_attacking():
			continue
		for target_player: Player in enemy.get_intent_target_players():
			if target_player != null and target_player.is_alive() and target_player != owner_player:
				return true
	return false
