## Base class for any action which requires selecting cards from either the hand, deck, or a pile.
## Extend to provide functionality.
## This action will be passed to Hand, CardSelectionOverlay, or CardDraftSelectionOverlay and modified with the selected cards
## Override perform_async_action() to actually perform the action once the cards are selected and passed into picked_cards
## See ActionPickCards subclass for instead deferring logic to child cardset actions, which provides more flexibility.
extends BaseAsyncAction
class_name ActionBasePickCards

func _get_editor_relevant_value_names() -> Array[String]:
	return [
		ActionValueRegistry.CARD_PICK_TYPE,
		ActionValueRegistry.CARD_PICK_TEXT,
		ActionValueRegistry.MIN_CARD_AMOUNT,
		ActionValueRegistry.MAX_CARD_AMOUNT,
		ActionValueRegistry.MIN_CARDS_ARE_REQUIRED_FOR_ACTION,
		ActionValueRegistry.PICKABLE_CARDS_MAX_AMOUNT,
		ActionValueRegistry.QUICK_PICK,
		ActionValueRegistry.RANDOM_SELECTION,
		ActionValueRegistry.PICK_DRAFT_CARDS,
		ActionValueRegistry.DRAFT_FROM_CARD_POOL,
		ActionValueRegistry.DRAFT_CARD_PACK_ID,
		ActionValueRegistry.DRAFT_USE_PLAYER_DRAFT,
		ActionValueRegistry.DRAFT_IS_WEIGHTED,
		ActionValueRegistry.DRAFT_USE_PITY_SYSTEM,
		ActionValueRegistry.DRAFT_MAX_CARD_AMOUNT,
	]

## The final cards picked automatically or by the player. Child actions of this will typically use
## this value.
var picked_cards: Array[CardData] = []

enum CARD_PICK_TYPES {	# THE TYPE OF DRAFT. DETERMINES THE UI USED FOR THE PICKING AND THE CARD INPUT SOURCE TO USE
	# hand selection ui
	HAND,
	# deck selection ui
	DECK,	# The player's source deck. Typically used for selecting cards to permanently modify
	COMBAT_DECK,	# The cards across the copied deck of the player in combat
	DRAW,
	DISCARD,
	EXHAUST,
	PLAYED_THIS_TURN,
	PLAYED_LAST_TURN,
	# draft selection ui
	DRAFT,
	}

# helper contant used to see if the deck ui picking should be used
const DECK_PICK_TYPES: Array = [	
	CARD_PICK_TYPES.DECK,
	CARD_PICK_TYPES.COMBAT_DECK,
	CARD_PICK_TYPES.DRAW,
	CARD_PICK_TYPES.DISCARD,
	CARD_PICK_TYPES.EXHAUST,
	CARD_PICK_TYPES.PLAYED_THIS_TURN,
	CARD_PICK_TYPES.PLAYED_LAST_TURN,
	]

func get_editor_script_type() -> String:
	return "card_pick_action"

func _get_editor_description() -> String:
	return "Base async action for selecting cards from piles or draft sources before running follow-up logic."

