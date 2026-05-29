@tool
extends Control
class_name EnemyEditorScreen

const DEFAULT_PARTY_SIZE := 4
const SECTION_TITLE_SIZE := 18
const BODY_FONT_SIZE := 15
const CONTROL_PAD_X := 12
const CONTROL_PAD_Y := 7
const SUPPORTED_CONDITION_CLASSES := EnemyEditorPreviewService.SUPPORTED_PREVIEW_VALIDATORS

@onready var title_screen: Control = get_parent() as Control
@onready var status_label: Label = $MainMargin/RootVBox/Header/StatusLabel
@onready var stats_label: Label = $MainMargin/RootVBox/Header/StatsLabel
@onready var back_button: Button = $MainMargin/RootVBox/Header/ButtonRow/BackButton
@onready var new_button: Button = $MainMargin/RootVBox/Header/ButtonRow/NewButton
@onready var duplicate_button: Button = $MainMargin/RootVBox/Header/ButtonRow/DuplicateButton
@onready var save_triage_button: Button = $MainMargin/RootVBox/Header/ButtonRow/SaveTriageButton
@onready var promote_button: Button = $MainMargin/RootVBox/Header/ButtonRow/PromoteButton
@onready var search_input: LineEdit = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/SearchInput
@onready var source_filter: OptionButton = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/FilterRow/SourceFilter
@onready var type_filter: OptionButton = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/FilterRow/TypeFilter
@onready var minion_filter: OptionButton = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/FilterRow/MinionFilter
@onready var library_list: VBoxContainer = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/LibraryScroll/LibraryList
@onready var navigator_content: VBoxContainer = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/NavigatorScroll/NavigatorContent
@onready var editor_content: VBoxContainer = $MainMargin/RootVBox/BodySplit/WorkspaceSplit/CenterPanel/CenterMargin/CenterScroll/EditorContent
@onready var preview_content: VBoxContainer = $MainMargin/RootVBox/BodySplit/WorkspaceSplit/RightPanel/RightMargin/RightScroll/PreviewContent

var service := EnemyEditorService.new()
var current_session: EnemyEditorSession = null
var library_entries: Array[Dictionary] = []
var filtered_entries: Array[Dictionary] = []
var selected_library_path: String = ""
var selected_base_stage_id: String = ""
var selected_reactive_stage_id: String = ""
var selected_difficulty_index: int = -1
var last_preview_result: Dictionary = {}
var editor_theme: Theme = null

func _ready() -> void:
	visible = not _is_embedded_in_title_screen()
	_setup_editor_theme()
	back_button.button_up.connect(_on_back_button_up)
	new_button.button_up.connect(_on_new_button_up)
	duplicate_button.button_up.connect(_on_duplicate_button_up)
	save_triage_button.button_up.connect(_on_save_triage_button_up)
	promote_button.button_up.connect(_on_promote_button_up)
	search_input.text_changed.connect(_on_search_changed)
	source_filter.item_selected.connect(_on_filter_changed)
	type_filter.item_selected.connect(_on_filter_changed)
	minion_filter.item_selected.connect(_on_filter_changed)
	_populate_filters()
	_apply_compact_font_sizes(self)
	if not _is_embedded_in_title_screen():
		show_editor()

func show_editor() -> void:
	visible = true
	_refresh_library()
	if current_session == null:
		current_session = service.create_blank_session()
		_select_default_navigation_targets()
	_set_status("Started a new enemy triage draft. Use the library or shape the stages directly.", "info")
	_render_all()

func _populate_filters() -> void:
	_populate_option_button(source_filter, [
		{"label": "All Sources", "value": "all"},
		{"label": "Content", "value": "content"},
		{"label": "Triage", "value": "triage"},
	])
	var type_options: Array[Dictionary] = [{"label": "All Types", "value": -1}]
	type_options.append_array(EnemyEditorSchema.enemy_type_options())
	_populate_option_button(type_filter, type_options)
	_populate_option_button(minion_filter, [
		{"label": "Minions and Non-Minions", "value": -1},
		{"label": "Non-Minion", "value": 0},
		{"label": "Minion", "value": 1},
	])

func _refresh_library() -> void:
	library_entries = service.list_library_enemies()
	_apply_library_filters()

func _apply_library_filters() -> void:
	var filters: Dictionary = {}
	var source_value: Variant = _get_option_value(source_filter)
	if source_value != null and source_value != "all":
		filters["source_bucket"] = source_value
	var type_value: Variant = _get_option_value(type_filter)
	if type_value != null and int(type_value) >= 0:
		filters["enemy_type"] = int(type_value)
	var minion_value: Variant = _get_option_value(minion_filter)
	if minion_value != null and int(minion_value) >= 0:
		filters["enemy_is_minion"] = int(minion_value) == 1
	filtered_entries = service.filter_library_enemies(library_entries, filters, search_input.text)
	_render_library()
	_update_stats()

func _render_all() -> void:
	_ensure_preview_defaults()
	_select_default_navigation_targets()
	last_preview_result = service.resolve_preview(current_session)
	_render_library()
	_render_navigator()
	_render_editor()
	_render_preview()
	_update_stats()
	_apply_compact_font_sizes(self)
	_apply_control_padding(self)
	duplicate_button.disabled = current_session == null
	save_triage_button.disabled = current_session == null
	promote_button.disabled = current_session == null

func _render_library() -> void:
	_clear_children(library_list)
	if filtered_entries.is_empty():
		library_list.add_child(_make_note_label("No enemies matched the current filters."))
		return
	for entry: Dictionary in filtered_entries:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var padding := MarginContainer.new()
		padding.add_theme_constant_override("margin_left", 12)
		padding.add_theme_constant_override("margin_top", 10)
		padding.add_theme_constant_override("margin_right", 12)
		padding.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(padding)
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s\n%s | %s | %s stage(s), %s reactive" % [
			str(entry.get("enemy_name", entry.get("object_id", "Enemy"))),
			str(entry.get("object_id", "")),
			str(entry.get("source_bucket", "")),
			int(entry.get("stage_count", 0)),
			int(entry.get("reactive_stage_count", 0)),
		]
		button.tooltip_text = str(entry.get("resource_path", ""))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 64)
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if str(entry.get("resource_path", "")) == selected_library_path:
			button.disabled = true
		button.button_up.connect(func() -> void:
			_open_library_entry(entry)
		)
		padding.add_child(button)
		library_list.add_child(panel)

