@tool
extends Control
class_name CardEditorScreen

const PROPERTY_GROUP_LABELS := {
	"card_play_actions": "Play Actions",
	"card_additional_actions": "Additional Actions",
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
	"card_play_actions",
	"card_play_validators",
	"card_glow_validators",
	"card_right_click_actions",
]
const SECONDARY_BEHAVIOR_GROUPS := [
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
	"card_play_actions": "What the card does when played.",
	"card_additional_actions": "Reusable child actions referenced by action parameters. These do not run unless another action points to them.",
	"card_play_validators": "Rules that block the card from being played.",
	"card_glow_validators": "Rules that make the card light up without blocking play.",
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

@onready var title_screen: Control = get_parent() as Control
@onready var screen_title: Label = $MainContainer/Header/ScreenSummary/ScreenTitle
@onready var screen_subtitle: Label = $MainContainer/Header/ScreenSummary/ScreenSubtitle
@onready var status_banner: Label = $MainContainer/Header/ScreenSummary/StatusBanner
@onready var header_container: VBoxContainer = $MainContainer/Header
@onready var library_count_label: Label = $MainContainer/Header/ScreenSummary/StatsRow/LibraryCountLabel
@onready var filter_count_label: Label = $MainContainer/Header/ScreenSummary/StatsRow/FilterCountLabel
@onready var selection_count_label: Label = $MainContainer/Header/ScreenSummary/StatsRow/SelectionCountLabel
@onready var diagnostics_count_label: Label = $MainContainer/Header/ScreenSummary/StatsRow/DiagnosticsCountLabel
@onready var body_split: HSplitContainer = $MainContainer/Header/Body
@onready var editor_split: HSplitContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit
@onready var library_panel: PanelContainer = $MainContainer/Header/Body/LibraryPanel
@onready var editor_panel: PanelContainer = $MainContainer/Header/Body/EditorPanel
@onready var preview_panel: PanelContainer = $MainContainer/Header/Body/PreviewPanel
@onready var back_button: Button = $MainContainer/Header/BackButton
@onready var button_row: HBoxContainer = $MainContainer/Header/ButtonRow
@onready var library_search: LineEdit = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/SearchRow/SearchInput
@onready var clear_filters_button: Button = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/SearchRow/ClearFiltersButton
@onready var source_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/SourceFilter
@onready var owner_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/OwnerFilter
@onready var color_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/ColorFilter
@onready var type_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/TypeFilter
@onready var rarity_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/RarityFilter
@onready var kind_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/KindFilter
@onready var library_scroll: ScrollContainer = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/LibraryScroll
@onready var library_sections: VBoxContainer = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/LibraryScroll/LibrarySections
@onready var library_vbox: VBoxContainer = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox
@onready var editor_padding: MarginContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding
@onready var inspector_scroll: ScrollContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit/InspectorScroll
@onready var inspector_container: VBoxContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit/InspectorScroll/InspectorVBox
@onready var behavior_scroll: ScrollContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit/BehaviorScroll
@onready var behavior_container: VBoxContainer = $MainContainer/Header/Body/EditorPanel/EditorPadding/EditorSplit/BehaviorScroll/BehaviorVBox
@onready var preview_mount: Control = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/PreviewMount
@onready var preview_vbox: VBoxContainer = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox
@onready var session_label: Label = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/SessionSummary/SessionLabel
@onready var diagnostics_text: RichTextLabel = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/SessionSummary/DiagnosticsText
@onready var save_status_label: Label = $MainContainer/Header/Body/PreviewPanel/PreviewPadding/PreviewVBox/SaveStatusLabel
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
var collapsed_property_groups: Dictionary[String, bool] = {
	"Extra Costs And Flags": true,
	"Upgrade Rules": true,
	"Metadata And Edge Cases": true,
}
var collapsed_behavior_groups: Dictionary[String, bool] = {}
var expanded_entry_parameters: Dictionary[String, bool] = {}
var collapsed_behavior_entries: Dictionary[String, bool] = {}
var show_secondary_behavior_groups: bool = false
var new_button: Button = null
var duplicate_button: Button = null
var preset_option: OptionButton = null
var apply_preset_button: Button = null
var save_triage_button: Button = null
var promote_button: Button = null
var target_filter: OptionButton = null
var library_panel_collapsed: bool = false
var editor_panel_collapsed: bool = false
var preview_panel_collapsed: bool = false
var collapsed_panel_row: HBoxContainer = null
var library_panel_toggle: Button = null
var editor_panel_toggle: Button = null
var preview_panel_toggle: Button = null
var behavior_render_queued: bool = false
var editor_panels_refresh_queued: bool = false
var status_message: String = "Open a card to inspect it, or start a new triage draft."
var status_severity: String = "info"

func _ready() -> void:
	_bind_optional_header_nodes()
	visible = not _is_embedded_in_title_screen()
	screen_title.text = "Card Workshop"
	screen_subtitle.text = "Build cards without fighting the editor."
	diagnostics_text.bbcode_enabled = true
	diagnostics_text.fit_content = true
	library_search.placeholder_text = "Search names, descriptions, tags, keywords, or file paths"
	back_button.button_up.connect(_on_back_button_up)
	if new_button != null:
		new_button.button_up.connect(_on_new_button_up)
	if duplicate_button != null:
		duplicate_button.button_up.connect(_on_duplicate_button_up)
	if apply_preset_button != null:
		apply_preset_button.button_up.connect(_on_apply_preset_button_up)
	if save_triage_button != null:
		save_triage_button.button_up.connect(_on_save_triage_button_up)
	if promote_button != null:
		promote_button.button_up.connect(_on_promote_button_up)
	clear_filters_button.button_up.connect(_on_clear_filters_button_up)
	library_search.text_changed.connect(_on_library_search_changed)
	for option_button: OptionButton in [source_filter, owner_filter, color_filter, type_filter, rarity_filter, kind_filter]:
		option_button.item_selected.connect(_on_filter_changed)
	action_group_option.item_selected.connect(_on_action_group_selected)
	validator_group_option.item_selected.connect(_on_validator_group_selected)
	add_action_button.button_up.connect(_on_add_action_button_up)
	add_validator_button.button_up.connect(_on_add_validator_button_up)
	resized.connect(_apply_split_layout)
	_compact_header_layout()
	_populate_static_filters()
	_populate_group_options()
	_populate_preset_options()
	_refresh_status_banner()
	call_deferred("_apply_split_layout")
	if _is_embedded_in_title_screen():
		back_button.visible = true
	else:
		back_button.visible = false
		call_deferred("populate_editor")

func _bind_optional_header_nodes() -> void:
	new_button = get_node_or_null("MainContainer/Header/ButtonRow/NewButton") as Button
	duplicate_button = get_node_or_null("MainContainer/Header/ButtonRow/DuplicateButton") as Button
	preset_option = get_node_or_null("MainContainer/Header/ButtonRow/PresetOption") as OptionButton
	apply_preset_button = get_node_or_null("MainContainer/Header/ButtonRow/ApplyPresetButton") as Button
	save_triage_button = get_node_or_null("MainContainer/Header/ButtonRow/SaveTriageButton") as Button
	promote_button = get_node_or_null("MainContainer/Header/ButtonRow/PromoteButton") as Button
	target_filter = get_node_or_null("MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/TargetFilter") as OptionButton

func show_editor() -> void:
	visible = true
	call_deferred("_apply_split_layout")
	populate_editor()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or current_session == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		if key_event.ctrl_pressed and key_event.keycode == KEY_S:
			if key_event.shift_pressed:
				_on_promote_button_up()
			else:
				_on_save_triage_button_up()
			get_viewport().set_input_as_handled()
			return
		if key_event.ctrl_pressed and key_event.keycode == KEY_D:
			_on_duplicate_button_up()
			get_viewport().set_input_as_handled()
			return
		if key_event.ctrl_pressed and key_event.keycode == KEY_N:
			_on_new_button_up()
			get_viewport().set_input_as_handled()
			return
		if key_event.ctrl_pressed and key_event.keycode == KEY_F:
			library_search.grab_focus()
			library_search.select_all()
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_ESCAPE and _is_embedded_in_title_screen():
			_on_back_button_up()
			get_viewport().set_input_as_handled()

func populate_editor() -> void:
	_refresh_library()
	if current_session == null:
		current_session = service.create_blank_session()
		_set_status_message("Started a new triage session. Use a preset or open a library card to begin.", "info")
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
	filtered_entries = service.filter_library_cards(library_entries, filters, library_search.text)
	_render_library_sections()
	_refresh_overview()

func _update_library_selection() -> void:
	pass

func _refresh_editor_panels() -> void:
	editor_panels_refresh_queued = false
	_render_inspector()
	_render_behavior()
	_render_preview()
	_render_session_summary()
	_populate_action_option_list()
	_populate_validator_option_list()
	_refresh_overview()
	if duplicate_button != null:
		duplicate_button.disabled = current_session == null
	if save_triage_button != null:
		save_triage_button.disabled = current_session == null
	if promote_button != null:
		promote_button.disabled = current_session == null

func _request_editor_panels_refresh() -> void:
	if editor_panels_refresh_queued:
		return
	editor_panels_refresh_queued = true
	call_deferred("_refresh_editor_panels")

func _render_inspector() -> void:
	for child in inspector_container.get_children():
		child.queue_free()
	if current_session == null or current_session.working_card_data == null:
		return
	inspector_container.add_child(_build_editor_hero())
	for group_data: Dictionary in ESSENTIAL_FIELD_GROUPS:
		inspector_container.add_child(_build_property_section(group_data))
	for group_data: Dictionary in ADVANCED_FIELD_GROUPS:
		inspector_container.add_child(_build_property_section(group_data))

func _compact_header_layout() -> void:
	screen_title.add_theme_font_size_override("font_size", 24)
	screen_subtitle.visible = false
	status_banner.visible = false
	button_row.visible = false
	if is_instance_valid(target_filter):
		target_filter.visible = false
		target_filter.queue_free()
	_install_panel_headers()
	_apply_panel_collapse_state()
	var search_row: HBoxContainer = library_search.get_parent() as HBoxContainer
	if search_row != null:
		var library_actions := HBoxContainer.new()
		library_actions.name = "LibraryActions"
		library_actions.add_theme_constant_override("separation", 8)
		search_row.get_parent().add_child(library_actions)
		search_row.get_parent().move_child(library_actions, search_row.get_index() + 1)
		for control: Control in [new_button, duplicate_button, preset_option, apply_preset_button]:
			if control == null:
				continue
			if control.get_parent() != null:
				control.get_parent().remove_child(control)
			library_actions.add_child(control)
	var preview_vbox: VBoxContainer = preview_mount.get_parent() as VBoxContainer
	if preview_vbox != null:
		var render_actions := HBoxContainer.new()
		render_actions.name = "RenderActions"
		render_actions.add_theme_constant_override("separation", 8)
		if save_triage_button != null and save_triage_button.get_parent() != null:
			save_triage_button.get_parent().remove_child(save_triage_button)
		if promote_button != null and promote_button.get_parent() != null:
			promote_button.get_parent().remove_child(promote_button)
		if save_triage_button != null:
			render_actions.add_child(save_triage_button)
		if promote_button != null:
			render_actions.add_child(promote_button)
		preview_vbox.add_child(render_actions)
		preview_vbox.move_child(render_actions, preview_mount.get_index() + 1)

func _install_panel_headers() -> void:
	if collapsed_panel_row == null and is_instance_valid(header_container):
		collapsed_panel_row = HBoxContainer.new()
		collapsed_panel_row.name = "CollapsedPanelRow"
		collapsed_panel_row.add_theme_constant_override("separation", 8)
		header_container.add_child(collapsed_panel_row)
		header_container.move_child(collapsed_panel_row, header_container.get_child_count() - 1)
	if library_panel_toggle == null and is_instance_valid(library_vbox):
		library_panel_toggle = _create_panel_toggle_row(library_vbox, "Library", "_on_library_panel_toggle")
	if editor_panel_toggle == null and is_instance_valid(editor_padding):
		editor_panel_toggle = _create_panel_toggle_row(editor_padding, "Editor", "_on_editor_panel_toggle")
	if preview_panel_toggle == null and is_instance_valid(preview_vbox):
		preview_panel_toggle = _create_panel_toggle_row(preview_vbox, "Preview", "_on_preview_panel_toggle")

func _create_panel_toggle_row(parent: Control, title_text: String, method_name: String) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var button := Button.new()
	button.custom_minimum_size = Vector2(42, 0)
	button.button_up.connect(Callable(self, method_name))
	row.add_child(button)
	parent.add_child(row)
	parent.move_child(row, 0)
	return button

func _apply_panel_collapse_state() -> void:
	library_panel.visible = not library_panel_collapsed
	editor_panel.visible = not editor_panel_collapsed
	preview_panel.visible = not preview_panel_collapsed
	if library_panel_toggle != null:
		library_panel_toggle.text = ">" if library_panel_collapsed else "<"
		library_panel_toggle.tooltip_text = "Expand library" if library_panel_collapsed else "Collapse library"
	if editor_panel_toggle != null:
		editor_panel_toggle.text = ">" if editor_panel_collapsed else "<"
		editor_panel_toggle.tooltip_text = "Expand editor" if editor_panel_collapsed else "Collapse editor"
	if preview_panel_toggle != null:
		preview_panel_toggle.text = "<" if preview_panel_collapsed else ">"
		preview_panel_toggle.tooltip_text = "Expand preview" if preview_panel_collapsed else "Collapse preview"
	_refresh_collapsed_panel_buttons()
	library_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if library_panel_collapsed else LIBRARY_PANEL_MIN_WIDTH
	editor_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if editor_panel_collapsed else EDITOR_PANEL_MIN_WIDTH
	preview_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if preview_panel_collapsed else PREVIEW_PANEL_MIN_WIDTH
	library_panel.size_flags_horizontal = 0 if library_panel_collapsed else Control.SIZE_EXPAND_FILL
	editor_panel.size_flags_horizontal = 0 if editor_panel_collapsed else Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_horizontal = 0 if preview_panel_collapsed else Control.SIZE_EXPAND_FILL
	call_deferred("_apply_split_layout")

func _refresh_collapsed_panel_buttons() -> void:
	if collapsed_panel_row == null:
		return
	for child: Node in collapsed_panel_row.get_children():
		child.queue_free()
	if library_panel_collapsed:
		collapsed_panel_row.add_child(_create_collapsed_panel_button("Show Library", "_on_library_panel_toggle"))
	if editor_panel_collapsed:
		collapsed_panel_row.add_child(_create_collapsed_panel_button("Show Editor", "_on_editor_panel_toggle"))
	if preview_panel_collapsed:
		collapsed_panel_row.add_child(_create_collapsed_panel_button("Show Preview", "_on_preview_panel_toggle"))
	collapsed_panel_row.visible = collapsed_panel_row.get_child_count() > 0

func _create_collapsed_panel_button(label_text: String, method_name: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.button_up.connect(Callable(self, method_name))
	return button

func _on_library_panel_toggle() -> void:
	library_panel_collapsed = not library_panel_collapsed
	_apply_panel_collapse_state()

func _on_editor_panel_toggle() -> void:
	editor_panel_collapsed = not editor_panel_collapsed
	_apply_panel_collapse_state()

func _on_preview_panel_toggle() -> void:
	preview_panel_collapsed = not preview_panel_collapsed
	_apply_panel_collapse_state()

func _build_editor_hero() -> Control:
	var card_data: CardData = current_session.working_card_data
	var counts: Dictionary = _get_diagnostic_counts()
	var severity_text: String = "Ready"
	if counts["errors"] > 0:
		severity_text = "%s error(s)" % counts["errors"]
	elif counts["warnings"] > 0:
		severity_text = "%s warning(s)" % counts["warnings"]
	var target_text: String = "No clicked target"
	if card_data.card_requires_target:
		target_text = "Needs %s target" % _format_clicked_target_mode(card_data.get_effective_clicked_target_mode())
	var lines: Array[String] = [
		"%s" % card_data.get_card_name(),
		"%s | %s | %s" % [
			_enum_label_from_value(CardData.CARD_TYPES, card_data.card_type).capitalize(),
			_enum_label_from_value(CardData.CARD_RARITIES, card_data.card_rarity).capitalize(),
			card_data.card_color_id,
		],
		"Cost %s | %s | %s" % [
			"X" if card_data.card_energy_cost_is_variable else str(card_data.card_energy_cost),
			target_text,
			severity_text,
		],
	]
	return _build_section_intro("Card Focus", "\n".join(lines))

func _build_property_section(group_data: Dictionary) -> Control:
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
	var title := Label.new()
	title.text = str(group_data.get("title", "Section"))
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.add_child(title)
	var collapse_button := Button.new()
	var group_title: String = str(group_data.get("title", "Section"))
	collapse_button.text = COLLAPSED_ARROW if bool(collapsed_property_groups.get(group_title, false)) else EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		collapsed_property_groups[group_title] = not bool(collapsed_property_groups.get(group_title, false))
		_render_inspector()
	)
	header.add_child(collapse_button)
	wrapper.add_child(header)
	var description_text: String = str(group_data.get("description", ""))
	if description_text != "":
		var description := Label.new()
		description.text = description_text
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.modulate = Color(0.8, 0.82, 0.86, 0.9)
		wrapper.add_child(description)
	if bool(collapsed_property_groups.get(group_title, false)):
		return panel
	var grid := GridContainer.new()
	grid.columns = int(group_data.get("columns", 1))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var field_definitions: Dictionary = service.get_card_field_definitions()
	for property_name: String in group_data.get("fields", []):
		var field_definition: Dictionary = field_definitions.get(property_name, {})
		grid.add_child(_build_property_card(property_name, field_definition))
	wrapper.add_child(grid)
	return panel

func _build_property_card(property_name: String, field_definition: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_type: String = str(field_definition.get("value_type", "string"))
	if value_type in ["multiline_string", "dictionary", "array"] or property_name == "card_keyword_object_ids":
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 10)
	padding.add_theme_constant_override("margin_top", 10)
	padding.add_theme_constant_override("margin_right", 10)
	padding.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(padding)
	padding.add_child(_build_property_editor(property_name, field_definition))
	return panel

func _build_simple_toggle_row(title_text: String, description_text: String, expanded: bool, on_toggle: Callable) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(padding)
	padding.add_child(row)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = title_text
	text_box.add_child(title)
	var description := Label.new()
	description.text = description_text
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.modulate = Color(0.8, 0.82, 0.86, 0.9)
	text_box.add_child(description)
	row.add_child(text_box)
	var button := Button.new()
	button.text = "Hide" if expanded else "Show"
	button.button_up.connect(on_toggle)
	row.add_child(button)
	return panel

func _build_section_intro(title_text: String, description_text: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 12)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 12)
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	panel.add_child(padding)
	padding.add_child(wrapper)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 20)
	wrapper.add_child(title)
	var description := Label.new()
	description.text = description_text
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.modulate = Color(0.84, 0.84, 0.88, 0.95)
	wrapper.add_child(description)
	return panel

