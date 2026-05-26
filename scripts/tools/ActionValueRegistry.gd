@tool
extends RefCounted
class_name ActionValueRegistry

static var _definitions_cache: Dictionary[String, Dictionary] = {}
static var _all_value_names_cache: Array[String] = []
static var _referenceable_value_names_cache: Array[String] = []
static var _all_value_options_cache: Array[Dictionary] = []
static var _referenceable_value_options_cache: Array[Dictionary] = []
static var _card_value_definitions_cache: Dictionary[String, Dictionary] = {}

const ACT_ID := "act_id"
const ACT_NUMBER := "act_number"
const ADD_CARD_PACK_OBJECT_IDS := "add_card_pack_object_ids"
const ADD_REST_ACTION_OBJECT_IDS := "add_rest_action_object_ids"
const ARTIFACT_CHARGE_INCREASE := "artifact_charge_increase"
const ARTIFACT_ID := "artifact_id"
const ARTIFACT_IDS := "artifact_ids"
const AUTOSAVE_BEFORE_VISIT := "autosave_before_visit"
const BLACKLIST_CARD_OBJECT_IDS := "blacklist_card_object_ids"
const BLOCK := "block"
const BYPASS_BLOCK := "bypass_block"
const CARD_COST_MAX := "card_cost_max"
const CARD_COST_MIN := "card_cost_min"
const CARD_DESTINATION := "card_destination"
const CARD_DRAFTS := "card_drafts"
const CARD_ENERGY_COST := "card_energy_cost"
const CARD_ENERGY_COST_UNTIL_COMBAT := "card_energy_cost_until_combat"
const CARD_ENERGY_COST_UNTIL_PLAYED := "card_energy_cost_until_played"
const CARD_ENERGY_COST_UNTIL_TURN := "card_energy_cost_until_turn"
const CARD_PICK_TEXT := "card_pick_text"
const CARD_PICK_TYPE := "card_pick_type"
const CHANGE_PARENT_CARD := "change_parent_card"
const CHEST_ARTIFACT_COUNT := "chest_artifact_count"
const CHEST_CARD_AMOUNT_DRAFT := "chest_card_amount_draft"
const CHEST_CARDS := "chest_cards"
const CHEST_CARDS_PER_DRAFT := "chest_cards_per_draft"
const CHEST_CONSUMABLE_COUNT := "chest_consumable_count"
const CHEST_GENERATES_ARTIFACTS := "chest_generates_artifacts"
const CHEST_GENERATES_CARDS := "chest_generates_cards"
const CHEST_GENERATES_CONSUMABLES := "chest_generates_consumables"
const CHEST_GENERATES_MONEY := "chest_generates_money"
const CHEST_HAS_ARTIFACTS := "chest_has_artifacts"
const CHEST_HAS_CARDS := "chest_has_cards"
const CHEST_HAS_CONSUMABLES := "chest_has_consumables"
const CHEST_HAS_MONEY := "chest_has_money"
const CHEST_MONEY := "chest_money"
const CONSUMABLE_BLACKLIST_IDS := "consumable_blacklist_ids"
const CONSUMABLE_IDS := "consumable_ids"
const CONSUMABLE_OBJECT_ID := "consumable_object_id"
const CONSUMABLE_SLOT_INDEX := "consumable_slot_index"
const CONSUMABLE_WHITELIST_IDS := "consumable_whitelist_ids"
const CREATED_CARD_OBJECT_ID := "created_card_object_id"
const CUSTOM_SIGNAL_OBJECT_ID := "custom_signal_object_id"
const CUSTOM_SIGNAL_VALUE := "custom_signal_value"
const CUSTOM_UI_OBJECT_ID := "custom_ui_object_id"
const DAMAGE := "damage"
const DAMAGE_RANDOM := "damage_random"
const DRAFT_CARD_PACK_ID := "draft_card_pack_id"
const DRAFT_FROM_CARD_POOL := "draft_from_card_pool"
const DRAFT_IS_WEIGHTED := "draft_is_weighted"
const DRAFT_MAX_CARD_AMOUNT := "draft_max_card_amount"
const DRAFT_USE_PITY_SYSTEM := "draft_use_pity_system"
const DRAFT_USE_PLAYER_DRAFT := "draft_use_player_draft"
const DRAW_COUNT := "draw_count"
const ENABLE_CUSTOM_UI := "enable_custom_ui"
const END_TURN_IMMEDIACY_LEVEL := "end_turn_immediacy_level"
const ENERGY_AMOUNT := "energy_amount"
const ENERGY_AMOUNT_MAX := "energy_amount_max"
const EVENT_OBJECT_ID := "event_object_id"
const FILL_ALL_SLOTS := "fill_all_slots"
const FLOORS_PER_ACT := "floors_per_act"
const FORCE_UPGRADE_LEVEL := "force_upgrade_level"
const HAND_CARD_COUNT_MAX := "hand_card_count_max"
const HEALTH_AMOUNT := "health_amount"
const HEALTH_MAX_AMOUNT := "health_max_amount"
const IMPROVE_PARENT_CARD := "improve_parent_card"
const IS_TOTAL_STAT := "is_total_stat"
const KEEP_COLOR := "keep_color"
const KEEP_RARITY := "keep_rarity"
const KEEP_TYPE := "keep_type"
const KEEP_UPGRADE_LEVEL := "keep_upgrade_level"
const LOCATION_ID := "location_id"
const LOCATION_NON_COMBAT_EVENT_RATE := "location_non_combat_event_rate"
const LOCATION_OBFUSCATION_RATE := "location_obfuscation_rate"
const LOCATIONS_PER_FLOOR := "locations_per_floor"
const LOG_MESSAGE := "log_message"
const LOG_MESSAGE_COLOR_HTML := "log_message_color_html"
const LOG_SEVERITY := "log_severity"
const MAX_CARD_AMOUNT := "max_card_amount"
const MERGE_ATTACKS := "merge_attacks"
const MIN_CARD_AMOUNT := "min_card_amount"
const MIN_CARDS_ARE_REQUIRED_FOR_ACTION := "min_cards_are_required_for_action"
const MONEY_AMOUNT := "money_amount"
const MULTIPLIED_VALUES := "multiplied_values"
const MULTIPLIED_VALUES_BASES := "multiplied_values_bases"
const MULTIPLIER_OFFSET := "multiplier_offset"
const NUMBER_OF_ATTACKS := "number_of_attacks"
const NUMBER_OF_CARDS := "number_of_cards"
const NUMBER_OF_SPAWNS := "number_of_spawns"
const OVERKILL_DAMAGE := "overkill_damage"
const PERCENTAGE_HEAL_AMOUNT := "percentage_heal_amount"
const PICK_DRAFT_CARDS := "pick_draft_cards"
const PICK_PLAYED_CARD := "pick_played_card"
const PICKABLE_CARDS_MAX_AMOUNT := "pickable_cards_max_amount"
const QUICK_PICK := "quick_pick"
const RANDOM_CONSUMABLE := "random_consumable"
const RANDOM_ENEMY_OBJECT_IDS := "random_enemy_object_ids"
const RANDOM_SELECTION := "random_selection"
const RANDOMIZE_CARD_ENERGY_COST := "randomize_card_energy_cost"
const RANDOMIZE_CARD_ENERGY_COST_UNTIL_COMBAT := "randomize_card_energy_cost_until_combat"
const RANDOMIZE_CARD_ENERGY_COST_UNTIL_PLAYED := "randomize_card_energy_cost_until_played"
const RANDOMIZE_CARD_ENERGY_COST_UNTIL_TURN := "randomize_card_energy_cost_until_turn"
const REMOVE_ALL_CARD_PACKS := "remove_all_card_packs"
const REMOVE_CARD_PACK_OBJECT_IDS := "remove_card_pack_object_ids"
const REMOVE_REST_ACTION_OBJECT_IDS := "remove_rest_action_object_ids"
const RESET_TO_STARTING_CARD_PACKS := "reset_to_starting_card_packs"
const REWARD_GROUP := "reward_group"
const SHOP_ARTIFACT_IDS := "shop_artifact_ids"
const SHOP_ARTIFACT_PRICES := "shop_artifact_prices"
const SHOP_CARD_PRICES := "shop_card_prices"
const SHOP_CONSUMABLE_IDS := "shop_consumable_ids"
const SHOP_CONSUMABLE_PRICES := "shop_consumable_prices"
const SHUFFLE_DISCARD_INTO_DRAW := "shuffle_discard_into_draw"
const SPAWN_SLOTS := "spawn_slots"
const STAT_ENUM := "stat_enum"
const STATUS_CHARGE_AMOUNT := "status_charge_amount"
const STATUS_EFFECT_OBJECT_ID := "status_effect_object_id"
const STATUS_FORCE_APPLY_NEW_EFFECT := "status_force_apply_new_effect"
const STATUS_SECONDARY_CHARGE_AMOUNT := "status_secondary_charge_amount"
const TRANSFORM_COLORS := "transform_colors"
const TRANSFORM_INTO_CARD_OBJECT_ID := "transform_into_card_object_id"
const TRANSFORM_PARENT_CARD := "transform_parent_card"
const TRANSFORM_RARITIES := "transform_rarities"
const TRANSFORM_TYPES := "transform_types"
const UNBLOCKED_DAMAGE := "unblocked_damage"
const UNBLOCKED_DAMAGE_CAPPED := "unblocked_damage_capped"
const UPGRADE_PARENT_CARD := "upgrade_parent_card"
const WHITELIST_CARD_OBJECT_IDS := "whitelist_card_object_ids"