func _render_navigator() -> void:
	_clear_children(navigator_content)
	if current_session == null or current_session.working_enemy_data == null:
		navigator_content.add_child(_make_note_label("No active enemy session."))
		return

	var session_section := _add_section(navigator_content, "Session")
	session_section.add_child(_make_note_label("%s\n%s" % [
		current_session.working_enemy_data.enemy_name,
		current_session.get_active_save_path(),
	]))

	var stages_section := _add_section(navigator_content, "Base Stages")
	var stage_add_row := HBoxContainer.new()
	var add_stage_button := Button.new()
	add_stage_button.text = "Add Base Stage"
	add_stage_button.button_up.connect(func() -> void:
		var stage: EnemyStageData = service.create_stage(current_session)
		if stage != null:
			selected_base_stage_id = stage.object_id
			selected_reactive_stage_id = ""
			selected_difficulty_index = -1
			_set_status("Added a new base stage.", "success")
			_render_all()
	)
	stage_add_row.add_child(add_stage_button)
	stages_section.add_child(stage_add_row)
	for stage_data: EnemyStageData in current_session.working_enemy_data.stages:
		stages_section.add_child(_build_stage_nav_row(stage_data))

	var reactive_section := _add_section(navigator_content, "Reactive Stages")
	var add_reactive_button := Button.new()
	add_reactive_button.text = "Add Reactive Stage"
	add_reactive_button.button_up.connect(func() -> void:
		var stage: EnemyReactiveStageData = service.create_reactive_stage(current_session)
		if stage != null:
			selected_reactive_stage_id = stage.object_id
			selected_base_stage_id = ""
			selected_difficulty_index = -1
			_set_status("Added a new reactive stage.", "success")
			_render_all()
	)
	reactive_section.add_child(add_reactive_button)
	var reactive_stages: Array[EnemyReactiveStageData] = current_session.working_enemy_data.reactive_stages.duplicate()
	reactive_stages.sort_custom(func(left: EnemyReactiveStageData, right: EnemyReactiveStageData) -> bool:
		return left.priority > right.priority
	)
	for stage_data: EnemyReactiveStageData in reactive_stages:
		reactive_section.add_child(_build_reactive_nav_row(stage_data))

	var difficulty_section := _add_section(navigator_content, "Difficulty")
	var add_difficulty_button := Button.new()
	add_difficulty_button.text = "Add Difficulty Override"
	add_difficulty_button.button_up.connect(func() -> void:
		var override_data: EnemyDifficultyOverrideData = service.create_difficulty_override(current_session, 0)
		if override_data != null:
			selected_difficulty_index = current_session.working_enemy_data.difficulty_overrides.find(override_data)
			selected_base_stage_id = ""
			selected_reactive_stage_id = ""
			_set_status("Added a difficulty override.", "success")
			_render_all()
	)
	difficulty_section.add_child(add_difficulty_button)
	for index: int in range(current_session.working_enemy_data.difficulty_overrides.size()):
		var override_data: EnemyDifficultyOverrideData = current_session.working_enemy_data.difficulty_overrides[index]
		difficulty_section.add_child(_build_difficulty_nav_row(override_data, index))

func _render_editor() -> void:
	_clear_children(editor_content)
	if current_session == null or current_session.working_enemy_data == null:
		editor_content.add_child(_make_note_label("No active enemy session."))
		return
	_render_enemy_profile_section(editor_content)
	if selected_base_stage_id != "":
		var stage_data: EnemyStageData = current_session.working_enemy_data.get_stage(selected_base_stage_id)
		if stage_data != null:
			_render_base_stage_editor(editor_content, stage_data)
			return
	if selected_reactive_stage_id != "":
		var reactive_stage: EnemyReactiveStageData = current_session.working_enemy_data.get_reactive_stage(selected_reactive_stage_id)
		if reactive_stage != null:
			_render_reactive_stage_editor(editor_content, reactive_stage)
			return
	if selected_difficulty_index >= 0 and selected_difficulty_index < current_session.working_enemy_data.difficulty_overrides.size():
		_render_difficulty_editor(editor_content, selected_difficulty_index)
		return
	editor_content.add_child(_make_note_label("Select a base stage, reactive stage, or difficulty override from the navigator."))

func _render_preview() -> void:
	_clear_children(preview_content)
	if current_session == null:
		preview_content.add_child(_make_note_label("No preview available."))
		return
	_render_preview_controls(preview_content)
	_render_preview_results(preview_content)
	_render_diagnostics(preview_content)

func _render_enemy_profile_section(parent: VBoxContainer) -> void:
	var section := _add_section(parent, "Enemy Profile")
	var enemy_data: EnemyData = current_session.working_enemy_data
	section.add_child(_build_string_field("Enemy Name", enemy_data.enemy_name, func(next_value: String) -> void:
		if service.set_enemy_property(current_session, "enemy_name", next_value):
			_render_all()
	))
	section.add_child(_build_string_field("Stable Object ID", enemy_data.object_id, func(next_value: String) -> void:
		if service.set_enemy_property(current_session, "object_id", next_value):
			_render_all()
	))
	section.add_child(_build_string_field("Legacy Enemy ID", enemy_data.enemy_object_id, func(next_value: String) -> void:
		if service.set_enemy_property(current_session, "enemy_object_id", next_value):
			_render_all()
	))
	section.add_child(_build_string_field("Texture Path", enemy_data.enemy_texture_path, func(next_value: String) -> void:
		if service.set_enemy_property(current_session, "enemy_texture_path", next_value):
			_render_all()
	))
	section.add_child(_build_int_field("Health", enemy_data.enemy_health, 0, 9999, func(next_value: int) -> void:
		if service.set_enemy_property(current_session, "enemy_health", next_value):
			_render_all()
	))
	section.add_child(_build_int_field("Max Health", enemy_data.enemy_health_max, 0, 9999, func(next_value: int) -> void:
		if service.set_enemy_property(current_session, "enemy_health_max", next_value):
			_render_all()
	))
	section.add_child(_build_int_field("Poise", enemy_data.enemy_poise, 0, 9999, func(next_value: int) -> void:
		if service.set_enemy_property(current_session, "enemy_poise", next_value):
			_render_all()
	))
	section.add_child(_build_int_field("Max Poise", enemy_data.enemy_poise_max, 0, 9999, func(next_value: int) -> void:
		if service.set_enemy_property(current_session, "enemy_poise_max", next_value):
			_render_all()
	))
	section.add_child(_build_int_field("Starting Block", enemy_data.enemy_block, 0, 9999, func(next_value: int) -> void:
		if service.set_enemy_property(current_session, "enemy_block", next_value):
			_render_all()
	))
	section.add_child(_build_option_field("Enemy Type", EnemyEditorSchema.enemy_type_options(), enemy_data.enemy_type, func(next_value: Variant) -> void:
		if service.set_enemy_property(current_session, "enemy_type", int(next_value)):
			_render_all()
	))
	section.add_child(_build_bool_field("Minion", enemy_data.enemy_is_minion, func(next_value: bool) -> void:
		if service.set_enemy_property(current_session, "enemy_is_minion", next_value):
			_render_all()
	))
	section.add_child(_build_option_field("Opening Stage", _base_stage_options(), enemy_data.opening_stage_id, func(next_value: Variant) -> void:
		if service.set_enemy_property(current_session, "opening_stage_id", str(next_value)):
			selected_base_stage_id = str(next_value)
			_render_all()
	))
	section.add_child(_make_note_label("Save policy: %s\nManaged triage: %s\nManaged content: %s" % [
		current_session.save_policy,
		current_session.managed_triage_save_path,
		current_session.managed_save_path,
	]))

func _render_base_stage_editor(parent: VBoxContainer, stage_data: EnemyStageData) -> void:
	var section := _add_section(parent, "Base Stage")
	section.add_child(_make_note_label(EnemyEditorSchema.summarize_stage(stage_data)))
	section.add_child(_build_string_field("Stage ID", stage_data.object_id, func(next_value: String) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "object_id", next_value, false):
			selected_base_stage_id = next_value
			_render_all()
	))
	section.add_child(_build_string_field("Label", stage_data.label, func(next_value: String) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "label", next_value, false):
			_render_all()
	))
	section.add_child(_build_option_field("Next Stage", _base_stage_options(), stage_data.next_stage_id, func(next_value: Variant) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "next_stage_id", str(next_value), false):
			_render_all()
	))
	var remove_button := Button.new()
	remove_button.text = "Remove Base Stage"
	remove_button.button_up.connect(func() -> void:
		if service.remove_stage(current_session, stage_data.object_id):
			selected_base_stage_id = ""
			_select_default_navigation_targets()
			_set_status("Removed base stage %s." % stage_data.object_id, "success")
			_render_all()
	)
	section.add_child(remove_button)

	var variants_section := _add_section(parent, "Intent Variants")
	var add_variant_button := Button.new()
	add_variant_button.text = "Add Intent Variant"
	add_variant_button.button_up.connect(func() -> void:
		if service.create_intent_variant(current_session, stage_data.object_id, false) != null:
			_render_all()
	)
	variants_section.add_child(add_variant_button)
	for variant_index: int in range(stage_data.intents.size()):
		var variant: EnemyIntentVariantData = stage_data.intents[variant_index]
		variants_section.add_child(_build_variant_panel(stage_data.object_id, variant_index, variant, false))

	var actions_section := _add_section(parent, "Extra Actions")
	_render_action_entries(actions_section, stage_data.extra_actions, BaseAction.EDITOR_CONTEXT_ENEMY_ACTIONS, func(next_entries: Array[Dictionary]) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "extra_actions", next_entries, false):
			_render_all()
	)

