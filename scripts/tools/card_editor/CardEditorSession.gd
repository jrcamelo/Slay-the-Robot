@tool
extends RefCounted
class_name CardEditorSession

const SAVE_POLICY_MANAGED_CONTENT := "managed_content"
const SAVE_POLICY_MANAGED_TRIAGE := "managed_triage"
const SAVE_POLICY_MANUAL := "manual"

var working_card_data: CardData = null
var original_resource_path: String = ""
var managed_save_path: String = ""
var managed_triage_save_path: String = ""
var manual_save_override_path: String = ""
var dirty: bool = false
var diagnostics: Array[Dictionary] = []
var content_root: String = CardEditorPathUtils.DEFAULT_CONTENT_ROOT
var triage_root: String = CardEditorPathUtils.DEFAULT_TRIAGE_ROOT
var save_policy: String = SAVE_POLICY_MANAGED_TRIAGE

func _init(
	card_data: CardData = null,
	resource_path: String = "",
	_content_root: String = CardEditorPathUtils.DEFAULT_CONTENT_ROOT,
	_triage_root: String = CardEditorPathUtils.DEFAULT_TRIAGE_ROOT,
	_save_policy: String = SAVE_POLICY_MANAGED_TRIAGE
):
	content_root = _content_root
	triage_root = _triage_root
	save_policy = _save_policy
	working_card_data = card_data
	original_resource_path = resource_path
	if save_policy == "":
		save_policy = infer_save_policy_from_path(original_resource_path)
	recompute_managed_paths()

func mark_dirty(value: bool = true) -> void:
	dirty = value

func clear_dirty() -> void:
	dirty = false

func get_active_save_path() -> String:
	if save_policy == SAVE_POLICY_MANUAL and manual_save_override_path.strip_edges() != "":
		return manual_save_override_path
	if save_policy == SAVE_POLICY_MANAGED_CONTENT:
		return managed_save_path
	if save_policy == SAVE_POLICY_MANAGED_TRIAGE:
		return managed_triage_save_path
	if manual_save_override_path.strip_edges() != "":
		return manual_save_override_path
	return managed_triage_save_path

func recompute_managed_path() -> String:
	recompute_managed_paths()
	return managed_save_path

func recompute_managed_paths() -> void:
	managed_save_path = CardEditorPathUtils.build_content_card_path(working_card_data, content_root)
	managed_triage_save_path = CardEditorPathUtils.build_triage_card_path(working_card_data, triage_root)

func set_manual_save_override_path(path: String) -> void:
	manual_save_override_path = path.strip_edges()
	save_policy = SAVE_POLICY_MANUAL
	mark_dirty()

func set_save_policy(new_save_policy: String) -> void:
	save_policy = new_save_policy.strip_edges()
	mark_dirty()

func set_content_root(new_content_root: String) -> void:
	content_root = new_content_root.strip_edges()
	recompute_managed_paths()
	mark_dirty()

func set_triage_root(new_triage_root: String) -> void:
	triage_root = new_triage_root.strip_edges()
	recompute_managed_paths()
	mark_dirty()

func infer_save_policy_from_path(resource_path: String) -> String:
	if CardEditorPathUtils.path_is_within_root(resource_path, triage_root):
		return SAVE_POLICY_MANAGED_TRIAGE
	if CardEditorPathUtils.path_is_within_root(resource_path, content_root):
		return SAVE_POLICY_MANAGED_CONTENT
	if manual_save_override_path.strip_edges() != "":
		return SAVE_POLICY_MANUAL
	return SAVE_POLICY_MANAGED_TRIAGE

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
			"managed_triage_save_path": managed_triage_save_path,
			"active_save_path": get_active_save_path(),
			"save_policy": save_policy,
			"dirty": dirty,
		}
	return {
		"object_id": card_data.object_id,
		"card_name": card_data.card_name,
		"card_color_id": card_data.card_color_id,
		"card_rarity": card_data.card_rarity,
		"resource_path": original_resource_path,
		"managed_save_path": managed_save_path,
		"managed_triage_save_path": managed_triage_save_path,
		"active_save_path": get_active_save_path(),
		"save_policy": save_policy,
		"dirty": dirty,
	}
