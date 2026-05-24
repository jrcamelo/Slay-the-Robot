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

@onready var title_screen: Control = get_parent() as Control
@onready var back_button: Button = $MainContainer/Header/BackButton
@onready var new_button: Button = $MainContainer/Header/ButtonRow/NewButton
@onready var duplicate_button: Button = $MainContainer/Header/ButtonRow/DuplicateButton
@onready var preset_option: OptionButton = $MainContainer/Header/ButtonRow/PresetOption
@onready var apply_preset_button: Button = $MainContainer/Header/ButtonRow/ApplyPresetButton
@onready var save_triage_button: Button = $MainContainer/Header/ButtonRow/SaveTriageButton
@onready var promote_button: Button = $MainContainer/Header/ButtonRow/PromoteButton
@onready var library_search: LineEdit = $MainContainer/Header/Body/LibraryPanel/LibraryVBox/SearchRow/SearchInput
@onready var source_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryVBox/FilterGrid/SourceFilter
@onready var owner_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryVBox/FilterGrid/OwnerFilter
@onready var color_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryVBox/FilterGrid/ColorFilter
@onready var type_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryVBox/FilterGrid/TypeFilter
@onready var rarity_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryVBox/FilterGrid/RarityFilter
@onready var kind_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryVBox/FilterGrid/KindFilter
@onready var target_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryVBox/FilterGrid/TargetFilter
@onready var library_list: ItemList = $MainContainer/Header/Body/LibraryPanel/LibraryVBox/LibraryList
@onready var inspector_scroll: ScrollContainer = $MainContainer/Header/Body/EditorPanel/EditorSplit/InspectorScroll
@onready var inspector_container: VBoxContainer = $MainContainer/Header/Body/EditorPanel/EditorSplit/InspectorScroll/InspectorVBox
@onready var behavior_scroll: ScrollContainer = $MainContainer/Header/Body/EditorPanel/EditorSplit/BehaviorScroll
@onready var behavior_container: VBoxContainer = $MainContainer/Header/Body/EditorPanel/EditorSplit/BehaviorScroll/BehaviorVBox
@onready var preview_mount: Control = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/PreviewMount
@onready var session_label: Label = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/SessionSummary/SessionLabel
@onready var diagnostics_text: RichTextLabel = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/SessionSummary/DiagnosticsText
@onready var action_add_panel: VBoxContainer = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/QuickActions/ActionAddPanel
@onready var validator_add_panel: VBoxContainer = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/QuickActions/ValidatorAddPanel
@onready var action_group_option: OptionButton = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/QuickActions/ActionAddPanel/ActionGroupOption
@onready var action_option: OptionButton = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/QuickActions/ActionAddPanel/ActionOption
@onready var add_action_button: Button = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/QuickActions/ActionAddPanel/AddActionButton
@onready var validator_group_option: OptionButton = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/QuickActions/ValidatorAddPanel/ValidatorGroupOption
@onready var validator_option: OptionButton = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/QuickActions/ValidatorAddPanel/ValidatorOption
@onready var add_validator_button: Button = $MainContainer/Header/Body/PreviewPanel/PreviewVBox/QuickActions/ValidatorAddPanel/AddValidatorButton

var service := CardEditorService.new()
var current_session: CardEditorSession = null
var library_entries: Array[Dictionary] = []
var filtered_entries: Array[Dictionary] = []
var preview_card: Card = null

func _ready() -> void:
	visible = false
	back_button.button_up.connect(_on_back_button_up)
	new_button.button_up.connect(_on_new_button_up)
	duplicate_button.button_up.connect(_on_duplicate_button_up)
	apply_preset_button.button_up.connect(_on_apply_preset_button_up)
	save_triage_button.button_up.connect(_on_save_triage_button_up)
	promote_button.button_up.connect(_on_promote_button_up)
	library_search.text_changed.connect(_on_library_search_changed)
	for option_button: OptionButton in [source_filter, owner_filter, color_filter, type_filter, rarity_filter, kind_filter, target_filter]:
		option_button.item_selected.connect(_on_filter_changed)
	library_list.item_selected.connect(_on_library_item_selected)
	action_group_option.item_selected.connect(_on_action_group_selected)
	validator_group_option.item_selected.connect(_on_validator_group_selected)
	add_action_button.button_up.connect(_on_add_action_button_up)
	add_validator_button.button_up.connect(_on_add_validator_button_up)
	_populate_static_filters()
	_populate_group_options()
	_populate_preset_options()