func _render_reactive_stage_editor(parent: VBoxContainer, stage_data: EnemyReactiveStageData) -> void:
	var section := _add_section(parent, "Reactive Stage")
	section.add_child(_make_note_label("Interrupt | %s" % EnemyEditorSchema.summarize_reactive_stage(stage_data)))
	section.add_child(_build_string_field("Reactive Stage ID", stage_data.object_id, func(next_value: String) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "object_id", next_value, true):
			selected_reactive_stage_id = next_value
			_render_all()
	))
	section.add_child(_build_string_field("Label", stage_data.label, func(next_value: String) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "label", next_value, true):
			_render_all()
	))
	section.add_child(_build_int_field("Priority", stage_data.priority, -999, 999, func(next_value: int) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "priority", next_value, true):
			_render_all()
	))
	section.add_child(_build_option_field("Resume Mode", EnemyEditorSchema.resume_mode_options(), stage_data.resume_mode, func(next_value: Variant) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "resume_mode", str(next_value), true):
			_render_all()
	))
	section.add_child(_build_option_field("Resume Stage", _prepend_none(_base_stage_options(), "Resume Previous"), stage_data.resume_stage_id, func(next_value: Variant) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "resume_stage_id", str(next_value), true):
			_render_all()
	))
	var remove_button := Button.new()
	remove_button.text = "Remove Reactive Stage"
	remove_button.button_up.connect(func() -> void:
		if service.remove_reactive_stage(current_session, stage_data.object_id):
			selected_reactive_stage_id = ""
			_select_default_navigation_targets()
			_set_status("Removed reactive stage %s." % stage_data.object_id, "success")
			_render_all()
	)
	section.add_child(remove_button)

	var conditions_section := _add_section(parent, "Reactive Conditions")
	_render_condition_entries(conditions_section, stage_data.conditions, func(next_entries: Array[Dictionary]) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "conditions", next_entries, true):
			_render_all()
	)

	var variants_section := _add_section(parent, "Intent Variants")
	var add_variant_button := Button.new()
	add_variant_button.text = "Add Intent Variant"
	add_variant_button.button_up.connect(func() -> void:
		if service.create_intent_variant(current_session, stage_data.object_id, true) != null:
			_render_all()
	)
	variants_section.add_child(add_variant_button)
	for variant_index: int in range(stage_data.intents.size()):
		var variant: EnemyIntentVariantData = stage_data.intents[variant_index]
		variants_section.add_child(_build_variant_panel(stage_data.object_id, variant_index, variant, true))

	var actions_section := _add_section(parent, "Extra Actions")
	_render_action_entries(actions_section, stage_data.extra_actions, BaseAction.EDITOR_CONTEXT_ENEMY_ACTIONS, func(next_entries: Array[Dictionary]) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "extra_actions", next_entries, true):
			_render_all()
	)

func _render_difficulty_editor(parent: VBoxContainer, override_index: int) -> void:
	var override_data: EnemyDifficultyOverrideData = current_session.working_enemy_data.difficulty_overrides[override_index]
	var section := _add_section(parent, "Difficulty Override")
	section.add_child(_make_note_label(EnemyEditorSchema.summarize_difficulty_override(override_data)))
	section.add_child(_build_int_field("Difficulty Level", override_data.difficulty_level, 0, 99, func(next_value: int) -> void:
		override_data.difficulty_level = next_value
		_mark_session_dirty_only()
	))
	var remove_button := Button.new()
	remove_button.text = "Remove Difficulty Override"
	remove_button.button_up.connect(func() -> void:
		if service.remove_difficulty_override(current_session, override_index):
			selected_difficulty_index = -1
			_set_status("Removed difficulty override.", "success")
			_render_all()
	)
	section.add_child(remove_button)

	var top_level_section := _add_section(parent, "Top-Level Overrides")
	var allowed_fields: Dictionary[String, Dictionary] = {}
	for field_name: String in EnemyEditorSchema.get_top_level_field_definitions().keys():
		var definition: Dictionary = EnemyEditorSchema.get_top_level_field_definitions()[field_name]
		var value_type: String = str(definition.get("value_type", ""))
		if value_type in ["string", "int", "bool", "enum"]:
			allowed_fields[field_name] = definition
	for property_name: String in override_data.top_level_overrides.keys():
		top_level_section.add_child(_build_top_level_override_row(override_index, property_name, override_data.top_level_overrides[property_name], allowed_fields))
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var add_option := OptionButton.new()
	add_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(add_option, _field_definition_options(allowed_fields))
	var add_button := Button.new()
	add_button.text = "Add Override"
	add_button.button_up.connect(func() -> void:
		var selected_field: Variant = _get_option_value(add_option)
		if selected_field == null:
			return
		var definition: Dictionary = allowed_fields.get(str(selected_field), {})
		var default_value: Variant = _default_value_for_definition(definition)
		if service.set_difficulty_top_level_override(current_session, override_index, str(selected_field), default_value):
			_render_all()
	)
	add_row.add_child(add_option)
	add_row.add_child(add_button)
	top_level_section.add_child(add_row)
	if override_data.stage_overrides.size() > 0 or override_data.reactive_stage_overrides.size() > 0:
		top_level_section.add_child(_make_note_label("Stage and reactive-stage patch editing is not exposed yet in this v1 screen. Existing patches are preserved on load/save."))

