extends BaseStatusEffect

const JAB_CARD_ID: String = "card_monk_jab"

func _connect_signals() -> void:
	Signals.combatant_poise_depleted.connect(_on_combatant_poise_depleted)

func _disconnect_signals() -> void:
	if Signals.combatant_poise_depleted.is_connected(_on_combatant_poise_depleted):
		Signals.combatant_poise_depleted.disconnect(_on_combatant_poise_depleted)

func _on_combatant_poise_depleted(_base_combatant: BaseCombatant, attack_action: BaseAction) -> void:
	if attack_action == null or attack_action.card_play_request == null or attack_action.card_play_request.card_data == null:
		return
	if attack_action.card_play_request.card_data.object_id != JAB_CARD_ID:
		return
	if attack_action.card_play_request.card_data.card_owner_party_index != _get_parent_party_index():
		return
	_create_jabs(3)
	remove_self()

func _create_jabs(count: int) -> void:
	var created_cards: Array[CardData] = []
	for _i in count:
		var card_data: CardData = Global.get_card_data_from_prototype(JAB_CARD_ID)
		if Global.player_data.has_party_members():
			var party_member: PartyMemberData = Global.player_data.get_party_member(_get_parent_party_index())
			if party_member != null:
				Global.player_data.assign_card_owner(card_data, party_member.party_member_party_index)
			else:
				Global.player_data.ensure_card_has_owner(card_data)
		created_cards.append(card_data)
		Signals.card_created.emit(card_data)
	Signals.card_add_to_hand_requested.emit(created_cards, PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)

func _get_parent_party_index() -> int:
	if parent_combatant is Player:
		return (parent_combatant as Player).get_party_member_index()
	return -1
