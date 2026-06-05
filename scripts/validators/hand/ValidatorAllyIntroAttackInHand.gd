extends BaseValidator

func _get_editor_display_name() -> String:
	return "Ally Intro Attack In Hand"

func _get_editor_description() -> String:
	return "Checks whether the current trigger came from another ally's Intro Attack, or whether another ally currently has one in hand."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_CARD_PLAY_VALIDATORS, EDITOR_CONTEXT_CARD_GLOW_VALIDATORS]

func _validation(card_data: CardData, _action: BaseAction, _values: Dictionary[String, Variant]) -> bool:
	if card_data == null:
		return false
	var triggering_card_data: CardData = _values.get("triggering_card_data", null)
	if triggering_card_data != null:
		if triggering_card_data == card_data:
			return false
		if triggering_card_data.card_owner_party_index == card_data.card_owner_party_index:
			return false
		if triggering_card_data.card_type != CardData.CARD_TYPES.ATTACK:
			return false
		return triggering_card_data.is_card_kind(CardData.CARD_KIND_INTRO)
	for hand_card: CardData in Global.player_data.player_hand:
		if hand_card == null or hand_card == card_data:
			continue
		if hand_card.card_owner_party_index == card_data.card_owner_party_index:
			continue
		if hand_card.card_type != CardData.CARD_TYPES.ATTACK:
			continue
		if not hand_card.is_card_kind(CardData.CARD_KIND_INTRO):
			continue
		return true
	return false
