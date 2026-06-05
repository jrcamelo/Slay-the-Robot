extends BaseActionInterceptor

const STATUS_EFFECT_ID: String = "status_effect_next_attack_piercing"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = action_interceptor_processor.parent_action.parent_combatant
	if parent_combatant == null or not parent_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED

	var status_charges: int = parent_combatant.get_status_charges(STATUS_EFFECT_ID)
	if status_charges <= 0:
		return ACTION_ACCEPTENCES.CONTINUE

	action_interceptor_processor.shadowed_action_values["bypass_block"] = true
	if not preview_mode:
		parent_combatant.add_status_effect_charges(STATUS_EFFECT_ID, -1, 0)

	return ACTION_ACCEPTENCES.CONTINUE
