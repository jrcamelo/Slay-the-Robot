# Modifies the damage output of attack actions by strength amount
extends BaseActionInterceptor

const STATUS_EFFECT_ID: String = "status_effect_weaken"
const LEGACY_STATUS_EFFECT_ID: String = "status_effect_weaken_old"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = action_interceptor_processor.parent_action.parent_combatant
	if parent_combatant == null:
		return ACTION_ACCEPTENCES.REJECTED
	if not parent_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED
	
	var weaken_amount: int = parent_combatant.get_status_charges(STATUS_EFFECT_ID)
	if weaken_amount <= 0:
		weaken_amount = parent_combatant.get_status_charges(LEGACY_STATUS_EFFECT_ID)
	action_interceptor_processor.add_damage(-weaken_amount)
	
	return ACTION_ACCEPTENCES.CONTINUE
