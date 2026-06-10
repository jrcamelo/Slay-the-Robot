@tool
extends Control
class_name CardEditorScreen

const CardEditorScreenConfig = preload("res://scripts/tools/card_editor/CardEditorScreenConfig.gd")
const CardEditorScreenBehavior = preload("res://scripts/tools/card_editor/CardEditorScreenBehavior.gd")
const CardEditorScreenBehaviorNested = preload("res://scripts/tools/card_editor/CardEditorScreenBehaviorNested.gd")
const CardEditorScreenInspector = preload("res://scripts/tools/card_editor/CardEditorScreenInspector.gd")
const CardEditorScreenLibrary = preload("res://scripts/tools/card_editor/CardEditorScreenLibrary.gd")
const CardEditorScreenPreview = preload("res://scripts/tools/card_editor/CardEditorScreenPreview.gd")

const PROPERTY_GROUP_LABELS := CardEditorScreenConfig.PROPERTY_GROUP_LABELS
const COLLAPSED_ARROW := CardEditorScreenConfig.COLLAPSED_ARROW
const EXPANDED_ARROW := CardEditorScreenConfig.EXPANDED_ARROW
const NOISY_PARAMETER_DEFAULTS := CardEditorScreenConfig.NOISY_PARAMETER_DEFAULTS
const STATUS_COLORS := CardEditorScreenConfig.STATUS_COLORS
const ESSENTIAL_FIELD_GROUPS := CardEditorScreenConfig.ESSENTIAL_FIELD_GROUPS
const ADVANCED_FIELD_GROUPS := CardEditorScreenConfig.ADVANCED_FIELD_GROUPS
const PRIMARY_BEHAVIOR_GROUPS := CardEditorScreenConfig.PRIMARY_BEHAVIOR_GROUPS
const SECONDARY_BEHAVIOR_GROUPS := CardEditorScreenConfig.SECONDARY_BEHAVIOR_GROUPS
const BEHAVIOR_GROUP_DESCRIPTIONS := CardEditorScreenConfig.BEHAVIOR_GROUP_DESCRIPTIONS
const MAX_VISIBLE_DIAGNOSTICS := CardEditorScreenConfig.MAX_VISIBLE_DIAGNOSTICS
const DEFAULT_CARD_COLOR_IDS := CardEditorScreenConfig.DEFAULT_CARD_COLOR_IDS
const COLLAPSED_PANEL_WIDTH := CardEditorScreenConfig.COLLAPSED_PANEL_WIDTH
const LIBRARY_PANEL_MIN_WIDTH := CardEditorScreenConfig.LIBRARY_PANEL_MIN_WIDTH
const INSPECTOR_PANEL_MIN_WIDTH := CardEditorScreenConfig.INSPECTOR_PANEL_MIN_WIDTH
const BEHAVIOR_PANEL_MIN_WIDTH := CardEditorScreenConfig.BEHAVIOR_PANEL_MIN_WIDTH
const PREVIEW_PANEL_MIN_WIDTH := CardEditorScreenConfig.PREVIEW_PANEL_MIN_WIDTH
const RESPONSIVE_COMPACT_BREAKPOINT := CardEditorScreenConfig.RESPONSIVE_COMPACT_BREAKPOINT
const RESPONSIVE_TWO_COLUMN_BREAKPOINT := CardEditorScreenConfig.RESPONSIVE_TWO_COLUMN_BREAKPOINT
const RESPONSIVE_FOUR_COLUMN_BREAKPOINT := CardEditorScreenConfig.RESPONSIVE_FOUR_COLUMN_BREAKPOINT
const RESPONSIVE_PANEL_GAP := CardEditorScreenConfig.RESPONSIVE_PANEL_GAP
const PREVIEW_FALLBACK_CHARACTER_ID := CardEditorScreenConfig.PREVIEW_FALLBACK_CHARACTER_ID
const CARD_EDITOR_FIT_WIDTH := 1347.0

