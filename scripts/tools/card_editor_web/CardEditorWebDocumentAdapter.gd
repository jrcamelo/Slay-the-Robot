@tool
extends RefCounted
class_name CardEditorWebDocumentAdapter

const BEHAVIOR_GROUPS: Array[String] = [
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
	"card_play_validators",
	"card_glow_validators",
]

const ACTION_REFERENCE_PARAMETER_NAMES := {
	"action_data": true,
	"passed_action_data": true,
	"failed_action_data": true,
	"actions_on_lethal": true,
}

func session_to_document(session: CardEditorSession) -> Dictionary:
	var state := {"next_id": 0}
	var card_data: CardData = session.working_card_data
	var behavior_groups: Dictionary = {}
	for property_name: String in BEHAVIOR_GROUPS:
		behavior_groups[property_name] = _entries_to_behavior_list(card_data.get(property_name), state)
	return {
		"identity": {
			"objectId": card_data.object_id,
			"objectUid": card_data.object_uid,
			"cardName": card_data.card_name,
			"cardDescription": card_data.card_description,
			"cardTexturePath": card_data.card_texture_path,
			"cardKeywordObjectIds": _string_array(card_data.card_keyword_object_ids),
			"cardColorId": card_data.card_color_id,
			"cardTags": _string_array(card_data.card_tags),
		},
		"classification": {
			"cardKind": card_data.card_kind,
			"cardType": card_data.card_type,
			"cardRarity": card_data.card_rarity,
			"cardRequiresTarget": card_data.card_requires_target,
			"cardClickedTargetMode": card_data.card_clicked_target_mode,
			"cardAppearsInCardPacks": card_data.card_appears_in_card_packs,
		},
		"costs": {
			"cardEnergyCost": card_data.card_energy_cost,
			"cardEnergyCostUntilPlayed": card_data.card_energy_cost_until_played,
			"cardEnergyCostUntilTurn": card_data.card_energy_cost_until_turn,
			"cardEnergyCostUntilCombat": card_data.card_energy_cost_until_combat,
			"cardEnergyCostIsVariable": card_data.card_energy_cost_is_variable,
			"cardEnergyCostVariableUpperBound": card_data.card_energy_cost_variable_upper_bound,
			"cardFirstShufflePriority": card_data.card_first_shuffle_priority,
		},
		"flags": {
			"cardIsPlayable": card_data.card_is_playable,
			"cardExhausts": card_data.card_exhausts,
			"cardIsEthereal": card_data.card_is_ethereal,
			"cardIsRetained": card_data.card_is_retained,
		},
		"values": {
			"cardValues": _json_value(card_data.card_values),
			"cardDescriptionPreviewOverrides": _json_value(card_data.card_description_preview_overrides),
		},
		"upgrades": {
			"cardUpgradeAmount": card_data.card_upgrade_amount,
			"cardUpgradeAmountMax": card_data.card_upgrade_amount_max,
			"cardFirstUpgradePropertyChanges": _json_value(card_data.card_first_upgrade_property_changes),
			"cardUpgradeValueImprovements": _json_value(card_data.card_upgrade_value_improvements),
		},
		"deckFlags": {
			"cardUnremovableFromDeck": card_data.card_unremovable_from_deck,
			"cardUntransformableFromDeck": card_data.card_untransformable_from_deck,
		},
		"metadata": {
			"cardOwnerPartyIndex": card_data.card_owner_party_index,
			"cardOwnerCharacterObjectId": card_data.card_owner_character_object_id,
			"cardListeners": _json_value(card_data.card_listeners),
		},
		"behavior": {
			"groups": behavior_groups,
			"additionalActions": _additional_actions_to_api(card_data.card_additional_actions, state),
		},
		"save": _save_to_api(session.to_summary()),
		"diagnostics": _diagnostics_to_api(session.diagnostics),
	}

