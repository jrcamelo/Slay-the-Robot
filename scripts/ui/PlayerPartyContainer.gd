extends Control
class_name PlayerPartyContainer

@onready var automatic_party_container: HBoxContainer = $AutomaticPartyContainer

var base_player: Player = null

func _ready():
	Signals.run_ended.connect(_on_run_ended)
	Signals.party_member_removed.connect(_on_party_member_removed)

func register_base_player(player: Player) -> void:
	if player == null:
		return
	base_player = player
	if player.get_parent() != automatic_party_container:
		player.reparent(automatic_party_container)

func populate_party_members() -> void:
	_clear_extra_players()
	var created_base_player: bool = false
	var primary_player: Player = base_player
	if not is_instance_valid(primary_player):
		primary_player = Scenes.PLAYER.instantiate()
		automatic_party_container.add_child(primary_player)
		base_player = primary_player
		created_base_player = true
	elif primary_player.get_parent() != automatic_party_container:
		primary_player.reparent(automatic_party_container)
	if primary_player == null:
		return
	
	var party_member_count: int = 1
	if Global.player_data.has_party_members():
		party_member_count = max(1, Global.player_data.get_party_member_count())
	
	primary_player.name = "PlayerPartyMember_0"
	primary_player.set_party_member_index(0)
	primary_player.visible = true
	if created_base_player:
		primary_player._on_run_started()
	
	for party_member_index: int in range(1, party_member_count):
		var player: Player = Scenes.PLAYER.instantiate()
		player.name = "PlayerPartyMember_%s" % party_member_index
		automatic_party_container.add_child(player)
		player.set_party_member_index(party_member_index)
		player._on_run_started()

func clear_party_members(keep_base_player: bool = true) -> void:
	for child: Node in automatic_party_container.get_children():
		if keep_base_player and child == base_player:
			continue
		child.queue_free()

func get_primary_player() -> Player:
	if is_instance_valid(base_player):
		return base_player
	for child: Node in automatic_party_container.get_children():
		if child is Player:
			return child
	return null

func get_party_players() -> Array[Player]:
	var party_players: Array[Player] = []
	for child: Node in automatic_party_container.get_children():
		if child is Player:
			party_players.append(child)
	return party_players

func _clear_extra_players() -> void:
	for child: Node in automatic_party_container.get_children():
		if child != base_player:
			child.queue_free()

func _on_run_ended():
	clear_party_members(true)

func _on_party_member_removed(party_member_index: int) -> void:
	for child: Node in automatic_party_container.get_children():
		if child is Player and child.get_party_member_index() == party_member_index:
			if child == base_player:
				base_player = null
			child.queue_free()
			break
