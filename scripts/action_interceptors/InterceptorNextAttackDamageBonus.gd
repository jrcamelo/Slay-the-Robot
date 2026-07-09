extends BaseActionInterceptor

const STATUS_EFFECT_ID: String = "status_effect_next_attack_damage_bonus"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = action_interceptor_processor.parent_action.parent_combatant
	if parent_combatant == null or not parent_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED

	var status_effects: Array[StatusEffect] = parent_combatant.get_status_effects(STATUS_EFFECT_ID)
	if status_effects.is_empty():
		return ACTION_ACCEPTENCES.CONTINUE

	var status_effect: StatusEffect = status_effects[0]
	var status_script: BaseStatusEffect = status_effect.status_effect_script
	if status_script.status_charges <= 0:
		return ACTION_ACCEPTENCES.CONTINUE

	var damage_bonus: int = max(0, status_script.status_secondary_charges)
	action_interceptor_processor.add_damage(damage_bonus)
	if not preview_mode:
		parent_combatant.add_status_effect_charges(STATUS_EFFECT_ID, -1, 0)

	return ACTION_ACCEPTENCES.CONTINUE
