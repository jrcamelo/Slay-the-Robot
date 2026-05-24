@tool
extends Control
class_name CardEditorScreen

const PROPERTY_GROUP_LABELS := {
	"card_play_actions": "Play Actions",
	"card_discard_actions": "Discard Actions",
	"card_end_of_turn_actions": "End Of Turn Actions",
	"card_exhaust_actions": "Exhaust Actions",
	"card_draw_actions": "Draw Actions",
	"card_retain_actions": "Retain Actions",
	"card_right_click_actions": "Right Click Actions",
	"card_initial_combat_actions": "Initial Combat Actions",
	"card_add_to_deck_actions": "Add To Deck Actions",
	"card_remove_from_deck_actions": "Remove From Deck Actions",
	"card_transform_in_deck_actions": "Transform In Deck Actions",
	"card_play_validators": "Play Validators",
	"card_glow_validators": "Glow Validators",
}
const COLLAPSED_ARROW := "Show"
const EXPANDED_ARROW := "Hide"
const NOISY_PARAMETER_DEFAULTS := {
	"time_delay": 0.0,
	"action_tags": [],
	"action_short_circuits": false,
	"invert_validation": false,
}

@onready var title_screen: Control = get_parent() as Control
@onready var body_split: HSplitContainer = $MainContainer/Header/Body
@onready var editor_split: HSplitContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit
@onready var back_button: Button = $MainContainer/Header/BackButton
@onready var new_button: Button = $MainContainer/Header/ButtonRow/NewButton
@onready var duplicate_button: Button = $MainContainer/Header/ButtonRow/DuplicateButton
@onready var preset_option: OptionButton = $MainContainer/Header/ButtonRow/PresetOption
@onready var apply_preset_button: Button = $MainContainer/Header/ButtonRow/ApplyPresetButton
@onready var save_triage_button: Button = $MainContainer/Header/ButtonRow/SaveTriageButton
@onready var promote_button: Button = $MainContainer/Header/ButtonRow/PromoteButton
@onready var library_search: LineEdit = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/SearchRow/SearchInput
@onready var source_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/SourceFilter
@onready var owner_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/OwnerFilter
@onready var color_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/ColorFilter
@onready var type_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/TypeFilter
@onready var rarity_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/RarityFilter
@onready var kind_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/KindFilter
@onready var target_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/TargetFilter
@onready var library_scroll: ScrollContainer = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/LibraryScroll
@onready var library_sections: VBoxContainer = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/LibraryScroll/LibrarySections
@onready var inspector_scroll: ScrollContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit/InspectorScroll
@onready var inspector_container: VBoxContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit/InspectorScroll/InspectorVBox
@onready var behavior_scroll: ScrollContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit/BehaviorScroll
@onready var behavior_container: VBoxContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit/BehaviorScroll/BehaviorVBox
@onready var preview_mount: Control = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/PreviewMount
@onready var session_label: Label = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/SessionSummary/SessionLabel
@onready var diagnostics_text: RichTextLabel = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/SessionSummary/DiagnosticsText
@onready var action_add_panel: VBoxContainer = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ActionAddPanel
@onready var validator_add_panel: VBoxContainer = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ValidatorAddPanel
@onready var action_group_option: OptionButton = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ActionAddPanel/ActionGroupOption
@onready var action_option: OptionButton = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ActionAddPanel/ActionOption
@onready var add_action_button: Button = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ActionAddPanel/AddActionButton
@onready var validator_group_option: OptionButton = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ValidatorAddPanel/ValidatorGroupOption
@onready var validator_option: OptionButton = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ValidatorAddPanel/ValidatorOption
@onready var add_validator_button: Button = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ValidatorAddPanel/AddValidatorButton

var service := CardEditorService.new()
var current_session: CardEditorSession = null
var library_entries: Array[Dictionary] = []
var filtered_entries: Array[Dictionary] = []
var preview_card: Card = null
const PREVIEW_FALLBACK_CHARACTER_ID := "character_red"
var collapsed_library_groups: Dictionary[String, bool] = {}
var collapsed_behavior_groups: Dictionary[String, bool] = {}
var expanded_entry_parameters: Dictionary[String, bool] = {}
var collapsed_behavior_entries: Dictionary[String, bool] = {}

func _ready() -> void:
	visible = not _is_embedded_in_title_screen()
	back_button.button_up.connect(_on_back_button_up)
	new_button.button_up.connect(_on_new_button_up)
	duplicate_button.button_up.connect(_on_duplicate_button_up)
	apply_preset_button.button_up.connect(_on_apply_preset_button_up)
	save_triage_button.button_up.connect(_on_save_triage_button_up)
	promote_button.button_up.connect(_on_promote_button_up)
	library_search.text_changed.connect(_on_library_search_changed)
	for option_button: OptionButton in [source_filter, owner_filter, color_filter, type_filter, rarity_filter, kind_filter, target_filter]:
		option_button.item_selected.connect(_on_filter_changed)
	action_group_option.item_selected.connect(_on_action_group_selected)
	validator_group_option.item_selected.connect(_on_validator_group_selected)
	add_action_button.button_up.connect(_on_add_action_button_up)
	add_validator_button.button_up.connect(_on_add_validator_button_up)
	resized.connect(_apply_split_layout)
	_populate_static_filters()
	_populate_group_options()
	_populate_preset_options()
	call_deferred("_apply_split_layout")
	if _is_embedded_in_title_screen():
		back_button.visible = true
	else:
		back_button.visible = false
		call_deferred("populate_editor")

func show_editor() -> void:
	visible = true
	call_deferred("_apply_split_layout")
	populate_editor()

func populate_editor() -> void:
	_refresh_library()
	if current_session == null:
		current_session = service.create_blank_session()
	_refresh_editor_panels()
	call_deferred("_apply_split_layout")

func _refresh_library() -> void:
	library_entries = service.list_library_cards()
	_populate_dynamic_filters()
	_apply_library_filters()

