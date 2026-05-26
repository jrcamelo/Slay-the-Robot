extends RefCounted

const PROPERTY_GROUP_LABELS := {
	"card_play_validators": "Play Validators",
	"card_glow_validators": "Glow Validators",
	"card_play_actions": "Play Actions",
	"card_additional_actions": "Internal Actions",
	"card_right_click_actions": "Right Click Actions",
	"card_discard_actions": "Discard Actions",
	"card_end_of_turn_actions": "End Of Turn Actions",
	"card_exhaust_actions": "Exhaust Actions",
	"card_draw_actions": "Draw Actions",
	"card_retain_actions": "Retain Actions",
	"card_initial_combat_actions": "Initial Combat Actions",
	"card_add_to_deck_actions": "Add To Deck Actions",
	"card_remove_from_deck_actions": "Remove From Deck Actions",
	"card_transform_in_deck_actions": "Transform In Deck Actions",
}
const COLLAPSED_ARROW := "Show"
const EXPANDED_ARROW := "Hide"
const NOISY_PARAMETER_DEFAULTS := {
	"time_delay": 0.0,
	"action_tags": [],
	"action_short_circuits": false,
	"invert_validation": false,
}
const STATUS_COLORS := {
	"info": Color(0.82, 0.87, 0.95, 1.0),
	"success": Color(0.7, 0.92, 0.76, 1.0),
	"warning": Color(0.95, 0.84, 0.54, 1.0),
	"error": Color(0.96, 0.63, 0.63, 1.0),
}
const ESSENTIAL_FIELD_GROUPS := [
	{
		"title": "Identity",
		"description": "Start with the fields that actually define the card a player will recognize.",
		"columns": 2,
		"fields": ["card_name", "object_id", "card_type", "card_rarity", "card_color_id", "card_texture_path", "card_tags", "card_exhausts", "card_is_ethereal", "card_is_retained", "card_unremovable_from_deck", "card_untransformable_from_deck"],
	},
	{
		"title": "Play Profile",
		"description": "These are the knobs that usually matter first when prototyping.",
		"columns": 2,
		"fields": ["card_energy_cost", "card_kind", "card_requires_target", "card_clicked_target_mode", "card_is_playable", "card_appears_in_card_packs"],
	},
	{
		"title": "Text And Values",
		"description": "Keep the description and the values it references close together.",
		"columns": 1,
		"fields": ["card_description", "card_values", "card_keyword_object_ids"],
	},
]
const ADVANCED_FIELD_GROUPS := [
	{
		"title": "Extra Costs And Flags",
		"description": "Temporary energy overrides, hand behavior, and special combat setup.",
		"columns": 2,
		"fields": [
			"card_energy_cost_until_played",
			"card_energy_cost_until_turn",
			"card_energy_cost_until_combat",
			"card_energy_cost_is_variable",
			"card_energy_cost_variable_upper_bound",
			"card_first_shuffle_priority",
		],
	},
	{
		"title": "Upgrade Rules",
		"description": "Only touch these once the base card already feels right.",
		"columns": 1,
		"fields": [
			"card_upgrade_amount_max",
			"card_upgrade_value_improvements",
			"card_first_upgrade_property_changes",
		],
	},
	{
		"title": "Metadata And Edge Cases",
		"description": "Low-frequency fields for organization, preview customization, and deck restrictions.",
		"columns": 1,
		"fields": [
			"card_description_preview_overrides",
		],
	},
]
const PRIMARY_BEHAVIOR_GROUPS := [
	"card_play_validators",
	"card_glow_validators",
	"card_play_actions",
]
const SECONDARY_BEHAVIOR_GROUPS := [
	"card_right_click_actions",
	"card_discard_actions",
	"card_end_of_turn_actions",
	"card_exhaust_actions",
	"card_draw_actions",
	"card_retain_actions",
	"card_initial_combat_actions",
	"card_add_to_deck_actions",
	"card_remove_from_deck_actions",
	"card_transform_in_deck_actions",
]
const BEHAVIOR_GROUP_DESCRIPTIONS := {
	"card_play_validators": "Rules that block the card from being played.",
	"card_glow_validators": "Rules that make the card light up without blocking play.",
	"card_play_actions": "What the card does when played.",
	"card_additional_actions": "Reusable child actions referenced by other actions. These are internal helpers and do not run unless another action points to them.",
	"card_right_click_actions": "Optional utility behavior while the card is in hand.",
	"card_discard_actions": "Triggered only by manual discard effects.",
	"card_end_of_turn_actions": "Triggered while the card remains in hand at turn end.",
	"card_exhaust_actions": "Triggered when the card is exhausted.",
	"card_draw_actions": "Triggered when the card enters the hand by drawing.",
	"card_retain_actions": "Triggered when the card is kept in hand.",
	"card_initial_combat_actions": "Triggered once for each copy at combat start.",
	"card_add_to_deck_actions": "Triggered when the permanent deck gains this card.",
	"card_remove_from_deck_actions": "Triggered when the permanent deck loses this card.",
	"card_transform_in_deck_actions": "Triggered before a permanent deck transform.",
}
const MAX_VISIBLE_DIAGNOSTICS := 5
const DEFAULT_CARD_COLOR_IDS := [
	"color_red",
	"color_blue",
	"color_green",
	"color_orange",
	"color_white",
	"color_purple",
]
const COLLAPSED_PANEL_WIDTH := 0
const LIBRARY_PANEL_MIN_WIDTH := 240
const EDITOR_PANEL_MIN_WIDTH := 560
const PREVIEW_PANEL_MIN_WIDTH := 300
const PREVIEW_FALLBACK_CHARACTER_ID := "character_red"
