extends BaseCardListener

func _connect_signals() -> void:
	Signals.combatant_status_changed.connect(_on_combatant_status_changed)
	Signals.card_drawn.connect(_on_card_drawn)
	Signals.player_turn_started.connect(_on_player_turn_started)
	_update_card_values()

func _on_combatant_status_changed(base_combatant: BaseCombatant, changed_status_effect_object_id: String) -> void:
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null or base_combatant != owner_player:
		return
	if changed_status_effect_object_id != str(values.get("status_effect_object_id", "")):
		return
	_update_card_values()

func _on_card_drawn(_card_data: CardData) -> void:
	if card_data == _card_data:
		_update_card_values()

func _on_player_turn_started() -> void:
	_update_card_values()

func _update_card_values() -> void:
	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null:
		return
	var status_effect_object_id: String = str(values.get("status_effect_object_id", ""))
	if status_effect_object_id == "":
		return
	var status_charges: int = max(0, owner_player.get_status_charges(status_effect_object_id))
	var multiplied_values: Array[String] = []
	multiplied_values.assign(values.get("multiplied_values", []))
	var multiplied_values_bases: Dictionary = values.get("multiplied_values_bases", {})
	var multiplied_values_per_status_charge: Dictionary = values.get("multiplied_values_per_status_charge", {})
	var card_values: Dictionary = parent_card.card_data.card_values.duplicate(true)
	for value_key: String in multiplied_values:
		var base_value: int = int(multiplied_values_bases.get(value_key, 0))
		var value_per_status_charge: int = int(multiplied_values_per_status_charge.get(value_key, 1))
		card_values[value_key] = base_value + (status_charges * value_per_status_charge)
	parent_card.card_data.card_values = card_values
	Signals.card_properties_changed.emit(parent_card.card_data)