func _apply_library_filters() -> void:
	var filters: Dictionary = {}
	_add_filter_value(filters, "source_bucket", source_filter)
	_add_filter_value(filters, "owner_bucket", owner_filter)
	_add_filter_value(filters, "card_color_id", color_filter)
	_add_filter_value(filters, "card_type", type_filter)
	_add_filter_value(filters, "card_rarity", rarity_filter)
	_add_filter_value(filters, "card_kind", kind_filter)
	_add_filter_value(filters, "card_requires_target", target_filter)
	filtered_entries = service.filter_library_cards(library_entries, filters, library_search.text)
	_render_library_sections()

func _update_library_selection() -> void:
	pass

func _refresh_editor_panels() -> void:
	_render_inspector()
	_render_behavior()
	_render_preview()
	_render_session_summary()
	_populate_action_option_list()
	_populate_validator_option_list()
	duplicate_button.disabled = current_session == null
	save_triage_button.disabled = current_session == null
	promote_button.disabled = current_session == null

func _render_inspector() -> void:
	for child in inspector_container.get_children():
		child.queue_free()
	if current_session == null or current_session.working_card_data == null:
		return
	var field_definitions: Dictionary = service.get_card_field_definitions()
	for section: Dictionary in service.get_card_field_sections():
		var section_panel := PanelContainer.new()
		section_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var section_padding := MarginContainer.new()
		section_padding.add_theme_constant_override("margin_left", 12)
		section_padding.add_theme_constant_override("margin_top", 12)
		section_padding.add_theme_constant_override("margin_right", 12)
		section_padding.add_theme_constant_override("margin_bottom", 12)
		var section_vbox := VBoxContainer.new()
		section_vbox.add_theme_constant_override("separation", 8)
		section_panel.add_child(section_padding)
		section_padding.add_child(section_vbox)
		var title_label := Label.new()
		title_label.text = str(section.get("label", "Section"))
		section_vbox.add_child(title_label)
		for property_name: String in section.get("fields", []):
			var field_definition: Dictionary = field_definitions.get(property_name, {})
			section_vbox.add_child(_build_property_editor(property_name, field_definition))
		inspector_container.add_child(section_panel)

func _build_property_editor(property_name: String, field_definition: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()
	var label := Label.new()
	label.text = str(field_definition.get("label", property_name))
	wrapper.add_child(label)
	var value_type: String = str(field_definition.get("value_type", "string"))
	var card_data: CardData = current_session.working_card_data
	var property_value: Variant = card_data.get(property_name)
	if property_name == "card_keyword_object_ids":
		var keyword_values: Array[String] = []
		keyword_values.assign(property_value)
		wrapper.add_child(_build_keyword_editor(property_name, keyword_values))
		return wrapper
	if value_type == "dictionary":
		var dictionary_value: Dictionary = property_value
		wrapper.add_child(_build_dictionary_editor(property_name, dictionary_value))
		var description := str(field_definition.get("description", ""))
		if description != "":
			var dictionary_hint := Label.new()
			dictionary_hint.text = description
			dictionary_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dictionary_hint.modulate = Color(0.8, 0.8, 0.8, 0.8)
			wrapper.add_child(dictionary_hint)
		return wrapper
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(property_value)
			checkbox.toggled.connect(func(pressed: bool): service.set_card_property(current_session, property_name, pressed); _refresh_editor_panels())
			wrapper.add_child(checkbox)
		"enum":
			var dropdown := OptionButton.new()
			var options: Array = field_definition.get("options", [])
			for option_data: Dictionary in options:
				dropdown.add_item(str(option_data.get("label", option_data.get("value", ""))))
				dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data.get("value", null))
			for index: int in range(dropdown.get_item_count()):
				if dropdown.get_item_metadata(index) == property_value:
					dropdown.select(index)
					break
			dropdown.item_selected.connect(func(index: int):
				service.set_card_property(current_session, property_name, dropdown.get_item_metadata(index))
				_refresh_editor_panels()
			)
			wrapper.add_child(dropdown)
		"int":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1
			spin.value = float(property_value)
			spin.value_changed.connect(func(value: float):
				service.set_card_property(current_session, property_name, int(value))
				_refresh_editor_panels()
			)
			wrapper.add_child(spin)
		"multiline_string":
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 96)
			text_edit.text = str(property_value)
			text_edit.focus_exited.connect(func():
				service.set_card_property(current_session, property_name, text_edit.text)
				_refresh_editor_panels()
			)
			wrapper.add_child(text_edit)
		"string_array":
			var line_edit := LineEdit.new()
			line_edit.text = ",".join(property_value)
			line_edit.placeholder_text = "comma,separated,values"
			line_edit.text_submitted.connect(func(_text: String):
				service.set_card_property(current_session, property_name, _parse_csv_strings(line_edit.text))
				_refresh_editor_panels()
			)
			line_edit.focus_exited.connect(func():
				service.set_card_property(current_session, property_name, _parse_csv_strings(line_edit.text))
				_refresh_editor_panels()
			)
			wrapper.add_child(line_edit)
		"array":
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 96)
			text_edit.text = JSON.stringify(property_value, "\t")
			text_edit.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(text_edit.text)
				if parsed_value != null:
					service.set_card_property(current_session, property_name, parsed_value)
					_refresh_editor_panels()
			)
			wrapper.add_child(text_edit)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = str(property_value)
			line_edit.text_submitted.connect(func(new_text: String):
				service.set_card_property(current_session, property_name, new_text)
				_refresh_editor_panels()
			)
			line_edit.focus_exited.connect(func():
				service.set_card_property(current_session, property_name, line_edit.text)
				_refresh_editor_panels()
			)
			wrapper.add_child(line_edit)
	var description := str(field_definition.get("description", ""))
	if description != "":
		var description_label := Label.new()
		description_label.text = description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.modulate = Color(0.8, 0.8, 0.8, 0.8)
		wrapper.add_child(description_label)
	return wrapper

