# Validator for checking the current player location type
extends BaseValidator

func _get_editor_description() -> String:
	return "Checks the current map location type."

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("location_type", "Location Type", "enum", LocationData.LOCATION_TYPES.COMBAT, "Required location type."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var location_type: int = _get_validator_value("location_type", values, _action, LocationData.LOCATION_TYPES.COMBAT)
	var location_data: LocationData = Global.get_player_location_data()
	return location_data.location_type == location_type
