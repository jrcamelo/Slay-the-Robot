## Validator for checking if a card could be drafted by the player.
## This primarily allows for ad hoc validators in card picking actions that are used for generating/selecting
## cards that only a player should be able to get, *in addition to* other filters you may wish to apply.
## NOTE: If you simply want to restrict to only player draftable cards in ActionBasePickCards, use
## the draft_use_player_draft flag
extends BaseValidator

func _validation(card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	if card_data == null:
		return false

	if Global.player_data.has_party_members():
		var party_member_data: PartyMemberData = null
		var party_member_index: int = values.get("party_member_index", -1)
		if party_member_index >= 0:
			party_member_data = Global.player_data.get_party_member(party_member_index)
		if party_member_data == null:
			party_member_data = Global.get_context_party_member(card_data, null, _action)
		if party_member_data != null and party_member_data.party_member_reward_card_filter_cache != null:
			return party_member_data.party_member_reward_card_filter_cache.convert_to_unique_card_object_ids().has(card_data.object_id)

	return Global.player_data.player_reward_card_filter_cache.convert_to_unique_card_object_ids().has(card_data.object_id)
