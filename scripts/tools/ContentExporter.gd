@tool
extends RefCounted
class_name ContentExporter

const CONTENT_ROOT := "res://content"

const CARD_RARITY_TO_FOLDER := {
	CardData.CARD_RARITIES.BASIC: "standard",
	CardData.CARD_RARITIES.COMMON: "standard",
	CardData.CARD_RARITIES.UNCOMMON: "standard",
	CardData.CARD_RARITIES.RARE: "advanced",
	CardData.CARD_RARITIES.GENERATED: "advanced",
}

const ARTIFACT_RARITY_TO_FOLDER := {
	ArtifactData.ARTIFACT_RARITIES.BASIC: "basic",
	ArtifactData.ARTIFACT_RARITIES.COMMON: "common",
	ArtifactData.ARTIFACT_RARITIES.UNCOMMON: "uncommon",
	ArtifactData.ARTIFACT_RARITIES.RARE: "rare",
	ArtifactData.ARTIFACT_RARITIES.BOSS: "boss",
	ArtifactData.ARTIFACT_RARITIES.SHOP: "shop",
	ArtifactData.ARTIFACT_RARITIES.EVENT: "event",
}

static func export_all_content(content_root: String = CONTENT_ROOT) -> Dictionary:
	if len(Global._id_to_card_data) == 0 and len(Global._id_to_enemy_data) == 0 and len(Global._id_to_character_data) == 0:
		push_error("ContentExporter: Global content is empty. Run after Global has finished loading data.")
		return {}

	var export_manifest: Dictionary = {
		"acts": {},
		"events": {},
		"event_pools": {},
		"dialogue": {},
		"card_packs": {},
		"cards": {},
		"artifacts": {},
		"enemies": {},
		"characters": {},
		"keywords": {},
		"consumables": {},
		"status_effects": {},
		"decks": {},
		"artifact_lists": {},
	}

	for card_data: CardData in Global._id_to_card_data.values():
		var card_export_path: String = _build_card_path(card_data, content_root)
		var saved_card_path: String = _save_unique_resource_copy(card_data, card_export_path)
		export_manifest["cards"][card_data.object_id] = saved_card_path

	for act_data: ActData in Global._id_to_act_data.values():
		var act_export_path: String = _build_act_path(act_data, content_root)
		var saved_act_path: String = _save_unique_resource_copy(act_data, act_export_path)
		export_manifest["acts"][act_data.object_id] = saved_act_path

	for event_data: EventData in Global._id_to_event_data.values():
		var event_export_path: String = _build_event_path(event_data, content_root)
		var saved_event_path: String = _save_unique_resource_copy(event_data, event_export_path)
		export_manifest["events"][event_data.object_id] = saved_event_path

	for event_pool_data: EventPoolData in Global._id_to_event_pool_data.values():
		var event_pool_export_path: String = _build_event_pool_path(event_pool_data, content_root)
		var saved_event_pool_path: String = _save_unique_resource_copy(event_pool_data, event_pool_export_path)
		export_manifest["event_pools"][event_pool_data.object_id] = saved_event_pool_path

	for dialogue_data: DialogueData in Global._id_to_dialogue_data.values():
		var dialogue_export_path: String = _build_dialogue_path(dialogue_data, content_root)
		var saved_dialogue_path: String = _save_unique_resource_copy(dialogue_data, dialogue_export_path)
		export_manifest["dialogue"][dialogue_data.object_id] = saved_dialogue_path

	for card_pack_data: CardPackData in Global._id_to_card_pack_data.values():
		var card_pack_export_path: String = _build_card_pack_path(card_pack_data, content_root)
		var saved_card_pack_path: String = _save_unique_resource_copy(card_pack_data, card_pack_export_path)
		export_manifest["card_packs"][card_pack_data.object_id] = saved_card_pack_path

	for artifact_data: ArtifactData in Global._id_to_artifact_data.values():
		var artifact_export_path: String = _build_artifact_path(artifact_data, content_root)
		var saved_artifact_path: String = _save_unique_resource_copy(artifact_data, artifact_export_path)
		export_manifest["artifacts"][artifact_data.object_id] = saved_artifact_path

	for enemy_data: EnemyData in Global._id_to_enemy_data.values():
		var enemy_export_path: String = _build_enemy_path(enemy_data, content_root)
		var saved_enemy_path: String = _save_unique_resource_copy(enemy_data, enemy_export_path)
		export_manifest["enemies"][enemy_data.object_id] = saved_enemy_path

	for character_data: CharacterData in Global._id_to_character_data.values():
		var character_folder_path: String = _build_character_folder_path(character_data, content_root)
		_ensure_res_directory(character_folder_path)

		var deck_resource_path: String = _export_character_deck(character_data, character_folder_path, export_manifest["cards"])
		if deck_resource_path != "":
			export_manifest["decks"][character_data.object_id] = deck_resource_path

		var artifact_list_path: String = _export_character_artifact_list(character_data, character_folder_path, export_manifest["artifacts"])
		if artifact_list_path != "":
			export_manifest["artifact_lists"][character_data.object_id] = artifact_list_path

		var character_export: CharacterData = character_data.duplicate(true)
		character_export.character_starting_deck_resource = load(deck_resource_path) if deck_resource_path != "" else null
		character_export.character_starting_artifact_resource = load(artifact_list_path) if artifact_list_path != "" else null

		var character_export_path: String = character_folder_path.path_join("Character.tres")
		var saved_character_path: String = _save_resource(character_export, character_export_path)
		export_manifest["characters"][character_data.object_id] = saved_character_path

	for keyword_data: KeywordData in Global._id_to_keyword_data.values():
		var keyword_export_path: String = _build_keyword_path(keyword_data, content_root)
		var saved_keyword_path: String = _save_unique_resource_copy(keyword_data, keyword_export_path)
		export_manifest["keywords"][keyword_data.object_id] = saved_keyword_path

	for consumable_data: ConsumableData in Global._id_to_consumable_data.values():
		var consumable_export_path: String = _build_consumable_path(consumable_data, content_root)
		var saved_consumable_path: String = _save_unique_resource_copy(consumable_data, consumable_export_path)
		export_manifest["consumables"][consumable_data.object_id] = saved_consumable_path

	for status_effect_data: StatusEffectData in Global._id_to_status_data.values():
		var status_effect_export_path: String = _build_status_effect_path(status_effect_data, content_root)
		var saved_status_effect_path: String = _save_unique_resource_copy(status_effect_data, status_effect_export_path)
		export_manifest["status_effects"][status_effect_data.object_id] = saved_status_effect_path

	return export_manifest

