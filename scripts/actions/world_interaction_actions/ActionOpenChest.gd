## Provides interceptable generation for rewards in a chest
extends BaseAction

func _get_editor_relevant_value_names() -> Array[String]:
	return [
		ActionValueRegistry.ARTIFACT_IDS,
		ActionValueRegistry.CHEST_ARTIFACT_COUNT,
		ActionValueRegistry.CHEST_CARD_AMOUNT_DRAFT,
		ActionValueRegistry.CHEST_CARDS,
		ActionValueRegistry.CHEST_CARDS_PER_DRAFT,
		ActionValueRegistry.CHEST_CONSUMABLE_COUNT,
		ActionValueRegistry.CHEST_GENERATES_ARTIFACTS,
		ActionValueRegistry.CHEST_GENERATES_CARDS,
		ActionValueRegistry.CHEST_GENERATES_CONSUMABLES,
		ActionValueRegistry.CHEST_GENERATES_MONEY,
		ActionValueRegistry.CHEST_HAS_ARTIFACTS,
		ActionValueRegistry.CHEST_HAS_CARDS,
		ActionValueRegistry.CHEST_HAS_CONSUMABLES,
		ActionValueRegistry.CHEST_HAS_MONEY,
		ActionValueRegistry.CHEST_MONEY,
		ActionValueRegistry.CONSUMABLE_IDS,
	]

func _get_editor_description() -> String:
	return "Builds chest rewards, either from explicit payload values or from the normal reward generation systems."

func _get_editor_contexts() -> Array[String]:
	return [
		EDITOR_CONTEXT_WORLD_ACTIONS,
		EDITOR_CONTEXT_REWARD_ACTIONS,
		EDITOR_CONTEXT_ACTION_CHILDREN,
	]

func perform_action() -> void:	
	# generates all world locations from a seed and stores them in PlayerData
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor in action_interceptor_processors:
		# flags to control whether these things can even generate in a chest, regardless of number
		# interceptors can set these flags to force chests to not generate anything
		var chest_has_money: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_HAS_MONEY, true)
		var chest_has_cards: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_HAS_CARDS, true)
		var chest_has_artifacts: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_HAS_ARTIFACTS, true)
		var chest_has_consumables: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_HAS_CONSUMABLES, true)
		
		# values for final rewards
		var reward_group: int = -1
		var money_amount: int = 0
		var card_drafts: Array[Array] = [] # array of array of CardData
		var artifact_ids: Array[String] = []
		var consumable_ids: Array[String] = []
		var custom_action_data: Array[Array] = []
		custom_action_data.assign(action_interceptor_processor.get_shadowed_action_values("custom_action_data", []))
		
		### Deciding whether to not have items, generate them, or use a value
		var location_data: LocationData = Global.get_player_location_data()
		# money
		if not chest_has_money:
			money_amount = 0
		else:
			# either generate money, or use a specified amount
			var chest_generates_money: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_GENERATES_MONEY, true)
			if chest_generates_money:
				money_amount = Random.get_location_money_reward()
			else:
				var chest_money: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_MONEY, 25)
				money_amount = chest_money
		
		# cards
		if not chest_has_cards:
			card_drafts = []
		else:
			# either generate cards, or use specified cards
			var chest_generates_cards: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_GENERATES_CARDS, true)
			if chest_generates_cards:
				#var chest_card_amount_draft: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_CARD_AMOUNT_DRAFT, 1)
				#var chest_cards_per_draft: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_CARDS_PER_DRAFT, 3)
				card_drafts = Random.get_location_card_rewards()
			else:
				var chest_cards: Array[Array] = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_CARDS, [])
				card_drafts = chest_cards
		
		# artifacts
		if not chest_has_artifacts:
			artifact_ids = []
		else:
			# either generate cards, or use specified cards
			var chest_generates_artifacts: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_GENERATES_ARTIFACTS, true)
			var chest_artifact_count: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_ARTIFACT_COUNT, 1)
			if chest_generates_artifacts:
				artifact_ids = Random.get_location_artifact_rewards(location_data, chest_artifact_count)
			else:
				var chest_artifact_ids: Array[String] = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.ARTIFACT_IDS, [])
				artifact_ids = chest_artifact_ids
		
		# consumables
		#TODO Support consumables in rewards
		#if not chest_has_consumables:
			#consumable_ids = []
		#else:
			## either generate cards, or use specified cards
			#var chest_generates_consumables: bool = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_GENERATES_CONSUMABLES, true)
			#if chest_generates_consumables:
				##TODO Generate consumables
				#pass
				## var chest_consumable_count: int = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CHEST_CONSUMABLE_COUNT, 1)
				## consumable_ids = Random.get_location_consumable_rewards(location_data, chest_consumable_count)
			#else:
				#var chest_consumable_ids: Array[String] = action_interceptor_processor.get_shadowed_action_values(ActionValueRegistry.CONSUMABLE_IDS, [])
				#consumable_ids = chest_consumable_ids
		
		var chest_contents: Dictionary[String, Variant] = {
			ActionValueRegistry.REWARD_GROUP: reward_group,
			ActionValueRegistry.MONEY_AMOUNT: money_amount,
			ActionValueRegistry.CARD_DRAFTS: card_drafts,
			ActionValueRegistry.ARTIFACT_IDS: artifact_ids,
			ActionValueRegistry.CONSUMABLE_IDS: consumable_ids,
			"custom_action_data": custom_action_data
		}
		
		# adds rewards
		var player: Player = Global.get_default_player_combatant()
		var action_data: Array[Dictionary] = [{
		Scripts.ACTION_GRANT_REWARDS: chest_contents
		}]
		var grant_reward_action: BaseAction = ActionGenerator.create_actions(player, null, [], action_data, null)[0]
		grant_reward_action.perform_action()
