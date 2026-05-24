@tool
extends RefCounted
class_name CardEditorSchema

static func get_card_field_sections() -> Array[Dictionary]:
	return [
		{
			"id": "identity",
			"label": "Identity",
			"fields": ["object_id", "card_name", "card_description", "card_texture_path", "card_color_id", "card_keyword_object_ids", "card_tags"],
		},
		{
			"id": "classification",
			"label": "Classification",
			"fields": ["card_kind", "card_type", "card_rarity", "card_requires_target", "card_appears_in_card_packs"],
		},
		{
			"id": "costs",
			"label": "Costs",
			"fields": [
				"card_energy_cost",
				"card_energy_cost_until_played",
				"card_energy_cost_until_turn",
				"card_energy_cost_until_combat",
				"card_energy_cost_is_variable",
				"card_energy_cost_variable_upper_bound",
				"card_first_shuffle_priority",
			],
		},
		{
			"id": "play_flags",
			"label": "Play Flags",
			"fields": ["card_is_playable", "card_exhausts", "card_is_ethereal", "card_is_retained"],
		},
		{
			"id": "values",
			"label": "Values",
			"fields": ["card_values", "card_description_preview_overrides"],
		},
		{
			"id": "upgrades",
			"label": "Upgrades",
			"fields": ["card_upgrade_amount", "card_upgrade_amount_max", "card_first_upgrade_property_changes", "card_upgrade_value_improvements"],
		},
		{
			"id": "deck_flags",
			"label": "Deck Flags",
			"fields": ["card_unremovable_from_deck", "card_untransformable_from_deck"],
		},
	]

static func get_card_field_definitions() -> Dictionary[String, Dictionary]:
	return {
		"object_id": _field("Object ID", "string", "Unique stable ID used by content and save systems."),
		"card_name": _field("Card Name", "string", "Display name rendered on the card."),
		"card_description": _field("Description", "multiline_string", "Rendered BBCode-friendly description. Value placeholders like [damage] are supported."),
		"card_texture_path": _field("Texture Path", "resource_path", "Texture path used for the card art."),
		"card_color_id": _field("Color", "string", "Logical card color ID like color_red."),
		"card_keyword_object_ids": _field("Keywords", "string_array", "Keyword IDs shown in the hover tooltip."),
		"card_tags": _field("Tags", "string_array", "Freeform card tags used by validators and effects."),
		"card_kind": _field("Kind", "enum", "Custom card kind used by sequencing rules.", {"options": _enum_options_from_strings(CardData.CARD_KINDS)}),
		"card_type": _field("Type", "enum", "Gameplay type displayed on the card.", {"options": _enum_options(CardData.CARD_TYPES)}),
		"card_rarity": _field("Rarity", "enum", "Card rarity used in filtering and draft pools.", {"options": _enum_options(CardData.CARD_RARITIES)}),
		"card_requires_target": _field("Requires Target", "bool", "Whether the card asks the player to choose a target."),
		"card_appears_in_card_packs": _field("Appears In Packs", "bool", "Whether this card is included in card pack caches."),
		"card_energy_cost": _field("Energy Cost", "int", "Base card energy cost."),
		"card_energy_cost_until_played": _field("Cost Until Played", "int", "Temporary cost override until the card is played. -1 disables."),
		"card_energy_cost_until_turn": _field("Cost Until Turn", "int", "Temporary cost override until end of turn. -1 disables."),
		"card_energy_cost_until_combat": _field("Cost Until Combat", "int", "Temporary cost override until combat ends. -1 disables."),
		"card_energy_cost_is_variable": _field("Variable Cost", "bool", "Makes the card spend all remaining available energy."),
		"card_energy_cost_variable_upper_bound": _field("Variable Upper Bound", "int", "Optional cap for variable/X costs. -1 disables."),
		"card_first_shuffle_priority": _field("Opening Shuffle Priority", "int", "Positive values move earlier in the combat opening shuffle."),
		"card_is_playable": _field("Playable", "bool", "If false, the card is informational or passive."),
		"card_exhausts": _field("Exhausts", "bool", "Moves to exhaust when played."),
		"card_is_ethereal": _field("Ethereal", "bool", "Exhausts if left in hand at end of turn."),
		"card_is_retained": _field("Retained", "bool", "Stays in hand at end of turn."),
		"card_values": _field("Card Values", "dictionary", "Named values consumed by actions and description placeholders.", {"key_type": "string", "item_value_type": "variant"}),
		"card_description_preview_overrides": _field("Preview Overrides", "array", "Custom preview rules for live description rendering."),
		"card_upgrade_amount": _field("Upgrade Amount", "int", "Current upgrade count."),
		"card_upgrade_amount_max": _field("Max Upgrades", "int", "Maximum number of upgrades."),
		"card_first_upgrade_property_changes": _field("First Upgrade Property Changes", "dictionary", "Property overrides applied on the first upgrade only.", {"key_type": "string", "item_value_type": "variant"}),
		"card_upgrade_value_improvements": _field("Upgrade Value Improvements", "dictionary", "Value deltas applied on each upgrade.", {"key_type": "string", "item_value_type": "variant"}),
		"card_unremovable_from_deck": _field("Unremovable", "bool", "Marks the card as protected from remove-card effects."),
		"card_untransformable_from_deck": _field("Untransformable", "bool", "Marks the card as protected from transform effects."),
	}

static func get_action_property_names() -> Array[String]:
	return [
		"card_play_actions",
		"card_discard_actions",
		"card_end_of_turn_actions",
		"card_exhaust_actions",
		"card_draw_actions",
		"card_retain_actions",
		"card_right_click_actions",
		"card_initial_combat_actions",
		"card_add_to_deck_actions",
		"card_remove_from_deck_actions",
		"card_transform_in_deck_actions",
	]

static func get_validator_property_names() -> Array[String]:
	return [
		"card_play_validators",
		"card_glow_validators",
	]

static func get_library_filter_definitions() -> Array[Dictionary]:
	return [
		{"id": "source_bucket", "label": "Source", "value_type": "enum", "options": [{"label": "Content", "value": "content"}, {"label": "Triage", "value": "triage"}]},
		{"id": "owner_bucket", "label": "Owner", "value_type": "string"},
		{"id": "card_color_id", "label": "Color", "value_type": "string"},
		{"id": "card_type", "label": "Type", "value_type": "enum", "options": _enum_options(CardData.CARD_TYPES)},
		{"id": "card_rarity", "label": "Rarity", "value_type": "enum", "options": _enum_options(CardData.CARD_RARITIES)},
		{"id": "card_kind", "label": "Kind", "value_type": "enum", "options": _enum_options_from_strings(CardData.CARD_KINDS)},
		{"id": "card_requires_target", "label": "Requires Target", "value_type": "bool"},
	]

static func _field(label: String, value_type: String, description: String, extra: Dictionary = {}) -> Dictionary:
	var field_data: Dictionary = {
		"label": label,
		"value_type": value_type,
		"description": description,
	}
	for key: Variant in extra.keys():
		field_data[key] = extra[key]
	return field_data

static func _enum_options(enum_map: Dictionary) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for enum_key: String in enum_map.keys():
		options.append({
			"label": enum_key.to_snake_case().replace("_", " ").capitalize(),
			"value": enum_map[enum_key],
		})
	options.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("value", 0)) < int(right.get("value", 0))
	)
	return options

static func _enum_options_from_strings(values: Array[String]) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for value: String in values:
		options.append({
			"label": value.to_snake_case().replace("_", " ").capitalize(),
			"value": value,
		})
	return options
