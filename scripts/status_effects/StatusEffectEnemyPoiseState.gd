extends BaseStatusEffect

const TEXTURE_FULL: String = "external/sprites/artifacts/artifact_white.png"
const TEXTURE_HIGH: String = "external/sprites/artifacts/artifact_green.png"
const TEXTURE_HALF: String = "external/sprites/artifacts/artifact_yellow.png"
const TEXTURE_LOW: String = "external/sprites/artifacts/artifact_orange.png"
const TEXTURE_BROKEN: String = "external/sprites/artifacts/artifact_red.png"

func init(_status_effect_data, _parent_combatant: BaseCombatant):
	super(_status_effect_data, _parent_combatant)
	refresh_from_parent_state()

func get_display_name() -> String:
	return _get_poise_state_data()["name"]

func get_display_description() -> String:
	var poise_state_data: Dictionary = _get_poise_state_data()
	var current_poise: int = _get_current_poise()
	var poise_max: int = _get_poise_max()
	if poise_max <= 0:
		return poise_state_data["description"]
	return "%s\nPoise: %s/%s" % [poise_state_data["description"], current_poise, poise_max]

func get_display_texture_path() -> String:
	return _get_poise_state_data()["texture"]

func refresh_from_parent_state() -> void:
	status_secondary_charges = _get_current_poise()
	refresh_status_effect_display()
	_pin_status_to_front()

func _get_poise_state_data() -> Dictionary:
	var poise_max: int = _get_poise_max()
	var current_poise: int = _get_current_poise()
	if poise_max <= 0 or current_poise <= 0:
		return {
			"name": "Broken Poise!",
			"description": "This enemy's poise is broken.",
			"texture": TEXTURE_BROKEN,
		}
	var poise_percent: float = float(current_poise) / float(max(1, poise_max))
	if poise_percent > 0.75:
		return {
			"name": "Full Poise",
			"description": "This enemy has more than 75% of its poise remaining.",
			"texture": TEXTURE_FULL,
		}
	if poise_percent > 0.5:
		return {
			"name": "High Poise",
			"description": "This enemy has more than 50% of its poise remaining.",
			"texture": TEXTURE_HIGH,
		}
	if poise_percent > 0.25:
		return {
			"name": "Half Poise",
			"description": "This enemy has more than 25% of its poise remaining.",
			"texture": TEXTURE_HALF,
		}
	return {
		"name": "Low Poise",
		"description": "This enemy is below 25% poise and close to breaking.",
		"texture": TEXTURE_LOW,
	}

func _pin_status_to_front() -> void:
	if parent_combatant == null:
		return
	var status_effects: Array[StatusEffect] = parent_combatant.get_status_effects(status_effect_data.object_id)
	if status_effects.is_empty():
		return
	var status_effect: StatusEffect = status_effects[0]
	if status_effect.get_parent() != null:
		status_effect.get_parent().move_child(status_effect, 0)

func _get_current_poise() -> int:
	if parent_combatant is Enemy:
		return (parent_combatant as Enemy).get_poise()
	return 0

func _get_poise_max() -> int:
	if parent_combatant is Enemy:
		return (parent_combatant as Enemy).get_poise_max()
	return 0
