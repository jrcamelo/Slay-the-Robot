extends RefCounted
class_name ContentDB

var content_root: String = "res://content"

var acts_by_id: Dictionary[String, ActData] = {}
var events_by_id: Dictionary[String, EventData] = {}
var event_pools_by_id: Dictionary[String, EventPoolData] = {}
var dialogues_by_id: Dictionary[String, DialogueData] = {}
var card_packs_by_id: Dictionary[String, CardPackData] = {}
var cards_by_id: Dictionary[String, CardData] = {}
var artifacts_by_id: Dictionary[String, ArtifactData] = {}
var enemies_by_id: Dictionary[String, EnemyData] = {}
var characters_by_id: Dictionary[String, CharacterData] = {}
var keywords_by_id: Dictionary[String, KeywordData] = {}
var consumables_by_id: Dictionary[String, ConsumableData] = {}
var status_effects_by_id: Dictionary[String, StatusEffectData] = {}

var _act_entries: Array[Dictionary] = []
var _event_entries: Array[Dictionary] = []
var _event_pool_entries: Array[Dictionary] = []
var _dialogue_entries: Array[Dictionary] = []
var _card_pack_entries: Array[Dictionary] = []
var _card_entries: Array[Dictionary] = []
var _artifact_entries: Array[Dictionary] = []
var _enemy_entries: Array[Dictionary] = []
var _character_entries: Array[Dictionary] = []
var _keyword_entries: Array[Dictionary] = []
var _consumable_entries: Array[Dictionary] = []
var _status_effect_entries: Array[Dictionary] = []

func load_from_directory(root_path: String = "res://content") -> void:
	content_root = root_path
	acts_by_id.clear()
	events_by_id.clear()
	event_pools_by_id.clear()
	dialogues_by_id.clear()
	card_packs_by_id.clear()
	cards_by_id.clear()
	artifacts_by_id.clear()
	enemies_by_id.clear()
	characters_by_id.clear()
	keywords_by_id.clear()
	consumables_by_id.clear()
	status_effects_by_id.clear()
	_act_entries.clear()
	_event_entries.clear()
	_event_pool_entries.clear()
	_dialogue_entries.clear()
	_card_pack_entries.clear()
	_card_entries.clear()
	_artifact_entries.clear()
	_enemy_entries.clear()
	_character_entries.clear()
	_keyword_entries.clear()
	_consumable_entries.clear()
	_status_effect_entries.clear()

	_load_directory_recursive(content_root)