@onready var title_screen: Control = get_parent() as Control
@onready var main_container: MarginContainer = $MainContainer
@onready var screen_title: Label = $MainContainer/Header/ScreenSummary/ScreenTitle
@onready var status_banner: Label = $MainContainer/Header/ScreenSummary/StatusBanner
@onready var header_container: VBoxContainer = $MainContainer/Header
@onready var library_count_label: Label = $MainContainer/Header/ScreenSummary/StatsRow/LibraryCountLabel
@onready var filter_count_label: Label = $MainContainer/Header/ScreenSummary/StatsRow/FilterCountLabel
@onready var selection_count_label: Label = $MainContainer/Header/ScreenSummary/StatsRow/SelectionCountLabel
@onready var diagnostics_count_label: Label = $MainContainer/Header/ScreenSummary/StatsRow/DiagnosticsCountLabel
@onready var body_split: HSplitContainer = $MainContainer/Header/Body
@onready var workspace_split: HSplitContainer = $MainContainer/Header/Body/WorkspaceSplit
@onready var editor_split: HSplitContainer = $MainContainer/Header/Body/WorkspaceSplit/EditorHostPanel/EditorHostPadding/EditorSplit
@onready var library_panel: PanelContainer = $MainContainer/Header/Body/LibraryPanel
@onready var inspector_panel: PanelContainer = $MainContainer/Header/Body/WorkspaceSplit/EditorHostPanel/EditorHostPadding/EditorSplit/InspectorPanel
@onready var behavior_panel: PanelContainer = $MainContainer/Header/Body/WorkspaceSplit/EditorHostPanel/EditorHostPadding/EditorSplit/BehaviorPanel
@onready var preview_panel: PanelContainer = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel
@onready var back_button: Button = $MainContainer/Header/BackButton
@onready var button_row: HBoxContainer = $MainContainer/Header/ButtonRow
@onready var library_search: LineEdit = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/SearchRow/SearchInput
@onready var clear_filters_button: Button = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/SearchRow/ClearFiltersButton
@onready var filter_grid: GridContainer = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid
@onready var source_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/SourceFilter
@onready var owner_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/OwnerFilter
@onready var color_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/ColorFilter
@onready var type_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/TypeFilter
@onready var rarity_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/RarityFilter
@onready var kind_filter: OptionButton = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/KindFilter
@onready var library_scroll: ScrollContainer = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/LibraryScroll
@onready var library_sections: VBoxContainer = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/LibraryScroll/LibrarySections
@onready var library_vbox: VBoxContainer = $MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox
@onready var inspector_vbox: VBoxContainer = $MainContainer/Header/Body/WorkspaceSplit/EditorHostPanel/EditorHostPadding/EditorSplit/InspectorPanel/InspectorPadding/InspectorVBox
@onready var behavior_vbox: VBoxContainer = $MainContainer/Header/Body/WorkspaceSplit/EditorHostPanel/EditorHostPadding/EditorSplit/BehaviorPanel/BehaviorPadding/BehaviorVBox
@onready var inspector_scroll: ScrollContainer = $MainContainer/Header/Body/WorkspaceSplit/EditorHostPanel/EditorHostPadding/EditorSplit/InspectorPanel/InspectorPadding/InspectorVBox/InspectorScroll
@onready var inspector_container: VBoxContainer = $MainContainer/Header/Body/WorkspaceSplit/EditorHostPanel/EditorHostPadding/EditorSplit/InspectorPanel/InspectorPadding/InspectorVBox/InspectorScroll/InspectorContent
@onready var behavior_scroll: ScrollContainer = $MainContainer/Header/Body/WorkspaceSplit/EditorHostPanel/EditorHostPadding/EditorSplit/BehaviorPanel/BehaviorPadding/BehaviorVBox/BehaviorScroll
@onready var behavior_container: VBoxContainer = $MainContainer/Header/Body/WorkspaceSplit/EditorHostPanel/EditorHostPadding/EditorSplit/BehaviorPanel/BehaviorPadding/BehaviorVBox/BehaviorScroll/BehaviorContent
@onready var preview_mount: Control = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/PreviewMount
@onready var preview_vbox: VBoxContainer = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox
@onready var save_triage_button: Button = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/SaveActions/SaveTriageButton
@onready var promote_button: Button = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/SaveActions/PromoteButton
@onready var session_label: Label = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/SessionSummary/SessionLabel
@onready var diagnostics_text: RichTextLabel = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/SessionSummary/DiagnosticsText
@onready var save_status_label: Label = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/SaveStatusLabel
@onready var action_add_panel: VBoxContainer = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ActionAddPanel
@onready var validator_add_panel: VBoxContainer = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ValidatorAddPanel
@onready var action_group_option: OptionButton = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ActionAddPanel/ActionGroupOption
@onready var action_option: OptionButton = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ActionAddPanel/ActionOption
@onready var add_action_button: Button = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ActionAddPanel/AddActionButton
@onready var validator_group_option: OptionButton = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ValidatorAddPanel/ValidatorGroupOption
@onready var validator_option: OptionButton = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ValidatorAddPanel/ValidatorOption
@onready var add_validator_button: Button = $MainContainer/Header/Body/WorkspaceSplit/PreviewPanel/PreviewPadding/PreviewVBox/QuickActions/ValidatorAddPanel/AddValidatorButton