static func has_definition(value_name: String) -> bool:
	return get_definitions().has(value_name)

static func get_definition(value_name: String) -> Dictionary:
	return get_definitions().get(value_name, {})

static func get_all_value_names() -> Array[String]:
	if _all_value_names_cache.is_empty():
		_all_value_names_cache.assign(get_definitions().keys())
		_all_value_names_cache.sort()
	return _all_value_names_cache

static func get_value_options(value_names: Array[String] = []) -> Array[Dictionary]:
	if value_names.is_empty():
		if _all_value_options_cache.is_empty():
			_all_value_options_cache = _get_value_options_from_definitions(get_definitions())
		return _all_value_options_cache
	return _get_value_options_from_definitions(get_definitions(), value_names)

static func _get_value_options_from_definitions(definitions: Dictionary[String, Dictionary], value_names: Array[String] = []) -> Array[Dictionary]:
	var names: Array[String] = value_names
	if names.is_empty():
		names.assign(definitions.keys())
		names.sort()
	var options: Array[Dictionary] = []
	for value_name: String in names:
		var definition: Dictionary = definitions.get(value_name, {})
		options.append({
			"label": str(definition.get("label", _default_label(value_name))),
			"value": value_name,
		})
	return options

static func get_referenceable_value_names() -> Array[String]:
	if _referenceable_value_names_cache.is_empty():
		_referenceable_value_names_cache = _get_referenceable_value_names_from_definitions(get_definitions())
	return _referenceable_value_names_cache