func _render_preview_controls(parent: VBoxContainer) -> void:
	var section := _add_section(parent, "Live Preview")
	var state: EnemyEditorPreviewState = current_session.preview_state
	section.add_child(_build_option_field("Planned Stage", _base_stage_options(), state.planned_stage_id, func(next_value: Variant) -> void:
		state.planned_stage_id = str(next_value)
		_render_all()
	))
	section.add_child(_build_option_field("Previous Executed Stage", _prepend_none(_stage_id_options(), "None"), state.previous_executed_stage_id, func(next_value: Variant) -> void:
		state.previous_executed_stage_id = str(next_value)
		_render_all()
	))
	section.add_child(_build_int_field("Turn Count", state.turn_count, 1, 99, func(next_value: int) -> void:
		state.turn_count = next_value
		_render_all()
	))
	section.add_child(_build_int_field("Stage Started Turn", state.planned_stage_started_turn_count, 1, 99, func(next_value: int) -> void:
		state.planned_stage_started_turn_count = next_value
		_render_all()
	))
	section.add_child(_build_int_field("Player Energy", state.player_energy, 0, 20, func(next_value: int) -> void:
		state.player_energy = next_value
		_render_all()
	))
	section.add_child(_build_int_field("Preview Difficulty", state.difficulty_level, 0, 99, func(next_value: int) -> void:
		state.difficulty_level = next_value
		_render_all()
	))
	var status_section := _add_section(parent, "Enemy Statuses")
	_render_status_dictionary_editor(status_section, state.enemy_status_effects, func(next_value: Dictionary[String, int]) -> void:
		state.enemy_status_effects = next_value
		_render_all()
	)

	var party_section := _add_section(parent, "Party State")
	for party_index: int in range(state.player_party_members.size()):
		var member: Dictionary = state.player_party_members[party_index]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.add_child(_make_inline_title("Player %s" % party_index))
		row.add_child(_build_int_field("Health", int(member.get("health", 0)), 0, 999, func(next_value: int) -> void:
			state.player_party_members[party_index]["health"] = next_value
			_render_all()
		))
		row.add_child(_build_int_field("Max Health", int(member.get("health_max", 1)), 1, 999, func(next_value: int) -> void:
			state.player_party_members[party_index]["health_max"] = next_value
			_render_all()
		))
		party_section.add_child(row)

	var ally_section := _add_section(parent, "Allies And Minions")
	var counts: Dictionary = _ally_count_summary(state.living_ally_enemy_states)
	ally_section.add_child(_build_int_field("Living Allies", int(counts.get("living_allies", 0)), 0, 6, func(next_value: int) -> void:
		state.living_ally_enemy_states = _build_ally_state_array(next_value, int(counts.get("living_minions", 0)))
		_render_all()
	))
	ally_section.add_child(_build_int_field("Living Minions", int(counts.get("living_minions", 0)), 0, 6, func(next_value: int) -> void:
		state.living_ally_enemy_states = _build_ally_state_array(int(counts.get("living_allies", 0)), next_value)
		_render_all()
	))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	var apply_button := Button.new()
	apply_button.text = "Apply Execution Result"
	apply_button.button_up.connect(_on_apply_preview_execution_result)
	var reset_button := Button.new()
	reset_button.text = "Reset Preview"
	reset_button.button_up.connect(func() -> void:
		current_session.reset_preview_state()
		_ensure_preview_defaults()
		_render_all()
	)
	button_row.add_child(apply_button)
	button_row.add_child(reset_button)
	parent.add_child(button_row)

func _render_preview_results(parent: VBoxContainer) -> void:
	var section := _add_section(parent, "Resolved Outcome")
	if not bool(last_preview_result.get("success", false)):
		section.add_child(_make_note_label("Preview resolution failed."))
		return
	section.add_child(_make_note_label("Base Stage: %s" % str(last_preview_result.get("active_base_stage_id", ""))))
	section.add_child(_make_note_label("Reactive Stage: %s" % str(last_preview_result.get("active_reactive_stage_id", ""))))
	section.add_child(_make_note_label("Active Stage: %s" % str(last_preview_result.get("active_stage_id", ""))))
	section.add_child(_make_note_label("Variant: %s" % str(last_preview_result.get("variant_summary", ""))))
	section.add_child(_make_note_label("Intent: %s" % str(last_preview_result.get("intent_summary", ""))))
	section.add_child(_make_note_label("Targets: %s" % str(last_preview_result.get("target_summary", ""))))
	section.add_child(_make_note_label("Preview Damage: %s\nPreview Attacks: %s\nPreview Block: %s" % [
		int(last_preview_result.get("preview_attack_damage", 0)),
		int(last_preview_result.get("preview_number_of_attacks", 0)),
		int(last_preview_result.get("preview_block", 0)),
	]))
	section.add_child(_make_note_label("Next Planned Stage: %s" % str(last_preview_result.get("next_planned_stage_id_after_execution", ""))))
	section.add_child(_make_note_label("Extra Actions: %s" % int(last_preview_result.get("extra_actions", []).size())))

func _render_diagnostics(parent: VBoxContainer) -> void:
	var section := _add_section(parent, "Validation")
	var diagnostics: Array[Dictionary] = current_session.diagnostics
	if diagnostics.is_empty():
		section.add_child(_make_note_label("No validation issues."))
	else:
		for diagnostic: Dictionary in diagnostics:
			section.add_child(_make_note_label("[%s] %s" % [
				str(diagnostic.get("severity", "")).to_upper(),
				str(diagnostic.get("message", "")),
			]))
	var preview_diagnostics: Array = last_preview_result.get("diagnostics", [])
	if not preview_diagnostics.is_empty():
		var preview_section := _add_section(parent, "Preview Diagnostics")
		for diagnostic: Dictionary in preview_diagnostics:
			preview_section.add_child(_make_note_label("[%s] %s" % [
				str(diagnostic.get("severity", "")).to_upper(),
				str(diagnostic.get("message", "")),
			]))

func _build_stage_nav_row(stage_data: EnemyStageData) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "%s -> %s" % [stage_data.object_id, stage_data.next_stage_id]
	button.tooltip_text = EnemyEditorSchema.summarize_stage(stage_data)
	button.disabled = stage_data.object_id == selected_base_stage_id
	button.button_up.connect(func() -> void:
		selected_base_stage_id = stage_data.object_id
		selected_reactive_stage_id = ""
		selected_difficulty_index = -1
		_render_all()
	)
	var remove_button := Button.new()
	remove_button.text = "X"
	remove_button.button_up.connect(func() -> void:
		if service.remove_stage(current_session, stage_data.object_id):
			selected_base_stage_id = ""
			_select_default_navigation_targets()
			_render_all()
	)
	row.add_child(button)
	row.add_child(remove_button)
	return row

func _build_reactive_nav_row(stage_data: EnemyReactiveStageData) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "P%s | %s" % [stage_data.priority, stage_data.object_id]
	button.tooltip_text = EnemyEditorSchema.summarize_reactive_stage(stage_data)
	button.disabled = stage_data.object_id == selected_reactive_stage_id
	button.button_up.connect(func() -> void:
		selected_reactive_stage_id = stage_data.object_id
		selected_base_stage_id = ""
		selected_difficulty_index = -1
		_render_all()
	)
	var remove_button := Button.new()
	remove_button.text = "X"
	remove_button.button_up.connect(func() -> void:
		if service.remove_reactive_stage(current_session, stage_data.object_id):
			selected_reactive_stage_id = ""
			_select_default_navigation_targets()
			_render_all()
	)
	row.add_child(button)
	row.add_child(remove_button)
	return row

func _build_difficulty_nav_row(override_data: EnemyDifficultyOverrideData, override_index: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "Difficulty %s" % override_data.difficulty_level
	button.tooltip_text = EnemyEditorSchema.summarize_difficulty_override(override_data)
	button.disabled = override_index == selected_difficulty_index
	button.button_up.connect(func() -> void:
		selected_difficulty_index = override_index
		selected_base_stage_id = ""
		selected_reactive_stage_id = ""
		_render_all()
	)
	row.add_child(button)
	return row

func _build_variant_panel(stage_id: String, variant_index: int, variant: EnemyIntentVariantData, is_reactive: bool) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var header := HBoxContainer.new()
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var summary: String = EnemyEditorSchema.summarize_intent_variant(variant)
	if variant.conditions.is_empty():
		summary += " | Default"
	label.text = summary
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func() -> void:
		if service.remove_intent_variant(current_session, stage_id, variant_index, is_reactive):
			_render_all()
	)
	header.add_child(label)
	header.add_child(remove_button)
	box.add_child(header)
	box.add_child(_build_int_field("Priority", variant.priority, -999, 999, func(next_value: int) -> void:
		if service.set_variant_field(current_session, stage_id, variant_index, "priority", next_value, is_reactive):
			_render_all()
	))
	var condition_section := _add_section(box, "Conditions")
	_render_condition_entries(condition_section, variant.conditions, func(next_entries: Array[Dictionary]) -> void:
		if service.patch_variant_conditions(current_session, stage_id, variant_index, next_entries, "overwrite", is_reactive):
			_render_all()
	)
	var intent_section := _add_section(box, "Intent")
	intent_section.add_child(_build_int_field("Damage", variant.intent.damage, 0, 999, func(next_value: int) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "damage", next_value, is_reactive):
			_render_all()
	))
	intent_section.add_child(_build_int_field("Attacks", variant.intent.number_of_attacks, 0, 20, func(next_value: int) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "number_of_attacks", next_value, is_reactive):
			_render_all()
	))
	intent_section.add_child(_build_int_field("Block", variant.intent.block, 0, 999, func(next_value: int) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "block", next_value, is_reactive):
			_render_all()
	))
	intent_section.add_child(_build_option_field("Targeting Rule", EnemyEditorSchema.targeting_rule_options(), variant.intent.targeting_rule, func(next_value: Variant) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "targeting_rule", str(next_value), is_reactive):
			_render_all()
	))
	intent_section.add_child(_build_int_field("Target Count", variant.intent.target_count, 1, 8, func(next_value: int) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "target_count", next_value, is_reactive):
			_render_all()
	))
	intent_section.add_child(_build_bool_field("Allow Repeat Targets", variant.intent.allow_repeat_targets, func(next_value: bool) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "allow_repeat_targets", next_value, is_reactive):
			_render_all()
	))
	return panel

