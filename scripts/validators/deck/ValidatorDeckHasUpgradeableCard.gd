# Validator for checking if the player has at least 1 upgradable card in their deck
extends BaseValidator

func _get_editor_display_name() -> String:
	return "Deck Has Upgradeable Card"

func _get_editor_description() -> String:
	return "Checks whether the player's permanent deck contains at least one upgradeable card."

func _get_editor_contexts() -> Array[String]:
	return [EDITOR_CONTEXT_CARD_PLAY_VALIDATORS, EDITOR_CONTEXT_CARD_GLOW_VALIDATORS, EDITOR_CONTEXT_ACTION_VALIDATORS]

func _validation(_card_data: CardData, _action: BaseAction, values: Dictionary[String, Variant]) -> bool:
	for card: CardData in Global.player_data.player_deck:
		if card.card_upgrade_amount < card.card_upgrade_amount_max:
			return true
	return false
