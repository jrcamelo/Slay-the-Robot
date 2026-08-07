extends BaseStatusEffect

func get_display_name() -> String:
	var source_name: String = _get_source_name()
	if status_effect_data.object_id == AggroManager.STATUS_PROVOKED:
		return "Provoked by %s" % source_name
	return "Hunted by %s" % source_name

func is_flag_status() -> bool:
	return status_charges < 0

func on_removed() -> void:
	var relationship_id: String = str(status_custom_values.get("relationship_id", ""))
	var combat_stats: CombatStatsData = Global.get_combat_stats()
	if relationship_id != "" and combat_stats != null:
		combat_stats.aggro_manager.on_relationship_status_removed(relationship_id)

func _get_source_name() -> String:
	var source: BaseCombatant = instance_from_id(int(status_custom_values.get("source_instance_id", -1))) as BaseCombatant
	if source is Player:
		var member: PartyMemberData = source.get_party_member_data()
		if member != null and member.party_member_name != "":
			return member.party_member_name
		var character_data: CharacterData = Global.get_player_character_data()
		if character_data != null:
			return character_data.character_name
	if source is Enemy and source.enemy_data != null:
		return source.enemy_data.enemy_name
	return "Unknown"