func apply_document_to_session(session: CardEditorSession, document: Dictionary) -> void:
	var card_data: CardData = session.working_card_data
	var identity: Dictionary = document.get("identity", {})
	card_data.object_id = str(identity.get("objectId", ""))
	card_data.object_uid = str(identity.get("objectUid", ""))
	card_data.card_name = str(identity.get("cardName", ""))
	card_data.card_description = str(identity.get("cardDescription", ""))
	card_data.card_texture_path = str(identity.get("cardTexturePath", ""))
	card_data.card_keyword_object_ids = _typed_string_array(card_data.card_keyword_object_ids, identity.get("cardKeywordObjectIds", []))
	card_data.card_color_id = str(identity.get("cardColorId", ""))
	card_data.card_tags = _typed_string_array(card_data.card_tags, identity.get("cardTags", []))

	var classification: Dictionary = document.get("classification", {})
	card_data.card_kind = str(classification.get("cardKind", CardData.CARD_KIND_VERSE))
	card_data.card_type = int(classification.get("cardType", CardData.CARD_TYPES.ATTACK))
	card_data.card_rarity = int(classification.get("cardRarity", CardData.CARD_RARITIES.COMMON))
	card_data.card_requires_target = bool(classification.get("cardRequiresTarget", false))
	card_data.card_clicked_target_mode = str(classification.get("cardClickedTargetMode", CardData.CARD_TARGET_MODE_ENEMY_ONLY))
	card_data.card_appears_in_card_packs = bool(classification.get("cardAppearsInCardPacks", true))

	var costs: Dictionary = document.get("costs", {})
	card_data.card_energy_cost = int(costs.get("cardEnergyCost", 0))
	card_data.card_energy_cost_until_played = int(costs.get("cardEnergyCostUntilPlayed", -1))
	card_data.card_energy_cost_until_turn = int(costs.get("cardEnergyCostUntilTurn", -1))
	card_data.card_energy_cost_until_combat = int(costs.get("cardEnergyCostUntilCombat", -1))
	card_data.card_energy_cost_is_variable = bool(costs.get("cardEnergyCostIsVariable", false))
	card_data.card_energy_cost_variable_upper_bound = int(costs.get("cardEnergyCostVariableUpperBound", -1))
	card_data.card_first_shuffle_priority = int(costs.get("cardFirstShufflePriority", 0))

	var flags: Dictionary = document.get("flags", {})
	card_data.card_is_playable = bool(flags.get("cardIsPlayable", true))
	card_data.card_exhausts = bool(flags.get("cardExhausts", false))
	card_data.card_is_ethereal = bool(flags.get("cardIsEthereal", false))
	card_data.card_is_retained = bool(flags.get("cardIsRetained", false))

	var values: Dictionary = document.get("values", {})
	card_data.card_values = _typed_dictionary(card_data.card_values, values.get("cardValues", {}))
	card_data.card_description_preview_overrides = _typed_array(card_data.card_description_preview_overrides, values.get("cardDescriptionPreviewOverrides", []))

	var upgrades: Dictionary = document.get("upgrades", {})
	card_data.card_upgrade_amount = int(upgrades.get("cardUpgradeAmount", 0))
	card_data.card_upgrade_amount_max = int(upgrades.get("cardUpgradeAmountMax", 1))
	card_data.card_first_upgrade_property_changes = _typed_dictionary(card_data.card_first_upgrade_property_changes, upgrades.get("cardFirstUpgradePropertyChanges", {}))
	card_data.card_upgrade_value_improvements = _typed_dictionary(card_data.card_upgrade_value_improvements, upgrades.get("cardUpgradeValueImprovements", {}))

	var deck_flags: Dictionary = document.get("deckFlags", {})
	card_data.card_unremovable_from_deck = bool(deck_flags.get("cardUnremovableFromDeck", false))
	card_data.card_untransformable_from_deck = bool(deck_flags.get("cardUntransformableFromDeck", false))

	var metadata: Dictionary = document.get("metadata", {})
	card_data.card_owner_party_index = int(metadata.get("cardOwnerPartyIndex", -1))
	card_data.card_owner_character_object_id = str(metadata.get("cardOwnerCharacterObjectId", ""))
	card_data.card_listeners = _typed_array(card_data.card_listeners, metadata.get("cardListeners", []))

	var behavior: Dictionary = document.get("behavior", {})
	var groups: Dictionary = behavior.get("groups", {})
	for property_name: String in BEHAVIOR_GROUPS:
		card_data.set(property_name, _entries_from_behavior_list(card_data.get(property_name), groups.get(property_name, [])))
	card_data.card_additional_actions = _additional_actions_from_api(card_data.card_additional_actions, behavior.get("additionalActions", []))

	var save_section: Dictionary = document.get("save", {})
	session.manual_save_override_path = ""
	session.save_policy = str(save_section.get("savePolicy", CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE))
	if session.save_policy == CardEditorSession.SAVE_POLICY_MANUAL:
		session.manual_save_override_path = str(save_section.get("activeSavePath", ""))
	session.managed_owner_bucket_hint = str(save_section.get("managedOwnerBucketHint", ""))
	card_data.synchronize_card_kind_rules()
	session.recompute_managed_paths()
	session.mark_dirty(bool(save_section.get("dirty", true)))