func _get_editor_parameter_definitions() -> Array[Dictionary]:
	var parameter_definitions: Array[Dictionary] = super()
	parameter_definitions.append(
		_editor_param(
			ActionValueRegistry.CARD_PICK_TYPE,
			"Card Pick Type",
			"enum",
			CARD_PICK_TYPES.HAND,
			"Controls both the source pile and the UI used for selection.",
			{
				"options": [
					{"label": "Hand", "value": CARD_PICK_TYPES.HAND},
					{"label": "Deck", "value": CARD_PICK_TYPES.DECK},
					{"label": "Combat Deck", "value": CARD_PICK_TYPES.COMBAT_DECK},
					{"label": "Draw", "value": CARD_PICK_TYPES.DRAW},
					{"label": "Discard", "value": CARD_PICK_TYPES.DISCARD},
					{"label": "Exhaust", "value": CARD_PICK_TYPES.EXHAUST},
					{"label": "Played This Turn", "value": CARD_PICK_TYPES.PLAYED_THIS_TURN},
					{"label": "Played Last Turn", "value": CARD_PICK_TYPES.PLAYED_LAST_TURN},
					{"label": "Draft", "value": CARD_PICK_TYPES.DRAFT},
				]
			}
		)
	)
	parameter_definitions.append(_editor_param(ActionValueRegistry.CARD_PICK_TEXT, "Card Pick Text", "string", "Choose {0} card(s). {1} cards selected", "UI prompt shown during selection."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.MIN_CARD_AMOUNT, "Minimum Cards", "int", 0, "Minimum number of cards that must be picked."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.MAX_CARD_AMOUNT, "Maximum Cards", "int", PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX, "Maximum number of cards the player can pick."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.MIN_CARDS_ARE_REQUIRED_FOR_ACTION, "Require Minimum Cards", "bool", false, "If true and not enough cards are available, the action does nothing."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.PICKABLE_CARDS_MAX_AMOUNT, "Pickable Cards Max", "int", -1, "Restricts the number of cards exposed after filtering."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.QUICK_PICK, "Quick Pick", "bool", true, "Auto-confirms once the maximum allowed cards have been selected."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.RANDOM_SELECTION, "Random Selection", "bool", false, "Selects cards automatically instead of prompting the user."))
	parameter_definitions.append(_editor_param("validator_data", "Validator Data", "validator_array", [], "Validators used to narrow pickable cards."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.PICK_DRAFT_CARDS, "Pick Draft Cards", "bool", false, "Uses provided draft cards instead of reading from a pile."))
	parameter_definitions.append(_editor_param("draft_cards", "Draft Cards", "card_array", [], "Explicit cards to present in draft mode."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.DRAFT_FROM_CARD_POOL, "Draft From Card Pool", "bool", false, "Generates draft choices from the broader card pool."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.DRAFT_CARD_PACK_ID, "Draft Card Pack ID", "string", "", "Card pack to draft from, if any."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.DRAFT_USE_PLAYER_DRAFT, "Use Player Draft Pool", "bool", false, "Uses the player's draft-eligible card pool."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.DRAFT_IS_WEIGHTED, "Weighted Draft", "bool", false, "Uses rarity weighting when drafting from the player's pool."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.DRAFT_USE_PITY_SYSTEM, "Use Pity System", "bool", false, "Applies the player's pity system for rare drafts."))
	parameter_definitions.append(_editor_param(ActionValueRegistry.DRAFT_MAX_CARD_AMOUNT, "Draft Max Cards", "int", 3, "Maximum number of generated draft cards."))
	return parameter_definitions

func _assign_generated_card_owners(cards: Array[CardData]) -> Array[CardData]:
	if not Global.player_data.has_party_members():
		return cards
	var source_party_member: PartyMemberData = Global.get_context_party_member(null, parent_combatant, self)
	for card_data: CardData in cards:
		if source_party_member != null:
			Global.player_data.assign_card_owner(card_data, source_party_member.party_member_party_index)
		else:
			Global.player_data.ensure_card_has_owner(card_data)
	return cards

### Override These

func perform_async_action() -> void:
	# override this to provide functionality after the player or game has picked the cards
	# picked_cards will be populated at this point and you can manipulate them
	action_async_finished.emit()

## Gets the display message for the user when picking cards.
## Uses card_pick_text from card's values.
## Formatted string of {0} for max cards, {1} for cards picked, and {2} for cards remaining.
## override for messages requiring different formatting
func get_card_pick_text() -> String:
	var max_card_amount: int = get_card_pick_max_amount()
	var picked_card_amount: int = len(picked_cards)
	var remaining_card_amount: int = max_card_amount - picked_card_amount
	var pickable_cards_max_amount: int = get_pickable_cards_max_amount()
	
	var card_pick_text: String = get_action_value(ActionValueRegistry.CARD_PICK_TEXT, "Choose {0} card(s). {1} cards selected")
	var returned_text: String = card_pick_text.format([max_card_amount, picked_card_amount, remaining_card_amount, pickable_cards_max_amount])
	return returned_text

func _to_string():
	return "Base Card Pick Action"

### Keep

func get_input_cardset() -> Array[CardData]:
	# these are the source of cards you pick from, before additional validators are applied
	# defaults to getting the player hand
	# support drafting cards
	var card_pick_type: int = get_card_pick_type()
	
	# can inject cards to select from via draft_cards
	# useful for RewardOverlay which pre-generates card rewards
	var pick_draft_cards: bool = get_action_value(ActionValueRegistry.PICK_DRAFT_CARDS, false)
	if pick_draft_cards:
		var draft_cards: Array[CardData] = []
		draft_cards.assign(get_action_value("draft_cards", []))
		if len(draft_cards) > 0:
			return draft_cards
		else:
			push_error("No Provided Draft Cards")
			return draft_cards
	
	# can generate random cards to pick from
	# mainly useful for combat
	var draft_from_card_pool: bool = get_action_value(ActionValueRegistry.DRAFT_FROM_CARD_POOL, false)

	if draft_from_card_pool:
		return get_drafted_cards()
	
	return Global.player_data.get_pile(card_pick_type)

