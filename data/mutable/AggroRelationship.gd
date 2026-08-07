extends RefCounted
class_name AggroRelationship

var relationship_id: String = ""
var enemy_instance_id: int = -1
var party_member_index: int = -1
var remaining_duration: int = 1

func _init(id: String = "", enemy_id: int = -1, player_index: int = -1, duration: int = 1) -> void:
	relationship_id = id
	enemy_instance_id = enemy_id
	party_member_index = player_index
	remaining_duration = duration

func get_enemy() -> Enemy:
	return instance_from_id(enemy_instance_id) as Enemy

func get_player() -> Player:
	return Global.get_player_by_party_index(party_member_index)