func library_entry_to_api(entry: Dictionary) -> Dictionary:
	return {
		"objectId": str(entry.get("object_id", "")),
		"cardName": str(entry.get("card_name", "")),
		"cardColorId": str(entry.get("card_color_id", "")),
		"cardRarity": int(entry.get("card_rarity", CardData.CARD_RARITIES.COMMON)),
		"cardType": int(entry.get("card_type", CardData.CARD_TYPES.ATTACK)),
		"cardKind": str(entry.get("card_kind", CardData.CARD_KIND_VERSE)),
		"cardRequiresTarget": bool(entry.get("card_requires_target", false)),
		"resourcePath": str(entry.get("resource_path", "")),
		"sourceBucket": str(entry.get("source_bucket", "")),
		"ownerBucket": str(entry.get("owner_bucket", "")),
		"searchBlob": str(entry.get("search_blob", "")),
	}

func metadata_to_api(metadata: Dictionary) -> Dictionary:
	var parameters: Array = metadata.get("parameters", [])
	var parameter_payloads: Array[Dictionary] = []
	for parameter_data: Dictionary in parameters:
		parameter_payloads.append({
			"name": str(parameter_data.get("name", "")),
			"label": str(parameter_data.get("label", "")),
			"valueType": str(parameter_data.get("value_type", "variant")),
			"defaultValue": _json_value(parameter_data.get("default_value", null)),
			"description": str(parameter_data.get("description", "")),
			"options": _options_to_api(parameter_data.get("options", [])),
		})
	return {
		"kind": str(metadata.get("kind", "")),
		"displayName": str(metadata.get("display_name", "")),
		"description": str(metadata.get("description", "")),
		"tokenOrPath": str(metadata.get("token_or_path", "")),
		"resolvedPath": str(metadata.get("resolved_path", "")),
		"resolvedToken": str(metadata.get("resolved_token", "")),
		"scriptPath": str(metadata.get("script_path", "")),
		"scriptClassName": str(metadata.get("script_class_name", "")),
		"scriptGlobalName": str(metadata.get("script_global_name", "")),
		"contexts": _string_array(metadata.get("contexts", [])),
		"parameters": parameter_payloads,
		"relevantValueNames": _string_array(metadata.get("relevant_value_names", [])),
	}

func _options_to_api(options: Array) -> Array[Dictionary]:
	var payloads: Array[Dictionary] = []
	for option_data: Variant in options:
		if option_data is Dictionary:
			payloads.append({
				"label": str(option_data.get("label", option_data.get("value", ""))),
				"value": _json_value(option_data.get("value", null)),
			})
		else:
			payloads.append({
				"label": str(option_data),
				"value": _json_value(option_data),
			})
	return payloads

func _entries_to_behavior_list(entries: Array, state: Dictionary) -> Array[Dictionary]:
	var payloads: Array[Dictionary] = []
	for entry: Variant in entries:
		if not (entry is Dictionary):
			continue
		var entry_dict: Dictionary = entry
		if len(entry_dict.keys()) != 1:
			continue
		var token: String = str(entry_dict.keys()[0])
		var values: Variant = entry_dict[token]
		payloads.append({
			"editorId": _next_editor_id(state),
			"token": token,
			"values": _json_value(values),
		})
	return payloads

func _entries_from_behavior_list(target: Array, payloads: Array) -> Array:
	var entries: Array = []
	for payload: Variant in payloads:
		if not (payload is Dictionary):
			continue
		var payload_dict: Dictionary = payload
		var token: String = str(payload_dict.get("token", ""))
		if token == "":
			continue
		var values: Dictionary = {}
		values.assign(payload_dict.get("values", {}))
		entries.append({token: values})
	var typed_array: Array = target.duplicate()
	typed_array.clear()
	typed_array.assign(entries)
	return typed_array

