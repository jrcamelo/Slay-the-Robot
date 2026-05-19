# Ends the player's turn when processed
# See CombatEndTurn for different levels of immediacy for ending turns
extends BaseAction

func _get_editor_description() -> String:
	return "Requests the end of the player's turn with a chosen queue immediacy. (Added automatically to OUTRO cards)"

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameter_definitions: Array[Dictionary] = super()
	parameter_definitions.append(
		_editor_param(
			"end_turn_immediacy_level",
			"End Turn Immediacy",
			"enum",
			CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ALL_CARD_PLAYS,
			"Controls whether queued plays finish before the turn ends.",
			{
				"options": [
					{"label": "Wait For All Card Plays", "value": CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ALL_CARD_PLAYS},
					{"label": "After Current Card", "value": CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.AFTER_CURRENT_CARD},
					{"label": "Immediate", "value": CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.IMMEDIATE},
				]
			}
		)
	)
	return parameter_definitions

func perform_action():
	var end_turn_immediacy_level: int = get_action_value("end_turn_immediacy_level", CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ALL_CARD_PLAYS)
	Signals.end_turn_requested.emit(end_turn_immediacy_level)