static func get_referenceable_value_options() -> Array[Dictionary]:
	if _referenceable_value_options_cache.is_empty():
		_referenceable_value_options_cache = _get_value_options_from_definitions(get_definitions(), get_referenceable_value_names())
	return _referenceable_value_options_cache

static func get_card_value_definitions() -> Dictionary[String, Dictionary]:
	if not _card_value_definitions_cache.is_empty():
		return _card_value_definitions_cache
	var definitions: Dictionary[String, Dictionary] = {}
	for value_name: String in get_all_value_names():
		var definition: Dictionary = get_definition(value_name)
		var value_type: String = str(definition.get("value_type", "variant"))
		if value_type not in ["int", "float", "bool", "string", "enum"]:
			continue
		if not bool(definition.get("card_value", true)):
			continue
		definitions[value_name] = {
			"label": definition.get("label", _default_label(value_name)),
			"description": definition.get("description", ""),
			"value_type": value_type,
			"default_value": definition.get("default_value", null),
			"options": definition.get("options", []),
		}
	_card_value_definitions_cache = definitions
	return _card_value_definitions_cache

static func apply_definition(parameter_definition: Dictionary) -> Dictionary:
	var parameter_name: String = str(parameter_definition.get("name", ""))
	var definition: Dictionary = get_definition(parameter_name)
	if definition.is_empty():
		return parameter_definition
	var merged: Dictionary = parameter_definition.duplicate(true)
	merged["label"] = definition.get("label", merged.get("label", _default_label(parameter_name)))
	merged["description"] = definition.get("description", merged.get("description", ""))
	merged["value_type"] = definition.get("value_type", merged.get("value_type", "variant"))
	merged["default_value"] = definition.get("default_value", merged.get("default_value", null))
	if definition.has("options"):
		merged["options"] = definition.get("options", [])
	return merged