static func _export_character_deck(character_data: CharacterData, character_folder_path: String, card_manifest: Dictionary) -> String:
	var deck_resource := DeckListResource.new()
	for card_object_id: String in character_data.character_starting_card_object_ids:
		var card_resource_path: String = card_manifest.get(card_object_id, "")
		if card_resource_path == "":
			push_warning("ContentExporter: Missing exported card for character deck: %s" % card_object_id)
			continue
		var card_resource: CardData = load(card_resource_path)
		if card_resource != null:
			deck_resource.cards.append(card_resource)

	var deck_path: String = character_folder_path.path_join("Deck.tres")
	return _save_resource(deck_resource, deck_path)

static func _export_character_artifact_list(character_data: CharacterData, character_folder_path: String, artifact_manifest: Dictionary) -> String:
	var artifact_list := ArtifactListResource.new()
	for artifact_object_id: String in character_data.character_starting_artifact_ids:
		var artifact_resource_path: String = artifact_manifest.get(artifact_object_id, "")
		if artifact_resource_path == "":
			push_warning("ContentExporter: Missing exported artifact for character loadout: %s" % artifact_object_id)
			continue
		var artifact_resource: ArtifactData = load(artifact_resource_path)
		if artifact_resource != null:
			artifact_list.artifacts.append(artifact_resource)

	var artifact_list_path: String = character_folder_path.path_join("StartingArtifacts.tres")
	return _save_resource(artifact_list, artifact_list_path)

