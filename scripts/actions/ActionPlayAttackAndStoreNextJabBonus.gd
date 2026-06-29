extends ActionBasePickCards

func _get_editor_relevant_value_names() -> Array[String]:
	var relevant_value_names: Array[String] = super()
	relevant_value_names.append("status_effect_object_id")
	return relevant_value_names

func _get_editor_description() -> String:
	return "Picks an attack from hand, stores its damage as next-Jab bonus, then plays it."

func perform_async_action() -> void:
	if picked_cards.is_empty():
		action_async_finished.emit()
		return
	var picked_attack: CardData = picked_cards[0]
	var bonus_damage: int = max(0, int(picked_attack.card_values.get(ActionValueRegistry.DAMAGE, 0)))
	var status_effect_object_id: String = get_action_value(ActionValueRegistry.STATUS_EFFECT_OBJECT_ID, "status_effect_next_jab_damage_bonus")
	if parent_combatant != null and bonus_damage > 0:
		parent_combatant.apply_status(status_effect_object_id, 1, parent_combatant, bonus_damage)

	var enemies: Array[Node] = Global.get_tree().get_nodes_in_group("enemies")
	var selected_target: BaseCombatant = null
	if not enemies.is_empty():
		var rng_targeting: RandomNumberGenerator = Global.player_data.get_player_rng("rng_targeting")
		enemies = Random.shuffle_array(rng_targeting, enemies)
		selected_target = enemies[0]

	var new_card_play_request: CardPlayRequest = CardPlayRequest.new()
	new_card_play_request.card_data = picked_attack
	new_card_play_request.selected_target = selected_target
	new_card_play_request.refundable_energy = 0
	new_card_play_request.input_energy = Global.player_data.player_energy
	new_card_play_request.card_values = picked_attack.card_values.duplicate(true)
	Signals.card_play_requested.emit(new_card_play_request, false, true)
	action_async_finished.emit()