func _build_property_editor(property_name: String, field_definition: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_constant_override("separation", 6)
	var description := _property_description(property_name, field_definition)
	wrapper.tooltip_text = description
	var label := Label.new()
	label.text = _property_label(property_name, field_definition)
	label.add_theme_font_size_override("font_size", 14)
	label.tooltip_text = description
	wrapper.add_child(label)
	var value_type: String = str(field_definition.get("value_type", "string"))
	var card_data: CardData = current_session.working_card_data
	var property_value: Variant = card_data.get(property_name)
	if property_name == "card_color_id":
		wrapper.add_child(_build_card_color_editor(property_name, str(property_value), description))
		return wrapper
	if property_name == "card_keyword_object_ids":
		var keyword_values: Array[String] = []
		keyword_values.assign(property_value)
		wrapper.add_child(_build_keyword_editor(property_name, keyword_values))
		return wrapper
	if property_name == "card_values":
		var card_values: Dictionary = property_value
		wrapper.add_child(_build_card_values_editor(property_name, card_values))
		return wrapper
	if value_type == "dictionary":
		var dictionary_value: Dictionary = property_value
		wrapper.add_child(_build_dictionary_editor(property_name, dictionary_value))
		return wrapper
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(property_value)
			_setup_checkbox(checkbox)
			_style_checkbox(checkbox, bool(property_value))
			checkbox.toggled.connect(func(pressed: bool):
				service.set_card_property(current_session, property_name, pressed)
				_request_editor_panels_refresh()
			)
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
				_request_editor_panels_refresh()
			)
			dropdown.tooltip_text = description
			wrapper.add_child(dropdown)
		"int":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1
			spin.value = float(property_value)
			spin.value_changed.connect(func(value: float):
				service.set_card_property(current_session, property_name, int(value))
				_request_editor_panels_refresh()
			)
			spin.tooltip_text = description
			wrapper.add_child(spin)
		"multiline_string":
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 96)
			text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_edit.text = str(property_value)
			text_edit.tooltip_text = description
			text_edit.focus_exited.connect(func():
				service.set_card_property(current_session, property_name, text_edit.text)
				_request_editor_panels_refresh()
			)
			wrapper.add_child(text_edit)
		"string_array":
			var line_edit := LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.text = ",".join(property_value)
			line_edit.placeholder_text = "comma,separated,values"
			line_edit.tooltip_text = description
			line_edit.text_submitted.connect(func(_text: String):
				service.set_card_property(current_session, property_name, _parse_csv_strings(line_edit.text))
				_request_editor_panels_refresh()
			)
			line_edit.focus_exited.connect(func():
				service.set_card_property(current_session, property_name, _parse_csv_strings(line_edit.text))
				_request_editor_panels_refresh()
			)
			wrapper.add_child(line_edit)
		"array":
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 96)
			text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_edit.text = JSON.stringify(property_value, "\t")
			text_edit.tooltip_text = description
			text_edit.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(text_edit.text)
				if parsed_value != null:
					service.set_card_property(current_session, property_name, parsed_value)
					_request_editor_panels_refresh()
			)
			wrapper.add_child(text_edit)
		_:
			var line_edit := LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.text = str(property_value)
			line_edit.tooltip_text = description
			line_edit.text_submitted.connect(func(new_text: String):
				service.set_card_property(current_session, property_name, new_text)
				_request_editor_panels_refresh()
			)
			line_edit.focus_exited.connect(func():
				service.set_card_property(current_session, property_name, line_edit.text)
				_request_editor_panels_refresh()
			)
			wrapper.add_child(line_edit)
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

func _build_card_color_editor(property_name: String, current_color_id: String, description: String) -> Control:
	var dropdown := OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dropdown.tooltip_text = description
	_populate_option_button(dropdown, _get_card_color_options(), current_color_id)
	dropdown.item_selected.connect(func(_index: int):
		var selected_color_id: Variant = _get_option_button_value(dropdown)
		if selected_color_id == null:
			return
		service.set_card_property(current_session, property_name, str(selected_color_id))
		_request_editor_panels_refresh()
	)
	return dropdown

func _build_card_values_editor(property_name: String, dictionary_value: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)
	var definitions: Dictionary[String, Dictionary] = service.get_card_value_definitions()
	var suggested_keys: Array[String] = _collect_card_value_suggestions()
	var used_key_lookup: Dictionary = {}
	for suggested_key: String in suggested_keys:
		used_key_lookup[suggested_key] = true
	var suggestion_panel := PanelContainer.new()
	var suggestion_padding := MarginContainer.new()
	suggestion_padding.add_theme_constant_override("margin_left", 8)
	suggestion_padding.add_theme_constant_override("margin_top", 8)
	suggestion_padding.add_theme_constant_override("margin_right", 8)
	suggestion_padding.add_theme_constant_override("margin_bottom", 8)
	var suggestion_vbox := VBoxContainer.new()
	suggestion_vbox.add_theme_constant_override("separation", 4)
	suggestion_panel.add_child(suggestion_padding)
	suggestion_padding.add_child(suggestion_vbox)
	var suggestion_label := Label.new()
	suggestion_label.text = "Suggested entries for this card"
	suggestion_vbox.add_child(suggestion_label)
	var missing_suggested_keys: Array[String] = []
	for suggested_key: String in suggested_keys:
		if not dictionary_value.has(suggested_key):
			missing_suggested_keys.append(suggested_key)
	suggestion_vbox.add_child(_build_card_value_suggestion_row(property_name, missing_suggested_keys, definitions))
	wrapper.add_child(suggestion_panel)
	var sorted_keys: Array[String] = []
	for dictionary_key: Variant in dictionary_value.keys():
		sorted_keys.append(str(dictionary_key))
	sorted_keys.sort()
	if sorted_keys.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No card values configured."
		wrapper.add_child(empty_label)
	for key_name: String in sorted_keys:
		wrapper.add_child(_build_card_value_row(property_name, key_name, dictionary_value.get(key_name), definitions.get(key_name, {}), bool(used_key_lookup.get(key_name, false))))
	wrapper.add_child(_build_card_value_add_panel(property_name, dictionary_value, definitions))
	return wrapper

func _build_card_value_suggestion_row(property_name: String, suggested_keys: Array[String], definitions: Dictionary[String, Dictionary]) -> Control:
	if suggested_keys.is_empty():
		var empty_label := Label.new()
		empty_label.text = "All detected suggestions are already present."
		empty_label.modulate = Color(0.76, 0.8, 0.88, 0.95)
		return empty_label
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	for key_name: String in suggested_keys:
		var definition: Dictionary = definitions.get(key_name, {})
		var button := Button.new()
		button.text = str(definition.get("label", key_name))
		button.tooltip_text = "%s (%s)" % [key_name, str(definition.get("description", "Suggested from this card's description or actions."))]
		button.button_up.connect(func():
			var resolved_definition: Dictionary = definitions.get(key_name, {})
			if service.set_dictionary_value(current_session, property_name, key_name, resolved_definition.get("default_value", null)):
				_request_editor_panels_refresh()
		)
		flow.add_child(button)
	return flow