func _render_condition_entries(parent: VBoxContainer, entries: Array[Dictionary], on_set_entries: Callable) -> void:
	var validator_options: Array[Dictionary] = _supported_condition_options()
	for entry_index: int in range(entries.size()):
		var entry: Dictionary = entries[entry_index]
		if entry.keys().is_empty():
			continue
		var token: String = str(entry.keys()[0])
		var values: Dictionary = entry[token]
		var panel := PanelContainer.new()
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		panel.add_child(margin)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		margin.add_child(box)
		var header := HBoxContainer.new()
		var option := OptionButton.new()
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_populate_option_button(option, validator_options, token)
		option.item_selected.connect(func(_selected: int) -> void:
			var next_entries: Array[Dictionary] = entries.duplicate(true)
			next_entries[entry_index] = service.create_validator_entry(str(_get_option_value(option)))
			on_set_entries.call(next_entries)
		)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func() -> void:
			var next_entries: Array[Dictionary] = entries.duplicate(true)
			next_entries.remove_at(entry_index)
			on_set_entries.call(next_entries)
		)
		header.add_child(option)
		header.add_child(remove_button)
		box.add_child(header)
		var metadata: Dictionary = service.get_validator_metadata(token)
		for parameter_data: Dictionary in metadata.get("parameters", []):
			var parameter_name: String = str(parameter_data.get("name", ""))
			box.add_child(_build_metadata_parameter_editor(
				parameter_name,
				values.get(parameter_name, parameter_data.get("default_value", null)),
				parameter_data,
				func(next_value: Variant) -> void:
					var next_entries: Array[Dictionary] = entries.duplicate(true)
					var next_values: Dictionary = values.duplicate(true)
					next_values[parameter_name] = next_value
					next_entries[entry_index] = {token: next_values}
					on_set_entries.call(next_entries)
			))
		parent.add_child(panel)
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var add_option := OptionButton.new()
	add_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(add_option, validator_options)
	var add_button := Button.new()
	add_button.text = "Add Condition"
	add_button.button_up.connect(func() -> void:
		var token: Variant = _get_option_value(add_option)
		if token == null:
			return
		var next_entries: Array[Dictionary] = entries.duplicate(true)
		next_entries.append(service.create_validator_entry(str(token)))
		on_set_entries.call(next_entries)
	)
	add_row.add_child(add_option)
	add_row.add_child(add_button)
	parent.add_child(add_row)

func _render_action_entries(parent: VBoxContainer, entries: Array[Dictionary], context: String, on_set_entries: Callable) -> void:
	var action_options: Array[Dictionary] = _action_options(context)
	for entry_index: int in range(entries.size()):
		var entry: Dictionary = entries[entry_index]
		if entry.keys().is_empty():
			continue
		var token: String = str(entry.keys()[0])
		var values: Dictionary = entry[token]
		var panel := PanelContainer.new()
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		panel.add_child(margin)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		margin.add_child(box)
		var header := HBoxContainer.new()
		var option := OptionButton.new()
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_populate_option_button(option, action_options, token)
		option.item_selected.connect(func(_selected: int) -> void:
			var next_entries: Array[Dictionary] = entries.duplicate(true)
			next_entries[entry_index] = service.create_action_entry(str(_get_option_value(option)))
			on_set_entries.call(next_entries)
		)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func() -> void:
			var next_entries: Array[Dictionary] = entries.duplicate(true)
			next_entries.remove_at(entry_index)
			on_set_entries.call(next_entries)
		)
		header.add_child(option)
		header.add_child(remove_button)
		box.add_child(header)
		var metadata: Dictionary = service.get_action_metadata(token)
		for parameter_data: Dictionary in metadata.get("parameters", []):
			var parameter_name: String = str(parameter_data.get("name", ""))
			box.add_child(_build_metadata_parameter_editor(
				parameter_name,
				values.get(parameter_name, parameter_data.get("default_value", null)),
				parameter_data,
				func(next_value: Variant) -> void:
					var next_entries: Array[Dictionary] = entries.duplicate(true)
					var next_values: Dictionary = values.duplicate(true)
					next_values[parameter_name] = next_value
					next_entries[entry_index] = {token: next_values}
					on_set_entries.call(next_entries)
			))
		parent.add_child(panel)
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var add_option := OptionButton.new()
	add_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(add_option, action_options)
	var add_button := Button.new()
	add_button.text = "Add Action"
	add_button.button_up.connect(func() -> void:
		var token: Variant = _get_option_value(add_option)
		if token == null:
			return
		var next_entries: Array[Dictionary] = entries.duplicate(true)
		next_entries.append(service.create_action_entry(str(token)))
		on_set_entries.call(next_entries)
	)
	add_row.add_child(add_option)
	add_row.add_child(add_button)
	parent.add_child(add_row)

func _build_top_level_override_row(override_index: int, property_name: String, property_value: Variant, definitions: Dictionary[String, Dictionary]) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(option, _field_definition_options(definitions), property_name)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func() -> void:
		if service.erase_difficulty_top_level_override(current_session, override_index, property_name):
			_render_all()
	)
	header.add_child(option)
	header.add_child(remove_button)
	row.add_child(header)
	var definition: Dictionary = definitions.get(property_name, {})
	option.item_selected.connect(func(_selected: int) -> void:
		var next_property: String = str(_get_option_value(option))
		if next_property == property_name:
			return
		service.erase_difficulty_top_level_override(current_session, override_index, property_name)
		service.set_difficulty_top_level_override(current_session, override_index, next_property, _default_value_for_definition(definitions.get(next_property, {})))
		_render_all()
	)
	row.add_child(_build_metadata_parameter_editor(
		property_name,
		property_value,
		_definition_to_parameter_data(property_name, definition),
		func(next_value: Variant) -> void:
			if service.set_difficulty_top_level_override(current_session, override_index, property_name, next_value):
				_render_all()
	))
	return row