var service := CardEditorService.new()
var current_session: CardEditorSession = null
var library_entries: Array[Dictionary] = []
var filtered_entries: Array[Dictionary] = []
var preview_card: Card = null
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
var target_filter: OptionButton = null
var library_panel_collapsed: bool = false
var inspector_panel_collapsed: bool = false
var behavior_panel_collapsed: bool = false
var preview_panel_collapsed: bool = false
var collapsed_panel_row: HBoxContainer = null
var library_panel_toggle: Button = null
var inspector_panel_toggle: Button = null
var behavior_panel_toggle: Button = null
var preview_panel_toggle: Button = null
var behavior_render_queued: bool = false
var editor_panels_refresh_queued: bool = false
var status_message: String = "Open a card to inspect it, or start a new triage draft."
var status_severity: String = "info"
var initial_split_widths_pending: bool = true
var layout_initialized: bool = false
var last_layout_width: int = 0
var last_layout_band: String = ""

func _ready() -> void:
	_bind_optional_header_nodes()
	visible = not _is_embedded_in_title_screen()
	screen_title.text = "Card Workshop"
	diagnostics_text.bbcode_enabled = true
	diagnostics_text.fit_content = true
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	behavior_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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
	_apply_screen_fit_scale()
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
	target_filter = get_node_or_null("MainContainer/Header/Body/LibraryPanel/LibraryPadding/LibraryVBox/FilterGrid/TargetFilter") as OptionButton

func show_editor() -> void:
	visible = true
	initial_split_widths_pending = true
	_apply_screen_fit_scale()
	call_deferred("_apply_split_layout")
	populate_editor()

