extends BaseStatusEffect

const DEFAULT_COMPANION_HEALTH_MAX := 10

func init(_status_effect_data, _parent_combatant: BaseCombatant):
	super(_status_effect_data, _parent_combatant)
	if not status_custom_values.has("companion_health_max"):
		status_custom_values["companion_health_max"] = DEFAULT_COMPANION_HEALTH_MAX
	if status_secondary_charges <= 0:
		status_secondary_charges = get_companion_health_max()

func get_companion_health_max() -> int:
	return max(0, int(status_custom_values.get("companion_health_max", DEFAULT_COMPANION_HEALTH_MAX)))
