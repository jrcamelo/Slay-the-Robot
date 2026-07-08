## Swaps the primary character's starting passive/artifact slot for the next available boss artifact.
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return []

func _get_editor_description() -> String:
	return "Disables the primary character's starting passive, removes any legacy starting artifacts, and grants the next boss artifact."

func perform_action():
	var player_character_data: CharacterData = Global.get_player_character_data()
	var primary_party_member: PartyMemberData = Global.player_data.get_primary_party_member()
	if primary_party_member != null:
		for passive_status_effect_id: String in player_character_data.character_passive_status_effect_ids:
			if not primary_party_member.party_member_disabled_character_passive_status_effect_ids.has(passive_status_effect_id):
				primary_party_member.party_member_disabled_character_passive_status_effect_ids.append(passive_status_effect_id)
	for starting_artifact_id: String in player_character_data.character_starting_artifact_ids:
		Global.player_data.remove_artifact(starting_artifact_id)
	
	var artifact_ids: Array[String] = Global.player_data.get_next_boss_artifacts_from_pool(1, true)
	for artifact_id: String in artifact_ids:
		Global.player_data.add_artifact(artifact_id)
