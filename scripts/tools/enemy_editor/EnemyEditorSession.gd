@tool
extends RefCounted
class_name EnemyEditorSession

const SAVE_POLICY_MANAGED_CONTENT := "managed_content"
const SAVE_POLICY_MANAGED_TRIAGE := "managed_triage"
const SAVE_POLICY_MANUAL := "manual"

var working_enemy_data: EnemyData = null
var original_resource_path: String = ""
var managed_save_path: String = ""
var managed_triage_save_path: String = ""
var manual_save_override_path: String = ""
var preferred_relative_directory: String = ""
var dirty: bool = false
var diagnostics: Array[Dictionary] = []
var content_root: String = EnemyEditorPathUtils.DEFAULT_CONTENT_ROOT
var triage_root: String = EnemyEditorPathUtils.DEFAULT_TRIAGE_ROOT
var save_policy: String = SAVE_POLICY_MANAGED_TRIAGE
var preview_state: EnemyEditorPreviewState = null

func _init(
	enemy_data: EnemyData = null,
	resource_path: String = "",
	_content_root: String = EnemyEditorPathUtils.DEFAULT_CONTENT_ROOT,
	_triage_root: String = EnemyEditorPathUtils.DEFAULT_TRIAGE_ROOT,
	_save_policy: String = SAVE_POLICY_MANAGED_TRIAGE
) -> void:
	content_root = _content_root
	triage_root = _triage_root
	save_policy = _save_policy
	working_enemy_data = enemy_data
	original_resource_path = resource_path
	preferred_relative_directory = EnemyEditorPathUtils.infer_preferred_relative_directory(resource_path, content_root, triage_root)
	preview_state = EnemyEditorPreviewState.new()
	if save_policy == "":
		save_policy = infer_save_policy_from_path(original_resource_path)
	recompute_managed_paths()
	reset_preview_state()

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
	managed_save_path = EnemyEditorPathUtils.build_content_enemy_path(working_enemy_data, content_root, preferred_relative_directory)
	managed_triage_save_path = EnemyEditorPathUtils.build_triage_enemy_path(working_enemy_data, triage_root, preferred_relative_directory)

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

func set_preferred_relative_directory(relative_directory: String) -> void:
	preferred_relative_directory = relative_directory.strip_edges().trim_suffix("/")
	recompute_managed_paths()
	mark_dirty()

func infer_save_policy_from_path(resource_path: String) -> String:
	if EnemyEditorPathUtils.path_is_within_root(resource_path, triage_root):
		return SAVE_POLICY_MANAGED_TRIAGE
	if EnemyEditorPathUtils.path_is_within_root(resource_path, content_root):
		return SAVE_POLICY_MANAGED_CONTENT
	if manual_save_override_path.strip_edges() != "":
		return SAVE_POLICY_MANUAL
	return SAVE_POLICY_MANAGED_TRIAGE

func refresh_diagnostics(service: Variant = null) -> Array[Dictionary]:
	if service != null and service.has_method("validate_session"):
		diagnostics = service.validate_session(self)
	return diagnostics

func reset_preview_state() -> void:
	if preview_state == null:
		preview_state = EnemyEditorPreviewState.new()
	preview_state.ensure_defaults(working_enemy_data)

func to_summary() -> Dictionary:
	var enemy_data: EnemyData = working_enemy_data
	if enemy_data == null:
		return {
			"object_id": "",
			"enemy_name": "",
			"enemy_type": EnemyData.ENEMY_TYPES.STANDARD,
			"enemy_is_minion": false,
			"resource_path": original_resource_path,
			"managed_save_path": managed_save_path,
			"managed_triage_save_path": managed_triage_save_path,
			"active_save_path": get_active_save_path(),
			"save_policy": save_policy,
			"dirty": dirty,
			"preferred_relative_directory": preferred_relative_directory,
		}
	return {
		"object_id": enemy_data.object_id,
		"enemy_name": enemy_data.enemy_name,
		"enemy_type": enemy_data.enemy_type,
		"enemy_is_minion": enemy_data.enemy_is_minion,
		"resource_path": original_resource_path,
		"managed_save_path": managed_save_path,
		"managed_triage_save_path": managed_triage_save_path,
		"active_save_path": get_active_save_path(),
		"save_policy": save_policy,
		"dirty": dirty,
		"preferred_relative_directory": preferred_relative_directory,
		"stage_count": len(enemy_data.stages),
		"reactive_stage_count": len(enemy_data.reactive_stages),
		"difficulty_override_count": len(enemy_data.difficulty_overrides),
	}
