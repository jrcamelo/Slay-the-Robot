# Validator for checking if the player has at least 1 removable card in their deck
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Deck Has Removable Card"

func _get_editor_description() -> String:
	return "Checks whether the player's permanent deck contains at least one removable card."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_CARD_PLAY_VALIDATORS, EDITOR_CONTEXT_CARD_GLOW_VALIDATORS, EDITOR_CONTEXT_ACTION_VALIDATORS]

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	for card: CardData in Global.player_data.player_deck:
		if not _card_matches_context_owner(card, _card_data, _action):
			continue
		if not card.card_unremovable_from_deck:
			return true
	return false

func _card_matches_context_owner(deck_card: CardData, context_card: CardData, action: BaseAction) -> bool:
	if not Global.player_data.has_party_members():
		return true
	var party_member_data: PartyMemberData = Global.get_context_party_member(context_card, null, action)
	if party_member_data == null:
		return true
	Global.player_data.ensure_card_has_owner(deck_card)
	return deck_card.card_owner_party_index == party_member_data.party_member_party_index