static func get_definitions() -> Dictionary[String, Dictionary]:
	if not _definitions_cache.is_empty():
		return _definitions_cache
	var definitions: Dictionary[String, Dictionary] = {
		ACT_ID: _def("Act ID", "string", "", "Act object_id to generate."),
		ACT_NUMBER: _def("Act Number", "int", 1, "Run act number to assign."),
		ADD_CARD_PACK_OBJECT_IDS: _def("Add Card Packs", "string_array", [], "Card pack object_ids to add to the draft pool.", {"card_value": false}),
		ADD_REST_ACTION_OBJECT_IDS: _def("Add Rest Actions", "string_array", [], "Rest action object_ids to add.", {"card_value": false}),
		ARTIFACT_CHARGE_INCREASE: _def("Artifact Charge Increase", "int", 0, "Amount of charge to add to the artifact."),
		ARTIFACT_ID: _def("Artifact ID", "string", "", "Artifact object_id to reference."),
		ARTIFACT_IDS: _def("Artifact IDs", "string_array", [], "Artifact object_ids to use.", {"card_value": false}),
		AUTOSAVE_BEFORE_VISIT: _def("Autosave Before Visit", "bool", true, "Whether to autosave before visiting the location.", {"card_value": false}),
		BLACKLIST_CARD_OBJECT_IDS: _def("Blacklist Card IDs", "string_array", [], "Card object_ids to exclude.", {"card_value": false}),
		BLOCK: _def("Block", "int", 0, "Block amount granted or consumed.", {"referenceable": true}),
		BYPASS_BLOCK: _def("Bypass Block", "bool", false, "Whether damage ignores block.", {"referenceable": true}),
		CARD_COST_MAX: _def("Card Cost Max", "int", 3, "Maximum randomized card cost."),
		CARD_COST_MIN: _def("Card Cost Min", "int", 0, "Minimum randomized card cost."),
		CARD_DESTINATION: _def("Card Destination", "enum", CardPlayRequest.CARD_PLAY_DESTINATIONS.DRAW_TOP, "Destination within the draw pile or piles.", {"options": _card_destination_options()}),
		CARD_DRAFTS: _def("Card Drafts", "array", [], "Reward card draft payloads.", {"card_value": false}),
		CARD_ENERGY_COST: _def("Card Energy Cost", "int", 1, "Base card energy cost.", {"referenceable": true}),
		CARD_ENERGY_COST_UNTIL_COMBAT: _def("Cost Until Combat", "int", -1, "Temporary cost override lasting until combat ends."),
		CARD_ENERGY_COST_UNTIL_PLAYED: _def("Cost Until Played", "int", -1, "Temporary cost override lasting until the card is played."),
		CARD_ENERGY_COST_UNTIL_TURN: _def("Cost Until Turn", "int", -1, "Temporary cost override lasting until end of turn."),
		CARD_PICK_TEXT: _def("Card Pick Text", "string", "Choose {0} card(s). {1} cards selected", "Prompt shown while selecting cards."),
		CARD_PICK_TYPE: _def("Card Pick Type", "enum", ActionBasePickCards.CARD_PICK_TYPES.HAND, "Source pile and UI style for the card pick.", {"options": _card_pick_type_options()}),
		CHANGE_PARENT_CARD: _def("Change Parent Card", "bool", true, "Apply property changes to the permanent parent card when available.", {"referenceable": true}),
		CHEST_ARTIFACT_COUNT: _def("Chest Artifact Count", "int", 1, "Number of artifact rewards to generate."),
		CHEST_CARD_AMOUNT_DRAFT: _def("Chest Card Draft Count", "int", 1, "Number of card draft choices to present."),
		CHEST_CARDS: _def("Chest Cards", "array", [], "Explicit chest card rewards.", {"card_value": false}),
		CHEST_CARDS_PER_DRAFT: _def("Chest Cards Per Draft", "int", 3, "Cards shown per draft choice."),
		CHEST_CONSUMABLE_COUNT: _def("Chest Consumable Count", "int", 1, "Number of consumables to generate."),
		CHEST_GENERATES_ARTIFACTS: _def("Generate Artifacts", "bool", true, "Generate artifact rewards instead of only using explicit values."),
		CHEST_GENERATES_CARDS: _def("Generate Cards", "bool", true, "Generate card rewards instead of only using explicit values."),
		CHEST_GENERATES_CONSUMABLES: _def("Generate Consumables", "bool", true, "Generate consumable rewards instead of only using explicit values."),
		CHEST_GENERATES_MONEY: _def("Generate Money", "bool", true, "Generate money reward instead of only using explicit values."),
		CHEST_HAS_ARTIFACTS: _def("Chest Has Artifacts", "bool", true, "Whether the chest can include artifacts."),
		CHEST_HAS_CARDS: _def("Chest Has Cards", "bool", true, "Whether the chest can include cards."),
		CHEST_HAS_CONSUMABLES: _def("Chest Has Consumables", "bool", true, "Whether the chest can include consumables."),
		CHEST_HAS_MONEY: _def("Chest Has Money", "bool", true, "Whether the chest can include money."),
		CHEST_MONEY: _def("Chest Money", "int", 25, "Money amount to award from the chest."),
		CONSUMABLE_BLACKLIST_IDS: _def("Consumable Blacklist", "string_array", [], "Consumable object_ids to exclude.", {"card_value": false}),
		CONSUMABLE_IDS: _def("Consumable IDs", "string_array", [], "Consumable object_ids to use.", {"card_value": false}),
		CONSUMABLE_OBJECT_ID: _def("Consumable ID", "string", "", "Consumable object_id to use."),
		CONSUMABLE_SLOT_INDEX: _def("Consumable Slot Index", "int", 0, "Consumable inventory slot index."),
		CONSUMABLE_WHITELIST_IDS: _def("Consumable Whitelist", "string_array", [], "Consumable object_ids allowed for random selection.", {"card_value": false}),
		CREATED_CARD_OBJECT_ID: _def("Created Card ID", "string", "", "Card object_id to generate."),
		CUSTOM_SIGNAL_OBJECT_ID: _def("Custom Signal ID", "string", "", "Custom signal object_id to emit."),
		CUSTOM_SIGNAL_VALUE: _def("Custom Signal Value", "variant", null, "Value payload sent with the custom signal."),
		CUSTOM_UI_OBJECT_ID: _def("Custom UI ID", "string", "", "Custom UI object_id to enable or disable."),
		DAMAGE: _def("Damage", "int", 0, "Damage amount used by attacks and direct damage.", {"referenceable": true}),
		DAMAGE_RANDOM: _def("Random Damage Bonus", "int", 0, "Upper bound of random bonus damage added at execution."),
		DRAFT_CARD_PACK_ID: _def("Draft Card Pack ID", "string", "", "Card pack object_id to draft from."),
		DRAFT_FROM_CARD_POOL: _def("Draft From Card Pool", "bool", false, "Generate draft options from card pools instead of a concrete pile."),
		DRAFT_IS_WEIGHTED: _def("Weighted Draft", "bool", false, "Use weighted rarity drafting."),
		DRAFT_MAX_CARD_AMOUNT: _def("Draft Max Cards", "int", 3, "Maximum generated draft options."),
		DRAFT_USE_PITY_SYSTEM: _def("Use Pity System", "bool", false, "Use the player's pity rules while drafting."),
		DRAFT_USE_PLAYER_DRAFT: _def("Use Player Draft Pool", "bool", false, "Draft from the player's available draft pool."),
		DRAW_COUNT: _def("Draw Count", "int", 1, "Number of cards to draw.", {"referenceable": true}),
		ENABLE_CUSTOM_UI: _def("Enable Custom UI", "bool", true, "Enable or disable the target custom UI."),
		END_TURN_IMMEDIACY_LEVEL: _def("End Turn Immediacy", "enum", CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ALL_CARD_PLAYS, "How aggressively the turn should end.", {"options": _end_turn_immediacy_options()}),
		ENERGY_AMOUNT: _def("Energy Amount", "int", 0, "Amount of current energy to add or remove.", {"referenceable": true}),
		ENERGY_AMOUNT_MAX: _def("Max Energy Amount", "int", 0, "Amount of max energy to add or remove.", {"referenceable": true}),
		EVENT_OBJECT_ID: _def("Event ID", "string", "", "Event object_id to start or reference."),
		FILL_ALL_SLOTS: _def("Fill All Slots", "bool", false, "Fill all available consumable slots."),
		FLOORS_PER_ACT: _def("Floors Per Act", "int", 15, "Number of floors to generate in the act."),
		FORCE_UPGRADE_LEVEL: _def("Force Upgrade Level", "int", -1, "Force the transformed card to this upgrade count. -1 disables."),
		HAND_CARD_COUNT_MAX: _def("Hand Card Count Max", "int", PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX, "Maximum cards allowed in hand."),
		HEALTH_AMOUNT: _def("Health Amount", "int", 0, "Health to add or remove.", {"referenceable": true}),
		HEALTH_MAX_AMOUNT: _def("Health Max Amount", "int", 0, "Max health to add or remove.", {"referenceable": true}),
		IMPROVE_PARENT_CARD: _def("Improve Parent Card", "bool", true, "Apply card value improvements to the permanent parent card when available."),
		IS_TOTAL_STAT: _def("Use Total Stat", "bool", false, "Read the combat stat from the total-combat bucket instead of the current turn.", {"referenceable": true}),
		KEEP_COLOR: _def("Keep Color", "bool", true, "Keep the original card color during random transforms."),
		KEEP_RARITY: _def("Keep Rarity", "bool", false, "Keep the original card rarity during random transforms."),
		KEEP_TYPE: _def("Keep Type", "bool", false, "Keep the original card type during random transforms."),
		KEEP_UPGRADE_LEVEL: _def("Keep Upgrade Level", "bool", false, "Preserve the original upgrade count after transform."),
		LOCATION_ID: _def("Location ID", "string", "", "Location object_id to visit."),
		LOCATION_NON_COMBAT_EVENT_RATE: _def("Non-Combat Event Rate", "float", 0.5, "Chance for non-combat locations while generating the map."),
		LOCATION_OBFUSCATION_RATE: _def("Location Obfuscation Rate", "float", 0.0, "Chance that generated locations are hidden."),
		LOCATIONS_PER_FLOOR: _def("Locations Per Floor", "int", 3, "Map locations generated per floor."),
		LOG_MESSAGE: _def("Log Message", "string", "", "Message written to the debug log."),
		LOG_MESSAGE_COLOR_HTML: _def("Log Color", "string", "", "Optional HTML color string for the log entry."),
		LOG_SEVERITY: _def("Log Severity", "string", "info", "Severity tag for the log entry.", {"referenceable": true}),
		MAX_CARD_AMOUNT: _def("Maximum Cards", "int", PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX, "Maximum cards the action may pick.", {"referenceable": true}),
		MERGE_ATTACKS: _def("Merge Attacks", "bool", false, "Combine repeated attacks into a single larger hit.", {"referenceable": true}),
		MIN_CARD_AMOUNT: _def("Minimum Cards", "int", 0, "Minimum cards required or selected.", {"referenceable": true}),
		MIN_CARDS_ARE_REQUIRED_FOR_ACTION: _def("Require Minimum Cards", "bool", false, "Abort the action if not enough cards are available.", {"referenceable": true}),
		MONEY_AMOUNT: _def("Money Amount", "int", 0, "Money to grant or spend.", {"referenceable": true}),
		MULTIPLIED_VALUES: _def("Multiplied Values", "enum_array", [], "Value names modified by a wrapper action or listener.", {"card_value": false}),
		MULTIPLIED_VALUES_BASES: _def("Multiplied Value Bases", "dictionary", {}, "Base values added before multiplier scaling.", {"card_value": false}),
		MULTIPLIER_OFFSET: _def("Multiplier Offset", "int", 0, "Additional value added to the multiplier source.", {"referenceable": true}),
		NUMBER_OF_ATTACKS: _def("Number Of Attacks", "int", 1, "How many repeated attack actions to perform.", {"referenceable": true}),
		NUMBER_OF_CARDS: _def("Number Of Cards", "int", 1, "Number of cards to generate.", {"referenceable": true}),
		NUMBER_OF_SPAWNS: _def("Number Of Spawns", "int", 1, "Number of enemies to summon.", {"referenceable": true}),
		OVERKILL_DAMAGE: _def("Overkill Damage", "int", 0, "Damage dealt past lethal.", {"referenceable": true}),
		PERCENTAGE_HEAL_AMOUNT: _def("Percentage Heal Amount", "float", 1.0, "Fraction of max health to restore.", {"referenceable": true}),
		PICK_DRAFT_CARDS: _def("Pick Draft Cards", "bool", false, "Use explicit draft cards instead of a pile.", {"referenceable": true}),
		PICK_PLAYED_CARD: _def("Pick Played Card", "bool", false, "Use the currently played card as the cardset source.", {"referenceable": true}),
		PICKABLE_CARDS_MAX_AMOUNT: _def("Pickable Cards Max", "int", -1, "Limit the visible pickable cards after filtering.", {"referenceable": true}),
		QUICK_PICK: _def("Quick Pick", "bool", true, "Auto-confirm once enough cards have been chosen.", {"referenceable": true}),
		RANDOM_CONSUMABLE: _def("Random Consumable", "bool", false, "Choose a random consumable instead of a fixed one.", {"referenceable": true}),
		RANDOM_ENEMY_OBJECT_IDS: _def("Random Enemy IDs", "string_array", [], "Enemy object_ids allowed for random summoning.", {"card_value": false}),
		RANDOM_SELECTION: _def("Random Selection", "bool", false, "Select cards automatically at random.", {"referenceable": true}),
		RANDOMIZE_CARD_ENERGY_COST: _def("Randomize Base Cost", "bool", false, "Randomize the base card cost."),
		RANDOMIZE_CARD_ENERGY_COST_UNTIL_COMBAT: _def("Randomize Cost Until Combat", "bool", false, "Randomize the until-combat cost override."),
		RANDOMIZE_CARD_ENERGY_COST_UNTIL_PLAYED: _def("Randomize Cost Until Played", "bool", false, "Randomize the until-played cost override."),
		RANDOMIZE_CARD_ENERGY_COST_UNTIL_TURN: _def("Randomize Cost Until Turn", "bool", false, "Randomize the until-turn cost override."),
		REMOVE_ALL_CARD_PACKS: _def("Remove All Card Packs", "bool", false, "Remove all draft card packs before applying updates."),
		REMOVE_CARD_PACK_OBJECT_IDS: _def("Remove Card Packs", "string_array", [], "Card pack object_ids to remove.", {"card_value": false}),
		REMOVE_REST_ACTION_OBJECT_IDS: _def("Remove Rest Actions", "string_array", [], "Rest action object_ids to remove.", {"card_value": false}),
		RESET_TO_STARTING_CARD_PACKS: _def("Reset To Starting Card Packs", "bool", false, "Reset the player's draft packs to the character starting set."),
		REWARD_GROUP: _def("Reward Group", "string", "default", "Reward group identifier."),
		SHOP_ARTIFACT_IDS: _def("Shop Artifact IDs", "string_array", [], "Artifact object_ids to populate the shop.", {"card_value": false}),
		SHOP_ARTIFACT_PRICES: _def("Shop Artifact Prices", "array", [], "Artifact prices parallel to shop_artifact_ids.", {"card_value": false}),
		SHOP_CARD_PRICES: _def("Shop Card Prices", "array", [], "Card prices parallel to shop cards.", {"card_value": false}),
		SHOP_CONSUMABLE_IDS: _def("Shop Consumable IDs", "string_array", [], "Consumable object_ids to populate the shop.", {"card_value": false}),
		SHOP_CONSUMABLE_PRICES: _def("Shop Consumable Prices", "array", [], "Consumable prices parallel to shop_consumable_ids.", {"card_value": false}),
		SHUFFLE_DISCARD_INTO_DRAW: _def("Shuffle Discard Into Draw", "bool", true, "Whether discard should be merged back into draw before shuffling.", {"referenceable": true}),
		SPAWN_SLOTS: _def("Spawn Slots", "array", [], "Encounter slot indices to use for summoned enemies.", {"card_value": false}),
		STAT_ENUM: _def("Combat Stat", "enum", CombatStatsData.STATS.ENEMIES_KILLED, "Combat stat used for scaling or checks.", {"options": _combat_stat_options()}),
		STATUS_CHARGE_AMOUNT: _def("Status Charge Amount", "int", 1, "Primary charge amount applied to the status.", {"referenceable": true}),
		STATUS_EFFECT_OBJECT_ID: _def("Status Effect ID", "string", "", "Status effect object_id to apply or decay."),
		STATUS_FORCE_APPLY_NEW_EFFECT: _def("Force New Status Effect", "bool", false, "Create a new status instance instead of modifying the existing one.", {"referenceable": true}),
		STATUS_SECONDARY_CHARGE_AMOUNT: _def("Secondary Charge Amount", "int", 0, "Secondary charge amount applied to the status.", {"referenceable": true}),
		TRANSFORM_COLORS: _def("Transform Colors", "enum_array", [], "Allowed colors for random transforms.", {"options": _card_color_options()}),
		TRANSFORM_INTO_CARD_OBJECT_ID: _def("Transform Target Card ID", "string", "", "Specific card object_id to transform into."),
		TRANSFORM_PARENT_CARD: _def("Transform Parent Card", "bool", true, "Transform the permanent parent card when available.", {"referenceable": true}),
		TRANSFORM_RARITIES: _def("Transform Rarities", "enum_array", CardData.STANDARD_CARD_RARITIES, "Allowed rarities for random transforms.", {"options": _card_rarity_options()}),
		TRANSFORM_TYPES: _def("Transform Types", "enum_array", CardData.STANDARD_CARD_TYPES, "Allowed card types for random transforms.", {"options": _card_type_options()}),
		UNBLOCKED_DAMAGE: _def("Unblocked Damage", "int", 0, "Damage that passed block.", {"referenceable": true}),
		UNBLOCKED_DAMAGE_CAPPED: _def("Unblocked Damage Capped", "int", 0, "Unblocked damage excluding overkill.", {"referenceable": true}),
		UPGRADE_PARENT_CARD: _def("Upgrade Parent Card", "bool", false, "Apply upgrades to the permanent parent deck copy.", {"referenceable": true}),
		WHITELIST_CARD_OBJECT_IDS: _def("Whitelist Card IDs", "string_array", [], "Card object_ids to include.", {"card_value": false}),
	}
	var referenceable_value_names: Array[String] = _get_referenceable_value_names_from_definitions(definitions)
	definitions[MULTIPLIED_VALUES]["options"] = _get_value_options_from_definitions(definitions, referenceable_value_names)
	_definitions_cache = definitions
	return _definitions_cache

