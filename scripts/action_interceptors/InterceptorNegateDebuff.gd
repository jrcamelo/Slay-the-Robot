# Completely stop a debuff from happening
# Tied to corresponding status effect
extends BaseActionInterceptor

const NEGATE_DEBUFF_STATUS_EFFECT_ID: String = "status_effect_negate_debuff"
const WARD_STATUS_EFFECT_ID: String = "status_effect_ward"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, preview_mode: bool = false) -> int:
	if preview_mode:
		return ACTION_ACCEPTENCES.CONTINUE
	
	var target_combatant: BaseCombatant = action_interceptor_processor.target
	if target_combatant == null:
		return ACTION_ACCEPTENCES.REJECTED
	if not target_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED
	
	var status_charge_amount: int = action_interceptor_processor.get_shadowed_action_values("status_charge_amount", 0)
	var status_effect_object_id: String = action_interceptor_processor.get_shadowed_action_values("status_effect_object_id", "")
	
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	if status_effect_data == null:
		push_error("Status effect \"", status_effect_object_id,"\" does not exist")
		return ACTION_ACCEPTENCES.REJECTED
	
	var status_effect_is_debuff: bool = status_effect_data.status_effect_disposition == StatusEffectData.STATUS_DISPOSITIONS.NEGATIVE
	if not status_effect_is_debuff:
		if status_effect_data.status_effect_type == StatusEffectData.STATUS_EFFECT_TYPES.BUFF:
			status_effect_is_debuff = status_charge_amount < 0
		elif status_effect_data.status_effect_type == StatusEffectData.STATUS_EFFECT_TYPES.DEBUFF:
			status_effect_is_debuff = status_charge_amount > 0
	
	if status_effect_is_debuff:
		if target_combatant.get_status_charges(WARD_STATUS_EFFECT_ID) > 0:
			target_combatant.consume_flag_status(WARD_STATUS_EFFECT_ID)
			return ACTION_ACCEPTENCES.REJECTED # prevent the debuff from processing
		if target_combatant.get_status_charges(NEGATE_DEBUFF_STATUS_EFFECT_ID) > 0:
			target_combatant.add_status_effect_charges(NEGATE_DEBUFF_STATUS_EFFECT_ID, -1)
			return ACTION_ACCEPTENCES.REJECTED # prevent the debuff from processing
	
	return ACTION_ACCEPTENCES.CONTINUE