func _build_metadata_parameter_editor(parameter_name: String, current_value: Variant, parameter_data: Dictionary, on_change: Callable) -> Control:
	var value_type: String = str(parameter_data.get("value_type", "variant"))
	var label: String = str(parameter_data.get("label", parameter_name))
	match value_type:
		"bool":
			return _build_bool_field(label, bool(current_value), func(next_value: bool) -> void: on_change.call(next_value))
		"int":
			return _build_int_field(label, int(current_value), -9999, 9999, func(next_value: int) -> void: on_change.call(next_value))
		"float":
			return _build_float_field(label, float(current_value), -9999.0, 9999.0, func(next_value: float) -> void: on_change.call(next_value))
		"enum":
			return _build_option_field(label, _normalize_enum_options(parameter_data.get("options", [])), current_value, func(next_value: Variant) -> void: on_change.call(next_value))
		"string_array":
			var string_values: Array[String] = []
			if current_value is Array:
				for item: Variant in current_value:
					string_values.append(str(item))
			return _build_string_field(label, ", ".join(string_values), func(next_value: String) -> void:
				on_change.call(_parse_csv_array(next_value))
			)
		"array":
			return _build_string_field(label, JSON.stringify(current_value), func(next_value: String) -> void:
				on_change.call(_parse_json_variant(next_value, []))
			)
		"dictionary":
			return _build_string_field(label, JSON.stringify(current_value), func(next_value: String) -> void:
				on_change.call(_parse_json_variant(next_value, {}))
			)
		"multiline_string":
			return _build_multiline_field(label, str(current_value), func(next_value: String) -> void: on_change.call(next_value))
		"resource_path", "string", "variant", _:
			return _build_string_field(label, str(current_value), func(next_value: String) -> void: on_change.call(next_value))