func _apply_screen_fit_scale() -> void:
	if main_container == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0:
		return
	var content_width: float = maxf(main_container.size.x, CARD_EDITOR_FIT_WIDTH)
	var fit_scale: float = minf(1.0, viewport_size.x / content_width)
	main_container.scale = Vector2.ONE * fit_scale
	main_container.position = Vector2((viewport_size.x - (main_container.size.x * fit_scale)) * 0.5, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if current_session == null:
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
	CardEditorScreenLibrary.refresh_library(self)

func _apply_library_filters() -> void:
	CardEditorScreenLibrary.apply_library_filters(self)

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
	_update_save_buttons()

func _request_editor_panels_refresh() -> void:
	if editor_panels_refresh_queued:
		return
	editor_panels_refresh_queued = true
	call_deferred("_refresh_editor_panels")

func _render_inspector() -> void:
	CardEditorScreenInspector.render_inspector(self)
	_relax_horizontal_sizing(inspector_container)
	call_deferred("_apply_initial_split_widths")

func _compact_header_layout() -> void:
	screen_title.add_theme_font_size_override("font_size", 24)
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
	if save_triage_button != null:
		save_triage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		save_triage_button.custom_minimum_size = Vector2(0, 42)
	if promote_button != null:
		promote_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		promote_button.custom_minimum_size = Vector2(0, 42)
	_apply_responsive_density()

func _get_responsive_scale() -> float:
	if body_split == null:
		return 1.0
	var width: float = maxf(size.x, body_split.size.x)
	if width <= 0.0:
		return 1.0
	return clampf(width / 2548.0, 0.50, 1.0)

func _get_responsive_panel_min_width(base_width: int) -> int:
	return max(96, int(round(float(base_width) * _get_responsive_scale())))

func _get_responsive_font_size(base_size: int) -> int:
	return max(10, int(round(float(base_size) * _get_responsive_scale())))

func _apply_responsive_density() -> void:
	if library_panel == null or inspector_panel == null or behavior_panel == null or preview_panel == null:
		return
	var scale_factor: float = _get_responsive_scale()
	var is_compact: bool = scale_factor < 0.82
	screen_title.add_theme_font_size_override("font_size", _get_responsive_font_size(24))
	library_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if library_panel_collapsed else _get_responsive_panel_min_width(LIBRARY_PANEL_MIN_WIDTH)
	inspector_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if inspector_panel_collapsed else _get_responsive_panel_min_width(INSPECTOR_PANEL_MIN_WIDTH)
	behavior_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if behavior_panel_collapsed else _get_responsive_panel_min_width(BEHAVIOR_PANEL_MIN_WIDTH)
	preview_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if preview_panel_collapsed else _get_responsive_panel_min_width(PREVIEW_PANEL_MIN_WIDTH)
	preview_mount.custom_minimum_size = Vector2(160, 220) if is_compact else Vector2(280, 320)
	diagnostics_text.custom_minimum_size.y = 84.0 if is_compact else 140.0
	if save_triage_button != null:
		save_triage_button.custom_minimum_size.y = 32.0 if is_compact else 42.0
	if promote_button != null:
		promote_button.custom_minimum_size.y = 32.0 if is_compact else 42.0
	_apply_responsive_control_density(self, scale_factor)

func _apply_responsive_control_density(root: Node, scale_factor: float) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		_apply_responsive_control_density(child, scale_factor)
	if not (root is Control):
		return
	var control: Control = root as Control
	if control is Label and control != screen_title:
		control.add_theme_font_size_override("font_size", _get_responsive_font_size(14))
	elif control is Button:
		control.add_theme_font_size_override("font_size", _get_responsive_font_size(14))
	elif control is OptionButton:
		control.add_theme_font_size_override("font_size", _get_responsive_font_size(13))
	elif control is LineEdit:
		control.add_theme_font_size_override("font_size", _get_responsive_font_size(13))
	elif control is TextEdit:
		control.add_theme_font_size_override("font_size", _get_responsive_font_size(13))
		control.custom_minimum_size.y = 56.0 if scale_factor < 0.82 else 72.0
	elif control is SpinBox:
		control.add_theme_font_size_override("font_size", _get_responsive_font_size(13))

func _install_panel_headers() -> void:
	if collapsed_panel_row == null and is_instance_valid(header_container):
		collapsed_panel_row = HBoxContainer.new()
		collapsed_panel_row.name = "CollapsedPanelRow"
		collapsed_panel_row.add_theme_constant_override("separation", 8)
		header_container.add_child(collapsed_panel_row)
		header_container.move_child(collapsed_panel_row, header_container.get_child_count() - 1)
	if library_panel_toggle == null and is_instance_valid(library_vbox):
		library_panel_toggle = _create_panel_toggle_row(library_vbox, "Library", "_on_library_panel_toggle")
	if inspector_panel_toggle == null and is_instance_valid(inspector_vbox):
		inspector_panel_toggle = _create_panel_toggle_row(inspector_vbox, "Card", "_on_inspector_panel_toggle")
	if behavior_panel_toggle == null and is_instance_valid(behavior_vbox):
		behavior_panel_toggle = _create_panel_toggle_row(behavior_vbox, "Actions", "_on_behavior_panel_toggle")
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
	inspector_panel.visible = not inspector_panel_collapsed
	behavior_panel.visible = not behavior_panel_collapsed
	preview_panel.visible = not preview_panel_collapsed
	if library_panel_toggle != null:
		library_panel_toggle.text = "Show" if library_panel_collapsed else "Hide"
		library_panel_toggle.tooltip_text = "Expand library" if library_panel_collapsed else "Collapse library"
	if inspector_panel_toggle != null:
		inspector_panel_toggle.text = "Show" if inspector_panel_collapsed else "Hide"
		inspector_panel_toggle.tooltip_text = "Expand card panel" if inspector_panel_collapsed else "Collapse card panel"
	if behavior_panel_toggle != null:
		behavior_panel_toggle.text = "Show" if behavior_panel_collapsed else "Hide"
		behavior_panel_toggle.tooltip_text = "Expand actions panel" if behavior_panel_collapsed else "Collapse actions panel"
	if preview_panel_toggle != null:
		preview_panel_toggle.text = "Show" if preview_panel_collapsed else "Hide"
		preview_panel_toggle.tooltip_text = "Expand preview" if preview_panel_collapsed else "Collapse preview"
	_refresh_collapsed_panel_buttons()
	library_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if library_panel_collapsed else LIBRARY_PANEL_MIN_WIDTH
	inspector_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if inspector_panel_collapsed else INSPECTOR_PANEL_MIN_WIDTH
	behavior_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if behavior_panel_collapsed else BEHAVIOR_PANEL_MIN_WIDTH
	preview_panel.custom_minimum_size.x = COLLAPSED_PANEL_WIDTH if preview_panel_collapsed else PREVIEW_PANEL_MIN_WIDTH
	library_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if library_panel_collapsed else Control.SIZE_EXPAND_FILL
	inspector_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if inspector_panel_collapsed else Control.SIZE_EXPAND_FILL
	behavior_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if behavior_panel_collapsed else Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if preview_panel_collapsed else Control.SIZE_EXPAND_FILL
	call_deferred("_apply_split_layout")

func _refresh_collapsed_panel_buttons() -> void:
	if collapsed_panel_row == null:
		return
	for child: Node in collapsed_panel_row.get_children():
		child.queue_free()
	if library_panel_collapsed:
		collapsed_panel_row.add_child(_create_collapsed_panel_button("Show Library", "_on_library_panel_toggle"))
	if inspector_panel_collapsed:
		collapsed_panel_row.add_child(_create_collapsed_panel_button("Show Card", "_on_inspector_panel_toggle"))
	if behavior_panel_collapsed:
		collapsed_panel_row.add_child(_create_collapsed_panel_button("Show Actions", "_on_behavior_panel_toggle"))
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

func _on_inspector_panel_toggle() -> void:
	inspector_panel_collapsed = not inspector_panel_collapsed
	_apply_panel_collapse_state()

func _on_behavior_panel_toggle() -> void:
	behavior_panel_collapsed = not behavior_panel_collapsed
	_apply_panel_collapse_state()

func _on_preview_panel_toggle() -> void:
	preview_panel_collapsed = not preview_panel_collapsed
	_apply_panel_collapse_state()

func _build_editor_hero() -> Control:
	return CardEditorScreenInspector.build_editor_hero(self)

func _build_property_section(group_data: Dictionary) -> Control:
	return CardEditorScreenInspector.build_property_section(self, group_data)

func _build_property_card(property_name: String, field_definition: Dictionary) -> Control:
	return CardEditorScreenInspector.build_property_card(self, property_name, field_definition)

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
	return CardEditorScreenInspector.build_property_editor(self, property_name, field_definition)

func _build_keyword_editor(property_name: String, values: Array[String]) -> Control:
	return CardEditorScreenInspector.build_keyword_editor(self, property_name, values)

func _build_card_color_editor(property_name: String, current_color_id: String, description: String) -> Control:
	return CardEditorScreenInspector.build_card_color_editor(self, property_name, current_color_id, description)

func _build_card_values_editor(property_name: String, dictionary_value: Dictionary) -> Control:
	return CardEditorScreenInspector.build_card_values_editor(self, property_name, dictionary_value)

func _build_card_value_suggestion_row(property_name: String, suggested_keys: Array[String], definitions: Dictionary[String, Dictionary]) -> Control:
	return CardEditorScreenInspector.build_card_value_suggestion_row(self, property_name, suggested_keys, definitions)

func _build_card_value_row(property_name: String, key_name: String, current_value: Variant, definition: Dictionary, is_referenced: bool) -> Control:
	return CardEditorScreenInspector.build_card_value_row(self, property_name, key_name, current_value, definition, is_referenced)

func _build_card_value_value_editor(property_name: String, key_name: String, current_value: Variant, definition: Dictionary) -> Control:
	return CardEditorScreenInspector.build_card_value_value_editor(self, property_name, key_name, current_value, definition)

func _build_card_value_add_panel(property_name: String, dictionary_value: Dictionary, definitions: Dictionary[String, Dictionary]) -> Control:
	return CardEditorScreenInspector.build_card_value_add_panel(self, property_name, dictionary_value, definitions)

func _build_dictionary_editor(property_name: String, dictionary_value: Dictionary, use_suggestions: bool = false) -> Control:
	return CardEditorScreenInspector.build_dictionary_editor(self, property_name, dictionary_value, use_suggestions)

func _build_dictionary_row(property_name: String, key_name: String, current_value: Variant) -> Control:
	return CardEditorScreenInspector.build_dictionary_row(self, property_name, key_name, current_value)

func _render_behavior() -> void:
	CardEditorScreenBehavior.render_behavior(self)
	_relax_horizontal_sizing(behavior_container)
	call_deferred("_apply_initial_split_widths")

func _build_entry_group(property_name: String, is_action: bool) -> Control:
	return CardEditorScreenBehavior.build_entry_group(self, property_name, is_action)

func _build_additional_action_group() -> Control:
	return CardEditorScreenBehavior.build_additional_action_group(self)

func _build_additional_action_editor(entry_index: int, additional_action: Dictionary) -> Control:
	return CardEditorScreenBehavior.build_additional_action_editor(self, entry_index, additional_action)

func _build_entry_editor(property_name: String, index: int, entry: Dictionary, is_action: bool) -> Control:
	return CardEditorScreenBehavior.build_entry_editor(self, property_name, index, entry, is_action)

func _build_entry_summary(token: String, values: Dictionary, is_action: bool) -> String:
	return CardEditorScreenBehavior.build_entry_summary(self, token, values, is_action)

func _build_entry_parameter_editor(property_name: String, index: int, token: String, parameter_data: Dictionary, values: Dictionary) -> Control:
	return CardEditorScreenBehavior.build_entry_parameter_editor(self, property_name, index, token, parameter_data, values)

func _build_additional_action_parameter_editor(additional_action_id: String, token: String, parameter_data: Dictionary, values: Dictionary) -> Control:
	return CardEditorScreenBehavior.build_additional_action_parameter_editor(self, additional_action_id, token, parameter_data, values)

func _build_action_reference_array_editor(owner_type: String, owner_key: String, parameter_name: String, current_value: Variant) -> Control:
	return CardEditorScreenBehavior.build_action_reference_array_editor(self, owner_type, owner_key, parameter_name, current_value)

func _build_additional_action_enum_array_editor(additional_action_id: String, parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
	return CardEditorScreenBehavior.build_additional_action_enum_array_editor(self, additional_action_id, parameter_name, parameter_data, current_value)

func _build_additional_action_string_array_editor(additional_action_id: String, parameter_name: String, current_value: Variant, placeholder_text: String) -> Control:
	return CardEditorScreenBehavior.build_additional_action_string_array_editor(self, additional_action_id, parameter_name, current_value, placeholder_text)

func _card_entry_owner_key(property_name: String, index: int) -> String:
	return CardEditorScreenBehavior.card_entry_owner_key(property_name, index)

func _get_action_reference_label(reference_id: String, reference_value: Variant) -> String:
	return CardEditorScreenBehavior.get_action_reference_label(self, reference_id, reference_value)

func _render_preview() -> void:
	CardEditorScreenPreview.render_preview(self)

func _render_session_summary() -> void:
	CardEditorScreenPreview.render_session_summary(self)

func _refresh_overview() -> void:
	CardEditorScreenPreview.refresh_overview(self)

func _refresh_status_banner() -> void:
	CardEditorScreenPreview.refresh_status_banner(self)

func _set_status_message(message: String, severity: String = "info") -> void:
	status_message = message
	status_severity = severity
	_refresh_status_banner()

func _get_diagnostic_counts() -> Dictionary:
	return CardEditorScreenPreview.get_diagnostic_counts(self)

func _format_save_policy(save_policy: String) -> String:
	return CardEditorScreenPreview.format_save_policy(save_policy)

func _status_color_hex(severity: String) -> String:
	return CardEditorScreenPreview.status_color_hex(self, severity)

func _apply_split_layout() -> void:
	_apply_screen_fit_scale()
	_apply_responsive_density()
	CardEditorScreenPreview.apply_split_layout(self)
	call_deferred("_rebalance_split_widths")

func _rebalance_split_widths() -> void:
	if not is_instance_valid(body_split) or not is_instance_valid(workspace_split) or not is_instance_valid(editor_split):
		return
	var total_width: float = maxf(body_split.size.x, size.x)
	if total_width <= 0.0:
		return
	var body_separation: float = float(body_split.get_theme_constant("separation"))
	var workspace_separation: float = float(workspace_split.get_theme_constant("separation"))
	var editor_separation: float = float(editor_split.get_theme_constant("separation"))
	var available_width: float = maxf(total_width - body_separation - workspace_separation - editor_separation, 0.0)
	var panel_width: int = int(round(available_width / 4.0))
	panel_width = max(
		panel_width,
		_get_responsive_panel_min_width(LIBRARY_PANEL_MIN_WIDTH),
		_get_responsive_panel_min_width(INSPECTOR_PANEL_MIN_WIDTH),
		_get_responsive_panel_min_width(BEHAVIOR_PANEL_MIN_WIDTH),
		_get_responsive_panel_min_width(PREVIEW_PANEL_MIN_WIDTH)
	)
	var body_usable_width: float = maxf(total_width - body_separation, 0.0)
	body_split.split_offset = int(round(float(panel_width) - (body_usable_width * 0.5)))
	var workspace_total_width: float = maxf(body_usable_width - float(panel_width), 0.0)
	var workspace_usable_width: float = maxf(workspace_total_width - workspace_separation, 0.0)
	var editor_target_width: float = maxf(workspace_usable_width - float(panel_width), 0.0)
	workspace_split.split_offset = int(round(editor_target_width - (workspace_usable_width * 0.5)))
	editor_split.split_offset = 0

func _apply_initial_split_widths() -> void:
	if not initial_split_widths_pending:
		return
	call_deferred("_rebalance_split_widths")
	initial_split_widths_pending = false

func _get_body_split_offset(total_width: int) -> int:
	return CardEditorScreenPreview.get_body_split_offset(self, total_width)

func _render_library_sections() -> void:
	CardEditorScreenLibrary.render_library_sections(self)
	call_deferred("_apply_initial_split_widths")

func _build_library_group(group_name: String, entries: Array) -> Control:
	return CardEditorScreenLibrary.build_library_group(self, group_name, entries)

func _build_library_card_tile(entry: Dictionary) -> Control:
	return CardEditorScreenLibrary.build_library_card_tile(self, entry)

func _load_library_entry_cost(entry_path: String) -> int:
	return CardEditorScreenLibrary.load_library_entry_cost(entry_path)

func _load_library_entry_texture(entry_path: String) -> Texture2D:
	return CardEditorScreenLibrary.load_library_entry_texture(entry_path)

func _get_library_grid_columns() -> int:
	return CardEditorScreenLibrary.get_library_grid_columns(self)

func _get_library_group_name(entry: Dictionary) -> String:
	return CardEditorScreenLibrary.get_library_group_name(entry)

func _open_library_entry(entry: Dictionary) -> void:
	CardEditorScreenLibrary.open_library_entry(self, entry)

func _should_show_parameter(parameter_data: Dictionary, values: Dictionary) -> bool:
	return CardEditorScreenBehavior.should_show_parameter(self, parameter_data, values)

func _build_advanced_parameter_toggle(property_name: String, index: int, token: String, is_action: bool, values: Dictionary) -> Control:
	return CardEditorScreenBehavior.build_advanced_parameter_toggle(self, property_name, index, token, is_action, values)

func _entry_visibility_key(property_name: String, index: int, token: String) -> String:
	return CardEditorScreenBehavior.entry_visibility_key(property_name, index, token)

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
	CardEditorScreenBehavior.refresh_after_behavior_change(self)

func _refresh_after_behavior_structure_change() -> void:
	CardEditorScreenBehavior.refresh_after_behavior_structure_change(self)

func _request_behavior_render() -> void:
	CardEditorScreenBehavior.request_behavior_render(self)

func _build_string_array_parameter_editor(property_name: String, index: int, parameter_name: String, current_value: Variant, placeholder_text: String) -> Control:
	return CardEditorScreenBehaviorNested.build_string_array_parameter_editor(self, property_name, index, parameter_name, current_value, placeholder_text)

func _build_enum_array_parameter_editor(property_name: String, index: int, parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
	return CardEditorScreenBehaviorNested.build_enum_array_parameter_editor(self, property_name, index, parameter_name, parameter_data, current_value)

func _build_nested_validator_array_editor(property_name: String, index: int, parameter_name: String, current_value: Variant) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_validator_array_editor(self, property_name, index, parameter_name, current_value)

func _build_nested_action_array_editor(property_name: String, index: int, parameter_name: String, current_value: Variant) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_action_array_editor(self, property_name, index, parameter_name, current_value)

func _build_nested_action_entry_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_entry: Dictionary, entries: Array) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_action_entry_editor(self, property_name, index, parameter_name, nested_index, nested_entry, entries)

func _build_nested_action_parameter_row(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_values: Dictionary, parameter_data: Dictionary) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_action_parameter_row(self, property_name, index, parameter_name, nested_index, nested_token, nested_values, parameter_data)

func _build_nested_action_enum_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_action_enum_array_editor(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, parameter_data, current_value)

func _build_nested_action_string_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant, placeholder_text: String) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_action_string_array_editor(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value, placeholder_text)

func _build_nested_action_validator_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_action_validator_array_editor(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value)

func _build_nested_action_validator_parameter_row(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, validator_index: int, validator_token: String, validator_values: Dictionary, parameter_data: Dictionary) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_action_validator_parameter_row(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, validator_values, parameter_data)

func _build_deep_nested_action_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant) -> Control:
	return CardEditorScreenBehaviorNested.build_deep_nested_action_array_editor(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value)

