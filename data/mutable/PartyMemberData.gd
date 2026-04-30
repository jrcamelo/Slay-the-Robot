## Embedded per-character state for shared-party runs.
## This keeps combat survivability and reward-pool ownership separate from the shared deck/energy/run state.
extends SerializableData
class_name PartyMemberData

@export var party_member_party_index: int = -1
@export var party_member_character_object_id: String = ""
@export var party_member_name: String = ""

@export var party_member_health: int = 50
@export var party_member_health_max: int = 50

var party_member_block: int = 0 # combat-only, not saved

@export var party_member_reward_draft_card_pack_ids: Array[String] = []
@export var party_member_reward_draft_card_id_blacklist: Array[String] = []
@export var party_member_reward_draft_card_id_whitelist: Array[String] = []

@export var party_member_rare_card_modifier_current: float = 0.0
@export var party_member_rare_card_modifier_base: float = 0.0
@export var party_member_rare_card_increment_rate: float = 1.5

var party_member_reward_card_filter_cache: CardFilter = null
var party_member_reward_card_rarity_cache: Dictionary[int, Array] = {}

func is_alive() -> bool:
	return party_member_health > 0

func add_health(health_amount: int, health_amount_max: int = 0) -> void:
	set_health(party_member_health + health_amount, party_member_health_max + health_amount_max)

func set_health(health_amount: int, health_amount_max: int = party_member_health_max) -> void:
	party_member_health_max = max(1, health_amount_max)
	party_member_health = clamp(0, health_amount, party_member_health_max)

func revive_after_combat_if_dead(revive_health: int = 1) -> void:
	if not is_alive():
		party_member_health = clamp(revive_health, 1, party_member_health_max)

func regenerate_card_draft_card_filter() -> void:
	var card_unique_object_ids: Dictionary[String, Variant] = {}
	for reward_draft_card_pack_id: String in party_member_reward_draft_card_pack_ids:
		var card_pack_card_filter: CardFilter = Global.get_cached_card_filter(reward_draft_card_pack_id)
		if card_pack_card_filter != null:
			card_unique_object_ids.merge(card_pack_card_filter.filtered_card_unique_object_ids)

	for card_object_id: String in party_member_reward_draft_card_id_blacklist:
		card_unique_object_ids.erase(card_object_id)
	for card_object_id: String in party_member_reward_draft_card_id_whitelist:
		card_unique_object_ids[card_object_id] = null

	var card_filter: CardFilter = CardFilter.new([], card_unique_object_ids.keys())
	party_member_reward_card_filter_cache = card_filter

	var reward_card_rarity_buckets: Dictionary[int, Array] = {}
	for card_data: CardData in card_filter.filtered_cards:
		var bucket: Array = reward_card_rarity_buckets.get(card_data.card_rarity, [])
		bucket.append(card_data.object_id)
		reward_card_rarity_buckets[card_data.card_rarity] = bucket

	party_member_reward_card_rarity_cache = reward_card_rarity_buckets
