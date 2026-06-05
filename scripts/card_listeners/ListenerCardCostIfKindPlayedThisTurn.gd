# Sets a card's per-turn cost override based on whether a given card kind was played this turn.
extends BaseCardListener

func _connect_signals():
	Signals.player_turn_started.connect(_on_player_turn_started)
	Signals.card_drawn.connect(_on_card_drawn)
	Signals.combat_stat_changed.connect(_on_combat_stat_changed)

func _on_player_turn_started():
	_update_card_cost()

func _on_card_drawn(_card_data: CardData):
	if card_data == _card_data:
		_update_card_cost()

func _on_combat_stat_changed(stat_enum: int):
	if stat_enum == CombatStatsData.STATS.CARDS_PLAYED:
		_update_card_cost()

func _update_card_cost() -> void:
	var required_kind: String = str(values.get("required_kind", CardData.CARD_KIND_INTRO)).strip_edges().to_upper()
	var inactive_cost: int = int(values.get("inactive_cost", 0))
	var combat_stats: CombatStatsData = Global.player_data.player_current_combat_stats
	if combat_stats == null:
		return

	var has_required_kind_played: bool = false
	for card_play_request: CardPlayRequest in combat_stats.cards_played_this_turn:
		if card_play_request == null or card_play_request.card_data == null:
			continue
		if card_play_request.card_data.is_card_kind(required_kind):
			has_required_kind_played = true
			break

	var desired_shadow_cost: int = -1 if has_required_kind_played else inactive_cost
	if parent_card.card_data.card_energy_cost_until_turn != desired_shadow_cost:
		parent_card.card_data.set_card_energy_cost_until_turn(desired_shadow_cost)