func _build_card_value_row(property_name: String, key_name: String, current_value: Variant, definition: Dictionary, is_referenced: bool) -> Control:
	var panel := PanelContainer.new()
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 8)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_right", 8)
	padding.add_theme_constant_override("margin_bottom", 8)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(padding)
	padding.add_child(row)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	var title_label := Label.new()
	var display_label: String = str(definition.get("label", key_name))
	title_label.text = display_label
	title_label.add_theme_font_size_override("font_size", 14)
	title_box.add_child(title_label)
	if not is_referenced:
		var stale_label := Label.new()
		stale_label.text = "Not referenced by current description/actions"
		stale_label.modulate = Color(0.95, 0.78, 0.48, 0.98)
		title_box.add_child(stale_label)
	var meta_label := Label.new()
	var value_type: String = str(definition.get("value_type", _infer_variant_type(current_value)))
	meta_label.text = "%s | %s" % [key_name, value_type]
	meta_label.modulate = Color(0.76, 0.8, 0.88, 0.95)
	title_box.add_child(meta_label)
	var description: String = str(definition.get("description", ""))
	if description != "":
		var description_label := Label.new()
		description_label.text = description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.modulate = Color(0.82, 0.82, 0.86, 0.95)
		title_box.add_child(description_label)
	header.add_child(title_box)
	if definition.is_empty():
		var key_edit := LineEdit.new()
		key_edit.custom_minimum_size = Vector2(180, 0)
		key_edit.text = key_name
		key_edit.focus_exited.connect(func():
			var renamed_key: String = key_edit.text.strip_edges()
			if renamed_key == "" or renamed_key == key_name:
				key_edit.text = key_name
				return
			if service.rename_dictionary_key(current_session, property_name, key_name, renamed_key):
				_request_editor_panels_refresh()
			else:
				key_edit.text = key_name
		)
		header.add_child(key_edit)
		var type_option := OptionButton.new()
		_populate_option_button(type_option, _variant_type_options())
		_select_option_value(type_option, value_type)
		type_option.item_selected.connect(func(_index: int):
			var next_type: String = str(_get_option_button_value(type_option))
			if service.set_dictionary_value(current_session, property_name, key_name, _coerce_variant_value(current_value, next_type)):
				_request_editor_panels_refresh()
		)
		header.add_child(type_option)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		if service.remove_dictionary_value(current_session, property_name, key_name):
			_request_editor_panels_refresh()
	)
	header.add_child(remove_button)
	row.add_child(header)
	row.add_child(_build_card_value_value_editor(property_name, key_name, current_value, definition))
	return panel

func _build_card_value_value_editor(property_name: String, key_name: String, current_value: Variant, definition: Dictionary) -> Control:
	var value_type: String = str(definition.get("value_type", _infer_variant_type(current_value)))
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			_setup_checkbox(checkbox)
			_style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				if service.set_dictionary_value(current_session, property_name, key_name, pressed):
					_request_editor_panels_refresh()
			)
			return checkbox
		"int":
			var int_spin := SpinBox.new()
			int_spin.min_value = -9999
			int_spin.max_value = 99999
			int_spin.step = 1
			int_spin.value = float(current_value if current_value != null else 0)
			int_spin.value_changed.connect(func(value: float):
				if service.set_dictionary_value(current_session, property_name, key_name, int(value)):
					_request_editor_panels_refresh()
			)
			return int_spin
		"float":
			var float_spin := SpinBox.new()
			float_spin.min_value = -9999
			float_spin.max_value = 99999
			float_spin.step = 0.1
			float_spin.value = float(current_value if current_value != null else 0)
			float_spin.value_changed.connect(func(value: float):
				if service.set_dictionary_value(current_session, property_name, key_name, value):
					_request_editor_panels_refresh()
			)
			return float_spin
		"enum":
			var dropdown := OptionButton.new()
			var options: Array = definition.get("options", [])
			for option_data: Variant in options:
				if option_data is Dictionary:
					dropdown.add_item(str(option_data.get("label", option_data.get("value", ""))))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data.get("value", null))
				else:
					dropdown.add_item(str(option_data))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data)
			for option_index: int in range(dropdown.get_item_count()):
				if dropdown.get_item_metadata(option_index) == current_value:
					dropdown.select(option_index)
					break
			dropdown.item_selected.connect(func(option_index: int):
				if service.set_dictionary_value(current_session, property_name, key_name, dropdown.get_item_metadata(option_index)):
					_request_editor_panels_refresh()
			)
			return dropdown
		_:
			var line_edit := LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				if service.set_dictionary_value(current_session, property_name, key_name, _coerce_string_parameter(new_text, value_type)):
					_request_editor_panels_refresh()
			)
			line_edit.focus_exited.connect(func():
				if service.set_dictionary_value(current_session, property_name, key_name, _coerce_string_parameter(line_edit.text, value_type)):
					_request_editor_panels_refresh()
			)
			return line_edit

func _build_card_value_add_panel(property_name: String, dictionary_value: Dictionary, definitions: Dictionary[String, Dictionary]) -> Control:
	var panel := PanelContainer.new()
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 8)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_right", 8)
	padding.add_theme_constant_override("margin_bottom", 8)
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)
	panel.add_child(padding)
	padding.add_child(wrapper)
	var known_title := Label.new()
	known_title.text = "Add Known Value"
	wrapper.add_child(known_title)
	var known_row := HBoxContainer.new()
	known_row.add_theme_constant_override("separation", 6)
	var known_option := OptionButton.new()
	known_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var known_options: Array[Dictionary] = _get_card_value_definition_options(dictionary_value, definitions)
	_populate_option_button(known_option, known_options)
	known_row.add_child(known_option)
	var add_known_button := Button.new()
	add_known_button.text = "Add"
	add_known_button.disabled = known_option.get_item_count() == 0
	add_known_button.button_up.connect(func():
		var selected_key: Variant = _get_option_button_value(known_option)
		if selected_key == null:
			return
		var key_name: String = str(selected_key)
		var definition: Dictionary = definitions.get(key_name, {})
		if service.set_dictionary_value(current_session, property_name, key_name, definition.get("default_value", null)):
			_refresh_editor_panels()
	)
	known_row.add_child(add_known_button)
	wrapper.add_child(known_row)
	var custom_title := Label.new()
	custom_title.text = "Add Custom Value"
	wrapper.add_child(custom_title)
	var custom_row := HBoxContainer.new()
	custom_row.add_theme_constant_override("separation", 6)
	var add_key_edit := LineEdit.new()
	add_key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_key_edit.placeholder_text = "custom_key_name"
	custom_row.add_child(add_key_edit)
	var add_type_option := OptionButton.new()
	_populate_option_button(add_type_option, _variant_type_options())
	custom_row.add_child(add_type_option)
	var add_custom_button := Button.new()
	add_custom_button.text = "Add"
	add_custom_button.button_up.connect(func():
		var key_name: String = add_key_edit.text.strip_edges()
		if key_name == "" or dictionary_value.has(key_name):
			return
		var type_name: String = str(_get_option_button_value(add_type_option))
		if service.set_dictionary_value(current_session, property_name, key_name, _default_value_for_variant_type(type_name)):
			_refresh_editor_panels()
	)
	custom_row.add_child(add_custom_button)
	wrapper.add_child(custom_row)
	return panel

func _build_dictionary_editor(property_name: String, dictionary_value: Dictionary, use_suggestions: bool = false) -> Control:
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
	var suggested_key_option: OptionButton = null
	if use_suggestions:
		suggested_key_option = OptionButton.new()
		_populate_option_button(suggested_key_option, _get_card_value_key_options(dictionary_value))
		add_vbox.add_child(suggested_key_option)
	var add_key_edit := LineEdit.new()
	add_key_edit.placeholder_text = "key_name"
	add_vbox.add_child(add_key_edit)
	var add_type_option := OptionButton.new()
	_populate_option_button(add_type_option, _variant_type_options())
	add_vbox.add_child(add_type_option)
	if suggested_key_option != null:
		suggested_key_option.item_selected.connect(func(_index: int):
			var selected_key: Variant = _get_option_button_value(suggested_key_option)
			if selected_key != null:
				add_key_edit.text = str(selected_key)
		)
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
	behavior_render_queued = false
	for child in behavior_container.get_children():
		behavior_container.remove_child(child)
		child.queue_free()
	if current_session == null or current_session.working_card_data == null:
		return
	behavior_container.add_child(_build_section_intro(
		"Behavior",
		"Keep the main card flow visible. Secondary hooks stay tucked away until you need them."
	))
	for property_name: String in PRIMARY_BEHAVIOR_GROUPS:
		behavior_container.add_child(_build_entry_group(property_name, not property_name.contains("validators")))
	behavior_container.add_child(_build_additional_action_group())
	var secondary_toggle := _build_simple_toggle_row(
		"Triggered and deck hooks",
		"Discard, draw, retain, and deck-change hooks are usually niche. Open them only when the card needs them.",
		show_secondary_behavior_groups,
		func():
			show_secondary_behavior_groups = not show_secondary_behavior_groups
			_request_behavior_render()
	)
	behavior_container.add_child(secondary_toggle)
	if show_secondary_behavior_groups:
		for property_name: String in SECONDARY_BEHAVIOR_GROUPS:
			var entries: Array = current_session.working_card_data.get(property_name)
			if entries.is_empty():
				continue
			behavior_container.add_child(_build_entry_group(property_name, true))

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
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var collapse_button := Button.new()
	collapse_button.text = COLLAPSED_ARROW if collapsed_behavior_groups.get(property_name, false) else EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		collapsed_behavior_groups[property_name] = not bool(collapsed_behavior_groups.get(property_name, false))
		_request_behavior_render()
	)
	header.add_child(collapse_button)
	vbox.add_child(header)
	if BEHAVIOR_GROUP_DESCRIPTIONS.has(property_name):
		var description := Label.new()
		description.text = str(BEHAVIOR_GROUP_DESCRIPTIONS[property_name])
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.modulate = Color(0.8, 0.82, 0.86, 0.9)
		vbox.add_child(description)
	if bool(collapsed_behavior_groups.get(property_name, false)):
		return panel
	if entries.is_empty():
		var no_entries := Label.new()
		no_entries.text = "No entries configured yet."
		no_entries.modulate = Color(0.78, 0.8, 0.84, 0.9)
		vbox.add_child(no_entries)
		return panel
	for index: int in range(len(entries)):
		var entry: Dictionary = entries[index]
		vbox.add_child(_build_entry_editor(property_name, index, entry, is_action))
	return panel

func _build_additional_action_group() -> Control:
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
	var property_name := "card_additional_actions"
	var entries: Array = service.get_additional_action_entries(current_session)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "%s (%s)" % [PROPERTY_GROUP_LABELS[property_name], len(entries)]
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var collapse_button := Button.new()
	collapse_button.text = COLLAPSED_ARROW if collapsed_behavior_groups.get(property_name, false) else EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		collapsed_behavior_groups[property_name] = not bool(collapsed_behavior_groups.get(property_name, false))
		_request_behavior_render()
	)
	header.add_child(collapse_button)
	vbox.add_child(header)
	var description := Label.new()
	description.text = str(BEHAVIOR_GROUP_DESCRIPTIONS.get(property_name, ""))
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.modulate = Color(0.8, 0.82, 0.86, 0.9)
	vbox.add_child(description)
	if bool(collapsed_behavior_groups.get(property_name, false)):
		return panel
	if entries.is_empty():
		var no_entries := Label.new()
		no_entries.text = "No additional actions yet. Use an action parameter's Add Action button to create one."
		no_entries.modulate = Color(0.78, 0.8, 0.84, 0.9)
		vbox.add_child(no_entries)
		return panel
	for entry_index: int in range(len(entries)):
		var additional_action: Dictionary = entries[entry_index]
		vbox.add_child(_build_additional_action_editor(entry_index, additional_action))
	return panel