func _build_keyword_editor(property_name: String, values: Array[String]) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var add_row := HBoxContainer.new()
	var dropdown := OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var keyword_options: Array[Dictionary] = _get_keyword_options(values)
	_populate_option_button(dropdown, keyword_options)
	add_row.add_child(dropdown)
	var add_button := Button.new()
	add_button.text = "Add Keyword"
	add_button.disabled = dropdown.get_item_count() == 0
	add_button.button_up.connect(func():
		var keyword_id: Variant = _get_option_button_value(dropdown)
		if keyword_id == null:
			return
		if service.add_string_array_value(current_session, property_name, str(keyword_id)):
			_refresh_editor_panels()
	)
	add_row.add_child(add_button)
	wrapper.add_child(add_row)
	if values.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No keywords assigned."
		wrapper.add_child(empty_label)
		return wrapper
	for keyword_id: String in values:
		var row := HBoxContainer.new()
		var keyword_label := Label.new()
		keyword_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var keyword_data: KeywordData = Global.get_keyword_data(keyword_id)
		keyword_label.text = keyword_id
		keyword_label.tooltip_text = "" if keyword_data == null else keyword_data.keyword_text_bb_code
		row.add_child(keyword_label)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func():
			if service.remove_array_value(current_session, property_name, keyword_id):
				_refresh_editor_panels()
		)
		row.add_child(remove_button)
		wrapper.add_child(row)
	return wrapper

func _build_dictionary_editor(property_name: String, dictionary_value: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var sorted_keys: Array[String] = []
	for dictionary_key: Variant in dictionary_value.keys():
		sorted_keys.append(str(dictionary_key))
	sorted_keys.sort()
	if sorted_keys.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No entries configured."
		wrapper.add_child(empty_label)
	for key_name: String in sorted_keys:
		wrapper.add_child(_build_dictionary_row(property_name, key_name, dictionary_value.get(key_name)))
	var add_panel := PanelContainer.new()
	var add_vbox := VBoxContainer.new()
	add_vbox.add_theme_constant_override("separation", 6)
	add_panel.add_child(add_vbox)
	var add_label := Label.new()
	add_label.text = "Add Entry"
	add_vbox.add_child(add_label)
	var add_key_edit := LineEdit.new()
	add_key_edit.placeholder_text = "key_name"
	add_vbox.add_child(add_key_edit)
	var add_type_option := OptionButton.new()
	_populate_option_button(add_type_option, _variant_type_options())
	add_vbox.add_child(add_type_option)
	var add_button := Button.new()
	add_button.text = "Add"
	add_button.button_up.connect(func():
		var key_name: String = add_key_edit.text.strip_edges()
		if key_name == "":
			return
		if dictionary_value.has(key_name):
			return
		var type_name: String = str(_get_option_button_value(add_type_option))
		if service.set_dictionary_value(current_session, property_name, key_name, _default_value_for_variant_type(type_name)):
			_refresh_editor_panels()
	)
	add_vbox.add_child(add_button)
	wrapper.add_child(add_panel)
	return wrapper

func _build_dictionary_row(property_name: String, key_name: String, current_value: Variant) -> Control:
	var panel := PanelContainer.new()
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	var header := HBoxContainer.new()
	var key_edit := LineEdit.new()
	key_edit.text = key_name
	key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_edit.focus_exited.connect(func():
		var renamed_key: String = key_edit.text.strip_edges()
		if renamed_key == "" or renamed_key == key_name:
			key_edit.text = key_name
			return
		if service.rename_dictionary_key(current_session, property_name, key_name, renamed_key):
			_refresh_editor_panels()
		else:
			key_edit.text = key_name
	)
	header.add_child(key_edit)
	var type_option := OptionButton.new()
	_populate_option_button(type_option, _variant_type_options())
	_select_option_value(type_option, _infer_variant_type(current_value))
	type_option.item_selected.connect(func(_index: int):
		var next_type: String = str(_get_option_button_value(type_option))
		if service.set_dictionary_value(current_session, property_name, key_name, _coerce_variant_value(current_value, next_type)):
			_refresh_editor_panels()
	)
	header.add_child(type_option)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		if service.remove_dictionary_value(current_session, property_name, key_name):
			_refresh_editor_panels()
	)
	header.add_child(remove_button)
	row.add_child(header)
	row.add_child(_build_variant_value_editor(
		current_value,
		func(next_value: Variant):
			if service.set_dictionary_value(current_session, property_name, key_name, next_value):
				_refresh_editor_panels()
	))
	return panel

func _render_behavior() -> void:
	for child in behavior_container.get_children():
		child.queue_free()
	if current_session == null or current_session.working_card_data == null:
		return
	var populated_groups: Array[Dictionary] = []
	var empty_groups: Array[Dictionary] = []
	for property_name: String in CardEditorSchema.get_action_property_names():
		var entries: Array = current_session.working_card_data.get(property_name)
		var group_data := {"property_name": property_name, "is_action": true, "count": len(entries)}
		if entries.is_empty():
			empty_groups.append(group_data)
		else:
			populated_groups.append(group_data)
	for property_name: String in CardEditorSchema.get_validator_property_names():
		var entries: Array = current_session.working_card_data.get(property_name)
		var group_data := {"property_name": property_name, "is_action": false, "count": len(entries)}
		if entries.is_empty():
			empty_groups.append(group_data)
		else:
			populated_groups.append(group_data)
	for group_data: Dictionary in populated_groups:
		behavior_container.add_child(_build_entry_group(str(group_data["property_name"]), bool(group_data["is_action"])))
	if not populated_groups.is_empty() and not empty_groups.is_empty():
		var spacer := HSeparator.new()
		behavior_container.add_child(spacer)
	for group_data: Dictionary in empty_groups:
		behavior_container.add_child(_build_entry_group(str(group_data["property_name"]), bool(group_data["is_action"])))