func _build_deep_nested_action_entry_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, deep_index: int, deep_entry: Dictionary, entries: Array) -> Control:
	return CardEditorScreenBehaviorNested.build_deep_nested_action_entry_editor(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_entry, entries)

func _build_deep_nested_action_parameter_row(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, deep_index: int, deep_token: String, deep_values: Dictionary, parameter_data: Dictionary) -> Control:
	return CardEditorScreenBehaviorNested.build_deep_nested_action_parameter_row(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, deep_values, parameter_data)

func _build_nested_validator_parameter_row(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_values: Dictionary, parameter_data: Dictionary) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_validator_parameter_row(self, property_name, index, parameter_name, nested_index, nested_token, nested_values, parameter_data)

func _build_nested_validator_enum_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_validator_enum_array_editor(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, parameter_data, current_value)

func _build_nested_validator_string_array_editor(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant) -> Control:
	return CardEditorScreenBehaviorNested.build_nested_validator_string_array_editor(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value)

func _update_nested_validator_value(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, next_value: Variant) -> void:
	CardEditorScreenBehaviorNested.update_nested_validator_value(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_value)

func _update_nested_action_value(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, next_value: Variant, rerender_behavior: bool = false) -> void:
	CardEditorScreenBehaviorNested.update_nested_action_value(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_value, rerender_behavior)