func _build_additional_action_editor(entry_index: int, additional_action: Dictionary) -> Control:
	var additional_action_id: String = str(additional_action.get("id", ""))
	var action_entry: Dictionary = additional_action.get("action", {})
	if additional_action_id == "" or action_entry.is_empty():
		return Label.new()
	var token: String = str(action_entry.keys()[0])
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
	var option_entries: Array[Dictionary] = service.get_action_options("action_children")
	var token_option := OptionButton.new()
	for option_data: Dictionary in option_entries:
		token_option.add_item(str(option_data.get("display_name", option_data.get("resolved_token", ""))))
		token_option.set_item_metadata(token_option.get_item_count() - 1, option_data)
	var display_name: String = token
	for item_index: int in range(token_option.get_item_count()):
		var metadata: Dictionary = token_option.get_item_metadata(item_index)
		if str(metadata.get("resolved_token", "")) == Scripts.normalize_script_reference(token):
			token_option.select(item_index)
			display_name = str(metadata.get("display_name", token))
			break
	var title_label := Label.new()
	title_label.text = "%s (%s)" % [display_name, additional_action_id]
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 15)
	toolbar.add_child(title_label)
	var entry_key: String = _entry_visibility_key("card_additional_actions", entry_index, additional_action_id)
	var collapse_button := Button.new()
	collapse_button.text = COLLAPSED_ARROW if collapsed_behavior_entries.get(entry_key, false) else EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		collapsed_behavior_entries[entry_key] = not bool(collapsed_behavior_entries.get(entry_key, false))
		_request_behavior_render()
	)
	toolbar.add_child(collapse_button)
	var up_button := Button.new()
	up_button.text = "Up"
	up_button.button_up.connect(func():
		if service.move_additional_action(current_session, entry_index, max(entry_index - 1, 0)):
			_refresh_editor_panels()
	)
	toolbar.add_child(up_button)
	var down_button := Button.new()
	down_button.text = "Down"
	down_button.button_up.connect(func():
		if service.move_additional_action(current_session, entry_index, min(entry_index + 1, len(service.get_additional_action_entries(current_session)) - 1)):
			_refresh_editor_panels()
	)
	toolbar.add_child(down_button)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		if service.remove_additional_action(current_session, additional_action_id):
			_refresh_editor_panels()
	)
	toolbar.add_child(remove_button)
	wrapper.add_child(toolbar)
	if bool(collapsed_behavior_entries.get(entry_key, false)):
		var collapsed_summary := Label.new()
		collapsed_summary.text = _build_entry_summary(token, action_entry[token], true)
		collapsed_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		collapsed_summary.modulate = Color(0.82, 0.82, 0.86, 0.95)
		wrapper.add_child(collapsed_summary)
		return entry_panel
	var token_metadata: Dictionary = service.get_action_metadata(token)
	var token_description: String = str(token_metadata.get("description", ""))
	if token_description != "":
		var description_label := Label.new()
		description_label.text = token_description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.modulate = Color(0.82, 0.82, 0.86, 0.95)
		wrapper.add_child(description_label)
	var token_row := HBoxContainer.new()
	var token_label := Label.new()
	token_label.text = "Effect"
	token_label.custom_minimum_size = Vector2(52, 0)
	token_row.add_child(token_label)
	token_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	token_row.add_child(token_option)
	wrapper.add_child(token_row)
	token_option.item_selected.connect(func(selected_index: int):
		var metadata: Dictionary = token_option.get_item_metadata(selected_index)
		var next_token: String = str(metadata.get("resolved_token", metadata.get("token_or_path", "")))
		service.replace_additional_action(current_session, additional_action_id, next_token)
		_refresh_after_behavior_structure_change()
	)
	var parameters: Array[Dictionary] = []
	parameters.assign(token_metadata.get("parameters", []))
	var values: Dictionary = action_entry[token]
	var visible_parameters: Array[Dictionary] = []
	for parameter_data: Dictionary in parameters:
		if _should_show_parameter(parameter_data, values):
			visible_parameters.append(parameter_data)
	if not visible_parameters.is_empty():
		var parameter_grid := GridContainer.new()
		parameter_grid.columns = 2
		parameter_grid.add_theme_constant_override("h_separation", 8)
		parameter_grid.add_theme_constant_override("v_separation", 8)
		for parameter_data: Dictionary in visible_parameters:
			parameter_grid.add_child(_build_additional_action_parameter_editor(additional_action_id, token, parameter_data, values))
		wrapper.add_child(parameter_grid)
	return entry_panel

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
	title_label.add_theme_font_size_override("font_size", 15)
	toolbar.add_child(title_label)
	var entry_key: String = _entry_visibility_key(property_name, index, token)
	var collapse_button := Button.new()
	collapse_button.text = COLLAPSED_ARROW if collapsed_behavior_entries.get(entry_key, false) else EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		collapsed_behavior_entries[entry_key] = not bool(collapsed_behavior_entries.get(entry_key, false))
		_request_behavior_render()
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
		var collapsed_summary := Label.new()
		collapsed_summary.text = _build_entry_summary(token, entry[token], is_action)
		collapsed_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		collapsed_summary.modulate = Color(0.82, 0.82, 0.86, 0.95)
		wrapper.add_child(collapsed_summary)
		return entry_panel
	var token_metadata: Dictionary = service.get_action_metadata(token) if is_action else service.get_validator_metadata(token)
	var token_description: String = str(token_metadata.get("description", ""))
	if token_description != "":
		var description_label := Label.new()
		description_label.text = token_description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.modulate = Color(0.82, 0.82, 0.86, 0.95)
		wrapper.add_child(description_label)
	var token_row := HBoxContainer.new()
	var token_label := Label.new()
	token_label.text = "Effect"
	token_label.custom_minimum_size = Vector2(52, 0)
	token_row.add_child(token_label)
	token_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	token_row.add_child(token_option)
	wrapper.add_child(token_row)
	token_option.item_selected.connect(func(selected_index: int):
		var metadata: Dictionary = token_option.get_item_metadata(selected_index)
		var next_token: String = str(metadata.get("resolved_token", metadata.get("token_or_path", "")))
		service.replace_entry(current_session, property_name, index, next_token)
		_refresh_after_behavior_structure_change()
	)
	var parameters: Array[Dictionary] = []
	parameters.assign(token_metadata.get("parameters", []))
	var values: Dictionary = entry[token]
	var visible_parameters: Array[Dictionary] = []
	for parameter_data: Dictionary in parameters:
		if _should_show_parameter(parameter_data, values):
			visible_parameters.append(parameter_data)
	if not visible_parameters.is_empty():
		var parameter_grid := GridContainer.new()
		parameter_grid.columns = 2
		parameter_grid.add_theme_constant_override("h_separation", 8)
		parameter_grid.add_theme_constant_override("v_separation", 8)
		for parameter_data: Dictionary in visible_parameters:
			parameter_grid.add_child(_build_entry_parameter_editor(property_name, index, token, parameter_data, values))
		wrapper.add_child(parameter_grid)
	var advanced_toggle := _build_advanced_parameter_toggle(property_name, index, token, is_action, values)
	if advanced_toggle != null:
		wrapper.add_child(advanced_toggle)
	return entry_panel

func _build_entry_summary(token: String, values: Dictionary, is_action: bool) -> String:
	var metadata: Dictionary = service.get_action_metadata(token) if is_action else service.get_validator_metadata(token)
	var fragments: Array[String] = []
	var parameters: Array[Dictionary] = []
	parameters.assign(metadata.get("parameters", []))
	for parameter_data: Dictionary in parameters:
		var parameter_name: String = str(parameter_data.get("name", ""))
		if parameter_name == "" or not values.has(parameter_name):
			continue
		if not _should_show_parameter(parameter_data, values):
			continue
		fragments.append("%s: %s" % [str(parameter_data.get("label", parameter_name)), _format_inline_value(values[parameter_name])])
		if len(fragments) >= 3:
			break
	if fragments.is_empty():
		return "No edited parameters."
	return " | ".join(fragments)

func _build_entry_parameter_editor(property_name: String, index: int, token: String, parameter_data: Dictionary, values: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 8)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_right", 8)
	padding.add_theme_constant_override("margin_bottom", 8)
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	panel.add_child(padding)
	padding.add_child(wrapper)
	var label := Label.new()
	var parameter_name: String = str(parameter_data.get("name", ""))
	label.text = str(parameter_data.get("label", parameter_name))
	label.add_theme_font_size_override("font_size", 13)
	var description: String = str(parameter_data.get("description", ""))
	label.tooltip_text = description
	panel.tooltip_text = description
	wrapper.add_child(label)
	var current_value: Variant = values.get(parameter_name, parameter_data.get("default_value", null))
	var value_type: String = str(parameter_data.get("value_type", "variant"))
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			_setup_checkbox(checkbox)
			_style_checkbox(checkbox, bool(current_value))
			checkbox.toggled.connect(func(pressed: bool):
				service.update_entry_values(current_session, property_name, index, {parameter_name: pressed})
				_refresh_after_behavior_change()
			)
			wrapper.add_child(checkbox)
		"enum":
			var dropdown := OptionButton.new()
			var options: Array = parameter_data.get("options", [])
			for option_data: Variant in options:
				if option_data is Dictionary:
					dropdown.add_item(str(option_data.get("label", option_data.get("value", ""))))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data.get("value", null))
				else:
					dropdown.add_item(str(option_data))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data)
			for option_index: int in range(dropdown.get_item_count()):
				if dropdown.get_item_metadata(option_index) == current_value:
					dropdown.select(option_index)
					break
			dropdown.item_selected.connect(func(option_index: int):
				service.update_entry_values(current_session, property_name, index, {parameter_name: dropdown.get_item_metadata(option_index)})
				_refresh_after_behavior_change()
			)
			dropdown.tooltip_text = description
			wrapper.add_child(dropdown)
		"enum_array":
			wrapper.add_child(_build_enum_array_parameter_editor(property_name, index, parameter_name, parameter_data, current_value))
		"int", "float":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1 if value_type == "int" else 0.1
			spin.value = float(current_value if current_value != null else 0)
			spin.value_changed.connect(func(value: float):
				service.update_entry_values(current_session, property_name, index, {parameter_name: int(value) if value_type == "int" else value})
				_refresh_after_behavior_change()
			)
			spin.tooltip_text = description
			wrapper.add_child(spin)
		"validator_array":
			wrapper.add_child(_build_nested_validator_array_editor(property_name, index, parameter_name, current_value))
		"array":
			if _is_action_reference_parameter(parameter_name):
				wrapper.add_child(_build_action_reference_array_editor("card_entry", _card_entry_owner_key(property_name, index), parameter_name, current_value))
				return panel
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 72)
			text_edit.text = JSON.stringify(current_value, "\t")
			text_edit.tooltip_text = description
			text_edit.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(text_edit.text)
				if parsed_value != null:
					service.update_entry_values(current_session, property_name, index, {parameter_name: parsed_value})
					_refresh_after_behavior_change()
			)
			wrapper.add_child(text_edit)
		"card_array":
			wrapper.add_child(_build_string_array_parameter_editor(property_name, index, parameter_name, current_value, "card_1,card_2"))
		"string_array":
			wrapper.add_child(_build_string_array_parameter_editor(property_name, index, parameter_name, current_value, "value_1,value_2"))
		"dictionary":
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 72)
			text_edit.text = JSON.stringify(current_value, "\t")
			text_edit.tooltip_text = description
			text_edit.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(text_edit.text)
				if parsed_value != null:
					service.update_entry_values(current_session, property_name, index, {parameter_name: parsed_value})
					_refresh_after_behavior_change()
			)
			wrapper.add_child(text_edit)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.tooltip_text = description
			line_edit.text_submitted.connect(func(new_text: String):
				service.update_entry_values(current_session, property_name, index, {parameter_name: _coerce_string_parameter(new_text, value_type)})
				_refresh_after_behavior_change()
			)
			line_edit.focus_exited.connect(func():
				service.update_entry_values(current_session, property_name, index, {parameter_name: _coerce_string_parameter(line_edit.text, value_type)})
				_refresh_after_behavior_change()
			)
			wrapper.add_child(line_edit)
	return panel

func _build_additional_action_parameter_editor(additional_action_id: String, token: String, parameter_data: Dictionary, values: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 8)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_right", 8)
	padding.add_theme_constant_override("margin_bottom", 8)
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	panel.add_child(padding)
	padding.add_child(wrapper)
	var parameter_name: String = str(parameter_data.get("name", ""))
	var label := Label.new()
	label.text = str(parameter_data.get("label", parameter_name))
	label.add_theme_font_size_override("font_size", 13)
	var description: String = str(parameter_data.get("description", ""))
	label.tooltip_text = description
	panel.tooltip_text = description
	wrapper.add_child(label)
	var current_value: Variant = values.get(parameter_name, parameter_data.get("default_value", null))
	var value_type: String = str(parameter_data.get("value_type", "variant"))
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			_setup_checkbox(checkbox)
			_style_checkbox(checkbox, bool(current_value))
			checkbox.toggled.connect(func(pressed: bool):
				service.update_additional_action_values(current_session, additional_action_id, {parameter_name: pressed})
				_refresh_after_behavior_change()
			)
			wrapper.add_child(checkbox)
		"enum":
			var dropdown := OptionButton.new()
			var options: Array = parameter_data.get("options", [])
			for option_data: Variant in options:
				if option_data is Dictionary:
					dropdown.add_item(str(option_data.get("label", option_data.get("value", ""))))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data.get("value", null))
				else:
					dropdown.add_item(str(option_data))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data)
			for option_index: int in range(dropdown.get_item_count()):
				if dropdown.get_item_metadata(option_index) == current_value:
					dropdown.select(option_index)
					break
			dropdown.item_selected.connect(func(option_index: int):
				service.update_additional_action_values(current_session, additional_action_id, {parameter_name: dropdown.get_item_metadata(option_index)})
				_refresh_after_behavior_change()
			)
			wrapper.add_child(dropdown)
		"enum_array":
			wrapper.add_child(_build_additional_action_enum_array_editor(additional_action_id, parameter_name, parameter_data, current_value))
		"validator_array":
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 72)
			text_edit.text = JSON.stringify(current_value, "\t")
			text_edit.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(text_edit.text)
				if parsed_value != null:
					service.update_additional_action_values(current_session, additional_action_id, {parameter_name: parsed_value})
					_refresh_after_behavior_change()
			)
			wrapper.add_child(text_edit)
		"array":
			if _is_action_reference_parameter(parameter_name):
				wrapper.add_child(_build_action_reference_array_editor("additional_action", additional_action_id, parameter_name, current_value))
				return panel
			var array_text := TextEdit.new()
			array_text.custom_minimum_size = Vector2(0, 72)
			array_text.text = JSON.stringify(current_value, "\t")
			array_text.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(array_text.text)
				if parsed_value != null:
					service.update_additional_action_values(current_session, additional_action_id, {parameter_name: parsed_value})
					_refresh_after_behavior_change()
			)
			wrapper.add_child(array_text)
		"card_array":
			wrapper.add_child(_build_additional_action_string_array_editor(additional_action_id, parameter_name, current_value, "card_1,card_2"))
		"string_array":
			wrapper.add_child(_build_additional_action_string_array_editor(additional_action_id, parameter_name, current_value, "value_1,value_2"))
		"int", "float":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1 if value_type == "int" else 0.1
			spin.value = float(current_value if current_value != null else 0)
			spin.value_changed.connect(func(value: float):
				service.update_additional_action_values(current_session, additional_action_id, {parameter_name: int(value) if value_type == "int" else value})
				_refresh_after_behavior_change()
			)
			wrapper.add_child(spin)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				service.update_additional_action_values(current_session, additional_action_id, {parameter_name: _coerce_string_parameter(new_text, value_type)})
				_refresh_after_behavior_change()
			)
			line_edit.focus_exited.connect(func():
				service.update_additional_action_values(current_session, additional_action_id, {parameter_name: _coerce_string_parameter(line_edit.text, value_type)})
				_refresh_after_behavior_change()
			)
			wrapper.add_child(line_edit)
	return panel