func perform_action():
	# determine if its possible to select the cards from the input card set
	# the number of min cards and min requirement determine if the action is performable
	# and if its automatically performed
	var pickable_cards: Array[CardData] = get_pickable_cards() # automatically obtain list of pickable cards from an input set
	
	# card selection params
	var min_cards_are_required: bool = get_min_cards_are_required_for_action()
	var random_selection: bool = get_action_value(ActionValueRegistry.RANDOM_SELECTION, false) 	# to select the cards randomly without player input
	var min_card_amount: int = get_card_pick_min_amount()
	
	if len(pickable_cards) < min_card_amount:
		# not enough cards
		if min_cards_are_required:
			# not enough cards to perform the card action, do nothing
			await Global.get_tree().process_frame # add a delay to allow ActionHandler to catch up with async to avoid infinite hang
			action_async_finished.emit()
			return
		else:
			# automatically select the cards
			picked_cards = pickable_cards
			await Global.get_tree().process_frame # add a delay to allow ActionHandler to catch up with async to avoid infinite hang
			perform_async_action()
			return
	elif len(pickable_cards) == min_card_amount:
		# exactly enough cards; automatically select them
		picked_cards = pickable_cards
		await Global.get_tree().process_frame # add a delay to allow ActionHandler to catch up with async to avoid infinite hang
		perform_async_action()
		return
	else:
		# more than min cards
		if random_selection:
			# automatically randomly select the cards
			var rng_card_picking: RandomNumberGenerator = Global.player_data.get_player_rng("rng_card_picking")
			
			# randomize card order and pick first X cards
			pickable_cards = Random.shuffle_array(rng_card_picking, pickable_cards)
			picked_cards = pickable_cards.slice(0, min_card_amount)

			await Global.get_tree().process_frame # add a delay to allow ActionHandler to catch up with async to avoid infinite hang
			perform_async_action()
			return
		else:
			# prompt the user for card input
			async_awaiting = true 
			Signals.card_pick_requested.emit(self)
			await Signals.card_pick_confirmed
			async_awaiting = false
			perform_async_action()
			return

### Card Picking

## Some support for drafting random cards, such as cards that generate random cards in
## combat that the player can then select.
## NOTE: This is typically not useful for general card rewards because generation happens at time of
## action and is not saved.
## Still useful for generating random cards in combat, or generating rewards through
## deterministic criteria (eg pick a rare card from all rare cards)
## You may use a predefined card pack, use the card pool available to the player,
## or filter all cards using validator criteria.
func get_drafted_cards() -> Array[CardData]:
	var filtered_card_draft: Array[CardData] = []
	var source_party_member: PartyMemberData = Global.get_context_party_member(null, parent_combatant, self)
	
	# a specific card pack to use
	# for complex queries you may wish to generate a card pack specific for the draft rather
	# than narrowing from all cards with validators each time
	var draft_card_pack_id: String = get_action_value(ActionValueRegistry.DRAFT_CARD_PACK_ID, "")
	
	# use the cards that the player is capable of drafting, from PlayerData
	var draft_use_player_draft: bool = get_action_value(ActionValueRegistry.DRAFT_USE_PLAYER_DRAFT, false)
	
	# randomize ordering and reduce to a max number of cards
	var rng_non_reward_card_drafting: RandomNumberGenerator = Global.player_data.get_player_rng("rng_non_reward_card_drafting")
	var draft_max_card_amount: int = get_action_value(ActionValueRegistry.DRAFT_MAX_CARD_AMOUNT, 3) # 0 or negative for all cards. Use DECK card pick type for larger ui selections
	
	if draft_card_pack_id != "":
		#TODO support weighting for card pack based drafting
		filtered_card_draft = Random.generate_unweighted_card_draft_from_card_pack_id(rng_non_reward_card_drafting, draft_card_pack_id, draft_max_card_amount)
	elif draft_use_player_draft:
		# generate a draft from player available cards
		# can be weighted or unweighted
		# NOTE: validator_data should be empty for this kind of draft or it may break the
		# draft once it hits get_pickable_cards() and runs the validator over them
		var draft_probability_is_weighted: bool = get_action_value(ActionValueRegistry.DRAFT_IS_WEIGHTED, false)
		var draft_use_pity_system: bool = get_action_value(ActionValueRegistry.DRAFT_USE_PITY_SYSTEM, false)
		if draft_probability_is_weighted:
			filtered_card_draft = Random.generate_rarity_weighted_card_draft(rng_non_reward_card_drafting, draft_max_card_amount, Random.CARD_DRAFT_TABLE_TYPES.STANDARD, draft_use_pity_system, source_party_member)
		else:
			filtered_card_draft = Random.generate_unweighted_card_draft(rng_non_reward_card_drafting, draft_max_card_amount, source_party_member)	
	else:
		# generate a draft from all cards and narrow using validators
		var card_validator_data: Array = get_card_pick_validator_data()
		
		var card_ids: Array[String] = CardFilter.new().filter_card_validators(card_validator_data).convert_to_unique_card_object_ids()
		card_ids = Random.shuffle_slice_array(rng_non_reward_card_drafting, card_ids, draft_max_card_amount)
		# generate the card instances
		filtered_card_draft = Global.get_card_data_from_prototypes(card_ids)
	
	return _assign_generated_card_owners(filtered_card_draft)

