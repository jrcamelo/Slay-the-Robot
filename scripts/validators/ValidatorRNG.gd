# Validator for applying a random chance
# this should generally only be used in ActionValidator, not anywhere else, as the rolls will be
# different each time
extends BaseValidator

func _get_editor_display_name() -> String:
	return "RNG Chance"

func _get_editor_description() -> String:
	return "Rolls a random chance using one of the player's RNG tracks."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameters: Array[Dictionary] = super()
	parameters.append(_editor_param("chance", "Chance", "float", 1.0, "Passes when a random roll is less than or equal to this value."))
	return parameters

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	var chance: float = values.get("chance", 1.0)
	
	var rng: RandomNumberGenerator = Global.player_data.get_player_rng("rng_general")	
	
	return chance >= rng.randf()