func _build_action_reference_array_editor(owner_type: String, owner_key: String, parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var reference_ids: Array = []
	reference_ids.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var action_dropdown := OptionButton.new()
	action_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(action_dropdown, _metadata_options(service.get_action_options("action_children")))
	add_row.add_child(action_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Action"
	add_button.button_up.connect(func():
		var selected_token: Variant = _get_option_button_value(action_dropdown)
		if selected_token == null:
			return
		if service.create_additional_action_reference(current_session, owner_type, owner_key, parameter_name, str(selected_token)) != "":
			_refresh_after_behavior_structure_change()
	)
	add_row.add_child(add_button)
	wrapper.add_child(add_row)
	if reference_ids.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No additional actions referenced."
		wrapper.add_child(empty_label)
		return wrapper
	for reference_index: int in range(len(reference_ids)):
		var reference_value: Variant = reference_ids[reference_index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var reference_id: String = str(reference_value)
		var reference_label := Label.new()
		reference_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reference_label.text = _get_action_reference_label(reference_id, reference_value)
		row.add_child(reference_label)
		var up_button := Button.new()
		up_button.text = "Up"
		up_button.button_up.connect(func():
			if service.move_action_reference(current_session, owner_type, owner_key, parameter_name, reference_index, max(reference_index - 1, 0)):
				_refresh_after_behavior_structure_change()
		)
		row.add_child(up_button)
		var down_button := Button.new()
		down_button.text = "Down"
		down_button.button_up.connect(func():
			if service.move_action_reference(current_session, owner_type, owner_key, parameter_name, reference_index, min(reference_index + 1, len(reference_ids) - 1)):
				_refresh_after_behavior_structure_change()
		)
		row.add_child(down_button)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func():
			if service.remove_action_reference(current_session, owner_type, owner_key, parameter_name, reference_index):
				_refresh_after_behavior_structure_change()
		)
		row.add_child(remove_button)
		wrapper.add_child(row)
	return wrapper

func _build_additional_action_enum_array_editor(additional_action_id: String, parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	var current_values: Array = []
	current_values.assign(current_value if current_value is Array else [])
	for option_data: Variant in parameter_data.get("options", []):
		var option_label: String = str(option_data)
		var option_value: Variant = option_data
		if option_data is Dictionary:
			option_label = str(option_data.get("label", option_data.get("value", "")))
			option_value = option_data.get("value", null)
		var checkbox := CheckBox.new()
		checkbox.text = option_label
		checkbox.button_pressed = current_values.has(option_value)
		_setup_checkbox(checkbox)
		_style_checkbox(checkbox, checkbox.button_pressed)
		checkbox.toggled.connect(func(pressed: bool):
			var next_values: Array = current_values.duplicate(true)
			if pressed and not next_values.has(option_value):
				next_values.append(option_value)
			elif not pressed:
				next_values.erase(option_value)
			service.update_additional_action_values(current_session, additional_action_id, {parameter_name: next_values})
			_refresh_after_behavior_change()
		)
		wrapper.add_child(checkbox)
	return wrapper

func _build_additional_action_string_array_editor(additional_action_id: String, parameter_name: String, current_value: Variant, placeholder_text: String) -> Control:
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = placeholder_text
	line_edit.text = ",".join(_variant_to_string_array(current_value))
	line_edit.text_submitted.connect(func(_text: String):
		service.update_additional_action_values(current_session, additional_action_id, {parameter_name: _parse_csv_strings(line_edit.text)})
		_refresh_after_behavior_change()
	)
	line_edit.focus_exited.connect(func():
		service.update_additional_action_values(current_session, additional_action_id, {parameter_name: _parse_csv_strings(line_edit.text)})
		_refresh_after_behavior_change()
	)
	return line_edit

func _card_entry_owner_key(property_name: String, index: int) -> String:
	return "%s::%s" % [property_name, index]

func _get_action_reference_label(reference_id: String, reference_value: Variant) -> String:
	var additional_entries: Array = service.get_additional_action_entries(current_session)
	for additional_action: Dictionary in additional_entries:
		if str(additional_action.get("id", "")) != reference_id:
			continue
		var action_entry: Dictionary = additional_action.get("action", {})
		if action_entry.is_empty():
			break
		var token: String = str(action_entry.keys()[0])
		var metadata: Dictionary = service.get_action_metadata(token)
		var display_name: String = str(metadata.get("display_name", token))
		return "%s (%s)" % [display_name, reference_id]
	if reference_value is Dictionary:
		var legacy_entry: Dictionary = reference_value
		if not legacy_entry.is_empty():
			return "Legacy inline action"
	return "Missing action (%s)" % reference_id

func _render_preview() -> void:
	for child in preview_mount.get_children():
		child.queue_free()
	preview_card = null
	if current_session == null or current_session.working_card_data == null:
		var empty_label := Label.new()
		empty_label.text = "Open a card from the library or create a new preset-based draft to see the live preview."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_mount.add_child(empty_label)
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
	var policy_label: String = _format_save_policy(str(summary.get("save_policy", "")))
	var dirty_label: String = "Unsaved changes" if bool(summary.get("dirty", false)) else "Saved"
	session_label.text = "%s\n%s | %s" % [
		"%s (%s)" % [summary.get("card_name", "Untitled Card"), summary.get("object_id", "no_id")],
		policy_label,
		dirty_label,
	]
	session_label.tooltip_text = "State: %s" % dirty_label
	var diagnostics_lines: Array[String] = []
	var counts: Dictionary = _get_diagnostic_counts()
	if counts["errors"] == 0 and counts["warnings"] == 0:
		diagnostics_lines.append("[color=#9fe2a9]Ready to save.[/color] No editor issues are currently blocking this card.")
	else:
		var visible_diagnostics: Array = current_session.diagnostics.slice(0, min(len(current_session.diagnostics), MAX_VISIBLE_DIAGNOSTICS))
		for diagnostic: Dictionary in visible_diagnostics:
			var severity: String = str(diagnostic.get("severity", "info"))
			var severity_color: String = _status_color_hex(severity)
			var field: String = str(diagnostic.get("field", ""))
			var suffix: String = "" if field == "" else " [i](%s)[/i]" % field
			diagnostics_lines.append("[color=%s][%s][/color]%s %s" % [
				severity_color,
				severity.to_upper(),
				suffix,
				str(diagnostic.get("message", "")).xml_escape(),
			])
		if len(current_session.diagnostics) > MAX_VISIBLE_DIAGNOSTICS:
			diagnostics_lines.append("[color=#d8d8d8]...and %s more issue(s).[/color]" % (len(current_session.diagnostics) - MAX_VISIBLE_DIAGNOSTICS))
	diagnostics_text.text = "\n".join(diagnostics_lines)

func _refresh_overview() -> void:
	library_count_label.text = "Library: %s" % len(library_entries)
	filter_count_label.text = "Visible: %s" % len(filtered_entries)
	if current_session == null or current_session.working_card_data == null:
		selection_count_label.text = "Selection: none"
	else:
		var card_data: CardData = current_session.working_card_data
		selection_count_label.text = "Selection: %s" % card_data.get_card_name()
	var counts: Dictionary = _get_diagnostic_counts()
	if current_session == null:
		diagnostics_count_label.text = "Diagnostics: none"
	elif counts["errors"] == 0 and counts["warnings"] == 0:
		diagnostics_count_label.text = "Diagnostics: clean"
	else:
		diagnostics_count_label.text = "Diagnostics: %s error(s), %s warning(s)" % [counts["errors"], counts["warnings"]]
	_refresh_status_banner()

func _refresh_status_banner() -> void:
	status_banner.text = status_message
	status_banner.modulate = STATUS_COLORS.get(status_severity, STATUS_COLORS["info"])
	save_status_label.text = status_message
	save_status_label.modulate = STATUS_COLORS.get(status_severity, STATUS_COLORS["info"])

func _set_status_message(message: String, severity: String = "info") -> void:
	status_message = message
	status_severity = severity
	_refresh_status_banner()

func _get_diagnostic_counts() -> Dictionary:
	var counts := {"errors": 0, "warnings": 0}
	if current_session == null:
		return counts
	for diagnostic: Dictionary in current_session.diagnostics:
		var severity: String = str(diagnostic.get("severity", ""))
		if severity == "error":
			counts["errors"] += 1
		elif severity == "warning":
			counts["warnings"] += 1
	return counts

func _format_save_policy(save_policy: String) -> String:
	match save_policy:
		CardEditorSession.SAVE_POLICY_MANAGED_CONTENT:
			return "Content save"
		CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE:
			return "Triage save"
		CardEditorSession.SAVE_POLICY_MANUAL:
			return "Manual save"
		_:
			return save_policy

func _status_color_hex(severity: String) -> String:
	var color: Color = STATUS_COLORS.get(severity, STATUS_COLORS["info"])
	return "#" + color.to_html()

func _apply_split_layout() -> void:
	if not visible:
		return
	var total_width: float = body_split.size.x
	if total_width > 960 and not library_panel_collapsed and (not editor_panel_collapsed or not preview_panel_collapsed):
		body_split.split_offset = _get_body_split_offset(int(total_width))
	var middle_width: float = editor_split.size.x
	if not editor_panel_collapsed and middle_width > 480:
		editor_split.split_offset = int(middle_width * 0.42)
	if is_instance_valid(library_sections):
		call_deferred("_render_library_sections")

func _get_body_split_offset(total_width: int) -> int:
	var target_library_width: int = int(total_width * 0.16)
	target_library_width = max(target_library_width, LIBRARY_PANEL_MIN_WIDTH)
	var max_library_width: int = total_width - (PREVIEW_PANEL_MIN_WIDTH if not preview_panel_collapsed else 0) - (EDITOR_PANEL_MIN_WIDTH if not editor_panel_collapsed else 0)
	if max_library_width < LIBRARY_PANEL_MIN_WIDTH:
		max_library_width = LIBRARY_PANEL_MIN_WIDTH
	return min(target_library_width, max_library_width)

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
	var grid := VBoxContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("separation", 8)
	for entry: Dictionary in entries:
		grid.add_child(_build_library_card_tile(entry))
	wrapper.add_child(grid)
	return panel

func _build_library_card_tile(entry: Dictionary) -> Control:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(0, 84)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	var entry_path: String = str(entry.get("resource_path", ""))
	var is_selected: bool = current_session != null and (entry_path == current_session.original_resource_path or entry_path == current_session.get_active_save_path())
	_apply_library_tile_style(tile, is_selected, false)
	var tile_padding := MarginContainer.new()
	tile_padding.add_theme_constant_override("margin_left", 8)
	tile_padding.add_theme_constant_override("margin_top", 6)
	tile_padding.add_theme_constant_override("margin_right", 8)
	tile_padding.add_theme_constant_override("margin_bottom", 6)
	var tile_row := HBoxContainer.new()
	tile_row.add_theme_constant_override("separation", 10)
	tile_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(tile_padding)
	tile_padding.add_child(tile_row)
	var cost_badge := Label.new()
	var is_variable_cost: bool = false
	var loaded_card: Resource = load(entry_path)
	if loaded_card is CardData:
		is_variable_cost = (loaded_card as CardData).card_energy_cost_is_variable
	cost_badge.text = "X" if is_variable_cost else str(_load_library_entry_cost(entry_path))
	cost_badge.custom_minimum_size = Vector2(32, 0)
	cost_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile_row.add_child(cost_badge)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_theme_constant_override("separation", 2)
	tile_row.add_child(text_column)
	var title_label := Label.new()
	title_label.text = str(entry.get("card_name", entry.get("object_id", "")))
	title_label.tooltip_text = "%s\n%s" % [entry.get("object_id", ""), entry_path]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.clip_text = true
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_font_size_override("font_size", 15)
	text_column.add_child(title_label)
	var meta_label := Label.new()
	meta_label.text = _format_library_meta(entry)
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.modulate = Color(0.82, 0.82, 0.86, 0.95)
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(meta_label)
	var submeta_label := Label.new()
	submeta_label.text = "%s | %s" % [entry.get("object_id", ""), "Triage" if str(entry.get("source_bucket", "")) == "triage" else "Content"]
	submeta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	submeta_label.modulate = Color(0.74, 0.78, 0.86, 0.95)
	submeta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(submeta_label)
	var art_mount := CenterContainer.new()
	art_mount.custom_minimum_size = Vector2(72, 72)
	art_mount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_texture := _load_library_entry_texture(entry_path)
	if art_texture != null:
		var art_preview := TextureRect.new()
		art_preview.texture = art_texture
		art_preview.custom_minimum_size = Vector2(64, 64)
		art_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art_mount.add_child(art_preview)
	tile_row.add_child(art_mount)
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
	click_overlay.mouse_entered.connect(func():
		_apply_library_tile_style(tile, is_selected, true)
	)
	click_overlay.mouse_exited.connect(func():
		_apply_library_tile_style(tile, is_selected, false)
	)
	tile.add_child(click_overlay)
	return tile

func _load_library_entry_cost(entry_path: String) -> int:
	var card_resource: Resource = load(entry_path)
	if card_resource is CardData:
		return (card_resource as CardData).card_energy_cost
	return 0

func _load_library_entry_texture(entry_path: String) -> Texture2D:
	var card_resource: Resource = load(entry_path)
	if card_resource is CardData:
		var texture_path: String = str((card_resource as CardData).card_texture_path)
		if texture_path != "":
			return FileLoader.load_texture(texture_path)
	return null

func _get_library_grid_columns() -> int:
	if library_scroll.size.x >= 540:
		return 2
	return 1

func _get_library_group_name(entry: Dictionary) -> String:
	var owner_bucket: String = str(entry.get("owner_bucket", "Unsorted"))
	var source_bucket: String = str(entry.get("source_bucket", ""))
	if source_bucket == "triage":
		return "Triage"
	if owner_bucket == "" or owner_bucket == "unknown":
		return "Misc"
	return owner_bucket.replace("/", " / ")

func _open_library_entry(entry: Dictionary) -> void:
	current_session = service.load_session(str(entry.get("resource_path", "")))
	if current_session != null and current_session.working_card_data != null:
		_set_status_message("Loaded %s from the library." % current_session.working_card_data.get_card_name(), "info")
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
	wrapper.add_theme_constant_override("separation", 6)
	var toggle_button := Button.new()
	toggle_button.text = "Hide advanced fields" if bool(expanded_entry_parameters.get(entry_key, false)) else "Show advanced fields"
	toggle_button.button_up.connect(func():
		expanded_entry_parameters[entry_key] = not bool(expanded_entry_parameters.get(entry_key, false))
		_request_behavior_render()
	)
	wrapper.add_child(toggle_button)
	if not bool(expanded_entry_parameters.get(entry_key, false)):
		return wrapper
	var parameter_grid := GridContainer.new()
	parameter_grid.columns = 2
	parameter_grid.add_theme_constant_override("h_separation", 8)
	parameter_grid.add_theme_constant_override("v_separation", 8)
	for parameter_data: Dictionary in parameters:
		if _should_show_parameter(parameter_data, values):
			continue
		parameter_grid.add_child(_build_entry_parameter_editor(property_name, index, token, parameter_data, values))
	wrapper.add_child(parameter_grid)
	return wrapper

func _entry_visibility_key(property_name: String, index: int, token: String) -> String:
	return "%s:%s:%s" % [property_name, index, token]

func _setup_checkbox(checkbox: CheckBox) -> void:
	checkbox.set_meta("base_text", checkbox.text)
	checkbox.toggled.connect(_on_styled_checkbox_toggled.bind(checkbox))

func _style_checkbox(checkbox: CheckBox, pressed: bool) -> void:
	checkbox.custom_minimum_size = Vector2(0, 28)
	var base_text: String = str(checkbox.get_meta("base_text", ""))
	var state_text: String = "Enabled" if pressed else "Disabled"
	checkbox.text = state_text if base_text == "" else "%s (%s)" % [base_text, state_text]
	checkbox.modulate = Color(0.96, 0.96, 0.98, 1.0) if pressed else Color(0.84, 0.86, 0.9, 1.0)

func _on_styled_checkbox_toggled(pressed: bool, checkbox: CheckBox) -> void:
	_style_checkbox(checkbox, pressed)

func _refresh_after_behavior_change() -> void:
	_render_preview()
	_render_session_summary()
	_refresh_overview()

func _refresh_after_behavior_structure_change() -> void:
	_request_behavior_render()
	_refresh_after_behavior_change()

func _request_behavior_render() -> void:
	if behavior_render_queued:
		return
	behavior_render_queued = true
	call_deferred("_render_behavior")

func _build_string_array_parameter_editor(property_name: String, index: int, parameter_name: String, current_value: Variant, placeholder_text: String) -> Control:
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = placeholder_text
	line_edit.text = ",".join(_variant_to_string_array(current_value))
	line_edit.text_submitted.connect(func(_text: String):
		service.update_entry_values(current_session, property_name, index, {parameter_name: _parse_csv_strings(line_edit.text)})
		_refresh_after_behavior_change()
	)
	line_edit.focus_exited.connect(func():
		service.update_entry_values(current_session, property_name, index, {parameter_name: _parse_csv_strings(line_edit.text)})
		_refresh_after_behavior_change()
	)
	return line_edit

func _build_enum_array_parameter_editor(property_name: String, index: int, parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	var current_values: Array = []
	current_values.assign(current_value if current_value is Array else [])
	var options: Array = parameter_data.get("options", [])
	for option_data: Variant in options:
		var option_label: String = ""
		var option_value: Variant = option_data
		if option_data is Dictionary:
			option_label = str(option_data.get("label", option_data.get("value", "")))
			option_value = option_data.get("value", null)
		else:
			option_label = str(option_data)
		var checkbox := CheckBox.new()
		checkbox.text = option_label
		checkbox.button_pressed = current_values.has(option_value)
		_setup_checkbox(checkbox)
		_style_checkbox(checkbox, checkbox.button_pressed)
		checkbox.toggled.connect(func(pressed: bool):
			var next_values: Array = []
			next_values.assign(current_values)
			if pressed and not next_values.has(option_value):
				next_values.append(option_value)
			elif not pressed:
				next_values.erase(option_value)
			service.update_entry_values(current_session, property_name, index, {parameter_name: next_values})
			_refresh_after_behavior_change()
		)
		wrapper.add_child(checkbox)
	return wrapper

func _build_nested_validator_array_editor(property_name: String, index: int, parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var entries: Array = []
	entries.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var validator_dropdown := OptionButton.new()
	validator_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(validator_dropdown, _metadata_options(service.get_validator_options("card_pick")))
	add_row.add_child(validator_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Validator"
	add_button.button_up.connect(func():
		var selected_token: Variant = _get_option_button_value(validator_dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries.append(service.create_validator_entry(str(selected_token)))
		service.update_entry_values(current_session, property_name, index, {parameter_name: next_entries})
		_refresh_after_behavior_structure_change()
	)
	add_row.add_child(add_button)
	wrapper.add_child(add_row)
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No nested validators."
		wrapper.add_child(empty_label)
		return wrapper
	for nested_index: int in range(len(entries)):
		var nested_entry: Dictionary = entries[nested_index]
		if nested_entry.is_empty():
			continue
		var nested_token: String = str(nested_entry.keys()[0])
		var nested_values: Dictionary = nested_entry[nested_token]
		var nested_panel := PanelContainer.new()
		var nested_padding := MarginContainer.new()
		nested_padding.add_theme_constant_override("margin_left", 8)
		nested_padding.add_theme_constant_override("margin_top", 8)
		nested_padding.add_theme_constant_override("margin_right", 8)
		nested_padding.add_theme_constant_override("margin_bottom", 8)
		var nested_vbox := VBoxContainer.new()
		nested_vbox.add_theme_constant_override("separation", 6)
		nested_panel.add_child(nested_padding)
		nested_padding.add_child(nested_vbox)
		var header := HBoxContainer.new()
		var dropdown := OptionButton.new()
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_populate_option_button(dropdown, _metadata_options(service.get_validator_options("card_pick")), nested_token)
		dropdown.item_selected.connect(func(_selected: int):
			var selected_token: Variant = _get_option_button_value(dropdown)
			if selected_token == null:
				return
			var replacement: Dictionary = service.create_validator_entry(str(selected_token))
			if replacement.is_empty():
				return
			var next_entries: Array = entries.duplicate(true)
			next_entries[nested_index] = replacement
			service.update_entry_values(current_session, property_name, index, {parameter_name: next_entries})
			_refresh_after_behavior_structure_change()
		)
		header.add_child(dropdown)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func():
			var next_entries: Array = entries.duplicate(true)
			next_entries.remove_at(nested_index)
			service.update_entry_values(current_session, property_name, index, {parameter_name: next_entries})
			_refresh_after_behavior_structure_change()
		)
		header.add_child(remove_button)
		nested_vbox.add_child(header)
		var metadata: Dictionary = service.get_validator_metadata(nested_token)
		var parameters: Array[Dictionary] = []
		parameters.assign(metadata.get("parameters", []))
		for parameter_data: Dictionary in parameters:
			var nested_parameter_name: String = str(parameter_data.get("name", ""))
			if nested_parameter_name == "":
				continue
			nested_vbox.add_child(_build_nested_validator_parameter_row(property_name, index, parameter_name, nested_index, nested_token, nested_values, parameter_data))
		wrapper.add_child(nested_panel)
	return wrapper

func _build_nested_action_array_editor(property_name: String, index: int, parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var entries: Array = []
	entries.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var action_dropdown := OptionButton.new()
	action_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(action_dropdown, _metadata_options(service.get_action_options("action_children")))
	add_row.add_child(action_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Child Action"
	add_button.button_up.connect(func():
		var selected_token: Variant = _get_option_button_value(action_dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries.append(service.create_action_entry(str(selected_token)))
		service.update_entry_values(current_session, property_name, index, {parameter_name: next_entries})
		_refresh_after_behavior_structure_change()
	)
	add_row.add_child(add_button)
	wrapper.add_child(add_row)
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No child actions."
		wrapper.add_child(empty_label)
		return wrapper
	for nested_index: int in range(len(entries)):
		var nested_entry: Dictionary = entries[nested_index]
		if nested_entry.is_empty():
			continue
		wrapper.add_child(_build_nested_action_entry_editor(property_name, index, parameter_name, nested_index, nested_entry, entries))
	return wrapper

func _build_nested_action_entry_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_entry: Dictionary, entries: Array) -> Control:
	var nested_token: String = str(nested_entry.keys()[0])
	var nested_values: Dictionary = nested_entry[nested_token]
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 8)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_right", 8)
	padding.add_theme_constant_override("margin_bottom", 8)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(padding)
	padding.add_child(vbox)
	var header := HBoxContainer.new()
	var dropdown := OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(dropdown, _metadata_options(service.get_action_options("action_children")), nested_token)
	dropdown.item_selected.connect(func(_selected: int):
		var selected_token: Variant = _get_option_button_value(dropdown)
		if selected_token == null:
			return
		var replacement: Dictionary = service.create_action_entry(str(selected_token))
		if replacement.is_empty():
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries[nested_index] = replacement
		service.update_entry_values(current_session, property_name, index, {parameter_name: next_entries})
		_refresh_after_behavior_structure_change()
	)
	header.add_child(dropdown)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		var next_entries: Array = entries.duplicate(true)
		next_entries.remove_at(nested_index)
		service.update_entry_values(current_session, property_name, index, {parameter_name: next_entries})
		_refresh_after_behavior_structure_change()
	)
	header.add_child(remove_button)
	vbox.add_child(header)
	var metadata: Dictionary = service.get_action_metadata(nested_token)
	var description_label := Label.new()
	description_label.text = str(metadata.get("description", ""))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.modulate = Color(0.82, 0.82, 0.86, 0.95)
	if description_label.text != "":
		vbox.add_child(description_label)
	for child_parameter: Dictionary in metadata.get("parameters", []):
		var child_parameter_name: String = str(child_parameter.get("name", ""))
		if child_parameter_name == "":
			continue
		vbox.add_child(_build_nested_action_parameter_row(property_name, index, parameter_name, nested_index, nested_token, nested_values, child_parameter))
	return panel

func _build_nested_action_parameter_row(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_values: Dictionary, parameter_data: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var nested_parameter_name: String = str(parameter_data.get("name", ""))
	var parameter_label := Label.new()
	parameter_label.text = str(parameter_data.get("label", nested_parameter_name))
	parameter_label.tooltip_text = str(parameter_data.get("description", ""))
	row.add_child(parameter_label)
	var value_type: String = str(parameter_data.get("value_type", "variant"))
	var current_value: Variant = nested_values.get(nested_parameter_name, parameter_data.get("default_value", null))
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			_setup_checkbox(checkbox)
			_style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, pressed)
			)
			row.add_child(checkbox)
		"enum":
			var dropdown := OptionButton.new()
			var options: Array = parameter_data.get("options", [])
			for option_data: Variant in options:
				if option_data is Dictionary:
					dropdown.add_item(str(option_data.get("label", option_data.get("value", ""))))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data.get("value", null))
				else:
					dropdown.add_item(str(option_data))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data)
			for option_index: int in range(dropdown.get_item_count()):
				if dropdown.get_item_metadata(option_index) == current_value:
					dropdown.select(option_index)
					break
			dropdown.item_selected.connect(func(option_index: int):
				_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, dropdown.get_item_metadata(option_index))
			)
			row.add_child(dropdown)
		"enum_array":
			row.add_child(_build_nested_action_enum_array_editor(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, parameter_data, current_value))
		"validator_array":
			row.add_child(_build_nested_action_validator_array_editor(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value))
		"array":
			if _is_action_array_parameter(nested_parameter_name, current_value):
				row.add_child(_build_deep_nested_action_array_editor(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value))
			else:
				var text_edit := TextEdit.new()
				text_edit.custom_minimum_size = Vector2(0, 72)
				text_edit.text = JSON.stringify(current_value, "\t")
				text_edit.focus_exited.connect(func():
					var parsed_value: Variant = JSON.parse_string(text_edit.text)
					if parsed_value != null:
						_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, parsed_value)
				)
				row.add_child(text_edit)
		"card_array":
			row.add_child(_build_nested_action_string_array_editor(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value, "card_1,card_2"))
		"string_array":
			row.add_child(_build_nested_action_string_array_editor(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value, "value_1,value_2"))
		"int", "float":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1 if value_type == "int" else 0.1
			spin.value = float(current_value if current_value != null else 0)
			spin.value_changed.connect(func(value: float):
				_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, int(value) if value_type == "int" else value)
			)
			row.add_child(spin)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, _coerce_string_parameter(new_text, value_type))
			)
			line_edit.focus_exited.connect(func():
				_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, _coerce_string_parameter(line_edit.text, value_type))
			)
			row.add_child(line_edit)
	return row