func _update_deep_nested_validator_value(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, validator_index: int, validator_token: String, child_parameter_name: String, next_value: Variant) -> void:
	CardEditorScreenBehaviorNested.update_deep_nested_validator_value(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, child_parameter_name, next_value)

func _update_deep_nested_action_value(property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, deep_index: int, deep_token: String, child_parameter_name: String, next_value: Variant) -> void:
	CardEditorScreenBehaviorNested.update_deep_nested_action_value(self, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, child_parameter_name, next_value)

func _variant_to_string_array(value: Variant) -> Array[String]:
	return CardEditorScreenBehaviorNested.variant_to_string_array(value)

func _is_action_reference_parameter(parameter_name: String) -> bool:
	return CardEditorScreenBehaviorNested.is_action_reference_parameter(parameter_name)

func _is_action_array_parameter(parameter_name: String, current_value: Variant) -> bool:
	return CardEditorScreenBehaviorNested.is_action_array_parameter(parameter_name, current_value)

func _populate_static_filters() -> void:
	CardEditorScreenLibrary.populate_static_filters(self)

func _populate_dynamic_filters() -> void:
	CardEditorScreenLibrary.populate_dynamic_filters(self)

func _get_card_color_options() -> Array[Dictionary]:
	return CardEditorScreenInspector.get_card_color_options(self)

