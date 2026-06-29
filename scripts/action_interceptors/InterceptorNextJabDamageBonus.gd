extends BaseActionInterceptor

const STATUS_EFFECT_ID: String = "status_effect_next_jab_damage_bonus"
const JAB_CARD_ID: String = "card_monk_jab"

func process_action_interception(action_interceptor_processor: ActionInterceptorProcessor, preview_mode: bool = false) -> int:
	var action: BaseAction = action_interceptor_processor.parent_action
	var parent_combatant: BaseCombatant = action.parent_combatant
	if parent_combatant == null or not parent_combatant.is_alive():
		return ACTION_ACCEPTENCES.REJECTED
	if action.card_play_request == null or action.card_play_request.card_data == null:
		return ACTION_ACCEPTENCES.CONTINUE
	if action.card_play_request.card_data.object_id != JAB_CARD_ID:
		return ACTION_ACCEPTENCES.CONTINUE
	var status_effects: Array[StatusEffect] = parent_combatant.status_id_to_status_effects.get(STATUS_EFFECT_ID, [])
	if status_effects.is_empty():
		return ACTION_ACCEPTENCES.CONTINUE
	var status_effect: StatusEffect = status_effects[0]
	var damage_bonus: int = max(0, status_effect.status_effect_script.status_secondary_charges)
	if damage_bonus <= 0:
		return ACTION_ACCEPTENCES.CONTINUE
	var current_damage: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.DAMAGE, 0)
	action_interceptor_processor.shadowed_action_values[ActionValueRegistry.DAMAGE] = current_damage + damage_bonus
	if not preview_mode:
		parent_combatant.remove_status(STATUS_EFFECT_ID, -1)
	return ACTION_ACCEPTENCES.CONTINUE