static func _build_card_path(card_data: CardData, content_root: String) -> String:
	return CardEditorPathUtils.build_managed_card_path(card_data, content_root)

static func _build_act_path(act_data: ActData, content_root: String) -> String:
	var file_name: String = _resource_file_name(act_data.act_name, act_data.object_id)
	return content_root.path_join("acts").path_join("%s.tres" % file_name)

static func _build_event_path(event_data: EventData, content_root: String) -> String:
	var object_id: String = event_data.object_id.to_lower()
	var path_segments: Array[String] = ["events"]
	if object_id.begins_with("event_act_"):
		var id_segments: PackedStringArray = object_id.split("_")
		if len(id_segments) >= 4:
			path_segments.append("%s%s" % [id_segments[1], id_segments[2]])
		if object_id.contains("_miniboss_"):
			path_segments.append("miniboss")
		elif object_id.contains("_boss_"):
			path_segments.append("boss")
		elif object_id.contains("_easy_"):
			path_segments.append("easy")
		elif object_id.contains("_hard_"):
			path_segments.append("hard")
		else:
			path_segments.append("combat")
	else:
		path_segments.append("dialogue")
	var file_name: String = _resource_file_name(event_data.object_id.trim_prefix("event_"), event_data.object_id)
	var export_path: String = content_root
	for segment: String in path_segments:
		export_path = export_path.path_join(segment)
	return export_path.path_join("%s.tres" % file_name)

static func _build_event_pool_path(event_pool_data: EventPoolData, content_root: String) -> String:
	var object_id: String = event_pool_data.object_id.to_lower()
	var path_segments: Array[String] = ["event_pools"]
	if object_id.begins_with("event_pool_act_"):
		var id_segments: PackedStringArray = object_id.split("_")
		if len(id_segments) >= 5:
			path_segments.append("%s%s" % [id_segments[2], id_segments[3]])
		if object_id.contains("_easy"):
			path_segments.append("easy")
		elif object_id.contains("_hard"):
			path_segments.append("hard")
		elif object_id.contains("_dialogue"):
			path_segments.append("dialogue")
		elif object_id.contains("_miniboss"):
			path_segments.append("miniboss")
		elif object_id.contains("_boss"):
			path_segments.append("boss")
	var file_name: String = _resource_file_name(event_pool_data.object_id.trim_prefix("event_pool_"), event_pool_data.object_id)
	var export_path: String = content_root
	for segment: String in path_segments:
		export_path = export_path.path_join(segment)
	return export_path.path_join("%s.tres" % file_name)

static func _build_dialogue_path(dialogue_data: DialogueData, content_root: String) -> String:
	var file_name: String = _resource_file_name(dialogue_data.object_id.trim_prefix("dialogue_"), dialogue_data.object_id)
	return content_root.path_join("dialogue").path_join("%s.tres" % file_name)

static func _build_card_pack_path(card_pack_data: CardPackData, content_root: String) -> String:
	var file_name: String = _resource_file_name(card_pack_data.object_id.trim_prefix("card_pack_"), card_pack_data.object_id)
	return content_root.path_join("card_packs").path_join("%s.tres" % file_name)

static func _build_artifact_path(artifact_data: ArtifactData, content_root: String) -> String:
	var owner_folder: String = "generic"
	var color_name: String = _color_id_to_folder_name(artifact_data.artifact_color_id)
	if color_name != "white":
		owner_folder = color_name
	var rarity_folder: String = ARTIFACT_RARITY_TO_FOLDER.get(artifact_data.artifact_rarity, "common")
	var file_name: String = _resource_file_name(artifact_data.artifact_name, artifact_data.object_id)
	return content_root.path_join("artifacts").path_join(owner_folder).path_join(rarity_folder).path_join("%s.tres" % file_name)

