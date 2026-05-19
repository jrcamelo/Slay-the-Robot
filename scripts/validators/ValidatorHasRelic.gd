# Validator for checking a relic
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Has Artifact"

func _get_editor_description() -> String:
	return "Checks whether the player currently owns a specific artifact."

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("artifact_id", "Artifact ID", "string", "", "Artifact object ID to check for."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var artifact_id: String = _get_validator_value("artifact_id", values, _action, "")
	return len(Global.player_data.get_player_artifacts_with_artifact_id(artifact_id)) > 0