func _build_entry_group(property_name: String, is_action: bool) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 12)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 12)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(padding)
	padding.add_child(vbox)
	var header := HBoxContainer.new()
	var title := Label.new()
	var entries: Array = current_session.working_card_data.get(property_name)
	title.text = "%s (%s)" % [PROPERTY_GROUP_LABELS.get(property_name, property_name), len(entries)]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var collapse_button := Button.new()
	collapse_button.text = COLLAPSED_ARROW if collapsed_behavior_groups.get(property_name, false) else EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		collapsed_behavior_groups[property_name] = not bool(collapsed_behavior_groups.get(property_name, false))
		_render_behavior()
	)
	header.add_child(collapse_button)
	vbox.add_child(header)
	if bool(collapsed_behavior_groups.get(property_name, false)):
		return panel
	if entries.is_empty():
		var no_entries := Label.new()
		no_entries.text = "No entries configured."
		vbox.add_child(no_entries)
		return panel
	for index: int in range(len(entries)):
		var entry: Dictionary = entries[index]
		vbox.add_child(_build_entry_editor(property_name, index, entry, is_action))
	return panel

func _build_entry_editor(property_name: String, index: int, entry: Dictionary, is_action: bool) -> Control:
	var token: String = str(entry.keys()[0])
	var entry_panel := PanelContainer.new()
	entry_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 10)
	padding.add_theme_constant_override("margin_top", 10)
	padding.add_theme_constant_override("margin_right", 10)
	padding.add_theme_constant_override("margin_bottom", 10)
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	entry_panel.add_child(padding)
	padding.add_child(wrapper)
	var toolbar := HBoxContainer.new()
	var display_name: String = token
	var token_option := OptionButton.new()
	var option_entries: Array[Dictionary] = service.get_action_options(service.get_entry_context(property_name)) if is_action else service.get_validator_options(service.get_entry_context(property_name))
	for option_data: Dictionary in option_entries:
		token_option.add_item(str(option_data.get("display_name", option_data.get("resolved_token", ""))))
		token_option.set_item_metadata(token_option.get_item_count() - 1, option_data)
	for item_index: int in range(token_option.get_item_count()):
		var metadata: Dictionary = token_option.get_item_metadata(item_index)
		if str(metadata.get("resolved_token", "")) == Scripts.normalize_script_reference(token):
			token_option.select(item_index)
			display_name = str(metadata.get("display_name", token))
			break
	var title_label := Label.new()
	title_label.text = "%s #%s" % [display_name, index + 1]
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(title_label)
	var entry_key: String = _entry_visibility_key(property_name, index, token)
	var collapse_button := Button.new()
	collapse_button.text = COLLAPSED_ARROW if collapsed_behavior_entries.get(entry_key, false) else EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		collapsed_behavior_entries[entry_key] = not bool(collapsed_behavior_entries.get(entry_key, false))
		_render_behavior()
	)
	toolbar.add_child(collapse_button)
	var up_button := Button.new()
	up_button.text = "Up"
	up_button.button_up.connect(func():
		if service.move_entry(current_session, property_name, index, max(index - 1, 0)):
			_refresh_editor_panels()
	)
	toolbar.add_child(up_button)
	var down_button := Button.new()
	down_button.text = "Down"
	down_button.button_up.connect(func():
		if service.move_entry(current_session, property_name, index, min(index + 1, len(current_session.working_card_data.get(property_name)) - 1)):
			_refresh_editor_panels()
	)
	toolbar.add_child(down_button)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		if service.remove_entry(current_session, property_name, index):
			_refresh_editor_panels()
	)
	toolbar.add_child(remove_button)
	wrapper.add_child(toolbar)
	if bool(collapsed_behavior_entries.get(entry_key, false)):
		return entry_panel
	var token_row := HBoxContainer.new()
	var token_label := Label.new()
	token_label.text = "Script"
	token_label.custom_minimum_size = Vector2(64, 0)
	token_row.add_child(token_label)
	token_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	token_row.add_child(token_option)
	wrapper.add_child(token_row)
	token_option.item_selected.connect(func(selected_index: int):
		var metadata: Dictionary = token_option.get_item_metadata(selected_index)
		var next_token: String = str(metadata.get("resolved_token", metadata.get("token_or_path", "")))
		service.replace_entry(current_session, property_name, index, next_token)
		_refresh_editor_panels()
	)
	var token_metadata: Dictionary = service.get_action_metadata(token) if is_action else service.get_validator_metadata(token)
	var parameters: Array[Dictionary] = []
	parameters.assign(token_metadata.get("parameters", []))
	var values: Dictionary = entry[token]
	for parameter_data: Dictionary in parameters:
		if not _should_show_parameter(parameter_data, values):
			continue
		wrapper.add_child(_build_entry_parameter_editor(property_name, index, token, parameter_data, values))
	var advanced_toggle := _build_advanced_parameter_toggle(property_name, index, token, is_action, values)
	if advanced_toggle != null:
		wrapper.add_child(advanced_toggle)
	return entry_panel

func _build_entry_parameter_editor(property_name: String, index: int, token: String, parameter_data: Dictionary, values: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()
	var label := Label.new()
	var parameter_name: String = str(parameter_data.get("name", ""))
	label.text = str(parameter_data.get("label", parameter_name))
	wrapper.add_child(label)
	var current_value: Variant = values.get(parameter_name, parameter_data.get("default_value", null))
	var value_type: String = str(parameter_data.get("value_type", "variant"))
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			checkbox.toggled.connect(func(pressed: bool):
				service.update_entry_values(current_session, property_name, index, {parameter_name: pressed})
				_refresh_editor_panels()
			)
			wrapper.add_child(checkbox)
		"enum":
			var dropdown := OptionButton.new()
			var options: Array = parameter_data.get("options", [])
			for option_data: Dictionary in options:
				dropdown.add_item(str(option_data.get("label", option_data.get("value", ""))))
				dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data.get("value", null))
			for option_index: int in range(dropdown.get_item_count()):
				if dropdown.get_item_metadata(option_index) == current_value:
					dropdown.select(option_index)
					break
			dropdown.item_selected.connect(func(option_index: int):
				service.update_entry_values(current_session, property_name, index, {parameter_name: dropdown.get_item_metadata(option_index)})
				_refresh_editor_panels()
			)
			wrapper.add_child(dropdown)
		"int", "float":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1 if value_type == "int" else 0.1
			spin.value = float(current_value if current_value != null else 0)
			spin.value_changed.connect(func(value: float):
				service.update_entry_values(current_session, property_name, index, {parameter_name: int(value) if value_type == "int" else value})
				_refresh_editor_panels()
			)
			wrapper.add_child(spin)
		"string_array", "array", "dictionary":
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 72)
			text_edit.text = JSON.stringify(current_value, "\t")
			text_edit.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(text_edit.text)
				if parsed_value != null:
					service.update_entry_values(current_session, property_name, index, {parameter_name: parsed_value})
					_refresh_editor_panels()
			)
			wrapper.add_child(text_edit)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				service.update_entry_values(current_session, property_name, index, {parameter_name: _coerce_string_parameter(new_text, value_type)})
				_refresh_editor_panels()
			)
			line_edit.focus_exited.connect(func():
				service.update_entry_values(current_session, property_name, index, {parameter_name: _coerce_string_parameter(line_edit.text, value_type)})
				_refresh_editor_panels()
			)
			wrapper.add_child(line_edit)
	var description: String = str(parameter_data.get("description", ""))
	if description != "":
		var hint_label := Label.new()
		hint_label.text = description
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.modulate = Color(0.8, 0.8, 0.8, 0.8)
		wrapper.add_child(hint_label)
	return wrapper

