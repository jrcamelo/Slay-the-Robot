@tool
extends RefCounted
class_name ScriptEditorMetadataRegistry

const ACTION_TOKEN_PREFIX := "ACTION_"
const VALIDATOR_TOKEN_PREFIX := "VALIDATOR_"

static func get_resolved_script_metadata(token_or_path: String) -> Dictionary:
	var script: Script = Scripts.resolve_script(token_or_path)
	if script == null:
		return {}
	var metadata: Dictionary = get_script_metadata(script)
	if metadata.is_empty():
		return {}
	metadata["token_or_path"] = token_or_path
	metadata["resolved_path"] = Scripts.resolve_script_path(token_or_path)
	metadata["resolved_token"] = Scripts.get_token_for_path(metadata["resolved_path"])
	return metadata

static func get_script_metadata(script: Script) -> Dictionary:
	if script == null or not script.can_instantiate():
		return {}
	var instance: Variant = script.new()
	if not (instance is BaseAction or instance is BaseValidator):
		return {}
	var metadata: Dictionary = instance.get_editor_metadata()
	metadata["script_path"] = script.resource_path
	metadata["script_global_name"] = script.get_global_name()
	metadata["script_class_name"] = instance.get_class()
	if instance is BaseAction:
		metadata["parameters"] = _merge_parameter_definitions(
			metadata.get("parameters", []),
			_infer_action_parameters(script.resource_path)
		)
	return metadata

static func get_all_action_metadata() -> Array[Dictionary]:
	return _get_all_token_metadata(ACTION_TOKEN_PREFIX)

static func get_all_validator_metadata() -> Array[Dictionary]:
	return _get_all_token_metadata(VALIDATOR_TOKEN_PREFIX)

static func _get_all_token_metadata(token_prefix: String) -> Array[Dictionary]:
	var metadata_list: Array[Dictionary] = []
	var constant_map: Dictionary = Scripts.get_script().get_script_constant_map()
	for constant_name: String in constant_map.keys():
		if not constant_name.begins_with(token_prefix):
			continue
		var token_value: Variant = constant_map[constant_name]
		if not token_value is String:
			continue
		var metadata: Dictionary = get_resolved_script_metadata(constant_name)
		if not metadata.is_empty():
			metadata_list.append(metadata)
	metadata_list.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("display_name", "")) < str(right.get("display_name", ""))
	)
	return metadata_list

static func _merge_parameter_definitions(primary_parameters: Array, inferred_parameters: Array) -> Array[Dictionary]:
	var parameters_by_name: Dictionary[String, Dictionary] = {}
	var parameter_order: Array[String] = []
	for parameter_data: Dictionary in inferred_parameters:
		var parameter_name: String = str(parameter_data.get("name", ""))
		if parameter_name == "":
			continue
		parameters_by_name[parameter_name] = parameter_data
		parameter_order.append(parameter_name)
	for parameter_data: Dictionary in primary_parameters:
		var parameter_name: String = str(parameter_data.get("name", ""))
		if parameter_name == "":
			continue
		if not parameter_order.has(parameter_name):
			parameter_order.append(parameter_name)
		parameters_by_name[parameter_name] = parameter_data
	var merged_parameters: Array[Dictionary] = []
	for parameter_name: String in parameter_order:
		merged_parameters.append(parameters_by_name[parameter_name])
	return merged_parameters

static func _infer_action_parameters(script_path: String) -> Array[Dictionary]:
	var source_text: String = _load_script_source(script_path)
	if source_text == "":
		return []
	var regex_patterns: Array[String] = [
		'get_action_value\\("([^"]+)",\\s*([^\\)]+)\\)',
		'get_shadowed_action_values\\("([^"]+)",\\s*([^\\)]+)\\)',
	]
	var parameter_map: Dictionary[String, Dictionary] = {}
	for regex_pattern: String in regex_patterns:
		var regex := RegEx.new()
		if regex.compile(regex_pattern) != OK:
			continue
		for result: RegExMatch in regex.search_all(source_text):
			var parameter_name: String = result.get_string(1)
			if parameter_name == "":
				continue
			if parameter_map.has(parameter_name):
				continue
			var default_expression: String = result.get_string(2).strip_edges()
			parameter_map[parameter_name] = {
				"name": parameter_name,
				"label": parameter_name.to_snake_case().replace("_", " ").capitalize(),
				"value_type": _infer_value_type(default_expression),
				"default_value": _parse_default_expression(default_expression),
				"description": "Inferred from %s." % script_path.get_file(),
				"inferred": true,
			}
	var parameter_names: Array[String] = []
	parameter_names.assign(parameter_map.keys())
	parameter_names.sort()
	var parameters: Array[Dictionary] = []
	for parameter_name: String in parameter_names:
		parameters.append(parameter_map[parameter_name])
	return parameters

static func _load_script_source(script_path: String) -> String:
	if script_path == "":
		return ""
	if not FileAccess.file_exists(script_path):
		return ""
	var file: FileAccess = FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

static func _infer_value_type(default_expression: String) -> String:
	var normalized_expression: String = default_expression.strip_edges()
	if normalized_expression == "":
		return "variant"
	if normalized_expression in ["true", "false"]:
		return "bool"
	if normalized_expression.begins_with('"') and normalized_expression.ends_with('"'):
		return "string"
	if normalized_expression.begins_with("["):
		return "array"
	if normalized_expression.begins_with("{"):
		return "dictionary"
	if normalized_expression.is_valid_int():
		return "int"
	if normalized_expression.is_valid_float():
		return "float"
	if normalized_expression.contains(".") or normalized_expression.contains("::"):
		return "enum"
	return "variant"

static func _parse_default_expression(default_expression: String) -> Variant:
	var normalized_expression: String = default_expression.strip_edges()
	if normalized_expression == "":
		return null
	if normalized_expression == "true":
		return true
	if normalized_expression == "false":
		return false
	if normalized_expression.begins_with('"') and normalized_expression.ends_with('"'):
		return normalized_expression.substr(1, normalized_expression.length() - 2)
	if normalized_expression == "[]":
		return []
	if normalized_expression == "{}":
		return {}
	if normalized_expression.is_valid_int():
		return int(normalized_expression)
	if normalized_expression.is_valid_float():
		return float(normalized_expression)
	return normalized_expression