func _get_card_value_key_options(existing_values: Dictionary) -> Array[Dictionary]:
	return CardEditorScreenInspector.get_card_value_key_options(self, existing_values)

func _get_card_value_definition_options(existing_values: Dictionary, definitions: Dictionary[String, Dictionary]) -> Array[Dictionary]:
	return CardEditorScreenInspector.get_card_value_definition_options(existing_values, definitions)

func _collect_card_value_suggestions() -> Array[String]:
	return CardEditorScreenInspector.collect_card_value_suggestions(self)

func _collect_description_placeholders() -> Array[String]:
	return CardEditorScreenInspector.collect_description_placeholders(self)

func _collect_action_value_suggestions() -> Array[String]:
	return CardEditorScreenInspector.collect_action_value_suggestions(self)

func _property_label(property_name: String, field_definition: Dictionary) -> String:
	return CardEditorScreenInspector.property_label(property_name, field_definition)

func _property_description(property_name: String, field_definition: Dictionary) -> String:
	return CardEditorScreenInspector.property_description(property_name, field_definition)

func _format_clicked_target_mode(target_mode: String) -> String:
	return CardEditorScreenInspector.format_clicked_target_mode(target_mode)

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
	return CardEditorScreenInspector.get_keyword_options(existing_keywords)

func _variant_type_options() -> Array[Dictionary]:
	return CardEditorScreenInspector.variant_type_options()

