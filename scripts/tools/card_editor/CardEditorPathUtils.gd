@tool
extends RefCounted
class_name CardEditorPathUtils

const DEFAULT_CONTENT_ROOT := "res://content"

const CARD_RARITY_TO_FOLDER := {
	CardData.CARD_RARITIES.BASIC: "standard",
	CardData.CARD_RARITIES.COMMON: "standard",
	CardData.CARD_RARITIES.UNCOMMON: "standard",
	CardData.CARD_RARITIES.RARE: "advanced",
	CardData.CARD_RARITIES.GENERATED: "advanced",
}

static func build_managed_card_path(card_data: CardData, content_root: String = DEFAULT_CONTENT_ROOT) -> String:
	if card_data == null:
		return ""
	var owner_folder: String = "generic"
	var color_name: String = _color_id_to_folder_name(card_data.card_color_id)
	if color_name != "white":
		owner_folder = "character/%s" % color_name
	var rarity_folder: String = CARD_RARITY_TO_FOLDER.get(card_data.card_rarity, "standard")
	var file_name: String = _resource_file_name(card_data.card_name, card_data.object_id)
	return content_root.path_join("cards").path_join(owner_folder).path_join(rarity_folder).path_join("%s.tres" % file_name)

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