func show_editor() -> void:
	visible = true
	populate_editor()

func populate_editor() -> void:
	_refresh_library()
	if current_session == null:
		current_session = service.create_blank_session()
	_refresh_editor_panels()

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
	library_list.clear()
	for entry: Dictionary in filtered_entries:
		var label: String = "%s [%s]" % [entry.get("card_name", entry.get("object_id", "")), entry.get("source_bucket", "")]
		library_list.add_item(label)
	_update_library_selection()

func _update_library_selection() -> void:
	if current_session == null:
		return
	var session_path: String = current_session.original_resource_path
	if session_path == "":
		return
	for index: int in range(len(filtered_entries)):
		if str(filtered_entries[index].get("resource_path", "")) == session_path:
			library_list.select(index)
			return

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
		var section_vbox := VBoxContainer.new()
		section_panel.add_child(section_vbox)
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
		"dictionary", "array":
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

func _render_behavior() -> void:
	for child in behavior_container.get_children():
		child.queue_free()
	if current_session == null or current_session.working_card_data == null:
		return
	for property_name: String in CardEditorSchema.get_action_property_names():
		behavior_container.add_child(_build_entry_group(property_name, true))
	for property_name: String in CardEditorSchema.get_validator_property_names():
		behavior_container.add_child(_build_entry_group(property_name, false))

func _build_entry_group(property_name: String, is_action: bool) -> Control:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = PROPERTY_GROUP_LABELS.get(property_name, property_name)
	header.add_child(title)
	vbox.add_child(header)
	var entries: Array = current_session.working_card_data.get(property_name)
	for index: int in range(len(entries)):
		var entry: Dictionary = entries[index]
		vbox.add_child(_build_entry_editor(property_name, index, entry, is_action))
	return panel

func _build_entry_editor(property_name: String, index: int, entry: Dictionary, is_action: bool) -> Control:
	var wrapper := VBoxContainer.new()
	var toolbar := HBoxContainer.new()
	var token_option := OptionButton.new()
	var option_entries: Array[Dictionary] = service.get_action_options(service.get_entry_context(property_name)) if is_action else service.get_validator_options(service.get_entry_context(property_name))
	for option_data: Dictionary in option_entries:
		token_option.add_item(str(option_data.get("display_name", option_data.get("resolved_token", ""))))
		token_option.set_item_metadata(token_option.get_item_count() - 1, option_data)
	var token: String = str(entry.keys()[0])
	for item_index: int in range(token_option.get_item_count()):
		var metadata: Dictionary = token_option.get_item_metadata(item_index)
		if str(metadata.get("resolved_token", "")) == Scripts.normalize_script_reference(token):
			token_option.select(item_index)
			break
	token_option.item_selected.connect(func(selected_index: int):
		var metadata: Dictionary = token_option.get_item_metadata(selected_index)
		var next_token: String = str(metadata.get("resolved_token", metadata.get("token_or_path", "")))
		service.replace_entry(current_session, property_name, index, next_token)
		_refresh_editor_panels()
	)
	toolbar.add_child(token_option)
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
	var token_metadata: Dictionary = service.get_action_metadata(token) if is_action else service.get_validator_metadata(token)
	var parameters: Array[Dictionary] = []
	parameters.assign(token_metadata.get("parameters", []))
	var values: Dictionary = entry[token]
	for parameter_data: Dictionary in parameters:
		wrapper.add_child(_build_entry_parameter_editor(property_name, index, token, parameter_data, values))
	return wrapper

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
	preview_card.position = Vector2(120, 180)
	preview_card.init(current_session.working_card_data, 0, false, false)

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
	visible = false
	if title_screen != null and title_screen.has_method("show_main_menu"):
		title_screen.show_main_menu()

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
