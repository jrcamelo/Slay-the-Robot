extends BaseStatusEffect

const JAB_CARD_ID: String = "card_monk_jab"

func _connect_signals() -> void:
	Signals.card_play_started.connect(_on_card_play_started)

func _disconnect_signals() -> void:
	if Signals.card_play_started.is_connected(_on_card_play_started):
		Signals.card_play_started.disconnect(_on_card_play_started)

func _on_card_play_started(card_play_request: CardPlayRequest) -> void:
	if card_play_request == null or card_play_request.card_data == null:
		return
	if card_play_request.card_data.card_type != CardData.CARD_TYPES.ATTACK:
		return
	if card_play_request.card_data.card_owner_party_index == _get_parent_party_index():
		return
	_create_jab()

func _create_jab() -> void:
	var card_data: CardData = Global.get_card_data_from_prototype(JAB_CARD_ID)
	if Global.player_data.has_party_members():
		var party_member: PartyMemberData = Global.player_data.get_party_member(_get_parent_party_index())
		if party_member != null:
			Global.player_data.assign_card_owner(card_data, party_member.party_member_party_index)
		else:
			Global.player_data.ensure_card_has_owner(card_data)
	Signals.card_created.emit(card_data)
	Signals.card_add_to_hand_requested.emit([card_data], PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)

func _get_parent_party_index() -> int:
	if parent_combatant is Player:
		return (parent_combatant as Player).get_party_member_index()
	return -1
