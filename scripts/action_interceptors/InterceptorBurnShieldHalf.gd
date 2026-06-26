extends BaseActionInterceptor

const STATUS_EFFECT_ID: String = "status_effect_burn"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var target_combatant: BaseCombatant = action_interceptor_processor.target
	if target_combatant == null or not target_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED
	if target_combatant.get_status_charges(STATUS_EFFECT_ID) <= 0:
		return ACTION_ACCEPTENCES.CONTINUE
	var current_block: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.BLOCK, 0)
	action_interceptor_processor.shadowed_action_values[ActionValueRegistry.BLOCK] = int(floor(float(current_block) * 0.5))
	return ACTION_ACCEPTENCES.CONTINUE
