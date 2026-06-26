extends BaseStatusEffect

const STATUS_BARRIER := "status_effect_barrier"
const STATUS_BLEED := "status_effect_bleed"
const STATUS_BURN := "status_effect_burn"
const STATUS_DAZE := "status_effect_daze"
const STATUS_EVASION := "status_effect_evasion"
const STATUS_GRIT := "status_effect_grit"
const STATUS_MIGHT := "status_effect_might"
const STATUS_PARALYZE := "status_effect_paralyze"
const STATUS_POISON := "status_effect_poison"
const STATUS_REGEN := "status_effect_regen"
const STATUS_SHIELD := "status_effect_shield"
const STATUS_SLEEP := "status_effect_sleep"
const STATUS_TAUNT := "status_effect_taunt"
const STATUS_THORNS := "status_effect_thorns"
const STATUS_VULNERABLE := "status_effect_vulnerable"
const STATUS_WARD := "status_effect_ward"
const STATUS_WEAKEN := "status_effect_weaken"

func _connect_signals() -> void:
	match status_effect_data.object_id:
		STATUS_SLEEP, STATUS_THORNS:
			if not Signals.combatant_damaged.is_connected(_on_combatant_damaged):
				Signals.combatant_damaged.connect(_on_combatant_damaged)

func _disconnect_signals() -> void:
	match status_effect_data.object_id:
		STATUS_SLEEP, STATUS_THORNS:
			if Signals.combatant_damaged.is_connected(_on_combatant_damaged):
				Signals.combatant_damaged.disconnect(_on_combatant_damaged)

func perform_status_effect_actions() -> void:
	match status_effect_data.object_id:
		STATUS_BARRIER:
			if _is_barrier_tick_process():
				parent_combatant.remove_status(STATUS_BARRIER, 1)
		STATUS_REGEN:
			parent_combatant.add_health(get_amount())
			tick_status()
		STATUS_BLEED:
			parent_combatant.damage(get_amount(), true, null)
			tick_status()
		STATUS_BURN:
			parent_combatant.damage(get_amount(), false, null)
			tick_status()
		STATUS_POISON:
			parent_combatant.damage(get_amount(), false, null)
			var current_turn: int = 1
			if Global.get_combat_stats() != null:
				current_turn = Global.get_combat_stats().turn_count
			if int(status_custom_values.get("last_applied_turn", -1)) != current_turn:
				tick_status()
		STATUS_VULNERABLE, STATUS_WEAKEN:
			decay_turn()

func _on_combatant_damaged(base_combatant: BaseCombatant, unblocked_damage: int, source_action: BaseAction = null) -> void:
	if base_combatant != parent_combatant or unblocked_damage <= 0:
		return
	match status_effect_data.object_id:
		STATUS_SLEEP:
			remove_self()
		STATUS_THORNS:
			if source_action == null:
				return
			var action_path: String = source_action.get_script().resource_path
			if action_path not in [Scripts.ACTION_ATTACK, Scripts.ACTION_ATTACK_POISE]:
				return
			var attacker: BaseCombatant = source_action.parent_combatant
			if attacker != null and attacker.is_alive():
				attacker.damage(get_amount(), false, null)

func _is_barrier_tick_process() -> bool:
	if parent_combatant is Player:
		return current_process_time == StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.PRE_DRAW_PLAYER_START_TURN
	if parent_combatant is Enemy:
		return current_process_time == StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.ENEMY_START_TURN
	return false