func _build_string_field(label_text: String, value: String, on_commit: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(_make_inline_title(label_text))
	var line_edit := LineEdit.new()
	line_edit.text = value
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text_submitted.connect(func(next_text: String) -> void:
		on_commit.call(next_text)
	)
	row.add_child(line_edit)
	return row

func _build_multiline_field(label_text: String, value: String, on_commit: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(_make_inline_title(label_text))
	var text_edit := TextEdit.new()
	text_edit.custom_minimum_size = Vector2(0, 84)
	text_edit.text = value
	row.add_child(text_edit)
	return row

func _build_int_field(label_text: String, value: int, min_value: int, max_value: int, on_change: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(_make_inline_title(label_text))
	var spin_box := SpinBox.new()
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = 1
	spin_box.rounded = true
	spin_box.value = value
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_box.custom_minimum_size = Vector2(132, 0)
	spin_box.add_theme_constant_override("buttons_width", 24)
	_style_spin_box(spin_box)
	spin_box.value_changed.connect(func(next_value: float) -> void:
		on_change.call(int(next_value))
	)
	row.add_child(spin_box)
	return row

func _build_float_field(label_text: String, value: float, min_value: float, max_value: float, on_change: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(_make_inline_title(label_text))
	var spin_box := SpinBox.new()
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = 0.1
	spin_box.value = value
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_box.custom_minimum_size = Vector2(132, 0)
	spin_box.add_theme_constant_override("buttons_width", 24)
	_style_spin_box(spin_box)
	spin_box.value_changed.connect(func(next_value: float) -> void:
		on_change.call(next_value)
	)
	row.add_child(spin_box)
	return row

func _build_bool_field(label_text: String, value: bool, on_change: Callable) -> Control:
	var check_box := CheckBox.new()
	check_box.text = label_text
	check_box.button_pressed = value
	check_box.toggled.connect(func(next_value: bool) -> void:
		on_change.call(next_value)
	)
	return check_box

func _build_option_field(label_text: String, options: Array[Dictionary], current_value: Variant, on_change: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(_make_inline_title(label_text))
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(option, options, current_value)
	option.item_selected.connect(func(_selected: int) -> void:
		on_change.call(_get_option_value(option))
	)
	row.add_child(option)
	return row

func _build_status_csv_field(label_text: String, value: String, on_change: Callable) -> Control:
	return _build_string_field(label_text, value, func(next_text: String) -> void:
		on_change.call(_parse_status_csv(next_text))
	)

func _render_status_dictionary_editor(parent: VBoxContainer, values: Dictionary[String, int], on_change: Callable) -> void:
	var sorted_status_ids: Array[String] = []
	sorted_status_ids.assign(values.keys())
	sorted_status_ids.sort()
	for status_id: String in sorted_status_ids:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var option := OptionButton.new()
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_populate_option_button(option, _available_status_options(values, status_id), status_id)
		option.item_selected.connect(func(_selected: int) -> void:
			var next_status_id: String = str(_get_option_value(option))
			if next_status_id == "" or next_status_id == status_id:
				return
			var next_values: Dictionary[String, int] = values.duplicate(true)
			var charge_amount: int = int(next_values.get(status_id, 0))
			next_values.erase(status_id)
			next_values[next_status_id] = charge_amount
			on_change.call(next_values)
		)
		var amount := SpinBox.new()
		amount.min_value = -999
		amount.max_value = 999
		amount.step = 1
		amount.rounded = true
		amount.value = int(values.get(status_id, 0))
		amount.custom_minimum_size = Vector2(110, 0)
		amount.add_theme_constant_override("buttons_width", 24)
		_style_spin_box(amount)
		amount.value_changed.connect(func(next_value: float) -> void:
			var next_values: Dictionary[String, int] = values.duplicate(true)
			next_values[status_id] = int(next_value)
			on_change.call(next_values)
		)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func() -> void:
			var next_values: Dictionary[String, int] = values.duplicate(true)
			next_values.erase(status_id)
			on_change.call(next_values)
		)
		row.add_child(option)
		row.add_child(amount)
		row.add_child(remove_button)
		parent.add_child(row)
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var add_option := OptionButton.new()
	add_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_option_button(add_option, _available_status_options(values))
	var add_button := Button.new()
	add_button.text = "Add Status"
	add_button.button_up.connect(func() -> void:
		var next_status_id: String = str(_get_option_value(add_option))
		if next_status_id == "":
			return
		var next_values: Dictionary[String, int] = values.duplicate(true)
		if not next_values.has(next_status_id):
			next_values[next_status_id] = 1
			on_change.call(next_values)
	)
	add_row.add_child(add_option)
	add_row.add_child(add_button)
	parent.add_child(add_row)

func _add_section(parent: VBoxContainer, title: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", SECTION_TITLE_SIZE)
	section.add_child(label)
	parent.add_child(section)
	return section

func _make_inline_title(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	return label

func _make_note_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _update_stats() -> void:
	var diagnostics: Array = [] if current_session == null else current_session.diagnostics
	var error_count: int = 0
	var warning_count: int = 0
	for diagnostic: Dictionary in diagnostics:
		match str(diagnostic.get("severity", "")):
			"error":
				error_count += 1
			"warning":
				warning_count += 1
	stats_label.text = "Library: %s | Visible: %s | Base stages: %s | Reactive: %s | Errors: %s | Warnings: %s" % [
		library_entries.size(),
		filtered_entries.size(),
		0 if current_session == null or current_session.working_enemy_data == null else current_session.working_enemy_data.stages.size(),
		0 if current_session == null or current_session.working_enemy_data == null else current_session.working_enemy_data.reactive_stages.size(),
		error_count,
		warning_count,
	]

func _open_library_entry(entry: Dictionary) -> void:
	var resource_path: String = str(entry.get("resource_path", ""))
	if resource_path == "":
		return
	current_session = service.load_session(resource_path)
	selected_library_path = resource_path
	_select_default_navigation_targets()
	_set_status("Loaded %s." % str(entry.get("enemy_name", entry.get("object_id", "enemy"))), "success")
	_render_all()

func _ensure_preview_defaults() -> void:
	if current_session == null or current_session.preview_state == null or current_session.working_enemy_data == null:
		return
	var state: EnemyEditorPreviewState = current_session.preview_state
	state.ensure_defaults(current_session.working_enemy_data)
	if state.player_party_members.is_empty():
		for party_index: int in range(DEFAULT_PARTY_SIZE):
			state.player_party_members.append({
				"party_member_index": party_index,
				"health": 40,
				"health_max": 40,
			})
	elif state.player_party_members.size() < DEFAULT_PARTY_SIZE:
		for party_index: int in range(state.player_party_members.size(), DEFAULT_PARTY_SIZE):
			state.player_party_members.append({
				"party_member_index": party_index,
				"health": 40,
				"health_max": 40,
			})
	for party_index: int in range(state.player_party_members.size()):
		state.player_party_members[party_index]["party_member_index"] = party_index

func _select_default_navigation_targets() -> void:
	if current_session == null or current_session.working_enemy_data == null:
		selected_base_stage_id = ""
		selected_reactive_stage_id = ""
		selected_difficulty_index = -1
		return
	var enemy_data: EnemyData = current_session.working_enemy_data
	if selected_base_stage_id != "" and enemy_data.get_stage(selected_base_stage_id) != null:
		return
	if selected_reactive_stage_id != "" and enemy_data.get_reactive_stage(selected_reactive_stage_id) != null:
		return
	if selected_difficulty_index >= 0 and selected_difficulty_index < enemy_data.difficulty_overrides.size():
		return
	selected_reactive_stage_id = ""
	selected_difficulty_index = -1
	selected_base_stage_id = enemy_data.opening_stage_id
	if selected_base_stage_id == "" and not enemy_data.stages.is_empty():
		selected_base_stage_id = enemy_data.stages[0].object_id

func _base_stage_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if current_session == null or current_session.working_enemy_data == null:
		return options
	for stage_data: EnemyStageData in current_session.working_enemy_data.stages:
		options.append({"label": "%s (%s)" % [stage_data.object_id, stage_data.label], "value": stage_data.object_id})
	return options

func _stage_id_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = _base_stage_options()
	if current_session == null or current_session.working_enemy_data == null:
		return options
	for stage_data: EnemyReactiveStageData in current_session.working_enemy_data.reactive_stages:
		options.append({"label": "%s (%s)" % [stage_data.object_id, stage_data.label], "value": stage_data.object_id})
	return options

func _supported_condition_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for metadata: Dictionary in service.list_validator_options():
		if not SUPPORTED_CONDITION_CLASSES.has(str(metadata.get("script_global_name", ""))):
			continue
		options.append({
			"label": str(metadata.get("display_name", metadata.get("resolved_token", ""))),
			"value": str(metadata.get("resolved_token", metadata.get("token_or_path", ""))),
		})
	return options

func _action_options(context: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for metadata: Dictionary in service.list_action_options(context):
		options.append({
			"label": str(metadata.get("display_name", metadata.get("resolved_token", ""))),
			"value": str(metadata.get("resolved_token", metadata.get("token_or_path", ""))),
		})
	return options

func _field_definition_options(definitions: Dictionary[String, Dictionary]) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for field_name: String in definitions.keys():
		options.append({
			"label": str(definitions[field_name].get("label", field_name)),
			"value": field_name,
		})
	options.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left.get("label", "")) < str(right.get("label", ""))
	)
	return options

func _definition_to_parameter_data(parameter_name: String, definition: Dictionary) -> Dictionary:
	var parameter_data: Dictionary = definition.duplicate(true)
	parameter_data["name"] = parameter_name
	return parameter_data

func _default_value_for_definition(definition: Dictionary) -> Variant:
	match str(definition.get("value_type", "variant")):
		"bool":
			return false
		"int":
			return 0
		"enum":
			var options: Array = definition.get("options", [])
			if options.is_empty():
				return null
			var option_entry: Variant = options[0]
			if option_entry is Dictionary:
				return option_entry.get("value", null)
			return option_entry
		"string", "resource_path", _:
			return ""

func _normalize_enum_options(options: Array) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	for option_entry: Variant in options:
		if option_entry is Dictionary:
			normalized.append({
				"label": str(option_entry.get("label", option_entry.get("value", ""))),
				"value": option_entry.get("value", null),
			})
		else:
			normalized.append({"label": str(option_entry), "value": option_entry})
	return normalized

func _prepend_none(options: Array[Dictionary], label: String) -> Array[Dictionary]:
	var merged: Array[Dictionary] = [{"label": label, "value": ""}]
	merged.append_array(options)
	return merged

func _ally_count_summary(entries: Array[Dictionary]) -> Dictionary:
	var living_allies: int = 0
	var living_minions: int = 0
	for entry: Dictionary in entries:
		if not bool(entry.get("alive", true)):
			continue
		living_allies += 1
		if bool(entry.get("enemy_is_minion", false)):
			living_minions += 1
	return {
		"living_allies": living_allies,
		"living_minions": living_minions,
	}

func _build_ally_state_array(living_allies: int, living_minions: int) -> Array[Dictionary]:
	var ally_entries: Array[Dictionary] = []
	var clamped_allies: int = max(0, living_allies)
	var clamped_minions: int = clamp(living_minions, 0, clamped_allies)
	for ally_index: int in range(clamped_allies):
		ally_entries.append({
			"alive": true,
			"enemy_is_minion": ally_index < clamped_minions,
		})
	return ally_entries

func _parse_csv_array(raw_text: String) -> Array[String]:
	var values: Array[String] = []
	for segment: String in raw_text.split(","):
		var trimmed: String = segment.strip_edges()
		if trimmed != "":
			values.append(trimmed)
	return values

func _parse_json_variant(raw_text: String, fallback: Variant) -> Variant:
	var parsed: Variant = JSON.parse_string(raw_text)
	return fallback if parsed == null else parsed

func _parse_status_csv(raw_text: String) -> Dictionary[String, int]:
	var values: Dictionary[String, int] = {}
	for segment: String in raw_text.split(","):
		var trimmed: String = segment.strip_edges()
		if trimmed == "":
			continue
		var parts: PackedStringArray = trimmed.split(":")
		if parts.size() != 2:
			continue
		values[parts[0].strip_edges()] = parts[1].strip_edges().to_int()
	return values

func _status_dictionary_to_csv(values: Dictionary[String, int]) -> String:
	var parts: Array[String] = []
	for status_id: String in values.keys():
		parts.append("%s:%s" % [status_id, values[status_id]])
	parts.sort()
	return ", ".join(parts)

func _mark_session_dirty_only() -> void:
	if current_session == null:
		return
	current_session.recompute_managed_paths()
	current_session.mark_dirty()
	current_session.refresh_diagnostics(service)
	_render_all()

func _populate_option_button(option_button: OptionButton, options: Array[Dictionary], preferred_value: Variant = null) -> void:
	var current_value: Variant = preferred_value if preferred_value != null else _get_option_value(option_button)
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

func _get_option_value(option_button: OptionButton) -> Variant:
	var selected_index: int = option_button.get_selected()
	if selected_index < 0:
		return null
	return option_button.get_item_metadata(selected_index)

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()

func _apply_compact_font_sizes(root: Node) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		_apply_compact_font_sizes(child)
	if not (root is Control):
		return
	var control: Control = root as Control
	if not control.has_theme_font_size_override("font_size"):
		control.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	if control is RichTextLabel:
		var rich_text: RichTextLabel = control as RichTextLabel
		rich_text.add_theme_font_size_override("normal_font_size", BODY_FONT_SIZE)
		rich_text.add_theme_font_size_override("bold_font_size", BODY_FONT_SIZE)
		rich_text.add_theme_font_size_override("italic_font_size", BODY_FONT_SIZE)
		rich_text.add_theme_font_size_override("mono_font_size", BODY_FONT_SIZE)
		return
	if control is TextEdit and not control.has_theme_font_size_override("font_size"):
		control.add_theme_font_size_override("font_size", BODY_FONT_SIZE)

func _apply_control_padding(root: Node) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		_apply_control_padding(child)
	if not (root is Control):
		return
	var control: Control = root as Control
	if control is OptionButton:
		_apply_stylebox_padding(control, ["normal", "hover", "pressed", "disabled", "focus"], CONTROL_PAD_X, CONTROL_PAD_Y)
	elif control is LineEdit:
		_apply_stylebox_padding(control, ["normal", "focus", "read_only"], CONTROL_PAD_X, CONTROL_PAD_Y)
	elif control is TextEdit:
		_apply_stylebox_padding(control, ["normal", "focus"], CONTROL_PAD_X, CONTROL_PAD_Y)
	elif control is SpinBox:
		_apply_stylebox_padding(control, ["normal", "focus"], CONTROL_PAD_X, CONTROL_PAD_Y)
		(control as SpinBox).add_theme_constant_override("buttons_width", 22)
		_style_spin_box(control as SpinBox)

func _apply_stylebox_padding(control: Control, stylebox_names: Array[String], horizontal_padding: int, vertical_padding: int) -> void:
	for stylebox_name: String in stylebox_names:
		var stylebox: StyleBox = control.get_theme_stylebox(stylebox_name)
		if stylebox == null:
			continue
		var padded_stylebox: StyleBox = stylebox.duplicate()
		_apply_stylebox_content_padding(padded_stylebox, horizontal_padding, vertical_padding)
		control.add_theme_stylebox_override(stylebox_name, padded_stylebox)

func _apply_stylebox_content_padding(stylebox: StyleBox, horizontal_padding: int, vertical_padding: int) -> void:
	if stylebox is StyleBoxFlat:
		var flat: StyleBoxFlat = stylebox as StyleBoxFlat
		flat.content_margin_left = max(flat.content_margin_left, horizontal_padding)
		flat.content_margin_right = max(flat.content_margin_right, horizontal_padding)
		flat.content_margin_top = max(flat.content_margin_top, vertical_padding)
		flat.content_margin_bottom = max(flat.content_margin_bottom, vertical_padding)
	elif stylebox is StyleBoxTexture:
		var textured: StyleBoxTexture = stylebox as StyleBoxTexture
		textured.content_margin_left = max(textured.content_margin_left, horizontal_padding)
		textured.content_margin_right = max(textured.content_margin_right, horizontal_padding)
		textured.content_margin_top = max(textured.content_margin_top, vertical_padding)
		textured.content_margin_bottom = max(textured.content_margin_bottom, vertical_padding)

func _style_spin_box(spin_box: SpinBox) -> void:
	if spin_box == null:
		return
	spin_box.add_theme_constant_override("buttons_width", 24)
	var line_edit: LineEdit = spin_box.get_line_edit()
	if line_edit == null:
		return
	line_edit.custom_minimum_size = Vector2(84, 0)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_stylebox_padding(line_edit, ["normal", "focus", "read_only"], CONTROL_PAD_X, CONTROL_PAD_Y)

func _setup_editor_theme() -> void:
	if theme == null:
		return
	editor_theme = theme.duplicate(true)
	theme = editor_theme
	editor_theme.set_font_size("font_size", "Label", BODY_FONT_SIZE)
	editor_theme.set_font_size("font_size", "TooltipLabel", BODY_FONT_SIZE)
	editor_theme.set_font_size("font_size", "PopupMenu", BODY_FONT_SIZE)
	editor_theme.set_font_size("normal_font_size", "RichTextLabel", BODY_FONT_SIZE)
	editor_theme.set_font_size("bold_font_size", "RichTextLabel", BODY_FONT_SIZE)
	editor_theme.set_font_size("italic_font_size", "RichTextLabel", BODY_FONT_SIZE)
	editor_theme.set_font_size("mono_font_size", "RichTextLabel", BODY_FONT_SIZE)

func _available_status_options(existing_values: Dictionary[String, int], include_current: String = "") -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var status_ids: Array[String] = []
	status_ids.assign(Global._id_to_status_data.keys())
	status_ids.sort()
	for status_id: String in status_ids:
		if status_id != include_current and existing_values.has(status_id):
			continue
		var status_data: StatusEffectData = Global.get_status_effect_data(status_id)
		var label: String = status_id
		if status_data != null and status_data.status_effect_name.strip_edges() != "":
			label = "%s (%s)" % [status_data.status_effect_name, status_id]
		options.append({"label": label, "value": status_id})
	if options.is_empty():
		options.append({"label": "No statuses available", "value": ""})
	return options

func _set_status(message: String, severity: String) -> void:
	status_label.text = message
	match severity:
		"error":
			status_label.modulate = Color(0.95, 0.70, 0.70, 1.0)
		"success":
			status_label.modulate = Color(0.76, 0.92, 0.78, 1.0)
		_:
			status_label.modulate = Color(0.83, 0.88, 0.95, 1.0)

func _on_apply_preview_execution_result() -> void:
	if current_session == null or not bool(last_preview_result.get("success", false)):
		return
	var state: EnemyEditorPreviewState = current_session.preview_state
	var base_stage_id: String = str(last_preview_result.get("active_base_stage_id", ""))
	state.previous_executed_stage_id = str(last_preview_result.get("active_stage_id", ""))
	state.planned_stage_id = str(last_preview_result.get("next_planned_stage_id_after_execution", state.planned_stage_id))
	state.turn_count += 1
	state.planned_stage_started_turn_count = state.turn_count
	if base_stage_id != "":
		var current_count: int = state.stage_id_to_execution_count.get(base_stage_id, 0)
		state.stage_id_to_execution_count[base_stage_id] = current_count + 1
	state.cached_random_target_signature = ""
	state.cached_random_target_party_member_indices.clear()
	_render_all()

func _on_back_button_up() -> void:
	if not _is_embedded_in_title_screen():
		return
	visible = false
	title_screen.show_codex_menu()

func _on_new_button_up() -> void:
	current_session = service.create_blank_session()
	selected_library_path = ""
	_select_default_navigation_targets()
	_set_status("Started a fresh triage enemy draft.", "success")
	_render_all()

func _on_duplicate_button_up() -> void:
	if current_session == null:
		return
	current_session = service.duplicate_session(current_session)
	selected_library_path = ""
	_select_default_navigation_targets()
	_set_status("Duplicated the current enemy into a new triage session.", "success")
	_render_all()

func _on_save_triage_button_up() -> void:
	if current_session == null:
		return
	var result: Dictionary = service.save_session_to_triage(current_session)
	_handle_save_result(result, "Saved to triage")

func _on_promote_button_up() -> void:
	if current_session == null:
		return
	var result: Dictionary = service.promote_session_to_content(current_session)
	_handle_save_result(result, "Promoted to content")

func _handle_save_result(result: Dictionary, success_prefix: String) -> void:
	if bool(result.get("success", false)):
		selected_library_path = str(result.get("path", ""))
		_set_status("%s at %s" % [success_prefix, selected_library_path], "success")
		_refresh_library()
		_render_all()
		return
	var diagnostics: Array = result.get("diagnostics", [])
	var error_count: int = 0
	for diagnostic: Dictionary in diagnostics:
		if str(diagnostic.get("severity", "")) == "error":
			error_count += 1
	_set_status("Save blocked by %s error(s). Review the validation panel." % error_count, "error")
	_render_all()

func _on_search_changed(_text: String) -> void:
	_apply_library_filters()

func _on_filter_changed(_index: int) -> void:
	_apply_library_filters()

func _is_embedded_in_title_screen() -> bool:
	return title_screen != null and title_screen.has_method("show_codex_menu")
