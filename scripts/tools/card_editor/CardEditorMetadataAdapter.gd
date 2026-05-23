@tool
extends RefCounted
class_name CardEditorMetadataAdapter

static func list_actions_for_context(context: String) -> Array[Dictionary]:
	return _filter_metadata_by_context(ScriptEditorMetadataRegistry.get_all_action_metadata(), context)

static func list_validators_for_context(context: String) -> Array[Dictionary]:
	return _filter_metadata_by_context(ScriptEditorMetadataRegistry.get_all_validator_metadata(), context)

static func get_action_metadata(token_or_path: String) -> Dictionary:
	return ScriptEditorMetadataRegistry.get_resolved_script_metadata(token_or_path)

static func get_validator_metadata(token_or_path: String) -> Dictionary:
	return ScriptEditorMetadataRegistry.get_resolved_script_metadata(token_or_path)

static func create_default_entry(token_or_path: String) -> Dictionary:
	var metadata: Dictionary = ScriptEditorMetadataRegistry.get_resolved_script_metadata(token_or_path)
	if metadata.is_empty():
		return {}
	var resolved_token: String = str(metadata.get("resolved_token", ""))
	if resolved_token == "":
		resolved_token = str(metadata.get("resolved_path", token_or_path))
	var default_values: Dictionary[String, Variant] = {}
	for parameter_data: Dictionary in metadata.get("parameters", []):
		var parameter_name: String = str(parameter_data.get("name", ""))
		if parameter_name == "":
			continue
		default_values[parameter_name] = parameter_data.get("default_value", null)
	return {
		resolved_token: default_values
	}

static func _filter_metadata_by_context(metadata_list: Array[Dictionary], context: String) -> Array[Dictionary]:
	var filtered_metadata: Array[Dictionary] = []
	for metadata: Dictionary in metadata_list:
		var contexts: Array[String] = []
		contexts.assign(metadata.get("contexts", []))
		if contexts.has(context):
			filtered_metadata.append(metadata)
	return filtered_metadata