static func _build_enemy_path(enemy_data: EnemyData, content_root: String) -> String:
	var act_folder: String = _extract_enemy_act_folder(enemy_data)
	var type_folder: String = "standard"
	match enemy_data.enemy_type:
		EnemyData.ENEMY_TYPES.STANDARD:
			type_folder = "standard"
		EnemyData.ENEMY_TYPES.MINIBOSS:
			type_folder = "elite"
		EnemyData.ENEMY_TYPES.BOSS:
			type_folder = "bosses"
	var file_name: String = _resource_file_name(enemy_data.enemy_name, enemy_data.object_id)
	return content_root.path_join("enemies").path_join(act_folder).path_join(type_folder).path_join("%s.tres" % file_name)

static func _build_character_folder_path(character_data: CharacterData, content_root: String) -> String:
	var color_name: String = _color_id_to_folder_name(character_data.character_color_id)
	if color_name == "":
		color_name = _extract_character_folder_name(character_data)
	return content_root.path_join("characters").path_join(color_name)

static func _build_keyword_path(keyword_data: KeywordData, content_root: String) -> String:
	var file_name: String = _resource_file_name(keyword_data.object_id.trim_prefix("keyword_"), keyword_data.object_id)
	return content_root.path_join("keywords").path_join("%s.tres" % file_name)

static func _build_consumable_path(consumable_data: ConsumableData, content_root: String) -> String:
	var rarity_folder := "common"
	match consumable_data.consumable_rarity:
		ConsumableData.CONSUMABLE_RARITIES.COMMON:
			rarity_folder = "common"
		ConsumableData.CONSUMABLE_RARITIES.UNCOMMON:
			rarity_folder = "uncommon"
		ConsumableData.CONSUMABLE_RARITIES.RARE:
			rarity_folder = "rare"
		ConsumableData.CONSUMABLE_RARITIES.LEGENDARY:
			rarity_folder = "legendary"
	var file_name: String = _resource_file_name(consumable_data.consumable_name, consumable_data.object_id)
	return content_root.path_join("consumables").path_join(rarity_folder).path_join("%s.tres" % file_name)

static func _build_status_effect_path(status_effect_data: StatusEffectData, content_root: String) -> String:
	var type_folder := "neutral"
	match status_effect_data.status_effect_type:
		StatusEffectData.STATUS_EFFECT_TYPES.BUFF:
			type_folder = "buff"
		StatusEffectData.STATUS_EFFECT_TYPES.DEBUFF:
			type_folder = "debuff"
		StatusEffectData.STATUS_EFFECT_TYPES.NEUTRAL:
			type_folder = "neutral"
	var file_name: String = _resource_file_name(status_effect_data.status_effect_name, status_effect_data.object_id)
	return content_root.path_join("status_effects").path_join(type_folder).path_join("%s.tres" % file_name)

static func _extract_enemy_act_folder(enemy_data: EnemyData) -> String:
	var object_id: String = enemy_data.object_id.to_lower()
	var search_index: int = object_id.find("act_")
	if search_index >= 0:
		var suffix: String = object_id.substr(search_index + 4)
		var act_digits: String = ""
		for index: int in range(suffix.length()):
			var character: String = suffix[index]
			if character >= "0" and character <= "9":
				act_digits += character
			else:
				break
		if act_digits != "":
			return "act%s" % act_digits
	return "act1"

static func _extract_character_folder_name(character_data: CharacterData) -> String:
	var object_id: String = character_data.object_id.to_lower()
	if object_id.begins_with("character_"):
		return object_id.trim_prefix("character_")
	return _sanitize_name(object_id)

static func _color_id_to_folder_name(color_id: String) -> String:
	var normalized: String = color_id.strip_edges().to_lower()
	if normalized.begins_with("color_"):
		return normalized.trim_prefix("color_")
	return normalized

static func _resource_file_name(display_name: String, fallback_id: String) -> String:
	var cleaned_name: String = _sanitize_name(display_name)
	if cleaned_name == "":
		cleaned_name = _sanitize_name(fallback_id)
	return cleaned_name.to_pascal_case()

