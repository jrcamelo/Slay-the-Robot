extends BaseArtifact

func connect_signals() -> void:
	# override
	Signals.enemy_killed.connect(_on_enemy_killed)

func disconnect_signals() -> void:
	_disconnect_signal(Signals.enemy_killed, _on_enemy_killed)
	
func _on_enemy_killed(_enemy: Enemy) -> void:
	# must have at least one enemy remaining
	if len(Global.get_tree().get_nodes_in_group("enemies")) > 0:
		
		var action_data: Array[Dictionary] = [{
		Scripts.ACTION_DRAW_GENERATOR: {"draw_count": 1}
		}]
		var generated_draw_actions: Array[BaseAction] = ActionGenerator.create_actions(get_owner_player(), null, [], action_data, null)

		ActionHandler.add_actions(generated_draw_actions)
		
		Signals.artifact_proc.emit(artifact_data)