### Picking Validation Methods

## Validates if manual selection will automatically confirm when maximum number of cards are picked.
## Especially useful for when there's only 1 card.
func is_quick_pick() -> bool:
	var quick_pick: bool = get_action_value(ActionValueRegistry.QUICK_PICK, true)
	if quick_pick:
		var picked_card_amount: int = len(picked_cards)
		return len(picked_cards) >= get_card_pick_max_amount()
	return false

func get_card_pick_type() -> int:
	return get_action_value(ActionValueRegistry.CARD_PICK_TYPE, CARD_PICK_TYPES.HAND)
	
func get_card_pick_validator_data() -> Array:
	# returns validators applied to any cards the user can pick
	return get_action_value("validator_data", [])

## The number of cards needed to be selected or the following actions will not be performed
func get_min_cards_are_required_for_action() -> int:
	return get_action_value(ActionValueRegistry.MIN_CARDS_ARE_REQUIRED_FOR_ACTION, false)

## The minimum number of cards required for this card pick to be 
func get_card_pick_min_amount() -> int:
	return get_action_value(ActionValueRegistry.MIN_CARD_AMOUNT, 0)

func get_card_pick_max_amount() -> int:
	return get_action_value(ActionValueRegistry.MAX_CARD_AMOUNT, PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)

## Gets how many cards are available after a card filter is applied. Useful for things like
## getting first X cards from top of discard/draw pile
func get_pickable_cards_max_amount() -> int:
	return get_action_value(ActionValueRegistry.PICKABLE_CARDS_MAX_AMOUNT, -1)

func get_pickable_cards() -> Array[CardData]:
	# gets all cards that meet pickable criteria from a given input list of cards
	# this factors in additonal validators that can be supplied
	var input_cardset: Array[CardData] = get_input_cardset()
	var pickable_cards: Array[CardData] = []
	var parent_card: CardData = null
	if card_play_request != null:
		parent_card = card_play_request.card_data
	
	# filter out cards that fail validation
	pickable_cards = CardFilter.new(input_cardset).filter_card_validators(get_card_pick_validator_data()).filtered_cards
	# ignore the card that generated this action
	pickable_cards.erase(parent_card)
	
	# limits the selection to the first N results. Eg: first 3 attack cards from draw pile
	# instead of showing all attack cards in draw pile
	var pickable_cards_max_amount: int = get_pickable_cards_max_amount()
	if pickable_cards_max_amount > 0 and len(pickable_cards) >= pickable_cards_max_amount:
		pickable_cards = pickable_cards.slice(0, pickable_cards_max_amount)
	
	return pickable_cards

func are_enough_cards_picked() -> bool:
	var min_card_amount: int = get_card_pick_min_amount()
	var max_card_amount: int = get_card_pick_max_amount()
	var picked_card_amount: int = len(picked_cards)
	return (min_card_amount <= picked_card_amount) and (picked_card_amount <= max_card_amount)  

func is_card_pickable(card_data: CardData) -> bool:
	# optionally override this 
	# method for determining if a given card can be selected for this action
	# for example limiting the player to only picking cards that are above an energy cost
	var max_card_amount: int = min(get_card_pick_max_amount(), PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
	if len(picked_cards) >= max_card_amount:
		return false
	
	# run card through validators, should return either empty array or contain the card
	var card_validator_data: Array = get_card_pick_validator_data()
	var validated_card: Array[CardData] = CardFilter.new([card_data]).filter_card_validators(card_validator_data).filtered_cards
	if len(validated_card) == 0:
		return false
		
	return true	# by default all cards are pickable

## Forces the card pick to end
func force_action_end() -> void:
	if async_awaiting:
		picked_cards = []
		Signals.card_pick_confirmed.emit()
		async_awaiting = false
