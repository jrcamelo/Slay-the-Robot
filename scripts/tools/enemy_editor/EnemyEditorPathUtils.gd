@tool
extends RefCounted
class_name EnemyEditorPathUtils

const DEFAULT_CONTENT_ROOT := "res://content"
const DEFAULT_TRIAGE_ROOT := "res://triage"

static func build_content_enemy_path(enemy_data: EnemyData, content_root: String = DEFAULT_CONTENT_ROOT, preferred_relative_dir: String = "") -> String:
	return _build_rooted_enemy_path(enemy_data, content_root, preferred_relative_dir)

static func build_triage_enemy_path(enemy_data: EnemyData, triage_root: String = DEFAULT_TRIAGE_ROOT, preferred_relative_dir: String = "") -> String:
	return _build_rooted_enemy_path(enemy_data, triage_root, preferred_relative_dir)

static func build_promoted_enemy_path(enemy_data: EnemyData, content_root: String = DEFAULT_CONTENT_ROOT, preferred_relative_dir: String = "") -> String:
	return build_content_enemy_path(enemy_data, content_root, preferred_relative_dir)

static func build_default_triage_override_path(enemy_data: EnemyData, triage_root: String = DEFAULT_TRIAGE_ROOT, preferred_relative_dir: String = "") -> String:
	return build_triage_enemy_path(enemy_data, triage_root, preferred_relative_dir)

static func analyze_enemy_resource_path(resource_path: String, content_root: String = DEFAULT_CONTENT_ROOT, triage_root: String = DEFAULT_TRIAGE_ROOT) -> Dictionary:
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

	var trimmed_enemy_relative_path: String = relative_path
	if trimmed_enemy_relative_path.begins_with("enemies/"):
		trimmed_enemy_relative_path = trimmed_enemy_relative_path.trim_prefix("enemies/")

	var path_segments: Array[String] = []
	for segment: String in trimmed_enemy_relative_path.get_base_dir().split("/"):
		if segment.strip_edges() != "":
			path_segments.append(segment.to_lower())

	var owner_bucket: String = trimmed_enemy_relative_path.get_base_dir().strip_edges()
	if owner_bucket == "":
		owner_bucket = "unknown"

	return {
		"resource_path": normalized_path,
		"source_root": source_root,
		"source_bucket": source_bucket,
		"relative_path": relative_path,
		"enemy_relative_path": trimmed_enemy_relative_path,
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

static func infer_preferred_relative_directory(resource_path: String, content_root: String = DEFAULT_CONTENT_ROOT, triage_root: String = DEFAULT_TRIAGE_ROOT) -> String:
	var metadata: Dictionary = analyze_enemy_resource_path(resource_path, content_root, triage_root)
	var relative_path: String = str(metadata.get("relative_path", ""))
	if relative_path == "":
		return ""
	return relative_path.get_base_dir()

static func get_default_enemy_filename(enemy_data: EnemyData) -> String:
	if enemy_data == null:
		return ""
	return _resource_file_name(enemy_data.enemy_name, enemy_data.object_id)

static func sanitize_resource_name(raw_name: String) -> String:
	var cleaned_name: String = raw_name.strip_edges()
	for blocked_character: String in ["'", "\"", "/", "\\", ":", "?", "*", "<", ">", "|", "."]:
		cleaned_name = cleaned_name.replace(blocked_character, " ")
	return cleaned_name

static func _build_rooted_enemy_path(enemy_data: EnemyData, root_path: String, preferred_relative_dir: String = "") -> String:
	if enemy_data == null:
		return ""
	var relative_dir: String = preferred_relative_dir.strip_edges().trim_suffix("/")
	if relative_dir == "":
		relative_dir = _default_enemy_relative_directory(enemy_data)
	elif relative_dir.begins_with("res://"):
		relative_dir = relative_dir.trim_prefix(root_path + "/")
	if not relative_dir.begins_with("enemies"):
		relative_dir = "enemies/%s" % relative_dir.trim_prefix("/")
	var file_name: String = _resource_file_name(enemy_data.enemy_name, enemy_data.object_id)
	return root_path.path_join(relative_dir).path_join("%s.tres" % file_name)

static func _default_enemy_relative_directory(enemy_data: EnemyData) -> String:
	var act_folder: String = ContentExporter._extract_enemy_act_folder(enemy_data)
	return "enemies/%s/%s" % [act_folder, _enemy_type_to_folder(enemy_data.enemy_type)]

static func _enemy_type_to_folder(enemy_type: int) -> String:
	match enemy_type:
		EnemyData.ENEMY_TYPES.MINIBOSS:
			return "elite"
		EnemyData.ENEMY_TYPES.BOSS:
			return "bosses"
		_:
			return "standard"

static func _resource_file_name(display_name: String, fallback_id: String) -> String:
	var cleaned_name: String = sanitize_resource_name(display_name)
	if cleaned_name == "":
		cleaned_name = sanitize_resource_name(fallback_id)
	return cleaned_name.to_pascal_case()
