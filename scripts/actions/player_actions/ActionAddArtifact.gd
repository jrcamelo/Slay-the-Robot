extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [ActionValueRegistry.ARTIFACT_ID, "artifact_owner_party_index", "artifact_owner_character_object_id"]

func _get_editor_description() -> String:
	return "Adds an artifact to the player by artifact id."

func perform_action():
	var artifact_id: String = get_action_value(ActionValueRegistry.ARTIFACT_ID, "")
	var artifact_data: ArtifactData = Global.get_artifact_data_from_prototype(artifact_id)
	if artifact_data != null:
		var owner_party_index: int = get_action_value("artifact_owner_party_index", -1)
		var owner_character_object_id: String = get_action_value("artifact_owner_character_object_id", "")
		if owner_party_index < 0 and Global.player_data.has_party_members():
			var owner_party_member: PartyMemberData = Global.get_context_party_member(null, parent_combatant, self)
			if owner_party_member != null:
				owner_party_index = owner_party_member.party_member_party_index
				owner_character_object_id = owner_party_member.party_member_character_object_id
		Global.player_data.add_artifact(artifact_id, owner_party_index, owner_character_object_id)

func _to_string():
	var artifact_id: String = get_action_value(ActionValueRegistry.ARTIFACT_ID, "")
	return "Add Artifact Action: " + artifact_id
