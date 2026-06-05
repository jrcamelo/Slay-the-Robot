extends BaseActionInterceptor

const STATUS_EFFECT_ID := "status_effect_next_attack_double_damage"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = action_interceptor_processor.parent_action.parent_combatant
	if parent_combatant == null or not parent_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED

	var status_effects: Array[StatusEffect] = parent_combatant.status_id_to_status_effects.get(STATUS_EFFECT_ID, [])
	if status_effects.is_empty():
		return ACTION_ACCEPTENCES.CONTINUE

	var status_effect: StatusEffect = status_effects[0]
	var status_script: BaseStatusEffect = status_effect.status_effect_script
	if status_script.status_charges <= 0:
		return ACTION_ACCEPTENCES.CONTINUE

	var current_damage: int = action_interceptor_processor.get_shadowed_action_values("damage", 0)
	action_interceptor_processor.shadowed_action_values["damage"] = current_damage * 2
	if not preview_mode:
		parent_combatant.add_status_effect_charges(STATUS_EFFECT_ID, -1, 0)

	return ACTION_ACCEPTENCES.CONTINUE
