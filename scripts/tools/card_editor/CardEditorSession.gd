@tool
extends RefCounted
class_name CardEditorSession

var working_card_data: CardData = null
var original_resource_path: String = ""
var managed_save_path: String = ""
var manual_save_override_path: String = ""
var dirty: bool = false
var diagnostics: Array[Dictionary] = []
var content_root: String = CardEditorPathUtils.DEFAULT_CONTENT_ROOT

func _init(card_data: CardData = null, resource_path: String = "", _content_root: String = CardEditorPathUtils.DEFAULT_CONTENT_ROOT):
	content_root = _content_root
	working_card_data = card_data
	original_resource_path = resource_path
	recompute_managed_path()

func mark_dirty(value: bool = true) -> void:
	dirty = value

func clear_dirty() -> void:
	dirty = false

func get_active_save_path() -> String:
	if manual_save_override_path.strip_edges() != "":
		return manual_save_override_path
	return managed_save_path

func recompute_managed_path() -> String:
	managed_save_path = CardEditorPathUtils.build_managed_card_path(working_card_data, content_root)
	return managed_save_path

func set_manual_save_override_path(path: String) -> void:
	manual_save_override_path = path.strip_edges()
	mark_dirty()

func refresh_diagnostics(service: Variant = null) -> Array[Dictionary]:
	if service != null and service.has_method("validate_session"):
		diagnostics = service.validate_session(self)
	return diagnostics

func to_summary() -> Dictionary:
	var card_data: CardData = working_card_data
	if card_data == null:
		return {
			"object_id": "",
			"card_name": "",
			"card_color_id": "",
			"card_rarity": CardData.CARD_RARITIES.COMMON,
			"resource_path": original_resource_path,
			"managed_save_path": managed_save_path,
			"active_save_path": get_active_save_path(),
			"dirty": dirty,
		}
	return {
		"object_id": card_data.object_id,
		"card_name": card_data.card_name,
		"card_color_id": card_data.card_color_id,
		"card_rarity": card_data.card_rarity,
		"resource_path": original_resource_path,
		"managed_save_path": managed_save_path,
		"active_save_path": get_active_save_path(),
		"dirty": dirty,
	}
