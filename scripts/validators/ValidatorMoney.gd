# Validator for checking player money
extends BaseValidator

func _get_editor_description() -> String:
	return "Checks whether the player has at least a given amount of money."

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("money_amount", "Money Amount", "int", 0, "Minimum money required."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var money_amount: int = values.get("money_amount", 0)
	return Global.player_data.player_money >= money_amount