func _render_preview() -> void:
	for child in preview_mount.get_children():
		child.queue_free()
	preview_card = null
	if current_session == null or current_session.working_card_data == null:
		return
	preview_card = Scenes.CARD.instantiate()
	preview_mount.add_child(preview_card)
	preview_card.scale = Vector2(1.5, 1.5)
	preview_card.position = Vector2.ZERO
	_render_preview_card(preview_card, current_session.working_card_data)

func _render_session_summary() -> void:
	if current_session == null:
		session_label.text = "No session"
		diagnostics_text.text = ""
		return
	var summary: Dictionary = service.get_card_summary(current_session)
	session_label.text = "Editing: %s\nSave: %s\nPolicy: %s\nDirty: %s" % [
		summary.get("card_name", ""),
		summary.get("active_save_path", ""),
		summary.get("save_policy", ""),
		str(summary.get("dirty", false)),
	]
	var diagnostics_lines: Array[String] = []
	for diagnostic: Dictionary in current_session.diagnostics:
		var severity: String = str(diagnostic.get("severity", "info")).to_upper()
		var field: String = str(diagnostic.get("field", ""))
		var suffix: String = "" if field == "" else " (%s)" % field
		diagnostics_lines.append("[%s]%s %s" % [severity, suffix, diagnostic.get("message", "")])
	diagnostics_text.text = "\n".join(diagnostics_lines)

func _apply_split_layout() -> void:
	if not visible:
		return
	var total_width: float = body_split.size.x
	if total_width > 960:
		var quarter_width: int = int(total_width / 4.0)
		body_split.set("split_offsets", PackedInt32Array([quarter_width, quarter_width * 3]))
	var editor_width: float = editor_split.size.x
	if editor_width > 480:
		editor_split.split_offset = int(editor_width / 2.0)

func _render_library_sections() -> void:
	for child in library_sections.get_children():
		child.queue_free()
	var grouped_entries: Dictionary = {}
	for entry: Dictionary in filtered_entries:
		var group_name: String = _get_library_group_name(entry)
		if not grouped_entries.has(group_name):
			grouped_entries[group_name] = []
		grouped_entries[group_name].append(entry)
	var group_names: Array[String] = []
	group_names.assign(grouped_entries.keys())
	group_names.sort()
	if group_names.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No cards match the current filters."
		library_sections.add_child(empty_label)
		return
	for group_name: String in group_names:
		library_sections.add_child(_build_library_group(group_name, grouped_entries[group_name]))

func _build_library_group(group_name: String, entries: Array) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 12)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 12)
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)
	panel.add_child(padding)
	padding.add_child(wrapper)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "%s (%s)" % [group_name, len(entries)]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var collapse_button := Button.new()
	collapse_button.text = COLLAPSED_ARROW if collapsed_library_groups.get(group_name, false) else EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		collapsed_library_groups[group_name] = not bool(collapsed_library_groups.get(group_name, false))
		_render_library_sections()
	)
	header.add_child(collapse_button)
	wrapper.add_child(header)
	if bool(collapsed_library_groups.get(group_name, false)):
		return panel
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for entry: Dictionary in entries:
		grid.add_child(_build_library_card_tile(entry))
	wrapper.add_child(grid)
	return panel

func _build_library_card_tile(entry: Dictionary) -> Control:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(160, 260)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	if current_session != null and str(entry.get("resource_path", "")) == current_session.original_resource_path:
		tile.modulate = Color(1.0, 0.96, 0.8, 1.0)
	var tile_padding := MarginContainer.new()
	tile_padding.add_theme_constant_override("margin_left", 8)
	tile_padding.add_theme_constant_override("margin_top", 8)
	tile_padding.add_theme_constant_override("margin_right", 8)
	tile_padding.add_theme_constant_override("margin_bottom", 8)
	var tile_vbox := VBoxContainer.new()
	tile_vbox.add_theme_constant_override("separation", 6)
	tile_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(tile_padding)
	tile_padding.add_child(tile_vbox)
	var preview_host := CenterContainer.new()
	preview_host.custom_minimum_size = Vector2(0, 200)
	preview_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_vbox.add_child(preview_host)
	var card_resource: Resource = load(str(entry.get("resource_path", "")))
	if card_resource is CardData:
		var library_card: Card = Scenes.CARD.instantiate()
		preview_host.add_child(library_card)
		library_card.scale = Vector2(0.82, 0.82)
		library_card.position = Vector2.ZERO
		library_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_render_preview_card(library_card, card_resource as CardData)
	var title_label := Label.new()
	title_label.text = str(entry.get("card_name", entry.get("object_id", "")))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.clip_text = true
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_vbox.add_child(title_label)
	var meta_label := Label.new()
	meta_label.text = _format_library_meta(entry)
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_vbox.add_child(meta_label)
	var click_overlay := Button.new()
	click_overlay.flat = true
	click_overlay.text = ""
	click_overlay.tooltip_text = str(entry.get("resource_path", ""))
	click_overlay.anchor_right = 1.0
	click_overlay.anchor_bottom = 1.0
	click_overlay.offset_right = 0.0
	click_overlay.offset_bottom = 0.0
	click_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	click_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	click_overlay.button_up.connect(func():
		_open_library_entry(entry)
	)
	tile.add_child(click_overlay)
	return tile

