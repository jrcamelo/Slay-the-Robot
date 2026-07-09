## Provides base level interface for attaching behaviors to artifacts
## Extend if you require more complex logic
extends Resource
class_name BaseArtifact

var artifact_data: ArtifactData = null

func _init(_artifact_data: ArtifactData, connect_artifact_signals: bool = true):
	artifact_data = _artifact_data
	if connect_artifact_signals:
		connect_signals()
	
func connect_signals() -> void:
	# override with super()
	# set up signal connections for the artifact to listen to
	Signals.combat_ended.connect(_on_combat_ended)
	Signals.player_turn_started.connect(_on_player_turn_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)

func disconnect_signals() -> void:
	_disconnect_signal(Signals.combat_ended, _on_combat_ended)
	_disconnect_signal(Signals.player_turn_started, _on_player_turn_started)
	_disconnect_signal(Signals.player_turn_ended, _on_player_turn_ended)

func dispose() -> void:
	disconnect_signals()

func _disconnect_signal(signal_ref: Signal, callable: Callable) -> void:
	if signal_ref.is_connected(callable):
		signal_ref.disconnect(callable)

 ## optional override
 ## performs any special logic on the player for when the artifact is added
 ## this should only be done when the artifact is acquired
func add_artifact() -> void:
	artifact_data.perform_artifact_actions(artifact_data.artifact_add_actions)

## optional override
## performs any special logic on the player for when the artifact is removed
func remove_artifact() -> void:
	artifact_data.perform_artifact_actions(artifact_data.artifact_remove_actions)

## Called from Artifact UI
func right_click_artifact() -> void:
	if not ActionHandler.actions_being_performed:
		if len(artifact_data.artifact_right_click_actions) > 0:
			artifact_data.perform_artifact_actions(artifact_data.artifact_right_click_actions)

func get_owner_party_member() -> PartyMemberData:
	if artifact_data == null:
		return null
	return Global.player_data.get_party_member_for_artifact(artifact_data)

func get_owner_player() -> Player:
	var owner_party_member: PartyMemberData = get_owner_party_member()
	if owner_party_member != null:
		var owner_player: Player = Global.get_player_by_party_index(owner_party_member.party_member_party_index)
		if owner_player != null:
			return owner_player
	return Global.get_default_player_combatant()

func card_belongs_to_owner(card_data: CardData) -> bool:
	var owner_party_member: PartyMemberData = get_owner_party_member()
	if owner_party_member == null or card_data == null:
		return false
	Global.player_data.ensure_card_has_owner(card_data)
	return card_data.card_owner_party_index == owner_party_member.party_member_party_index

func filter_owner_cards(cards: Array[CardData]) -> Array[CardData]:
	var owner_cards: Array[CardData] = []
	for card_data: CardData in cards:
		if card_belongs_to_owner(card_data):
			owner_cards.append(card_data)
	return owner_cards

func _on_combat_ended() -> void:
	# reset counter
	if artifact_data.artifact_counter_reset_on_combat_end >= 0:
		artifact_data.set_artifact_counter(artifact_data.artifact_counter_reset_on_combat_end)
	# end of combat actions
	artifact_data.perform_artifact_actions(artifact_data.artifact_end_of_combat_actions)

func _on_player_turn_started() -> void:
	# reset counter
	if artifact_data.artifact_counter_reset_on_turn_start >= 0:
		artifact_data.set_artifact_counter(artifact_data.artifact_counter_reset_on_turn_start)
	# first turn actions
	if Global.get_combat_stats().turn_count == 1:
		artifact_data.perform_artifact_actions(artifact_data.artifact_first_turn_actions)
	# normal start of turn actions
	artifact_data.perform_artifact_actions(artifact_data.artifact_turn_start_actions)

func _on_player_turn_ended() -> void:
	# end of turn actions
	artifact_data.perform_artifact_actions(artifact_data.artifact_turn_end_actions)