func get_cards_in_segments(required_segments: Array[String]) -> Array[CardData]:
	var results: Array[CardData] = []
	for entry: Dictionary in _get_entries_matching_segments(_card_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_acts_in_segments(required_segments: Array[String]) -> Array[ActData]:
	var results: Array[ActData] = []
	for entry: Dictionary in _get_entries_matching_segments(_act_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_events_in_segments(required_segments: Array[String]) -> Array[EventData]:
	var results: Array[EventData] = []
	for entry: Dictionary in _get_entries_matching_segments(_event_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_event_pools_in_segments(required_segments: Array[String]) -> Array[EventPoolData]:
	var results: Array[EventPoolData] = []
	for entry: Dictionary in _get_entries_matching_segments(_event_pool_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_dialogues_in_segments(required_segments: Array[String]) -> Array[DialogueData]:
	var results: Array[DialogueData] = []
	for entry: Dictionary in _get_entries_matching_segments(_dialogue_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_card_packs_in_segments(required_segments: Array[String]) -> Array[CardPackData]:
	var results: Array[CardPackData] = []
	for entry: Dictionary in _get_entries_matching_segments(_card_pack_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_artifacts_in_segments(required_segments: Array[String]) -> Array[ArtifactData]:
	var results: Array[ArtifactData] = []
	for entry: Dictionary in _get_entries_matching_segments(_artifact_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_enemies_in_segments(required_segments: Array[String]) -> Array[EnemyData]:
	var results: Array[EnemyData] = []
	for entry: Dictionary in _get_entries_matching_segments(_enemy_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_characters_in_segments(required_segments: Array[String]) -> Array[CharacterData]:
	var results: Array[CharacterData] = []
	for entry: Dictionary in _get_entries_matching_segments(_character_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_keywords_in_segments(required_segments: Array[String]) -> Array[KeywordData]:
	var results: Array[KeywordData] = []
	for entry: Dictionary in _get_entries_matching_segments(_keyword_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_consumables_in_segments(required_segments: Array[String]) -> Array[ConsumableData]:
	var results: Array[ConsumableData] = []
	for entry: Dictionary in _get_entries_matching_segments(_consumable_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_status_effects_in_segments(required_segments: Array[String]) -> Array[StatusEffectData]:
	var results: Array[StatusEffectData] = []
	for entry: Dictionary in _get_entries_matching_segments(_status_effect_entries, required_segments):
		results.append(entry["resource"])
	return results

func get_character_cards(character_name: String, tier: String) -> Array[CardData]:
	return get_cards_in_segments(["character", character_name.to_lower(), tier.to_lower()])

func get_act_enemies(act_name: String, encounter_tier: String) -> Array[EnemyData]:
	return get_enemies_in_segments([act_name.to_lower(), encounter_tier.to_lower()])

func compare_against_global() -> Dictionary:
	return {
		"acts": _compare_serializable_table(Global._id_to_act_data, acts_by_id, []),
		"events": _compare_serializable_table(Global._id_to_event_data, events_by_id, []),
		"event_pools": _compare_serializable_table(Global._id_to_event_pool_data, event_pools_by_id, []),
		"dialogue": _compare_serializable_table(Global._id_to_dialogue_data, dialogues_by_id, []),
		"card_packs": _compare_serializable_table(Global._id_to_card_pack_data, card_packs_by_id, []),
		"cards": _compare_serializable_table(Global._id_to_card_data, cards_by_id, []),
		"artifacts": _compare_serializable_table(Global._id_to_artifact_data, artifacts_by_id, []),
		"enemies": _compare_serializable_table(Global._id_to_enemy_data, enemies_by_id, []),
		"characters": _compare_characters(),
		"keywords": _compare_serializable_table(Global._id_to_keyword_data, keywords_by_id, []),
		"consumables": _compare_serializable_table(Global._id_to_consumable_data, consumables_by_id, []),
		"status_effects": _compare_serializable_table(Global._id_to_status_data, status_effects_by_id, []),
	}

func _load_directory_recursive(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_error("ContentDB: Failed to open directory %s" % directory_path)
		return

	directory.list_dir_begin()
	while true:
		var entry_name: String = directory.get_next()
		if entry_name == "":
			break
		if entry_name.begins_with("."):
			continue

		var child_path: String = directory_path.path_join(entry_name)
		if directory.current_is_dir():
			_load_directory_recursive(child_path)
			continue
		if not entry_name.to_lower().ends_with(".tres") and not entry_name.to_lower().ends_with(".res"):
			continue

		var resource: Resource = load(child_path)
		if resource == null:
			push_warning("ContentDB: Failed to load resource %s" % child_path)
			continue
		_register_resource(resource, child_path)
	directory.list_dir_end()

func _register_resource(resource: Resource, resource_path: String) -> void:
	var relative_path: String = resource_path.trim_prefix(content_root + "/")
	var path_segments: PackedStringArray = PackedStringArray(relative_path.get_base_dir().to_lower().split("/"))
	var entry: Dictionary = {
		"id": resource.get("object_id"),
		"resource": resource,
		"resource_path": resource_path,
		"segments": path_segments,
	}

	if resource is CardData:
		var card_data: CardData = resource
		cards_by_id[card_data.object_id] = card_data
		_card_entries.append(entry)
	elif resource is ActData:
		var act_data: ActData = resource
		acts_by_id[act_data.object_id] = act_data
		_act_entries.append(entry)
	elif resource is EventData:
		var event_data: EventData = resource
		events_by_id[event_data.object_id] = event_data
		_event_entries.append(entry)
	elif resource is EventPoolData:
		var event_pool_data: EventPoolData = resource
		event_pools_by_id[event_pool_data.object_id] = event_pool_data
		_event_pool_entries.append(entry)
	elif resource is DialogueData:
		var dialogue_data: DialogueData = resource
		dialogues_by_id[dialogue_data.object_id] = dialogue_data
		_dialogue_entries.append(entry)
	elif resource is CardPackData:
		var card_pack_data: CardPackData = resource
		card_packs_by_id[card_pack_data.object_id] = card_pack_data
		_card_pack_entries.append(entry)
	elif resource is ArtifactData:
		var artifact_data: ArtifactData = resource
		artifacts_by_id[artifact_data.object_id] = artifact_data
		_artifact_entries.append(entry)
	elif resource is EnemyData:
		var enemy_data: EnemyData = resource
		enemies_by_id[enemy_data.object_id] = enemy_data
		_enemy_entries.append(entry)
	elif resource is CharacterData:
		var character_data: CharacterData = resource
		characters_by_id[character_data.object_id] = character_data
		_character_entries.append(entry)
	elif resource is KeywordData:
		var keyword_data: KeywordData = resource
		keywords_by_id[keyword_data.object_id] = keyword_data
		_keyword_entries.append(entry)
	elif resource is ConsumableData:
		var consumable_data: ConsumableData = resource
		consumables_by_id[consumable_data.object_id] = consumable_data
		_consumable_entries.append(entry)
	elif resource is StatusEffectData:
		var status_effect_data: StatusEffectData = resource
		status_effects_by_id[status_effect_data.object_id] = status_effect_data
		_status_effect_entries.append(entry)

func _get_entries_matching_segments(entries: Array[Dictionary], required_segments: Array[String]) -> Array[Dictionary]:
	var normalized_segments: Array[String] = []
	for segment in required_segments:
		normalized_segments.append(segment.to_lower())

	var results: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var entry_segments: PackedStringArray = entry["segments"]
		var matches: bool = true
		for required_segment: String in normalized_segments:
			if not entry_segments.has(required_segment):
				matches = false
				break
		if matches:
			results.append(entry)
	return results

func _compare_serializable_table(global_table: Dictionary, loaded_table: Dictionary, ignored_fields: Array[String]) -> Dictionary:
	var missing_in_loaded: Array[String] = []
	var missing_in_global: Array[String] = []
	var mismatched: Array[String] = []

	for object_id: String in global_table.keys():
		if not loaded_table.has(object_id):
			missing_in_loaded.append(object_id)
			continue
		var global_signature: String = _resource_signature(global_table[object_id], ignored_fields)
		var loaded_signature: String = _resource_signature(loaded_table[object_id], ignored_fields)
		if global_signature != loaded_signature:
			mismatched.append(object_id)

	for object_id: String in loaded_table.keys():
		if not global_table.has(object_id):
			missing_in_global.append(object_id)

	return {
		"global_count": len(global_table),
		"loaded_count": len(loaded_table),
		"missing_in_loaded": missing_in_loaded,
		"missing_in_global": missing_in_global,
		"mismatched": mismatched,
	}

func _compare_characters() -> Dictionary:
	var ignored_fields: Array[String] = [
		"character_starting_deck_resource",
		"character_starting_artifact_resource",
	]
	var base_result: Dictionary = _compare_serializable_table(Global._id_to_character_data, characters_by_id, ignored_fields)
	var deck_mismatches: Array[String] = []
	var artifact_mismatches: Array[String] = []

	for object_id: String in Global._id_to_character_data.keys():
		if not characters_by_id.has(object_id):
			continue
		var global_character: CharacterData = Global._id_to_character_data[object_id]
		var loaded_character: CharacterData = characters_by_id[object_id]

		var loaded_deck_ids: Array[String] = []
		if loaded_character.character_starting_deck_resource != null:
			for card_data: CardData in loaded_character.character_starting_deck_resource.cards:
				loaded_deck_ids.append(card_data.object_id)
		if not _string_arrays_equal(global_character.character_starting_card_object_ids, loaded_deck_ids):
			deck_mismatches.append(object_id)

		var loaded_artifact_ids: Array[String] = []
		if loaded_character.character_starting_artifact_resource != null:
			for artifact_data: ArtifactData in loaded_character.character_starting_artifact_resource.artifacts:
				loaded_artifact_ids.append(artifact_data.object_id)
		if not _string_arrays_equal(global_character.character_starting_artifact_ids, loaded_artifact_ids):
			artifact_mismatches.append(object_id)

	base_result["deck_mismatches"] = deck_mismatches
	base_result["artifact_list_mismatches"] = artifact_mismatches
	return base_result

func _resource_signature(resource: Resource, ignored_fields: Array[String]) -> String:
	if resource == null:
		return ""
	if resource is SerializableData:
		var serializable_data: SerializableData = resource
		var properties: Dictionary = serializable_data.get_serializable_properties(true)
		for ignored_field: String in ignored_fields:
			properties.erase(ignored_field)
		return JSON.stringify(Scripts.normalize_variant_script_references(properties))
	return JSON.stringify(Scripts.normalize_variant_script_references(resource))

func _string_arrays_equal(left: Array[String], right: Array[String]) -> bool:
	if len(left) != len(right):
		return false
	for index: int in range(len(left)):
		if left[index] != right[index]:
			return false
	return true
