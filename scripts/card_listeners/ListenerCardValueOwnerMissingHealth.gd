extends BaseCardListener

func _connect_signals() -> void:
	Signals.player_health_changed.connect(_on_player_health_changed)
	Signals.card_drawn.connect(_on_card_drawn)
	Signals.player_turn_started.connect(_on_player_turn_started)
	_update_card_values()

func _on_player_health_changed() -> void:
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
	var missing_health: int = max(0, owner_player.get_health_max() - owner_player.get_health())
	var multiplied_values: Array[String] = []
	multiplied_values.assign(values.get("multiplied_values", []))
	var multiplied_values_bases: Dictionary = values.get("multiplied_values_bases", {})
	var multiplied_values_per_missing_health: Dictionary = values.get("multiplied_values_per_missing_health", {})
	var card_values: Dictionary = parent_card.card_data.card_values.duplicate(true)
	for value_key: String in multiplied_values:
		var base_value: int = int(multiplied_values_bases.get(value_key, 0))
		var value_per_missing_health: int = int(multiplied_values_per_missing_health.get(value_key, 1))
		card_values[value_key] = base_value + (missing_health * value_per_missing_health)
	parent_card.card_data.card_values = card_values
	Signals.card_properties_changed.emit(parent_card.card_data)
