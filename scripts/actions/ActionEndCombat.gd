extends BaseAction

func _get_editor_description() -> String:
	return "Ends the current combat immediately."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_CARD_PLAY_ACTIONS,
		EDITOR_CONTEXT_CARD_TRIGGER_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
		EDITOR_CONTEXT_ENEMY_ACTIONS,
	]

func perform_action() -> void:
	Signals.combat_ended.emit()

func is_instant_action() -> bool:
	return true

func _to_string():
	return "End Combat Action"