func _build_nested_action_enum_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	var current_values: Array = []
	current_values.assign(current_value if current_value is Array else [])
	for option_data: Variant in parameter_data.get("options", []):
		var option_label: String = str(option_data)
		var option_value: Variant = option_data
		if option_data is Dictionary:
			option_label = str(option_data.get("label", option_data.get("value", "")))
			option_value = option_data.get("value", null)
		var checkbox := CheckBox.new()
		checkbox.text = option_label
		checkbox.button_pressed = current_values.has(option_value)
		_setup_checkbox(checkbox)
		_style_checkbox(checkbox, checkbox.button_pressed)
		checkbox.toggled.connect(func(pressed: bool):
			var next_values: Array = current_values.duplicate(true)
			if pressed and not next_values.has(option_value):
				next_values.append(option_value)
			elif not pressed:
				next_values.erase(option_value)
			_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_values)
		)
		wrapper.add_child(checkbox)
	return wrapper

func _build_nested_action_string_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant, placeholder_text: String) -> Control:
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = placeholder_text
	line_edit.text = ",".join(_variant_to_string_array(current_value))
	line_edit.text_submitted.connect(func(_text: String):
		_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, _parse_csv_strings(line_edit.text))
	)
	line_edit.focus_exited.connect(func():
		_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, _parse_csv_strings(line_edit.text))
	)
	return line_edit