static func _def(label: String, value_type: String, default_value: Variant, description: String, extra: Dictionary = {}) -> Dictionary:
	var definition: Dictionary = {
		"label": label,
		"value_type": value_type,
		"default_value": default_value,
		"description": description,
		"card_value": true,
		"referenceable": false,
	}
	for key: Variant in extra.keys():
		definition[key] = extra[key]
	return definition

static func _default_label(value_name: String) -> String:
	return value_name.to_snake_case().replace("_", " ").capitalize()

static func _get_referenceable_value_names_from_definitions(definitions: Dictionary[String, Dictionary]) -> Array[String]:
	var names: Array[String] = []
	for value_name: String in definitions.keys():
		var definition: Dictionary = definitions[value_name]
		if bool(definition.get("referenceable", false)):
			names.append(value_name)
	names.sort()
	return names

static func _card_destination_options() -> Array[Dictionary]:
	return [
		{"label": "Discard", "value": CardPlayRequest.CARD_PLAY_DESTINATIONS.DISCARD},
		{"label": "Exhaust", "value": CardPlayRequest.CARD_PLAY_DESTINATIONS.EXHAUST},
		{"label": "Draw Bottom", "value": CardPlayRequest.CARD_PLAY_DESTINATIONS.DRAW_BOTTOM},
		{"label": "Draw Insert", "value": CardPlayRequest.CARD_PLAY_DESTINATIONS.DRAW_INSERT},
		{"label": "Draw Top", "value": CardPlayRequest.CARD_PLAY_DESTINATIONS.DRAW_TOP},
		{"label": "Hand", "value": CardPlayRequest.CARD_PLAY_DESTINATIONS.HAND},
		{"label": "Banish", "value": CardPlayRequest.CARD_PLAY_DESTINATIONS.BANISH},
	]

