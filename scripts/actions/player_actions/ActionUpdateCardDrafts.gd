## Changes the types of cards available to the player for future card rewards.
## Forces a recompiling of PlayerData.player_reward_card_filter_cache
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.ADD_CARD_PACK_OBJECT_IDS, ActionValueRegistry.BLACKLIST_CARD_OBJECT_IDS, ActionValueRegistry.REMOVE_ALL_CARD_PACKS, ActionValueRegistry.REMOVE_CARD_PACK_OBJECT_IDS, ActionValueRegistry.RESET_TO_STARTING_CARD_PACKS, ActionValueRegistry.WHITELIST_CARD_OBJECT_IDS]

func _get_editor_description() -> String:
	return "Adjusts the party member's future card reward pools by adding or removing card packs and id filters."

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	var party_member_data: PartyMemberData = null
	if Global.player_data.has_party_members():
		if parent_combatant is Player:
			party_member_data = parent_combatant.get_party_member_data()
		if party_member_data == null and card_play_request != null and card_play_request.card_data != null:
			party_member_data = Global.player_data.get_party_member_for_card(card_play_request.card_data)
	
	for action_interceptor_processor: ActionInterceptorProcessor in action_interceptor_processors:
		# option to reset to character's starting card packs
		var reset_to_starting_card_packs: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.RESET_TO_STARTING_CARD_PACKS, false)
		if reset_to_starting_card_packs:
			if party_member_data != null:
				party_member_data.party_member_reward_draft_card_pack_ids = []
				var party_character_data: CharacterData = Global.get_character_data(party_member_data.party_member_character_object_id)
				party_member_data.party_member_reward_draft_card_pack_ids.assign(party_character_data.character_starting_card_draft_card_pack_ids)
			else:
				Global.player_data.reward_draft_card_pack_ids = []
				var character_data: CharacterData = Global.get_character_data(Global.player_data.player_character_object_id)
				Global.player_data.reward_draft_card_pack_ids.assign(character_data.character_starting_card_draft_card_pack_ids)
		
		# option to reset to character's starting card packs
		var remove_all_card_packs: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.REMOVE_ALL_CARD_PACKS, false)
		if remove_all_card_packs:
			if party_member_data != null:
				party_member_data.party_member_reward_draft_card_pack_ids = []
			else:
				Global.player_data.reward_draft_card_pack_ids = []
		
		# adding card packs
		var add_card_pack_object_ids: Array[String] = []
		add_card_pack_object_ids.assign(action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.ADD_CARD_PACK_OBJECT_IDS, []))
		
		for card_pack_object_id: String in add_card_pack_object_ids:
			if party_member_data != null:
				if not party_member_data.party_member_reward_draft_card_pack_ids.has(card_pack_object_id):
					party_member_data.party_member_reward_draft_card_pack_ids.append(card_pack_object_id)
			else:
				if not Global.player_data.reward_draft_card_pack_ids.has(card_pack_object_id):
					Global.player_data.reward_draft_card_pack_ids.append(card_pack_object_id)
		
		# removing card packs
		var remove_card_pack_object_ids: Array[String] = []
		remove_card_pack_object_ids.assign(action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.REMOVE_CARD_PACK_OBJECT_IDS, []))
		
		for card_pack_object_id: String in remove_card_pack_object_ids:
			if party_member_data != null:
				party_member_data.party_member_reward_draft_card_pack_ids.erase(card_pack_object_id)
			else:
				Global.player_data.reward_draft_card_pack_ids.erase(card_pack_object_id)
		
		# whitelist card ids
		var whitelist_card_object_ids: Array[String] = []
		whitelist_card_object_ids.assign(action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.WHITELIST_CARD_OBJECT_IDS, []))
		
		for whitelist_card_object_id: String in whitelist_card_object_ids:
			if party_member_data != null:
				if not party_member_data.party_member_reward_draft_card_id_whitelist.has(whitelist_card_object_id):
					party_member_data.party_member_reward_draft_card_id_whitelist.append(whitelist_card_object_id)
				if party_member_data.party_member_reward_draft_card_id_blacklist.has(whitelist_card_object_id):
					party_member_data.party_member_reward_draft_card_id_blacklist.erase(whitelist_card_object_id)
			else:
				if not Global.player_data.player_reward_draft_card_id_whitelist.has(whitelist_card_object_id):
					Global.player_data.player_reward_draft_card_id_whitelist.append(whitelist_card_object_id)
				# remove blacklisted cards if whitelisted
				if Global.player_data.player_reward_draft_card_id_blacklist.has(whitelist_card_object_id):
					Global.player_data.player_reward_draft_card_id_blacklist.erase(whitelist_card_object_id)
		
		# blacklist card ids
		var blacklist_card_object_ids: Array[String] = []
		blacklist_card_object_ids.assign(action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.BLACKLIST_CARD_OBJECT_IDS, []))
		
		for blacklist_card_object_id: String in blacklist_card_object_ids:
			if party_member_data != null:
				if not party_member_data.party_member_reward_draft_card_id_blacklist.has(blacklist_card_object_id):
					party_member_data.party_member_reward_draft_card_id_blacklist.append(blacklist_card_object_id)
				if party_member_data.party_member_reward_draft_card_id_whitelist.has(blacklist_card_object_id):
					party_member_data.party_member_reward_draft_card_id_whitelist.erase(blacklist_card_object_id)
			else:
				if not Global.player_data.player_reward_draft_card_id_blacklist.has(blacklist_card_object_id):
					Global.player_data.player_reward_draft_card_id_blacklist.append(blacklist_card_object_id)
				# remove whitelisted cards if blacklisted
				if Global.player_data.player_reward_draft_card_id_whitelist.has(blacklist_card_object_id):
					Global.player_data.player_reward_draft_card_id_whitelist.erase(blacklist_card_object_id)
		
		# apply update to player drafting
		if party_member_data != null:
			party_member_data.regenerate_card_draft_card_filter()
			Global.player_data.generate_cache()
		else:
			Global.player_data.regenerate_card_draft_card_filter()
