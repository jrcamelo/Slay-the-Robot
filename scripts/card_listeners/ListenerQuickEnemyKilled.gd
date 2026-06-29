extends BaseQuickReactionListener

func _connect_signals() -> void:
	Signals.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(_enemy: Enemy) -> void:
	var reaction_request: CardPlayRequest = _begin_reaction(null, null)
	if reaction_request == null:
		return
	_queue_reaction_actions(reaction_request)
	_finish_reaction(reaction_request)
