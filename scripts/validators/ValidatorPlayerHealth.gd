# Validator for checking player's health
extends BaseValidator

func _get_editor_description() -> String:
	return "Checks whether the relevant player or party member has at least a given amount of health."

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("health_amount", "Health Amount", "int", 0, "Minimum health required."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var health_amount: int = values.get("health_amount", 0)
	if Global.player_data.has_party_members():
		var party_member_data: PartyMemberData = Global.get_context_party_member(_card_data, null, _action)
		if party_member_data != null:
			# TODO: Add explicit ally-target and whole-party health validator modes if content needs them.
			return party_member_data.party_member_health >= health_amount
	return Global.player_data.player_health >= health_amount