static func _card_pick_type_options() -> Array[Dictionary]:
	return [
		{"label": "Hand", "value": ActionBasePickCards.CARD_PICK_TYPES.HAND},
		{"label": "Deck", "value": ActionBasePickCards.CARD_PICK_TYPES.DECK},
		{"label": "Combat Deck", "value": ActionBasePickCards.CARD_PICK_TYPES.COMBAT_DECK},
		{"label": "Draw", "value": ActionBasePickCards.CARD_PICK_TYPES.DRAW},
		{"label": "Discard", "value": ActionBasePickCards.CARD_PICK_TYPES.DISCARD},
		{"label": "Exhaust", "value": ActionBasePickCards.CARD_PICK_TYPES.EXHAUST},
		{"label": "Played This Turn", "value": ActionBasePickCards.CARD_PICK_TYPES.PLAYED_THIS_TURN},
		{"label": "Played Last Turn", "value": ActionBasePickCards.CARD_PICK_TYPES.PLAYED_LAST_TURN},
		{"label": "Draft", "value": ActionBasePickCards.CARD_PICK_TYPES.DRAFT},
	]

static func _end_turn_immediacy_options() -> Array[Dictionary]:
	return [
		{"label": "Wait For All Card Plays", "value": CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ALL_CARD_PLAYS},
		{"label": "Wait For Actions", "value": CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ACTIONS},
		{"label": "Immediate", "value": CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.IMMEDIATE},
	]

