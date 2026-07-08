# Completely stops damage from happening
# Tied to corresponding status effect
extends BaseActionInterceptor

const NEGATE_DAMAGE_STATUS_EFFECT_ID: String = "status_effect_negate_damage"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, preview_mode: bool = false) -> int:
	if preview_mode:
		return ACTION_ACCEPTENCES.CONTINUE	# don't negate damage in preview mode
	
	var target_combatant: BaseCombatant = action_interceptor_processor.target
	if target_combatant == null:
		return ACTION_ACCEPTENCES.REJECTED
	if not target_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED
	
	var damage: int = action_interceptor_processor.get_shadowed_action_values("damage", 0)
	if damage > 0:
		# consume the negate effect on the next incoming attack damage instance
		target_combatant.add_status_effect_charges(NEGATE_DAMAGE_STATUS_EFFECT_ID, -1)
		action_interceptor_processor.set_damage(0)
		return ACTION_ACCEPTENCES.STOPPED
	
	return ACTION_ACCEPTENCES.CONTINUE
