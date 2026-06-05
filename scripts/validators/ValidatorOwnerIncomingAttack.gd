extends BaseValidator

func _get_editor_display_name() -> String:
	return "Owner Has Incoming Attack"

func _get_editor_description() -> String:
	return "Checks whether any living enemy is currently attacking the card owner's combatant."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_CARD_PLAY_VALIDATORS, EDITOR_CONTEXT_CARD_GLOW_VALIDATORS]

func _validation(card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null or not owner_player.is_alive():
		return false
	if action != null:
		for target: BaseCombatant in _get_context_targets(action, values):
			if target == owner_player:
				return true
		return false
	for node: Node in Global.get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node
		if not enemy.is_alive() or not enemy.is_attacking():
			continue
		if enemy.get_intent_target_players().has(owner_player):
			return true
	return false