static func _sanitize_name(raw_name: String) -> String:
	var cleaned_name: String = raw_name.strip_edges()
	cleaned_name = cleaned_name.replace("'", "")
	cleaned_name = cleaned_name.replace("\"", "")
	cleaned_name = cleaned_name.replace("/", " ")
	cleaned_name = cleaned_name.replace("\\", " ")
	cleaned_name = cleaned_name.replace(":", " ")
	cleaned_name = cleaned_name.replace("?", " ")
	cleaned_name = cleaned_name.replace("*", " ")
	cleaned_name = cleaned_name.replace("<", " ")
	cleaned_name = cleaned_name.replace(">", " ")
	cleaned_name = cleaned_name.replace("|", " ")
	cleaned_name = cleaned_name.replace(".", " ")
	return cleaned_name

static func _save_unique_resource_copy(resource: Resource, desired_path: String) -> String:
	var file_path: String = desired_path
	var file_name: String = desired_path.get_file().trim_suffix(".tres")
	var base_dir: String = desired_path.get_base_dir()
	var counter: int = 2
	while ResourceLoader.exists(file_path):
		var existing_resource: Resource = load(file_path)
		if existing_resource != null and existing_resource.get("object_id") == resource.get("object_id"):
			break
		file_path = base_dir.path_join("%s%s.tres" % [file_name, counter])
		counter += 1
	var resource_copy: Resource = resource.duplicate(true)
	return _save_resource(resource_copy, file_path)

static func _save_resource(resource: Resource, resource_path: String) -> String:
	_normalize_resource_script_references(resource)
	_ensure_res_directory(resource_path.get_base_dir())
	var save_result: Error = ResourceSaver.save(resource, resource_path)
	if save_result != OK:
		push_error("ContentExporter: Failed to save resource to %s (error %s)" % [resource_path, save_result])
	return resource_path

static func _ensure_res_directory(res_directory_path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(res_directory_path)
	DirAccess.make_dir_recursive_absolute(absolute_path)

static func _normalize_resource_script_references(resource: Resource) -> void:
	if resource == null:
		return
	for property_data: Dictionary in resource.get_property_list():
		var property_name: String = property_data.get("name", "")
		var usage: int = property_data.get("usage", 0)
		if property_name == "" or property_name == "script":
			continue
		if (usage & PROPERTY_USAGE_STORAGE) != PROPERTY_USAGE_STORAGE:
			continue
		var property_value: Variant = resource.get(property_name)
		var normalized_value: Variant = _normalize_variant_script_references(property_value)
		if property_value is Array and normalized_value is Array:
			var typed_array: Array = property_value.duplicate()
			typed_array.clear()
			typed_array.assign(normalized_value)
			resource.set(property_name, typed_array)
		elif property_value is Dictionary and normalized_value is Dictionary:
			var typed_dictionary: Dictionary = property_value.duplicate()
			typed_dictionary.clear()
			typed_dictionary.assign(normalized_value)
			resource.set(property_name, typed_dictionary)
		else:
			resource.set(property_name, normalized_value)

static func _normalize_variant_script_references(value: Variant) -> Variant:
	if value is SerializableData:
		_normalize_resource_script_references(value)
		return value
	if value is Array:
		var normalized_array: Array = []
		for item: Variant in value:
			normalized_array.append(_normalize_variant_script_references(item))
		return Scripts.normalize_variant_script_references(normalized_array)
	if value is Dictionary:
		var normalized_dictionary: Dictionary = {}
		for key: Variant in value.keys():
			var normalized_key: Variant = key
			if key is String:
				var normalized_script_key: String = Scripts.get_token_for_path(key)
				if normalized_script_key != "":
					normalized_key = normalized_script_key
			normalized_dictionary[normalized_key] = _normalize_variant_script_references(value[key])
		return normalized_dictionary
	return Scripts.normalize_variant_script_references(value)
