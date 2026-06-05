@tool
extends RefCounted
class_name CardEditorPathUtils

const DEFAULT_CONTENT_ROOT := "res://content"
const DEFAULT_TRIAGE_ROOT := "res://triage"

const CARD_RARITY_TO_FOLDER := {
	CardData.CARD_RARITIES.BASIC: "standard",
	CardData.CARD_RARITIES.COMMON: "standard",
	CardData.CARD_RARITIES.UNCOMMON: "standard",
	CardData.CARD_RARITIES.RARE: "advanced",
	CardData.CARD_RARITIES.GENERATED: "advanced",
}

static func build_managed_card_path(card_data: CardData, content_root: String = DEFAULT_CONTENT_ROOT, owner_bucket_hint: String = "") -> String:
	return build_content_card_path(card_data, content_root, owner_bucket_hint)

static func build_content_card_path(card_data: CardData, content_root: String = DEFAULT_CONTENT_ROOT, owner_bucket_hint: String = "") -> String:
	return _build_rooted_card_path(card_data, content_root, owner_bucket_hint)

static func build_triage_card_path(card_data: CardData, triage_root: String = DEFAULT_TRIAGE_ROOT, owner_bucket_hint: String = "") -> String:
	return _build_rooted_card_path(card_data, triage_root, owner_bucket_hint)

static func analyze_card_resource_path(resource_path: String, content_root: String = DEFAULT_CONTENT_ROOT, triage_root: String = DEFAULT_TRIAGE_ROOT) -> Dictionary:
	var normalized_path: String = resource_path.strip_edges()
	var source_root: String = ""
	var source_bucket: String = "external"
	if path_is_within_root(normalized_path, triage_root):
		source_root = triage_root
		source_bucket = "triage"
	elif path_is_within_root(normalized_path, content_root):
		source_root = content_root
		source_bucket = "content"

	var relative_path: String = normalized_path
	if source_root != "":
		relative_path = normalized_path.trim_prefix(source_root + "/")

	var path_segments: Array[String] = []
	for segment: String in relative_path.get_base_dir().split("/"):
		if segment.strip_edges() != "":
			path_segments.append(segment.to_lower())

	var owner_bucket: String = "unknown"
	if len(path_segments) >= 2 and path_segments[0] == "cards":
		if path_segments[1] == "generic":
			owner_bucket = "generic"
		elif path_segments[1] == "character" and len(path_segments) >= 3:
			owner_bucket = "character/%s" % path_segments[2]
		else:
			owner_bucket = path_segments[1]

	return {
		"resource_path": normalized_path,
		"source_root": source_root,
		"source_bucket": source_bucket,
		"relative_path": relative_path,
		"path_segments": path_segments,
		"owner_bucket": owner_bucket,
		"file_name": normalized_path.get_file(),
		"is_triage": source_bucket == "triage",
	}

static func path_is_within_root(resource_path: String, root_path: String) -> bool:
	var normalized_path: String = resource_path.strip_edges().trim_suffix("/")
	var normalized_root: String = root_path.strip_edges().trim_suffix("/")
	if normalized_path == "" or normalized_root == "":
		return false
	return normalized_path == normalized_root or normalized_path.begins_with(normalized_root + "/")

static func build_promoted_card_path(card_data: CardData, content_root: String = DEFAULT_CONTENT_ROOT, owner_bucket_hint: String = "") -> String:
	return build_content_card_path(card_data, content_root, owner_bucket_hint)

static func build_default_triage_override_path(card_data: CardData, triage_root: String = DEFAULT_TRIAGE_ROOT, owner_bucket_hint: String = "") -> String:
	return build_triage_card_path(card_data, triage_root, owner_bucket_hint)

static func _build_rooted_card_path(card_data: CardData, root_path: String, owner_bucket_hint: String = "") -> String:
	if card_data == null:
		return ""
	var owner_folder: String = _resolve_owner_folder(card_data, owner_bucket_hint)
	var rarity_folder: String = CARD_RARITY_TO_FOLDER.get(card_data.card_rarity, "standard")
	var file_name: String = _resource_file_name(card_data.card_name, card_data.object_id)
	return root_path.path_join("cards").path_join(owner_folder).path_join(rarity_folder).path_join("%s.tres" % file_name)

static func _resolve_owner_folder(card_data: CardData, owner_bucket_hint: String = "") -> String:
	var normalized_hint: String = owner_bucket_hint.strip_edges().to_lower()
	if normalized_hint == "generic" or normalized_hint.begins_with("character/"):
		return normalized_hint
	var resource_path_owner_bucket: String = _extract_owner_bucket_from_resource_path(card_data)
	if resource_path_owner_bucket == "generic" or resource_path_owner_bucket.begins_with("character/"):
		return resource_path_owner_bucket
	var owner_character_id: String = card_data.card_owner_character_object_id.strip_edges().to_lower()
	if owner_character_id.begins_with("character_"):
		return "character/%s" % owner_character_id.trim_prefix("character_")
	var owner_folder: String = "generic"
	var color_name: String = _color_id_to_folder_name(card_data.card_color_id)
	if color_name != "white":
		owner_folder = "character/%s" % color_name
	return owner_folder

static func _extract_owner_bucket_from_resource_path(card_data: CardData) -> String:
	if card_data == null:
		return ""
	var resource_path: String = str(card_data.resource_path).strip_edges()
	if resource_path == "":
		return ""
	var path_metadata: Dictionary = analyze_card_resource_path(resource_path)
	return str(path_metadata.get("owner_bucket", "")).strip_edges().to_lower()

static func sanitize_resource_name(raw_name: String) -> String:
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

static func get_default_card_filename(card_data: CardData) -> String:
	if card_data == null:
		return ""
	return _resource_file_name(card_data.card_name, card_data.object_id)

static func _resource_file_name(display_name: String, fallback_id: String) -> String:
	var cleaned_name: String = sanitize_resource_name(display_name)
	if cleaned_name == "":
		cleaned_name = sanitize_resource_name(fallback_id)
	return cleaned_name.to_pascal_case()

static func _color_id_to_folder_name(color_id: String) -> String:
	var normalized: String = color_id.strip_edges().to_lower()
	if normalized.begins_with("color_"):
		return normalized.trim_prefix("color_")
	return normalized
