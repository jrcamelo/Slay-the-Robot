extends BaseCardListener
class_name BaseQuickReactionListener

var reaction_consumed: bool = false

func _begin_reaction(selected_target: BaseCombatant = null, trigger_action: BaseAction = null, validator_values: Dictionary[String, Variant] = {}) -> CardPlayRequest:
	if reaction_consumed:
		return null
	if not Global.player_data.player_hand.has(card_data):
		return null

	var owner_player: Player = Global.get_card_owner_player(card_data)
	if owner_player == null or not owner_player.is_alive():
		return null
	if card_data.card_type == CardData.CARD_TYPES.ATTACK and owner_player.get_status_charges("status_effect_no_attack") > 0:
		return null
	if not _passes_reaction_validators(trigger_action, validator_values):
		return null

	var energy_cost: int = card_data.get_card_energy_cost()
	if Global.player_data.player_energy + energy_cost > Global.player_data.player_energy_max:
		return null

	reaction_consumed = true
	Global.player_data.player_energy += energy_cost
	Signals.energy_added.emit(0)

	var card_play_request := CardPlayRequest.new()
	card_play_request.card_data = card_data
	card_play_request.selected_target = selected_target
	card_play_request.card_values = card_data.card_values.duplicate(true)
	card_play_request.refundable_energy = 0
	card_play_request.input_energy = energy_cost
	card_play_request.hand_at_play_time = Global.player_data.player_hand.duplicate(false)
	Signals.card_play_started.emit(card_play_request)
	return card_play_request

func _passes_reaction_validators(trigger_action: BaseAction = null, validator_values: Dictionary[String, Variant] = {}) -> bool:
	if len(card_data.card_play_validators) == 0:
		return true
	for validator_data: Dictionary in card_data.card_play_validators:
		for validator_token: String in validator_data.keys():
			var validator_script_asset: Script = Scripts.resolve_script(validator_token)
			if validator_script_asset == null:
				return false
			var validator: BaseValidator = validator_script_asset.new()
			var values: Dictionary[String, Variant] = {}
			values.assign(validator_data[validator_token])
			for key: Variant in validator_values.keys():
				values[key] = validator_values[key]
			if not validator.validate(card_data, trigger_action, values):
				return false
	return true

func _queue_reaction_actions(card_play_request: CardPlayRequest, front_of_queue: bool = true) -> void:
	if card_play_request == null:
		return
	var owner_player: Player = Global.get_card_owner_player(card_data)
	var targets: Array[BaseCombatant] = []
	if card_play_request.selected_target != null:
		targets.append(card_play_request.selected_target)
	var actions: Array[BaseAction] = ActionGenerator.create_actions(owner_player, card_play_request, targets, card_data.card_play_actions, null)
	ActionHandler.add_actions(actions, true, front_of_queue)

func _finish_reaction(card_play_request: CardPlayRequest, discard_card: bool = true) -> void:
	if card_play_request == null:
		return
	Signals.card_played.emit(card_play_request)
	if discard_card:
		Signals.card_discard_requested.emit([card_data], false)