func _get_library_group_name(entry: Dictionary) -> String:
	var owner_bucket: String = str(entry.get("owner_bucket", "Unsorted"))
	var source_bucket: String = str(entry.get("source_bucket", ""))
	if source_bucket == "triage":
		return "Triage"
	if owner_bucket == "" or owner_bucket == "unknown":
		return "Misc"
	return owner_bucket.replace("/", " / ").capitalize()

func _open_library_entry(entry: Dictionary) -> void:
	current_session = service.load_session(str(entry.get("resource_path", "")))
	_refresh_editor_panels()

func _should_show_parameter(parameter_data: Dictionary, values: Dictionary) -> bool:
	var parameter_name: String = str(parameter_data.get("name", ""))
	if parameter_name == "":
		return false
	if not NOISY_PARAMETER_DEFAULTS.has(parameter_name):
		return true
	if values.has(parameter_name):
		return values[parameter_name] != NOISY_PARAMETER_DEFAULTS[parameter_name]
	return false

func _build_advanced_parameter_toggle(property_name: String, index: int, token: String, is_action: bool, values: Dictionary) -> Control:
	var metadata: Dictionary = service.get_action_metadata(token) if is_action else service.get_validator_metadata(token)
	var parameters: Array[Dictionary] = []
	parameters.assign(metadata.get("parameters", []))
	var hidden_parameters: Array[String] = []
	for parameter_data: Dictionary in parameters:
		var parameter_name: String = str(parameter_data.get("name", ""))
		if parameter_name == "":
			continue
		if _should_show_parameter(parameter_data, values):
			continue
		hidden_parameters.append(parameter_name)
	if hidden_parameters.is_empty():
		return null
	var entry_key: String = _entry_visibility_key(property_name, index, token)
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	var toggle_button := Button.new()
	toggle_button.text = "Hide advanced fields" if bool(expanded_entry_parameters.get(entry_key, false)) else "Show advanced fields"
	toggle_button.button_up.connect(func():
		expanded_entry_parameters[entry_key] = not bool(expanded_entry_parameters.get(entry_key, false))
		_refresh_editor_panels()
	)
	wrapper.add_child(toggle_button)
	if not bool(expanded_entry_parameters.get(entry_key, false)):
		return wrapper
	for parameter_data: Dictionary in parameters:
		if _should_show_parameter(parameter_data, values):
			continue
		wrapper.add_child(_build_entry_parameter_editor(property_name, index, token, parameter_data, values))
	return wrapper

func _entry_visibility_key(property_name: String, index: int, token: String) -> String:
	return "%s:%s:%s" % [property_name, index, token]

func _populate_static_filters() -> void:
	var source_options: Array[Dictionary] = [
		{"label": "All Sources", "value": null},
		{"label": "Content", "value": "content"},
		{"label": "Triage", "value": "triage"},
	]
	var type_options: Array[Dictionary] = _prepend_option(
		CardEditorSchema.get_card_field_definitions()["card_type"]["options"],
		"All Types",
		null
	)
	var rarity_options: Array[Dictionary] = _prepend_option(
		CardEditorSchema.get_card_field_definitions()["card_rarity"]["options"],
		"All Rarities",
		null
	)
	var kind_options: Array[Dictionary] = _prepend_option(
		CardEditorSchema.get_card_field_definitions()["card_kind"]["options"],
		"All Kinds",
		null
	)
	var target_options: Array[Dictionary] = [
		{"label": "Any Targeting", "value": null},
		{"label": "Requires Target", "value": true},
		{"label": "No Target", "value": false},
	]
	_populate_option_button(source_filter, source_options)
	_populate_option_button(type_filter, type_options)
	_populate_option_button(rarity_filter, rarity_options)
	_populate_option_button(kind_filter, kind_options)
	_populate_option_button(target_filter, target_options)

func _populate_dynamic_filters() -> void:
	var owner_options: Array[Dictionary] = [{"label": "All Owners", "value": null}]
	var color_options: Array[Dictionary] = [{"label": "All Colors", "value": null}]
	var seen_owners: Dictionary = {}
	var seen_colors: Dictionary = {}
	for entry: Dictionary in library_entries:
		var owner_bucket: String = str(entry.get("owner_bucket", ""))
		if owner_bucket != "" and not seen_owners.has(owner_bucket):
			seen_owners[owner_bucket] = true
			owner_options.append({"label": owner_bucket, "value": owner_bucket})
		var color_id: String = str(entry.get("card_color_id", ""))
		if color_id != "" and not seen_colors.has(color_id):
			seen_colors[color_id] = true
			color_options.append({"label": color_id, "value": color_id})
	_populate_option_button(owner_filter, owner_options)
	_populate_option_button(color_filter, color_options)

func _populate_group_options() -> void:
	_populate_option_button(action_group_option, _property_group_options(CardEditorSchema.get_action_property_names()))
	_populate_option_button(validator_group_option, _property_group_options(CardEditorSchema.get_validator_property_names()))

func _populate_preset_options() -> void:
	var options: Array[Dictionary] = []
	for preset: Dictionary in service.list_presets():
		options.append({
			"label": str(preset.get("display_name", preset.get("id", ""))),
			"value": str(preset.get("id", "")),
		})
	_populate_option_button(preset_option, options)

func _populate_action_option_list() -> void:
	var property_name: Variant = _get_option_button_value(action_group_option)
	var options: Array[Dictionary] = []
	if property_name != null:
		options = service.get_action_options(service.get_entry_context(str(property_name)))
	_populate_option_button(action_option, _metadata_options(options))

func _populate_validator_option_list() -> void:
	var property_name: Variant = _get_option_button_value(validator_group_option)
	var options: Array[Dictionary] = []
	if property_name != null:
		options = service.get_validator_options(service.get_entry_context(str(property_name)))
	_populate_option_button(validator_option, _metadata_options(options))

