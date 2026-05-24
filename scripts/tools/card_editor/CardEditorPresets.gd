@tool
extends RefCounted
class_name CardEditorPresets

static func list_presets() -> Array[Dictionary]:
	return [
		{
			"id": "blank_attack",
			"display_name": "Blank Attack",
			"description": "Simple targeted damage card scaffold.",
		},
		{
			"id": "blank_block",
			"display_name": "Blank Block",
			"description": "Simple self-protection skill scaffold.",
		},
		{
			"id": "blank_power",
			"display_name": "Blank Power",
			"description": "Persistent effect card scaffold.",
		},
		{
			"id": "blank_status",
			"display_name": "Status Utility",
			"description": "Applies a status effect to a selected target.",
		},
		{
			"id": "blank_transform",
			"display_name": "Right-Click Transform",
			"description": "Card scaffold that includes a right-click transform hook.",
		},
	]

static func apply_preset(card_data: CardData, preset_id: String, preserve_identity: bool = true) -> bool:
	if card_data == null:
		return false
	var original_object_id: String = card_data.object_id
	var original_card_name: String = card_data.card_name
	var original_object_uid: String = card_data.object_uid
	var original_owner_party_index: int = card_data.card_owner_party_index
	var original_owner_character_object_id: String = card_data.card_owner_character_object_id

	var preset_properties: Dictionary = _get_preset_properties(preset_id)
	if preset_properties.is_empty():
		return false
	card_data.set_card_properties(preset_properties)
	if preserve_identity:
		card_data.object_id = original_object_id
		card_data.card_name = original_card_name
		card_data.object_uid = original_object_uid
		card_data.card_owner_party_index = original_owner_party_index
		card_data.card_owner_character_object_id = original_owner_character_object_id
	return true

static func get_preset_properties(preset_id: String) -> Dictionary:
	return _get_preset_properties(preset_id).duplicate(true)

static func _get_preset_properties(preset_id: String) -> Dictionary:
	match preset_id:
		"blank_attack":
			return {
				"card_description": "Deal [damage] damage.",
				"card_type": CardData.CARD_TYPES.ATTACK,
				"card_rarity": CardData.CARD_RARITIES.COMMON,
				"card_requires_target": true,
				"card_values": {"damage": 6},
				"card_play_actions": [{Scripts.ACTION_ATTACK_GENERATOR: {"damage": 6, "number_of_attacks": 1}}],
				"card_play_validators": [],
				"card_glow_validators": [],
			}
		"blank_block":
			return {
				"card_description": "Gain [block] Block.",
				"card_type": CardData.CARD_TYPES.SKILL,
				"card_rarity": CardData.CARD_RARITIES.COMMON,
				"card_requires_target": false,
				"card_values": {"block": 5},
				"card_play_actions": [{Scripts.ACTION_BLOCK: {"block": 5, "target_override": BaseAction.TARGET_OVERRIDES.PLAYER}}],
				"card_play_validators": [],
				"card_glow_validators": [],
			}
		"blank_power":
			return {
				"card_description": "Persistent effect placeholder.",
				"card_type": CardData.CARD_TYPES.POWER,
				"card_rarity": CardData.CARD_RARITIES.UNCOMMON,
				"card_requires_target": false,
				"card_values": {},
				"card_play_actions": [],
				"card_play_validators": [],
				"card_glow_validators": [],
			}
		"blank_status":
			return {
				"card_description": "Apply [amount] of a status effect.",
				"card_type": CardData.CARD_TYPES.SKILL,
				"card_rarity": CardData.CARD_RARITIES.COMMON,
				"card_requires_target": true,
				"card_values": {"amount": 1},
				"card_play_actions": [{
					Scripts.ACTION_APPLY_STATUS: {
						"status_effect_object_id": "",
						"amount": 1,
						"target_override": BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS,
					}
				}],
				"card_play_validators": [],
				"card_glow_validators": [],
			}
		"blank_transform":
			return {
				"card_description": "Right click to transform this card.",
				"card_type": CardData.CARD_TYPES.SKILL,
				"card_rarity": CardData.CARD_RARITIES.UNCOMMON,
				"card_requires_target": false,
				"card_values": {
					"transform_into_card_object_id": "",
					"transform_parent_card": false,
					"pick_played_card": true,
				},
				"card_play_actions": [],
				"card_right_click_actions": [{Scripts.ACTION_TRANSFORM_CARDS: {}}],
				"card_play_validators": [],
				"card_glow_validators": [],
			}
		_:
			return {}
