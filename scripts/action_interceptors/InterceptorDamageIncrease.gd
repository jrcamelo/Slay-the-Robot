# Modifies the damage output of attack actions by strength amount
extends BaseActionInterceptor

const LEGACY_DAMAGE_INCREASE_STATUS_EFFECT_ID: String = "status_effect_damage_increase"
const MIGHT_STATUS_EFFECT_ID: String = "status_effect_might"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = action_interceptor_processor.parent_action.parent_combatant
	if parent_combatant == null:
		return ACTION_ACCEPTENCES.REJECTED
	if not parent_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED
	
	var damage_increase_charges: int = parent_combatant.get_status_charges(MIGHT_STATUS_EFFECT_ID)
	if damage_increase_charges <= 0:
		damage_increase_charges = parent_combatant.get_status_charges(LEGACY_DAMAGE_INCREASE_STATUS_EFFECT_ID)
	action_interceptor_processor.add_damage(damage_increase_charges)
	
	return ACTION_ACCEPTENCES.CONTINUE