func _property_group_options(property_names: Array[String]) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for property_name: String in property_names:
		options.append({
			"label": PROPERTY_GROUP_LABELS.get(property_name, property_name),
			"value": property_name,
		})
	return options

func _metadata_options(options: Array[Dictionary]) -> Array[Dictionary]:
	var normalized_options: Array[Dictionary] = []
	for metadata: Dictionary in options:
		normalized_options.append({
			"label": str(metadata.get("display_name", metadata.get("resolved_token", ""))),
			"value": str(metadata.get("resolved_token", metadata.get("token_or_path", ""))),
		})
	return normalized_options

func _get_keyword_options(existing_keywords: Array[String]) -> Array[Dictionary]:
	var keyword_options: Array[Dictionary] = []
	var content_database: ContentDB = Global.load_content_database()
	var keyword_ids: Array[String] = []
	keyword_ids.assign(content_database.keywords_by_id.keys())
	keyword_ids.sort()
	for keyword_id: String in keyword_ids:
		if existing_keywords.has(keyword_id):
			continue
		keyword_options.append({
			"label": keyword_id,
			"value": keyword_id,
		})
	return keyword_options

func _variant_type_options() -> Array[Dictionary]:
	return [
		{"label": "String", "value": "string"},
		{"label": "Int", "value": "int"},
		{"label": "Float", "value": "float"},
		{"label": "Bool", "value": "bool"},
	]

func _build_variant_value_editor(current_value: Variant, on_change: Callable) -> Control:
	match _infer_variant_type(current_value):
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			checkbox.toggled.connect(func(pressed: bool): on_change.call(pressed))
			return checkbox
		"int":
			var int_spin := SpinBox.new()
			int_spin.min_value = -9999
			int_spin.max_value = 99999
			int_spin.step = 1
			int_spin.value = float(current_value)
			int_spin.value_changed.connect(func(value: float): on_change.call(int(value)))
			return int_spin
		"float":
			var float_spin := SpinBox.new()
			float_spin.min_value = -9999
			float_spin.max_value = 99999
			float_spin.step = 0.1
			float_spin.value = float(current_value)
			float_spin.value_changed.connect(func(value: float): on_change.call(value))
			return float_spin
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String): on_change.call(new_text))
			line_edit.focus_exited.connect(func(): on_change.call(line_edit.text))
			return line_edit

func _default_value_for_variant_type(type_name: String) -> Variant:
	match type_name:
		"bool":
			return false
		"int":
			return 0
		"float":
			return 0.0
		_:
			return ""

func _infer_variant_type(value: Variant) -> String:
	if value is bool:
		return "bool"
	if value is int:
		return "int"
	if value is float:
		return "float"
	return "string"

func _coerce_variant_value(value: Variant, type_name: String) -> Variant:
	match type_name:
		"bool":
			if value is String:
				return value.to_lower() == "true"
			return bool(value)
		"int":
			if value is String:
				return value.to_int()
			if value is float:
				return int(value)
			if value is bool:
				return 1 if value else 0
			return int(value)
		"float":
			if value is String:
				return value.to_float()
			if value is bool:
				return 1.0 if value else 0.0
			return float(value)
		_:
			return "" if value == null else str(value)

func _select_option_value(option_button: OptionButton, desired_value: Variant) -> void:
	for index: int in range(option_button.get_item_count()):
		if option_button.get_item_metadata(index) == desired_value:
			option_button.select(index)
			return

func _format_library_entry_label(entry: Dictionary) -> String:
	var parts: Array[String] = [str(entry.get("card_name", entry.get("object_id", "")))]
	var type_label: String = _enum_label_from_value(CardData.CARD_TYPES, entry.get("card_type", null))
	if type_label != "":
		parts.append(type_label.capitalize())
	var rarity_label: String = _enum_label_from_value(CardData.CARD_RARITIES, entry.get("card_rarity", null))
	if rarity_label != "":
		parts.append(rarity_label.capitalize())
	if str(entry.get("source_bucket", "")) == "triage":
		parts.append("triage")
	return " | ".join(parts)

func _format_library_meta(entry: Dictionary) -> String:
	var parts: Array[String] = []
	var type_label: String = _enum_label_from_value(CardData.CARD_TYPES, entry.get("card_type", null))
	var rarity_label: String = _enum_label_from_value(CardData.CARD_RARITIES, entry.get("card_rarity", null))
	if rarity_label != "":
		parts.append(rarity_label.capitalize())
	if type_label != "":
		parts.append(type_label.capitalize())
	var owner_bucket: String = str(entry.get("owner_bucket", ""))
	if owner_bucket != "" and owner_bucket != "unknown":
		parts.append(owner_bucket.replace("/", " / "))
	return " | ".join(parts)

func _enum_label_from_value(enum_map: Dictionary, desired_value: Variant) -> String:
	for enum_key: String in enum_map.keys():
		if enum_map[enum_key] == desired_value:
			return enum_key.to_snake_case().replace("_", " ")
	return ""