func _build_nested_action_validator_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var entries: Array = []
	entries.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	var validator_dropdown := OptionButton.new()
	validator_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(validator_dropdown, _metadata_options(service.get_validator_options("card_pick")))
	add_row.add_child(validator_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Validator"
	add_button.button_up.connect(func():
		var selected_token: Variant = _get_option_button_value(validator_dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries.append(service.create_validator_entry(str(selected_token)))
		_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
	)
	add_row.add_child(add_button)
	wrapper.add_child(add_row)
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No nested validators."
		wrapper.add_child(empty_label)
		return wrapper
	for validator_index: int in range(len(entries)):
		var validator_entry: Dictionary = entries[validator_index]
		if validator_entry.is_empty():
			continue
		var validator_token: String = str(validator_entry.keys()[0])
		var validator_values: Dictionary = validator_entry[validator_token]
		var panel := PanelContainer.new()
		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_left", 8)
		pad.add_theme_constant_override("margin_top", 8)
		pad.add_theme_constant_override("margin_right", 8)
		pad.add_theme_constant_override("margin_bottom", 8)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		panel.add_child(pad)
		pad.add_child(vbox)
		var header := HBoxContainer.new()
		var dropdown := OptionButton.new()
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_populate_option_button(dropdown, _metadata_options(service.get_validator_options("card_pick")), validator_token)
		dropdown.item_selected.connect(func(_selected: int):
			var selected_token: Variant = _get_option_button_value(dropdown)
			if selected_token == null:
				return
			var next_entries: Array = entries.duplicate(true)
			next_entries[validator_index] = service.create_validator_entry(str(selected_token))
			_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
		)
		header.add_child(dropdown)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func():
			var next_entries: Array = entries.duplicate(true)
			next_entries.remove_at(validator_index)
			_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
		)
		header.add_child(remove_button)
		vbox.add_child(header)
		for child_parameter: Dictionary in service.get_validator_metadata(validator_token).get("parameters", []):
			var child_parameter_name: String = str(child_parameter.get("name", ""))
			if child_parameter_name == "":
				continue
			vbox.add_child(_build_nested_action_validator_parameter_row(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, validator_values, child_parameter))
		wrapper.add_child(panel)
	return wrapper

func _build_nested_action_validator_parameter_row(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, validator_index: int, validator_token: String, validator_values: Dictionary, parameter_data: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var child_parameter_name: String = str(parameter_data.get("name", ""))
	var label := Label.new()
	label.text = str(parameter_data.get("label", child_parameter_name))
	row.add_child(label)
	var value_type: String = str(parameter_data.get("value_type", "variant"))
	var current_value: Variant = validator_values.get(child_parameter_name, parameter_data.get("default_value", null))
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			_setup_checkbox(checkbox)
			_style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				_update_deep_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, child_parameter_name, pressed)
			)
			row.add_child(checkbox)
		"enum":
			var dropdown := OptionButton.new()
			for option_data: Variant in parameter_data.get("options", []):
				if option_data is Dictionary:
					dropdown.add_item(str(option_data.get("label", option_data.get("value", ""))))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data.get("value", null))
				else:
					dropdown.add_item(str(option_data))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data)
			for option_index: int in range(dropdown.get_item_count()):
				if dropdown.get_item_metadata(option_index) == current_value:
					dropdown.select(option_index)
					break
			dropdown.item_selected.connect(func(option_index: int):
				_update_deep_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, child_parameter_name, dropdown.get_item_metadata(option_index))
			)
			row.add_child(dropdown)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				_update_deep_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, child_parameter_name, _coerce_string_parameter(new_text, value_type))
			)
			line_edit.focus_exited.connect(func():
				_update_deep_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, child_parameter_name, _coerce_string_parameter(line_edit.text, value_type))
			)
			row.add_child(line_edit)
	return row

func _build_deep_nested_action_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var entries: Array = []
	entries.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	var action_dropdown := OptionButton.new()
	action_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(action_dropdown, _metadata_options(service.get_action_options("action_children")))
	add_row.add_child(action_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Child Action"
	add_button.button_up.connect(func():
		var selected_token: Variant = _get_option_button_value(action_dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries.append(service.create_action_entry(str(selected_token)))
		_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
	)
	add_row.add_child(add_button)
	wrapper.add_child(add_row)
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No child actions."
		wrapper.add_child(empty_label)
		return wrapper
	for deep_index: int in range(len(entries)):
		var deep_entry: Dictionary = entries[deep_index]
		if deep_entry.is_empty():
			continue
		wrapper.add_child(_build_deep_nested_action_entry_editor(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_entry, entries))
	return wrapper

func _build_deep_nested_action_entry_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, deep_index: int, deep_entry: Dictionary, entries: Array) -> Control:
	var deep_token: String = str(deep_entry.keys()[0])
	var deep_values: Dictionary = deep_entry[deep_token]
	var panel := PanelContainer.new()
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(pad)
	pad.add_child(vbox)
	var header := HBoxContainer.new()
	var dropdown := OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(dropdown, _metadata_options(service.get_action_options("action_children")), deep_token)
	dropdown.item_selected.connect(func(_selected: int):
		var selected_token: Variant = _get_option_button_value(dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries[deep_index] = service.create_action_entry(str(selected_token))
		_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
	)
	header.add_child(dropdown)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		var next_entries: Array = entries.duplicate(true)
		next_entries.remove_at(deep_index)
		_update_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
	)
	header.add_child(remove_button)
	vbox.add_child(header)
	for child_parameter: Dictionary in service.get_action_metadata(deep_token).get("parameters", []):
		var child_parameter_name: String = str(child_parameter.get("name", ""))
		if child_parameter_name == "":
			continue
		vbox.add_child(_build_deep_nested_action_parameter_row(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, deep_values, child_parameter))
	return panel

func _build_deep_nested_action_parameter_row(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, deep_index: int, deep_token: String, deep_values: Dictionary, parameter_data: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var child_parameter_name: String = str(parameter_data.get("name", ""))
	var label := Label.new()
	label.text = str(parameter_data.get("label", child_parameter_name))
	row.add_child(label)
	var value_type: String = str(parameter_data.get("value_type", "variant"))
	var current_value: Variant = deep_values.get(child_parameter_name, parameter_data.get("default_value", null))
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			_setup_checkbox(checkbox)
			_style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				_update_deep_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, child_parameter_name, pressed)
			)
			row.add_child(checkbox)
		"enum":
			var dropdown := OptionButton.new()
			for option_data: Variant in parameter_data.get("options", []):
				if option_data is Dictionary:
					dropdown.add_item(str(option_data.get("label", option_data.get("value", ""))))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data.get("value", null))
				else:
					dropdown.add_item(str(option_data))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data)
			for option_index: int in range(dropdown.get_item_count()):
				if dropdown.get_item_metadata(option_index) == current_value:
					dropdown.select(option_index)
					break
			dropdown.item_selected.connect(func(option_index: int):
				_update_deep_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, child_parameter_name, dropdown.get_item_metadata(option_index))
			)
			row.add_child(dropdown)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				_update_deep_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, child_parameter_name, _coerce_string_parameter(new_text, value_type))
			)
			line_edit.focus_exited.connect(func():
				_update_deep_nested_action_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, child_parameter_name, _coerce_string_parameter(line_edit.text, value_type))
			)
			row.add_child(line_edit)
	return row

func _build_nested_validator_parameter_row(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_values: Dictionary, parameter_data: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var parameter_label := Label.new()
	var nested_parameter_name: String = str(parameter_data.get("name", ""))
	parameter_label.text = str(parameter_data.get("label", nested_parameter_name))
	parameter_label.tooltip_text = str(parameter_data.get("description", ""))
	row.add_child(parameter_label)
	var value_type: String = str(parameter_data.get("value_type", "variant"))
	var current_value: Variant = nested_values.get(nested_parameter_name, parameter_data.get("default_value", null))
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			_setup_checkbox(checkbox)
			_style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				_update_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, pressed)
			)
			row.add_child(checkbox)
		"enum":
			var dropdown := OptionButton.new()
			var options: Array = parameter_data.get("options", [])
			for option_data: Variant in options:
				if option_data is Dictionary:
					dropdown.add_item(str(option_data.get("label", option_data.get("value", ""))))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data.get("value", null))
				else:
					dropdown.add_item(str(option_data))
					dropdown.set_item_metadata(dropdown.get_item_count() - 1, option_data)
			for option_index: int in range(dropdown.get_item_count()):
				if dropdown.get_item_metadata(option_index) == current_value:
					dropdown.select(option_index)
					break
			dropdown.item_selected.connect(func(option_index: int):
				_update_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, dropdown.get_item_metadata(option_index))
			)
			row.add_child(dropdown)
		"enum_array":
			row.add_child(_build_nested_validator_enum_array_editor(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, parameter_data, current_value))
		"int", "float":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1 if value_type == "int" else 0.1
			spin.value = float(current_value if current_value != null else 0)
			spin.value_changed.connect(func(value: float):
				_update_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, int(value) if value_type == "int" else value)
			)
			row.add_child(spin)
		"string_array":
			row.add_child(_build_nested_validator_string_array_editor(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value))
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				_update_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, _coerce_string_parameter(new_text, value_type))
			)
			line_edit.focus_exited.connect(func():
				_update_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, _coerce_string_parameter(line_edit.text, value_type))
			)
			row.add_child(line_edit)
	return row

func _build_nested_validator_enum_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	var current_values: Array = []
	current_values.assign(current_value if current_value is Array else [])
	for option_data: Variant in parameter_data.get("options", []):
		var option_label: String = str(option_data)
		var option_value: Variant = option_data
		if option_data is Dictionary:
			option_label = str(option_data.get("label", option_data.get("value", "")))
			option_value = option_data.get("value", null)
		var checkbox := CheckBox.new()
		checkbox.text = option_label
		checkbox.button_pressed = current_values.has(option_value)
		_setup_checkbox(checkbox)
		_style_checkbox(checkbox, checkbox.button_pressed)
		checkbox.toggled.connect(func(pressed: bool):
			var next_values: Array = current_values.duplicate(true)
			if pressed and not next_values.has(option_value):
				next_values.append(option_value)
			elif not pressed:
				next_values.erase(option_value)
			_update_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_values)
		)
		wrapper.add_child(checkbox)
	return wrapper

func _build_nested_validator_string_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant) -> Control:
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = "value_1,value_2"
	line_edit.text = ",".join(_variant_to_string_array(current_value))
	line_edit.text_submitted.connect(func(_text: String):
		_update_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, _parse_csv_strings(line_edit.text))
	)
	line_edit.focus_exited.connect(func():
		_update_nested_validator_value(property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, _parse_csv_strings(line_edit.text))
	)
	return line_edit

func _update_nested_validator_value(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, next_value: Variant) -> void:
	var entries: Array = []
	var root_entry: Dictionary = current_session.working_card_data.get(property_name)[index]
	entries.assign(root_entry.get(nested_token, {}).get(parameter_name, []))
	if nested_index < 0 or nested_index >= len(entries):
		return
	var target_entry: Dictionary = entries[nested_index]
	if target_entry.is_empty():
		return
	var target_token: String = str(target_entry.keys()[0])
	var target_values: Dictionary = target_entry[target_token]
	target_values[nested_parameter_name] = next_value
	target_entry[target_token] = target_values
	entries[nested_index] = target_entry
	service.update_entry_values(current_session, property_name, index, {parameter_name: entries})
	_refresh_after_behavior_change()

func _update_nested_action_value(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, next_value: Variant, rerender_behavior: bool = false) -> void:
	var entries: Array = []
	var root_entry: Dictionary = current_session.working_card_data.get(property_name)[index]
	entries.assign(root_entry.get(nested_token, {}).get(parameter_name, []))
	if nested_index < 0 or nested_index >= len(entries):
		return
	var target_entry: Dictionary = entries[nested_index]
	if target_entry.is_empty():
		return
	var target_token: String = str(target_entry.keys()[0])
	var target_values: Dictionary = target_entry[target_token]
	target_values[nested_parameter_name] = next_value
	target_entry[target_token] = target_values
	entries[nested_index] = target_entry
	service.update_entry_values(current_session, property_name, index, {parameter_name: entries})
	if rerender_behavior:
		_refresh_after_behavior_structure_change()
	else:
		_refresh_after_behavior_change()