static func _combat_stat_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for stat_name: String in CombatStatsData.STATS.keys():
		options.append({
			"label": stat_name.to_snake_case().replace("_", " ").capitalize(),
			"value": CombatStatsData.STATS[stat_name],
		})
	return options

static func _card_rarity_options() -> Array[Dictionary]:
	var rarity_values: Array[int] = []
	var rarity_labels_by_value: Dictionary[int, String] = {}
	for rarity_name: String in CardData.CARD_RARITIES.keys():
		var rarity_value: int = CardData.CARD_RARITIES[rarity_name]
		rarity_values.append(rarity_value)
		rarity_labels_by_value[rarity_value] = rarity_name.to_snake_case().replace("_", " ").capitalize()
	rarity_values.sort()
	var options: Array[Dictionary] = []
	for rarity_value: int in rarity_values:
		options.append({
			"label": rarity_labels_by_value.get(rarity_value, str(rarity_value)),
			"value": rarity_value,
		})
	return options

static func _card_type_options() -> Array[Dictionary]:
	var type_values: Array[int] = []
	var type_labels_by_value: Dictionary[int, String] = {}
	for type_name: String in CardData.CARD_TYPES.keys():
		var type_value: int = CardData.CARD_TYPES[type_name]
		type_values.append(type_value)
		type_labels_by_value[type_value] = type_name.to_snake_case().replace("_", " ").capitalize()
	type_values.sort()
	var options: Array[Dictionary] = []
	for type_value: int in type_values:
		options.append({
			"label": type_labels_by_value.get(type_value, str(type_value)),
			"value": type_value,
		})
	return options

static func _card_color_options() -> Array[Dictionary]:
	var color_ids: Array[String] = []
	color_ids.assign(Global._id_to_color_data.keys())
	color_ids.sort()
	var options: Array[Dictionary] = []
	for color_id: String in color_ids:
		options.append({
			"label": color_id.to_snake_case().replace("_", " ").capitalize(),
			"value": color_id,
		})
	return options