func _render_preview_card(card: Card, card_data: CardData) -> void:
	var preview_data: CardData = card_data.duplicate(true)
	card.card_data = preview_data
	var card_button: Button = card.get_node_or_null("Pivot/CardButton")
	var card_texture: TextureRect = card.get_node_or_null("Pivot/CardVisual/CardTexture")
	var card_name: RichTextLabel = card.get_node_or_null("Pivot/CardVisual/CardTexture/CardName")
	var card_kind: RichTextLabel = card.get_node_or_null("Pivot/CardVisual/CardTexture/CardKind")
	var card_description: RichTextLabel = card.get_node_or_null("Pivot/CardVisual/CardDescription")
	var card_type: Label = card.get_node_or_null("Pivot/CardVisual/CardType")
	var energy_sprite: CanvasItem = card.get_node_or_null("Pivot/CardVisual/EnergySprite")
	var card_energy_cost: Label = card.get_node_or_null("Pivot/CardVisual/EnergySprite/EnergyCost")
	var card_color: ColorRect = card.get_node_or_null("Pivot/CardVisual/ColorBackground")
	var card_owner_sprite: TextureRect = card.get_node_or_null("Pivot/CardVisual/CardOwnerSprite")
	if card_button != null:
		card_button.disabled = true
		card_button.focus_mode = Control.FOCUS_NONE
	if card_texture == null or card_name == null or card_kind == null or card_description == null or card_type == null or card_energy_cost == null or card_color == null:
		return
	card_texture.texture = null
	if preview_data.card_texture_path != "":
		card_texture.texture = FileLoader.load_texture(preview_data.card_texture_path)
	if preview_data.card_owner_character_object_id == "" and Global.get_character_data(PREVIEW_FALLBACK_CHARACTER_ID) != null:
		preview_data.card_owner_character_object_id = PREVIEW_FALLBACK_CHARACTER_ID
	if preview_data.card_owner_character_object_id != "" and card_owner_sprite != null:
		var character_data: CharacterData = Global.get_character_data(preview_data.card_owner_character_object_id)
		if character_data != null:
			card_owner_sprite.texture = FileLoader.load_texture(character_data.character_icon_texture_path)
	card_name.set_bbcode("[center]" + preview_data.get_card_name() + "[/center]")
	card_kind.set_bbcode("[center]" + preview_data.get_card_kind_display_name() + "[/center]")
	card_description.set_bbcode(preview_data.get_card_description())
	card_type.text = "%s %s" % [
		_enum_label_from_value(CardData.CARD_RARITIES, preview_data.card_rarity).capitalize(),
		_enum_label_from_value(CardData.CARD_TYPES, preview_data.card_type).capitalize(),
	]
	var color_data: ColorData = Global.get_color_data(preview_data.card_color_id)
	if color_data != null:
		card_color.color = color_data.color
	if energy_sprite != null:
		energy_sprite.visible = preview_data.card_is_playable
	if preview_data.card_energy_cost_is_variable:
		card_energy_cost.text = "X"
		if preview_data.card_energy_cost_variable_upper_bound >= 1:
			card_energy_cost.text = "X-" + str(preview_data.card_energy_cost_variable_upper_bound)
	else:
		card_energy_cost.text = str(preview_data.card_energy_cost)

func _prepend_option(options: Array[Dictionary], label: String, value: Variant) -> Array[Dictionary]:
	var merged_options: Array[Dictionary] = [{"label": label, "value": value}]
	for option_data: Dictionary in options:
		merged_options.append(option_data)
	return merged_options

func _populate_option_button(option_button: OptionButton, options: Array[Dictionary]) -> void:
	option_button.clear()
	for option_data: Dictionary in options:
		option_button.add_item(str(option_data.get("label", option_data.get("value", ""))))
		option_button.set_item_metadata(option_button.get_item_count() - 1, option_data.get("value", null))
	if option_button.get_item_count() > 0:
		option_button.select(0)

func _add_filter_value(filters: Dictionary, filter_name: String, option_button: OptionButton) -> void:
	var value: Variant = _get_option_button_value(option_button)
	if value != null:
		filters[filter_name] = value

func _get_option_button_value(option_button: OptionButton) -> Variant:
	var selected_index: int = option_button.get_selected()
	if selected_index < 0:
		return null
	return option_button.get_item_metadata(selected_index)

func _parse_csv_strings(raw_text: String) -> Array[String]:
	var values: Array[String] = []
	for segment: String in raw_text.split(","):
		var trimmed: String = segment.strip_edges()
		if trimmed != "":
			values.append(trimmed)
	return values

func _coerce_string_parameter(raw_value: String, value_type: String) -> Variant:
	match value_type:
		"int":
			return raw_value.to_int()
		"float":
			return raw_value.to_float()
		"resource_path", "string", "multiline_string":
			return raw_value
		_:
			return raw_value

func _on_back_button_up() -> void:
	if not _is_embedded_in_title_screen():
		return
	visible = false
	if title_screen != null and title_screen.has_method("show_main_menu"):
		title_screen.show_main_menu()

func _is_embedded_in_title_screen() -> bool:
	return title_screen != null and title_screen.has_method("show_main_menu")

func _on_new_button_up() -> void:
	current_session = service.create_blank_session()
	_refresh_editor_panels()

func _on_duplicate_button_up() -> void:
	if current_session == null:
		return
	current_session = service.duplicate_session(current_session)
	_refresh_editor_panels()

func _on_apply_preset_button_up() -> void:
	if current_session == null:
		return
	var preset_id: Variant = _get_option_button_value(preset_option)
	if preset_id == null:
		return
	service.apply_preset_to_session(current_session, str(preset_id), true)
	_refresh_editor_panels()

func _on_save_triage_button_up() -> void:
	if current_session == null:
		return
	service.save_session_to_triage(current_session)
	_refresh_library()
	_refresh_editor_panels()

func _on_promote_button_up() -> void:
	if current_session == null:
		return
	service.promote_session_to_content(current_session)
	_refresh_library()
	_refresh_editor_panels()

func _on_library_search_changed(_new_text: String) -> void:
	_apply_library_filters()

func _on_filter_changed(_index: int) -> void:
	_apply_library_filters()

func _on_library_item_selected(index: int) -> void:
	if index < 0 or index >= len(filtered_entries):
		return
	current_session = service.load_session(str(filtered_entries[index].get("resource_path", "")))
	_refresh_editor_panels()

func _on_action_group_selected(_index: int) -> void:
	_populate_action_option_list()

func _on_validator_group_selected(_index: int) -> void:
	_populate_validator_option_list()

func _on_add_action_button_up() -> void:
	if current_session == null:
		return
	var property_name: Variant = _get_option_button_value(action_group_option)
	var token: Variant = _get_option_button_value(action_option)
	if property_name == null or token == null:
		return
	service.add_entry(current_session, str(property_name), str(token))
	_refresh_editor_panels()

func _on_add_validator_button_up() -> void:
	if current_session == null:
		return
	var property_name: Variant = _get_option_button_value(validator_group_option)
	var token: Variant = _get_option_button_value(validator_option)
	if property_name == null or token == null:
		return
	service.add_entry(current_session, str(property_name), str(token))
	_refresh_editor_panels()