func _additional_actions_to_api(additional_actions: Array, state: Dictionary) -> Array[Dictionary]:
	var payloads: Array[Dictionary] = []
	for additional_action: Variant in additional_actions:
		if not (additional_action is Dictionary):
			continue
		var additional_action_dict: Dictionary = additional_action
		var additional_action_id: String = str(additional_action_dict.get("id", ""))
		var action_entry: Variant = additional_action_dict.get("action", {})
		if additional_action_id == "" or not (action_entry is Dictionary):
			continue
		var action_dict: Dictionary = action_entry
		if len(action_dict.keys()) != 1:
			continue
		var token: String = str(action_dict.keys()[0])
		payloads.append({
			"id": additional_action_id,
			"editorId": _next_editor_id(state),
			"token": token,
			"values": _json_value(action_dict[token]),
		})
	return payloads

func _additional_actions_from_api(target: Array, payloads: Array) -> Array:
	var entries: Array = []
	for payload: Variant in payloads:
		if not (payload is Dictionary):
			continue
		var payload_dict: Dictionary = payload
		var additional_action_id: String = str(payload_dict.get("id", ""))
		var token: String = str(payload_dict.get("token", ""))
		if additional_action_id == "" or token == "":
			continue
		var values: Dictionary = {}
		values.assign(payload_dict.get("values", {}))
		entries.append({
			"id": additional_action_id,
			"action": {token: values},
		})
	var typed_array: Array = target.duplicate()
	typed_array.clear()
	typed_array.assign(entries)
	return typed_array

func _save_to_api(summary: Dictionary) -> Dictionary:
	return {
		"originalResourcePath": str(summary.get("resource_path", "")),
		"activeSavePath": str(summary.get("active_save_path", "")),
		"managedSavePath": str(summary.get("managed_save_path", "")),
		"managedTriageSavePath": str(summary.get("managed_triage_save_path", "")),
		"managedOwnerBucketHint": str(summary.get("managed_owner_bucket_hint", "")),
		"savePolicy": str(summary.get("save_policy", CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE)),
		"dirty": bool(summary.get("dirty", false)),
	}

func _diagnostics_to_api(diagnostics: Array) -> Array[Dictionary]:
	var payloads: Array[Dictionary] = []
	for diagnostic: Variant in diagnostics:
		if not (diagnostic is Dictionary):
			continue
		var diagnostic_dict: Dictionary = diagnostic
		payloads.append({
			"code": str(diagnostic_dict.get("code", "")),
			"severity": str(diagnostic_dict.get("severity", "info")),
			"message": str(diagnostic_dict.get("message", "")),
			"field": str(diagnostic_dict.get("field", "")),
			"data": _json_value(diagnostic_dict.get("data", {})),
		})
	return payloads

func _next_editor_id(state: Dictionary) -> String:
	var next_id: int = int(state.get("next_id", 0))
	state["next_id"] = next_id + 1
	return "entry_%s" % next_id

func _json_value(value: Variant) -> Variant:
	if value is Array:
		var payload_array: Array = []
		for item: Variant in value:
			payload_array.append(_json_value(item))
		return payload_array
	if value is Dictionary:
		var payload_dict: Dictionary = {}
		for key: Variant in value.keys():
			payload_dict[str(key)] = _json_value(value[key])
		return payload_dict
	if value is SerializableData:
		return value.get_serializable_properties(true)
	return value

func _typed_array(target: Array, values: Variant) -> Array:
	var next_values: Array = []
	if values is Array:
		next_values.assign(values)
	var typed_array: Array = target.duplicate()
	typed_array.clear()
	typed_array.assign(next_values)
	return typed_array

func _typed_string_array(target: Array[String], values: Variant) -> Array[String]:
	var next_values: Array[String] = []
	if values is Array:
		for value: Variant in values:
			next_values.append(str(value))
	var typed_array: Array[String] = []
	typed_array.assign(target)
	typed_array.clear()
	typed_array.assign(next_values)
	return typed_array

func _typed_dictionary(target: Dictionary, values: Variant) -> Dictionary:
	var next_values: Dictionary = {}
	if values is Dictionary:
		for key: Variant in values.keys():
			next_values[key] = values[key]
	var typed_dictionary: Dictionary = target.duplicate()
	typed_dictionary.clear()
	typed_dictionary.assign(next_values)
	return typed_dictionary

func _string_array(values: Variant) -> Array[String]:
	var items: Array[String] = []
	if values is Array:
		for value: Variant in values:
			items.append(str(value))
	return items