func _update_deep_nested_validator_value(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, validator_index: int, validator_token: String, child_parameter_name: String, next_value: Variant) -> void:
	var nested_actions: Array = []
	var root_entry: Dictionary = current_session.working_card_data.get(property_name)[index]
	nested_actions.assign(root_entry.get(nested_token, {}).get(parameter_name, []))
	if nested_index < 0 or nested_index >= len(nested_actions):
		return
	var target_action: Dictionary = nested_actions[nested_index]
	var target_action_token: String = str(target_action.keys()[0])
	var target_action_values: Dictionary = target_action[target_action_token]
	var validators: Array = []
	validators.assign(target_action_values.get(nested_parameter_name, []))
	if validator_index < 0 or validator_index >= len(validators):
		return
	var validator_entry: Dictionary = validators[validator_index]
	var validator_values: Dictionary = validator_entry[validator_token]
	validator_values[child_parameter_name] = next_value
	validator_entry[validator_token] = validator_values
	validators[validator_index] = validator_entry
	target_action_values[nested_parameter_name] = validators
	target_action[target_action_token] = target_action_values
	nested_actions[nested_index] = target_action
	service.update_entry_values(current_session, property_name, index, {parameter_name: nested_actions})
	_refresh_after_behavior_change()

func _update_deep_nested_action_value(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, deep_index: int, deep_token: String, child_parameter_name: String, next_value: Variant) -> void:
	var nested_actions: Array = []
	var root_entry: Dictionary = current_session.working_card_data.get(property_name)[index]
	nested_actions.assign(root_entry.get(nested_token, {}).get(parameter_name, []))
	if nested_index < 0 or nested_index >= len(nested_actions):
		return
	var target_action: Dictionary = nested_actions[nested_index]
	var target_action_token: String = str(target_action.keys()[0])
	var target_action_values: Dictionary = target_action[target_action_token]
	var child_actions: Array = []
	child_actions.assign(target_action_values.get(nested_parameter_name, []))
	if deep_index < 0 or deep_index >= len(child_actions):
		return
	var child_action: Dictionary = child_actions[deep_index]
	var child_values: Dictionary = child_action[deep_token]
	child_values[child_parameter_name] = next_value
	child_action[deep_token] = child_values
	child_actions[deep_index] = child_action
	target_action_values[nested_parameter_name] = child_actions
	target_action[target_action_token] = target_action_values
	nested_actions[nested_index] = target_action
	service.update_entry_values(current_session, property_name, index, {parameter_name: nested_actions})
	_refresh_after_behavior_change()

func _variant_to_string_array(value: Variant) -> Array[String]:
	var values: Array[String] = []
	if value is Array:
		for item: Variant in value:
			values.append(str(item))
	return values

func _is_action_reference_parameter(parameter_name: String) -> bool:
	return parameter_name in ["action_data", "passed_action_data", "failed_action_data", "actions_on_lethal"]

func _is_action_array_parameter(parameter_name: String, current_value: Variant) -> bool:
	if not (current_value is Array):
		return false
	return _is_action_reference_parameter(parameter_name)

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
	_populate_option_button(source_filter, source_options)
	_populate_option_button(type_filter, type_options)
	_populate_option_button(rarity_filter, rarity_options)
	_populate_option_button(kind_filter, kind_options)

func _populate_dynamic_filters() -> void:
	var selected_owner: Variant = _get_option_button_value(owner_filter)
	var selected_color: Variant = _get_option_button_value(color_filter)
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
	_populate_option_button(owner_filter, owner_options, selected_owner)
	_populate_option_button(color_filter, color_options, selected_color)

func _get_card_color_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var seen: Dictionary = {}
	for color_id: String in DEFAULT_CARD_COLOR_IDS:
		var color_in_library: bool = false
		for entry: Dictionary in library_entries:
			if str(entry.get("card_color_id", "")) == color_id:
				color_in_library = true
				break
		if Global.get_color_data(color_id) == null and not color_in_library:
			continue
		options.append({"label": color_id, "value": color_id})
		seen[color_id] = true
	for entry: Dictionary in library_entries:
		var color_id: String = str(entry.get("card_color_id", ""))
		if color_id == "" or seen.has(color_id):
			continue
		options.append({"label": color_id, "value": color_id})
		seen[color_id] = true
	return options

func _get_card_value_key_options(existing_values: Dictionary) -> Array[Dictionary]:
	var suggestions: Array[Dictionary] = []
	var seen: Dictionary = {}
	for placeholder_name: String in _collect_card_value_suggestions():
		if placeholder_name == "" or existing_values.has(placeholder_name) or seen.has(placeholder_name):
			continue
		suggestions.append({"label": placeholder_name, "value": placeholder_name})
		seen[placeholder_name] = true
	return suggestions

func _get_card_value_definition_options(existing_values: Dictionary, definitions: Dictionary[String, Dictionary]) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var sorted_keys: Array[String] = []
	sorted_keys.assign(definitions.keys())
	sorted_keys.sort()
	for key_name: String in sorted_keys:
		if existing_values.has(key_name):
			continue
		var definition: Dictionary = definitions[key_name]
		var label: String = "%s (%s)" % [str(definition.get("label", key_name)), key_name]
		options.append({"label": label, "value": key_name})
	return options

func _collect_card_value_suggestions() -> Array[String]:
	var suggestions: Array[String] = []
	for placeholder_name: String in _collect_description_placeholders():
		if not suggestions.has(placeholder_name):
			suggestions.append(placeholder_name)
	for parameter_name: String in _collect_action_value_suggestions():
		if not suggestions.has(parameter_name):
			suggestions.append(parameter_name)
	return suggestions

func _collect_description_placeholders() -> Array[String]:
	var suggestions: Array[String] = []
	if current_session == null or current_session.working_card_data == null:
		return suggestions
	var regex := RegEx.new()
	if regex.compile("\\[([A-Za-z0-9_]+)\\]") == OK:
		for result: RegExMatch in regex.search_all(current_session.working_card_data.card_description):
			var placeholder_name: String = result.get_string(1)
			if placeholder_name != "" and placeholder_name != "energy_icon" and not suggestions.has(placeholder_name):
				suggestions.append(placeholder_name)
	return suggestions

func _collect_action_value_suggestions() -> Array[String]:
	var suggestions: Array[String] = []
	if current_session == null or current_session.working_card_data == null:
		return suggestions
	for property_name: String in CardEditorSchema.get_action_property_names():
		for entry: Dictionary in current_session.working_card_data.get(property_name):
			if entry.is_empty():
				continue
			var token: String = str(entry.keys()[0])
			var metadata: Dictionary = service.get_action_metadata(token)
			for parameter_data: Dictionary in metadata.get("parameters", []):
				var parameter_name: String = str(parameter_data.get("name", ""))
				if parameter_name == "" or parameter_name == "target_override":
					continue
				if parameter_name.begins_with("card_") or parameter_name.begins_with("picked_") or parameter_name.ends_with("_id") or parameter_name.ends_with("_ids") or parameter_name.contains("action_data") or parameter_name == "validator_data":
					continue
				if not suggestions.has(parameter_name):
					suggestions.append(parameter_name)
	return suggestions

func _property_label(property_name: String, field_definition: Dictionary) -> String:
	if property_name == "card_requires_target":
		return "Needs Clicked Target"
	if property_name == "card_clicked_target_mode":
		return "Clicked Target Mode"
	return str(field_definition.get("label", property_name))

func _property_description(property_name: String, field_definition: Dictionary) -> String:
	if property_name == "card_requires_target":
		return "Turn this on only if the player must click a combatant when playing the card. Leave it off for self-buffs, draw, block, or effects that pick their own targets."
	if property_name == "card_clicked_target_mode":
		return "When clicked targeting is enabled, this decides whether the card may click enemies only, allies only, or any combatant."
	return str(field_definition.get("description", ""))

func _format_clicked_target_mode(target_mode: String) -> String:
	match target_mode:
		CardData.CARD_TARGET_MODE_ALLY_ONLY:
			return "ally"
		CardData.CARD_TARGET_MODE_ANY_COMBATANT:
			return "combatant"
		_:
			return "enemy"

func _populate_group_options() -> void:
	_populate_option_button(action_group_option, _property_group_options(CardEditorSchema.get_action_property_names()))
	_populate_option_button(validator_group_option, _property_group_options(CardEditorSchema.get_validator_property_names()))

func _populate_preset_options() -> void:
	if preset_option == null:
		return
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
	var selected_action: Variant = _get_option_button_value(action_option)
	if property_name != null:
		options = service.get_action_options(service.get_entry_context(str(property_name)))
	_populate_option_button(action_option, _metadata_options(options), selected_action)

func _populate_validator_option_list() -> void:
	var property_name: Variant = _get_option_button_value(validator_group_option)
	var options: Array[Dictionary] = []
	var selected_validator: Variant = _get_option_button_value(validator_option)
	if property_name != null:
		options = service.get_validator_options(service.get_entry_context(str(property_name)))
	_populate_option_button(validator_option, _metadata_options(options), selected_validator)

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
			_setup_checkbox(checkbox)
			_style_checkbox(checkbox, checkbox.button_pressed)
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
	var owner_bucket: String = str(entry.get("owner_bucket", ""))
	if owner_bucket != "" and owner_bucket != "unknown":
		parts.append(owner_bucket.replace("/", " / "))
	var type_label: String = _enum_label_from_value(CardData.CARD_TYPES, entry.get("card_type", null))
	var rarity_label: String = _enum_label_from_value(CardData.CARD_RARITIES, entry.get("card_rarity", null))
	if rarity_label != "":
		parts.append(rarity_label.capitalize())
	if type_label != "":
		parts.append(type_label.capitalize())
	return " | ".join(parts)

func _apply_library_tile_style(tile: PanelContainer, is_selected: bool, is_hovered: bool) -> void:
	if is_selected and is_hovered:
		tile.modulate = Color(1.0, 0.9, 0.66, 1.0)
	elif is_selected:
		tile.modulate = Color(1.0, 0.96, 0.8, 1.0)
	elif is_hovered:
		tile.modulate = Color(0.86, 0.93, 1.0, 1.0)
	else:
		tile.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _format_inline_value(value: Variant) -> String:
	if value is Array:
		return "[%s]" % len(value)
	if value is Dictionary:
		return "{%s}" % len(value)
	if value is bool:
		return "On" if value else "Off"
	return str(value)

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

func _populate_option_button(option_button: OptionButton, options: Array[Dictionary], preferred_value: Variant = null) -> void:
	var current_value: Variant = preferred_value if preferred_value != null else _get_option_button_value(option_button)
	option_button.clear()
	for option_data: Dictionary in options:
		option_button.add_item(str(option_data.get("label", option_data.get("value", ""))))
		option_button.set_item_metadata(option_button.get_item_count() - 1, option_data.get("value", null))
	if option_button.get_item_count() == 0:
		return
	for index: int in range(option_button.get_item_count()):
		if option_button.get_item_metadata(index) == current_value:
			option_button.select(index)
			return
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
	_set_status_message("Started a fresh triage card. Pick a preset or shape the card field by field.", "info")
	_refresh_editor_panels()

func _on_duplicate_button_up() -> void:
	if current_session == null:
		return
	current_session = service.duplicate_session(current_session)
	if current_session != null and current_session.working_card_data != null:
		_set_status_message("Duplicated %s into a new triage draft." % current_session.working_card_data.get_card_name(), "success")
	_refresh_editor_panels()

func _on_apply_preset_button_up() -> void:
	if current_session == null or preset_option == null:
		return
	var preset_id: Variant = _get_option_button_value(preset_option)
	if preset_id == null:
		return
	service.apply_preset_to_session(current_session, str(preset_id), true)
	_set_status_message("Applied the %s preset. Review identity and values before saving." % preset_option.get_item_text(preset_option.get_selected()), "success")
	_refresh_editor_panels()

func _on_save_triage_button_up() -> void:
	if current_session == null:
		return
	var result: Dictionary = service.save_session_to_triage(current_session)
	_handle_save_result(result, "Saved to triage")
	_refresh_library()
	_refresh_editor_panels()

func _on_promote_button_up() -> void:
	if current_session == null:
		return
	var result: Dictionary = service.promote_session_to_content(current_session)
	_handle_save_result(result, "Promoted to content")
	_refresh_library()
	_refresh_editor_panels()

func _on_library_search_changed(_new_text: String) -> void:
	_apply_library_filters()

func _on_filter_changed(_index: int) -> void:
	_apply_library_filters()

func _on_clear_filters_button_up() -> void:
	library_search.text = ""
	for option_button: OptionButton in [source_filter, owner_filter, color_filter, type_filter, rarity_filter, kind_filter]:
		if option_button.get_item_count() > 0:
			option_button.select(0)
	_apply_library_filters()
	_set_status_message("Cleared library filters. Showing the full card library again.", "info")

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
	_set_status_message("Added a new %s entry." % PROPERTY_GROUP_LABELS.get(str(property_name), str(property_name)), "success")
	_refresh_editor_panels()

func _on_add_validator_button_up() -> void:
	if current_session == null:
		return
	var property_name: Variant = _get_option_button_value(validator_group_option)
	var token: Variant = _get_option_button_value(validator_option)
	if property_name == null or token == null:
		return
	service.add_entry(current_session, str(property_name), str(token))
	_set_status_message("Added a new %s entry." % PROPERTY_GROUP_LABELS.get(str(property_name), str(property_name)), "success")
	_refresh_editor_panels()

func _handle_save_result(result: Dictionary, success_prefix: String) -> void:
	if bool(result.get("success", false)):
		var saved_path: String = str(result.get("path", ""))
		_set_status_message("%s at %s" % [success_prefix, saved_path], "success")
		return
	var diagnostics: Array = result.get("diagnostics", [])
	var error_count: int = 0
	for diagnostic: Dictionary in diagnostics:
		if str(diagnostic.get("severity", "")) == "error":
			error_count += 1
	_set_status_message("Save blocked by %s error(s). Review the diagnostics list before trying again." % error_count, "error")
