extends BaseActionInterceptor

const STATUS_EFFECT_ID: String = "status_effect_burn"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, preview_mode: bool = false) -> int:
	if preview_mode:
		return ACTION_ACCEPTENCES.CONTINUE
	var target_combatant: BaseCombatant = action_interceptor_processor.target
	if target_combatant == null or not target_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED
	if target_combatant.get_status_charges(STATUS_EFFECT_ID) <= 0:
		return ACTION_ACCEPTENCES.CONTINUE
	return ACTION_ACCEPTENCES.REJECTED