func _build_variant_value_editor(current_value: Variant, on_change: Callable) -> Control:
	return CardEditorScreenInspector.build_variant_value_editor(self, current_value, on_change)

func _default_value_for_variant_type(type_name: String) -> Variant:
	return CardEditorScreenInspector.default_value_for_variant_type(type_name)

func _infer_variant_type(value: Variant) -> String:
	return CardEditorScreenInspector.infer_variant_type(value)

func _coerce_variant_value(value: Variant, type_name: String) -> Variant:
	return CardEditorScreenInspector.coerce_variant_value(value, type_name)

func _select_option_value(option_button: OptionButton, desired_value: Variant) -> void:
	CardEditorScreenInspector.select_option_value(option_button, desired_value)

func _format_library_entry_label(entry: Dictionary) -> String:
	return CardEditorScreenLibrary.format_library_entry_label(self, entry)

func _format_library_meta(entry: Dictionary) -> String:
	return CardEditorScreenLibrary.format_library_meta(self, entry)

func _apply_library_tile_style(tile: PanelContainer, is_selected: bool, is_hovered: bool) -> void:
	CardEditorScreenLibrary.apply_library_tile_style(tile, is_selected, is_hovered)

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
	CardEditorScreenPreview.render_preview_card(self, card, card_data)

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

func _get_inspector_section_columns(preferred_columns: int = 1) -> int:
	if preferred_columns <= 1:
		return 1
	return preferred_columns

func _get_behavior_parameter_columns() -> int:
	var panel_width: float = maxf(behavior_panel.size.x, behavior_panel.custom_minimum_size.x)
	if panel_width >= 900.0:
		return 2
	return 1

func _use_compact_inspector_controls() -> bool:
	return false

func _relax_horizontal_sizing(root: Node) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		_relax_horizontal_sizing(child)
	if not (root is Control):
		return
	var control: Control = root as Control
	if not (control is Label):
		control.custom_minimum_size.x = 0.0
	if control is PanelContainer or control is MarginContainer or control is VBoxContainer or control is GridContainer:
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if control is OptionButton:
		var option_button: OptionButton = control as OptionButton
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elif control is LineEdit:
		var line_edit: LineEdit = control as LineEdit
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elif control is SpinBox:
		var spin_box: SpinBox = control as SpinBox
		spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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

func _update_save_buttons() -> void:
	if save_triage_button == null or promote_button == null:
		return
	if current_session == null:
		save_triage_button.disabled = true
		promote_button.disabled = true
		save_triage_button.text = "Save To Triage"
		promote_button.text = "Promote To Content"
		return
	var is_dirty: bool = current_session.dirty
	var active_path: String = current_session.original_resource_path
	var is_triage_resource: bool = CardEditorPathUtils.path_is_within_root(active_path, current_session.triage_root)
	var is_content_resource: bool = CardEditorPathUtils.path_is_within_root(active_path, current_session.content_root)
	if is_triage_resource:
		save_triage_button.text = "Save"
		save_triage_button.disabled = not is_dirty
	else:
		save_triage_button.text = "Move To Triage" if is_content_resource else "Save To Triage"
		save_triage_button.disabled = false
	if is_content_resource:
		promote_button.text = "Save"
		promote_button.disabled = not is_dirty
	else:
		promote_button.text = "Promote To Content"
		promote_button.disabled = false
