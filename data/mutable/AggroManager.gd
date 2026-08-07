extends RefCounted
class_name AggroManager

const STATUS_PROVOKED: String = "status_effect_provoked"
const STATUS_HUNTED: String = "status_effect_hunted"

var _relationships: Dictionary[String, AggroRelationship] = {}
var _next_relationship_id: int = 1
var _is_removing_relationship: bool = false
var _is_clearing: bool = false

func create_or_refresh_provoke(enemy: Enemy, player: Player, duration: int = 1) -> AggroRelationship:
	if enemy == null or player == null or not enemy.is_alive() or not player.is_alive():
		return null
	duration = -1 if duration < 0 else max(1, duration)
	var existing: AggroRelationship = _find_relationship(enemy.get_instance_id(), player.get_party_member_index())
	if existing != null:
		existing.remaining_duration = duration
		_sync_relationship_statuses(existing)
		return existing

	var relationship_id: String = "provoke_%s" % _next_relationship_id
	_next_relationship_id += 1
	var relationship := AggroRelationship.new(relationship_id, enemy.get_instance_id(), player.get_party_member_index(), duration)
	_relationships[relationship_id] = relationship
	_notify_targeting_changed(enemy)
	_apply_relationship_status(enemy, STATUS_PROVOKED, relationship, player)
	_apply_relationship_status(player, STATUS_HUNTED, relationship, enemy)
	return relationship

func remove_relationship(relationship_id: String) -> void:
	if _is_removing_relationship or not _relationships.has(relationship_id):
		return
	_is_removing_relationship = true
	var relationship: AggroRelationship = _relationships[relationship_id]
	_relationships.erase(relationship_id)
	var enemy: Enemy = relationship.get_enemy()
	var player: Player = relationship.get_player()
	_notify_targeting_changed(enemy)
	_remove_relationship_status(enemy, STATUS_PROVOKED, relationship_id)
	_remove_relationship_status(player, STATUS_HUNTED, relationship_id)
	_is_removing_relationship = false

func on_relationship_status_removed(relationship_id: String) -> void:
	remove_relationship(relationship_id)

func get_provoker_indices(enemy: Enemy) -> Array[int]:
	var indices: Array[int] = []
	if enemy == null:
		return indices
	for relationship: AggroRelationship in _relationships.values():
		var player: Player = relationship.get_player()
		if relationship.enemy_instance_id == enemy.get_instance_id() and player != null and player.is_alive() and not indices.has(relationship.party_member_index):
			indices.append(relationship.party_member_index)
	return indices

func get_relationship_ids_for_enemy(enemy: Enemy) -> Array[String]:
	var ids: Array[String] = []
	if enemy == null:
		return ids
	for relationship: AggroRelationship in _relationships.values():
		if relationship.enemy_instance_id == enemy.get_instance_id():
			ids.append(relationship.relationship_id)
	ids.sort()
	return ids

func advance_enemy_turn_cycle() -> void:
	for relationship: AggroRelationship in _relationships.values().duplicate():
		if relationship.remaining_duration < 0:
			continue
		relationship.remaining_duration -= 1
		if relationship.remaining_duration <= 0:
			remove_relationship(relationship.relationship_id)
		else:
			_sync_relationship_statuses(relationship)

func remove_relationships_for_combatant(combatant: BaseCombatant) -> void:
	if combatant == null:
		return
	for relationship: AggroRelationship in _relationships.values().duplicate():
		if combatant is Enemy and relationship.enemy_instance_id == combatant.get_instance_id():
			remove_relationship(relationship.relationship_id)
		elif combatant is Player and relationship.party_member_index == combatant.get_party_member_index():
			remove_relationship(relationship.relationship_id)

func remove_relationships_for_party_member(party_member_index: int) -> void:
	for relationship: AggroRelationship in _relationships.values().duplicate():
		if relationship.party_member_index == party_member_index:
			remove_relationship(relationship.relationship_id)

func clear() -> void:
	_is_clearing = true
	for relationship_id: String in _relationships.keys().duplicate():
		remove_relationship(relationship_id)
	_is_clearing = false

func _find_relationship(enemy_instance_id: int, party_member_index: int) -> AggroRelationship:
	for relationship: AggroRelationship in _relationships.values():
		if relationship.enemy_instance_id == enemy_instance_id and relationship.party_member_index == party_member_index:
			return relationship
	return null

func _apply_relationship_status(target: BaseCombatant, status_id: String, relationship: AggroRelationship, source: BaseCombatant) -> void:
	var charges: int = -1 if relationship.remaining_duration < 0 else max(1, relationship.remaining_duration)
	target.apply_status(status_id, charges, source, 0, true, {"relationship_id": relationship.relationship_id})

func _sync_relationship_statuses(relationship: AggroRelationship) -> void:
	var charges: int = -1 if relationship.remaining_duration < 0 else max(1, relationship.remaining_duration)
	for pair: Array in [[relationship.get_enemy(), STATUS_PROVOKED], [relationship.get_player(), STATUS_HUNTED]]:
		var combatant: BaseCombatant = pair[0]
		if combatant == null:
			continue
		for status: StatusEffect in combatant.get_status_effects(pair[1]):
			if status.status_effect_script.status_custom_values.get("relationship_id", "") == relationship.relationship_id:
				status.status_effect_script.status_charges = charges
				status.update_status_charge_display()

func _remove_relationship_status(combatant: BaseCombatant, status_id: String, relationship_id: String) -> void:
	if combatant == null:
		return
	for status: StatusEffect in combatant.get_status_effects(status_id).duplicate():
		if status.status_effect_script.status_custom_values.get("relationship_id", "") == relationship_id:
			combatant.remove_status_instance(status, not _is_clearing)

func _notify_targeting_changed(enemy: Enemy) -> void:
	if _is_clearing:
		return
	Signals.targeting_state_changed.emit(enemy)
	Signals.enemy_intent_changed.emit()
