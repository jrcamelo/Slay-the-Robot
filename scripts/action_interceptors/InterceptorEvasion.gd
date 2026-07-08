extends BaseActionInterceptor

const STATUS_EFFECT_ID: String = "status_effect_evasion"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, preview_mode: bool = false) -> int:
	var target_combatant: BaseCombatant = action_interceptor_processor.target
	if target_combatant == null or not target_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED
	if target_combatant.get_status_charges(STATUS_EFFECT_ID) <= 0:
		return ACTION_ACCEPTENCES.CONTINUE
	action_interceptor_processor.set_damage(0)
	action_interceptor_processor.shadowed_action_values["poise_amount"] = 0
	if not preview_mode:
		target_combatant.consume_flag_status(STATUS_EFFECT_ID)
	return ACTION_ACCEPTENCES.STOPPED
