# Validator for checking if an action's targets are all attacking
# NOTE: See ValidatorEnemyAttacking
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Selected Enemy Attacking"

func _get_editor_description() -> String:
	return "Checks whether the selected target, or every resolved enemy target, is attacking."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_ACTION_VALIDATORS]

func _validation(_card_data: CardData, action: BaseAction, values: Dictionary[String, Variant]) -> bool:

	if action == null:
		push_error("No card given")
		return false
	elif action.card_play_request == null:
		push_error("No card play given")
		return false
	else:
		# use selected target if one exists
		if action.card_play_request.selected_target != null:
			var enemy: Enemy = action.card_play_request.selected_target # typecast iterator
			return enemy.is_attacking()
		
		# no selected target, try to use all enemies as a fallback
		for target: BaseCombatant in action.get_adjusted_action_targets():
			if target.is_in_group("enemies_alive_or_dead"):
				var enemy: Enemy = target # typecast iterator
				if not enemy.is_attacking():
					return false # not attacking
			else:
				return false # not an enemy
	
	return true
