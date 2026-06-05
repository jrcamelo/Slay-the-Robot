@tool
extends Control
class_name EnemyEditorScreen

const DEFAULT_PC_HEALTHS := [100, 50, 25]
const SECTION_TITLE_SIZE := 18
const BODY_FONT_SIZE := 15
const CONTROL_PAD_X := 12
const CONTROL_PAD_Y := 7
const TWO_COLUMN_MIN_WIDTH := 720.0
const SIMULATION_TOP_MARGIN := 12.0
const SIMULATION_SIDE_MARGIN := 18.0
const SIMULATION_VERTICAL_GAP := 14.0
const ENEMY_VERTICAL_OFFSET := -192.0
const ENEMY_HORIZONTAL_RATIO := 0.62
const ENEMY_CONTENT_VERTICAL_OFFSET := -52.0
const ENEMY_CONTAINER_FALLBACK_SIZE := Vector2(608, 192)
const PARTY_CONTAINER_FALLBACK_SIZE := Vector2(480, 160)

@onready var title_screen: Control = get_parent() as Control
@onready var header: Control = $MainMargin/RootVBox/Header
@onready var body_split: Control = $MainMargin/RootVBox/BodySplit
@onready var right_panel: Control = $MainMargin/RootVBox/BodySplit/WorkspaceSplit/RightPanel
@onready var status_label: Label = $MainMargin/RootVBox/Header/StatusLabel
@onready var stats_label: Label = $MainMargin/RootVBox/Header/StatsLabel
@onready var back_button: Button = $MainMargin/RootVBox/Header/ButtonRow/BackButton
@onready var new_button: Button = $MainMargin/RootVBox/Header/ButtonRow/NewButton
@onready var duplicate_button: Button = $MainMargin/RootVBox/Header/ButtonRow/DuplicateButton
@onready var save_triage_button: Button = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/SaveButtonColumn/PanelSaveTriageButton
@onready var promote_button: Button = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/SaveButtonColumn/PanelPromoteButton
@onready var search_input: LineEdit = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/SearchInput
@onready var source_filter: OptionButton = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/FilterRow/SourceFilter
@onready var type_filter: OptionButton = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/FilterRow/TypeFilter
@onready var minion_filter: OptionButton = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/FilterRow/MinionFilter
@onready var library_list: VBoxContainer = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/LibraryScroll/LibraryList
@onready var navigator_content: VBoxContainer = $MainMargin/RootVBox/BodySplit/LeftPanel/LeftMargin/LeftVBox/NavigatorScroll/NavigatorContent
@onready var editor_content: VBoxContainer = $MainMargin/RootVBox/BodySplit/WorkspaceSplit/CenterPanel/CenterMargin/CenterScroll/EditorContent
@onready var preview_content: VBoxContainer = $MainMargin/RootVBox/BodySplit/WorkspaceSplit/RightPanel/RightMargin/RightScroll/PreviewContent
@onready var party_container: PlayerPartyContainer = $PartyContainer
@onready var party_auto_container: HBoxContainer = $PartyContainer/AutomaticPartyContainer
@onready var enemy_container: Control = $EnemyContainer
@onready var auto_enemy_container: HBoxContainer = $EnemyContainer/AutomaticEnemyContainer
@onready var positional_enemy_container: Control = $EnemyContainer/PositionalEnemyContainer

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
var last_left_layout_columns: int = 1
var last_editor_layout_columns: int = 1
var last_preview_layout_columns: int = 1
var draft_sessions_by_resource_path: Dictionary[String, EnemyEditorSession] = {}
var simulation_player_data: PlayerData = null
var original_global_player_data: PlayerData = null
var original_global_is_run: bool = false
var simulation_context_active: bool = false

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
	navigator_content.resized.connect(_on_form_layout_resized)
	editor_content.resized.connect(_on_form_layout_resized)
	preview_content.resized.connect(_on_form_layout_resized)
	body_split.resized.connect(_layout_battle_simulation_containers)
	right_panel.resized.connect(_layout_battle_simulation_containers)
	_populate_filters()
	_apply_compact_font_sizes(self)
	if not _is_embedded_in_title_screen():
		show_editor()

func _exit_tree() -> void:
	_end_simulation_context()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_end_simulation_context()
	elif what == NOTIFICATION_RESIZED:
		_layout_battle_simulation_containers()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		return
	if focus_owner.get_global_rect().has_point(mouse_event.global_position):
		return
	focus_owner.release_focus()

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
	var type_options: Array[Dictionary] = [{"label": "All Types", "value": "all"}]
	for type_option: Dictionary in EnemyEditorSchema.enemy_type_options():
		var type_value: int = int(type_option.get("value", EnemyData.ENEMY_TYPES.STANDARD))
		var type_label: String = str(type_option.get("label", type_value))
		type_options.append({"label": type_label, "value": _enemy_role_value(type_value, false)})
		type_options.append({"label": "%s Minion" % type_label, "value": _enemy_role_value(type_value, true)})
	_populate_option_button(type_filter, type_options)
	minion_filter.visible = false

func _refresh_library() -> void:
	library_entries = service.list_library_enemies()
	_apply_library_filters()

func _apply_library_filters() -> void:
	var filters: Dictionary = {}
	var source_value: Variant = _get_option_value(source_filter)
	if source_value != null and source_value != "all":
		filters["source_bucket"] = source_value
	var type_value: Variant = _get_option_value(type_filter)
	if type_value != null and str(type_value) != "all":
		var role_data: Dictionary = _decode_enemy_role_value(type_value)
		filters["enemy_type"] = int(role_data.get("enemy_type", EnemyData.ENEMY_TYPES.STANDARD))
		filters["enemy_is_minion"] = bool(role_data.get("enemy_is_minion", false))
	filtered_entries = service.filter_library_enemies(library_entries, filters, search_input.text)
	_render_library()
	_update_stats()

func _render_all() -> void:
	_ensure_preview_defaults()
	_select_default_navigation_targets()
	_cache_current_session_if_needed()
	last_preview_result = service.resolve_preview(current_session)
	last_left_layout_columns = _resolved_form_columns(navigator_content)
	last_editor_layout_columns = _resolved_form_columns(editor_content)
	last_preview_layout_columns = _resolved_form_columns(preview_content)
	_render_library()
	_render_navigator()
	_render_editor()
	_render_preview()
	_refresh_battle_simulation()
	_update_stats()
	_apply_compact_font_sizes(self)
	_apply_control_padding(self)
	duplicate_button.disabled = current_session == null
	_update_save_buttons()

func _render_library() -> void:
	_clear_children(library_list)
	if filtered_entries.is_empty():
		library_list.add_child(_make_note_label("No enemies matched the current filters."))
		return
	for entry: Dictionary in filtered_entries:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var padding := MarginContainer.new()
		padding.add_theme_constant_override("margin_left", 12)
		padding.add_theme_constant_override("margin_top", 10)
		padding.add_theme_constant_override("margin_right", 12)
		padding.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(padding)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		padding.add_child(row)
		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.add_theme_constant_override("separation", 4)
		text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text_box)
		var title := Label.new()
		title.text = str(entry.get("enemy_name", entry.get("object_id", "Enemy")))
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.add_child(title)
		var meta := Label.new()
		meta.text = "%s | %s | %s stage(s), %s reactive" % [
			str(entry.get("object_id", "")),
			str(entry.get("source_bucket", "")),
			int(entry.get("stage_count", 0)),
			int(entry.get("reactive_stage_count", 0)),
		]
		meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.add_child(meta)
		var thumbnail := TextureRect.new()
		thumbnail.custom_minimum_size = Vector2(72, 72)
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumbnail.texture = _load_library_entry_texture(str(entry.get("resource_path", "")))
		row.add_child(thumbnail)
		panel.tooltip_text = str(entry.get("resource_path", ""))
		panel.custom_minimum_size = Vector2(0, 84)
		var is_selected: bool = str(entry.get("resource_path", "")) == selected_library_path
		panel.modulate = Color(1.0, 0.95, 0.8, 1.0) if is_selected else Color(1, 1, 1, 1)
		panel.gui_input.connect(func(event: InputEvent) -> void:
			if is_selected:
				return
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_open_library_entry(entry)
		)
		library_list.add_child(panel)

func _render_navigator() -> void:
	_clear_children(navigator_content)
	if current_session == null or current_session.working_enemy_data == null:
		navigator_content.add_child(_make_note_label("No active enemy session."))
		return
	_render_enemy_profile_section(navigator_content)

func _render_editor() -> void:
	_clear_children(editor_content)
	if current_session == null or current_session.working_enemy_data == null:
		editor_content.add_child(_make_note_label("No active enemy session."))
		return
	_render_stage_navigator(editor_content)
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

func _render_stage_navigator(parent: VBoxContainer) -> void:
	var root_section := _add_section(parent, "Stage and Intent Editor")
	root_section.add_child(_build_option_field("Opening Stage", _base_stage_options(), current_session.working_enemy_data.opening_stage_id, func(next_value: Variant) -> void:
		if service.set_enemy_property(current_session, "opening_stage_id", str(next_value)):
			selected_base_stage_id = str(next_value)
			_render_all()
	))
	var stages_section := _add_section(root_section, "Base Stages")
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
	var reactive_section := _add_section(root_section, "Reactive Stages")
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
	for stage_data: EnemyReactiveStageData in reactive_stages:
		reactive_section.add_child(_build_reactive_nav_row(stage_data))
	var difficulty_section := _add_section(root_section, "Difficulty")
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

func _render_preview() -> void:
	_clear_children(preview_content)
	if current_session == null:
		preview_content.add_child(_make_note_label("No preview available."))
		return
	_render_preview_controls(preview_content)
	_render_preview_results(preview_content)
	_render_diagnostics(preview_content)

func _refresh_battle_simulation() -> void:
	if not visible or current_session == null or current_session.working_enemy_data == null:
		_clear_battle_simulation()
		return
	_begin_simulation_context()
	_sync_simulation_player_data()
	_clear_battle_simulation()
	party_container.populate_party_members()
	var enemy: Enemy = _spawn_simulation_enemy()
	if enemy == null:
		return
	for player: Player in party_container.get_party_players():
		player.update_incoming_damage_amount(false)
	_layout_battle_simulation_containers()

func _begin_simulation_context() -> void:
	if simulation_context_active:
		Global.player_data = simulation_player_data
		Global.is_run = true
		return
	original_global_player_data = Global.player_data
	original_global_is_run = Global.is_run
	if simulation_player_data == null:
		simulation_player_data = _create_simulation_player_data()
	Global.player_data = simulation_player_data
	Global.is_run = true
	simulation_context_active = true

func _end_simulation_context() -> void:
	if not simulation_context_active:
		return
	_clear_battle_simulation()
	if simulation_player_data != null and simulation_player_data.player_current_combat_stats != null:
		simulation_player_data.player_current_combat_stats._disconnect_signals()
	Global.player_data = original_global_player_data
	Global.is_run = original_global_is_run
	original_global_player_data = null
	simulation_context_active = false
	simulation_player_data = null

func _create_simulation_player_data() -> PlayerData:
	var player_data: PlayerData = Global.get_player_data_from_prototype("player_red")
	player_data.player_party_members.clear()
	player_data.player_draw.clear()
	player_data.player_discard.clear()
	player_data.player_hand.clear()
	player_data.player_exhaust.clear()
	player_data.player_deck.clear()
	player_data.player_run_modifier_object_ids.clear()
	player_data.player_barrier = 0
	player_data.player_block = 0
	player_data.player_energy = 0
	player_data.player_current_combat_stats = CombatStatsData.new("enemy_editor_preview")
	return player_data

func _sync_simulation_player_data() -> void:
	var state: EnemyEditorPreviewState = current_session.preview_state
	if simulation_player_data == null:
		simulation_player_data = _create_simulation_player_data()
	var player_data: PlayerData = simulation_player_data
	player_data.player_run_seed = max(1, state.random_seed)
	player_data.player_rng.clear()
	player_data.player_energy = max(0, state.player_energy)
	player_data.player_barrier = 0
	player_data.player_block = 0
	player_data.player_run_modifier_object_ids.clear()
	player_data.location_id_to_location_data.clear()
	var location_data := LocationData.new()
	location_data.location_id = "enemy_editor_preview"
	location_data.location_type = LocationData.LOCATION_TYPES.COMBAT
	player_data.location_id_to_location_data[location_data.location_id] = location_data
	player_data.player_location_id = location_data.location_id
	if player_data.player_current_combat_stats == null:
		player_data.player_current_combat_stats = CombatStatsData.new("enemy_editor_preview")
	player_data.player_current_combat_stats.turn_count = max(1, state.turn_count)
	player_data.player_current_combat_stats.is_player_turn = true
	player_data.player_current_combat_stats.cards_played_this_turn.clear()
	player_data.player_current_combat_stats.cards_played_this_combat.clear()
	var character_ids: Array[String] = _simulation_character_ids()
	player_data.player_party_members.clear()
	for party_index: int in range(DEFAULT_PC_HEALTHS.size()):
		var preview_member: Dictionary = state.player_party_members[party_index]
		var party_member := PartyMemberData.new()
		party_member.party_member_party_index = party_index
		party_member.party_member_character_object_id = character_ids[party_index]
		var character_data: CharacterData = Global.get_character_data(character_ids[party_index])
		party_member.party_member_name = character_data.character_name if character_data != null else "PC %s" % str(party_index + 1)
		party_member.party_member_health_max = 100
		party_member.party_member_health = clampi(int(preview_member.get("health", DEFAULT_PC_HEALTHS[party_index])), 0, 100)
		player_data.player_party_members.append(party_member)
	player_data.generate_cache()
	player_data.synchronize_legacy_primary_member_state()
	Global.player_data = player_data

func _simulation_character_ids() -> Array[String]:
	var character_ids: Array[String] = ["character_red", "character_blue", "character_green"]
	var source_player_data: PlayerData = original_global_player_data
	if source_player_data == null:
		return character_ids
	var collected_ids: Array[String] = []
	if source_player_data.has_party_members():
		for party_member_data: PartyMemberData in source_player_data.player_party_members:
			if party_member_data == null or not party_member_data.is_active():
				continue
			if party_member_data.party_member_character_object_id == "":
				continue
			collected_ids.append(party_member_data.party_member_character_object_id)
			if collected_ids.size() >= DEFAULT_PC_HEALTHS.size():
				break
	elif source_player_data.player_character_object_id != "":
		collected_ids.append(source_player_data.player_character_object_id)
	while collected_ids.size() < DEFAULT_PC_HEALTHS.size():
		collected_ids.append(character_ids[collected_ids.size()])
	return collected_ids

func _spawn_simulation_enemy() -> Enemy:
	var enemy_data: EnemyData = current_session.working_enemy_data.duplicate(true)
	var preview_state: EnemyEditorPreviewState = current_session.preview_state
	enemy_data.apply_enemy_difficulty_modifiers_for_level(preview_state.difficulty_level)
	enemy_data.enemy_health_max = max(1, preview_state.enemy_health_max)
	enemy_data.enemy_health = clampi(preview_state.enemy_health, 0, enemy_data.enemy_health_max)
	enemy_data.enemy_poise_max = max(0, preview_state.enemy_poise_max)
	enemy_data.enemy_poise = clampi(preview_state.enemy_poise, 0, enemy_data.enemy_poise_max)
	if preview_state.enemy_type >= 0:
		enemy_data.enemy_type = preview_state.enemy_type
	enemy_data.enemy_is_minion = preview_state.enemy_is_minion
	var enemy: Enemy = Scenes.ENEMY.instantiate()
	auto_enemy_container.add_child(enemy)
	enemy.init(enemy_data)
	enemy.planned_stage_id = preview_state.planned_stage_id if preview_state.planned_stage_id != "" else enemy_data.opening_stage_id
	enemy.previous_executed_stage_id = preview_state.previous_executed_stage_id
	enemy.planned_stage_started_turn_count = max(1, preview_state.planned_stage_started_turn_count)
	enemy.stage_id_to_execution_count = preview_state.stage_id_to_execution_count.duplicate(true)
	enemy.cached_random_target_signature = preview_state.cached_random_target_signature
	enemy.cached_random_target_party_member_indices.assign(preview_state.cached_random_target_party_member_indices)
	if not preview_state.enemy_status_effects.is_empty():
		enemy.clear_all_status_effects()
		for status_id: String in preview_state.enemy_status_effects.keys():
			enemy.add_status_effect_charges(status_id, int(preview_state.enemy_status_effects[status_id]))
	enemy.update_health_bar(false)
	enemy.set_poise(enemy_data.enemy_poise, enemy_data.enemy_poise_max)
	enemy.update_enemy_intent()
	return enemy

func _clear_battle_simulation() -> void:
	if is_instance_valid(party_container):
		party_container.base_player = null
	if is_instance_valid(party_auto_container):
		_free_children_immediately(party_auto_container)
	if is_instance_valid(auto_enemy_container):
		_free_children_immediately(auto_enemy_container)
	if is_instance_valid(positional_enemy_container):
		_free_children_immediately(positional_enemy_container)

func _free_children_immediately(node: Node) -> void:
	if node == null:
		return
	for child: Node in node.get_children():
		child.free()

func _layout_battle_simulation_containers() -> void:
	if not is_instance_valid(enemy_container) or not is_instance_valid(party_container) or not visible:
		return
	var right_rect: Rect2 = right_panel.get_global_rect()
	var header_rect: Rect2 = header.get_global_rect()
	var body_rect: Rect2 = body_split.get_global_rect()
	var enemy_size: Vector2 = enemy_container.size
	if enemy_size == Vector2.ZERO:
		enemy_size = ENEMY_CONTAINER_FALLBACK_SIZE
	var enemy_scaled_size: Vector2 = enemy_size * enemy_container.scale
	var party_size: Vector2 = party_container.size
	if party_size == Vector2.ZERO:
		party_size = PARTY_CONTAINER_FALLBACK_SIZE
	var party_scaled_size: Vector2 = party_size * party_container.scale
	var party_top_y: float = body_rect.position.y - party_scaled_size.y - SIMULATION_TOP_MARGIN
	var enemy_top_y: float = party_top_y - enemy_scaled_size.y - SIMULATION_VERTICAL_GAP + ENEMY_VERTICAL_OFFSET
	var minimum_enemy_top: float = header_rect.position.y + SIMULATION_TOP_MARGIN
	if enemy_top_y < minimum_enemy_top:
		enemy_top_y = minimum_enemy_top
	var enemy_left_x: float = right_rect.position.x + (right_rect.size.x * ENEMY_HORIZONTAL_RATIO)
	var enemy_global_position := Vector2(
		enemy_left_x,
		enemy_top_y
	)
	var party_global_position := Vector2(
		right_rect.position.x + SIMULATION_SIDE_MARGIN,
		party_top_y
	)

	enemy_container.global_position = enemy_global_position
	party_container.global_position = party_global_position
	auto_enemy_container.position.y = ENEMY_CONTENT_VERTICAL_OFFSET

func _render_enemy_profile_section(parent: VBoxContainer) -> void:
	var section := _add_section(parent, "")
	var enemy_data: EnemyData = current_session.working_enemy_data
	var fields := _add_two_column_fields(section)
	fields.add_child(_build_string_field("Enemy Name", enemy_data.enemy_name, func(next_value: String) -> void:
		if service.set_enemy_property(current_session, "enemy_name", next_value):
			_render_all()
	))
	fields.add_child(_build_string_field("Stable Object ID", enemy_data.object_id, func(next_value: String) -> void:
		if service.set_enemy_property(current_session, "object_id", next_value):
			_render_all()
	))
	fields.add_child(_build_option_field("Texture Path", _enemy_texture_options(false, enemy_data.enemy_texture_path), enemy_data.enemy_texture_path, func(next_value: Variant) -> void:
		if service.set_enemy_property(current_session, "enemy_texture_path", str(next_value)):
			_render_all()
	))
	fields.add_child(_build_option_field("Texture Path When Broken", _enemy_texture_options(true, enemy_data.enemy_texture_path_when_broken), enemy_data.enemy_texture_path_when_broken, func(next_value: Variant) -> void:
		if service.set_enemy_property(current_session, "enemy_texture_path_when_broken", str(next_value)):
			_render_all()
	))
	fields.add_child(_build_int_field("Max Health", enemy_data.enemy_health_max, 0, 9999, func(next_value: int) -> void:
		var updated: bool = service.set_enemy_property(current_session, "enemy_health_max", next_value)
		updated = service.set_enemy_property(current_session, "enemy_health", next_value) or updated
		if updated:
			_render_all()
	))
	fields.add_child(_build_int_field("Max Poise", enemy_data.enemy_poise_max, 0, 9999, func(next_value: int) -> void:
		var updated: bool = service.set_enemy_property(current_session, "enemy_poise_max", next_value)
		updated = service.set_enemy_property(current_session, "enemy_poise", next_value) or updated
		if updated:
			_render_all()
	))
	fields.add_child(_build_int_field("Starting Block", enemy_data.enemy_block, 0, 9999, func(next_value: int) -> void:
		if service.set_enemy_property(current_session, "enemy_block", next_value):
			_render_all()
	))
	fields.add_child(_build_option_field("Enemy Role", _enemy_role_options(), _enemy_role_value(enemy_data.enemy_type, enemy_data.enemy_is_minion), func(next_value: Variant) -> void:
		var role_data: Dictionary = _decode_enemy_role_value(next_value)
		var updated: bool = service.set_enemy_property(current_session, "enemy_type", int(role_data.get("enemy_type", EnemyData.ENEMY_TYPES.STANDARD)))
		updated = service.set_enemy_property(current_session, "enemy_is_minion", bool(role_data.get("enemy_is_minion", false))) or updated
		if updated:
			_render_all()
	))
func _render_base_stage_editor(parent: VBoxContainer, stage_data: EnemyStageData) -> void:
	var section := _add_section(parent, "Base Stage")
	section.add_child(_make_note_label(EnemyEditorSchema.summarize_stage(stage_data)))
	var fields := _add_two_column_fields(section)
	fields.add_child(_build_string_field("Stage ID", stage_data.object_id, func(next_value: String) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "object_id", next_value, false):
			selected_base_stage_id = next_value
			_render_all()
	))
	fields.add_child(_build_string_field("Label", stage_data.label, func(next_value: String) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "label", next_value, false):
			_render_all()
	))
	fields.add_child(_build_option_field("Next Stage", _base_stage_options(), stage_data.next_stage_id, func(next_value: Variant) -> void:
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

func _render_reactive_stage_editor(parent: VBoxContainer, stage_data: EnemyReactiveStageData) -> void:
	var section := _add_section(parent, "Reactive Stage")
	section.add_child(_make_note_label("Interrupt | %s" % EnemyEditorSchema.summarize_reactive_stage(stage_data)))
	var fields := _add_two_column_fields(section)
	fields.add_child(_build_string_field("Reactive Stage ID", stage_data.object_id, func(next_value: String) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "object_id", next_value, true):
			selected_reactive_stage_id = next_value
			_render_all()
	))
	fields.add_child(_build_string_field("Label", stage_data.label, func(next_value: String) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "label", next_value, true):
			_render_all()
	))
	var priority_field := _build_int_field("Priority", stage_data.priority, -999, 999, func(next_value: int) -> void:
		if stage_data.priority_override_enabled and service.set_stage_property(current_session, stage_data.object_id, "priority", next_value, true):
			_render_all()
	)
	_set_controls_disabled(priority_field, not stage_data.priority_override_enabled)
	fields.add_child(priority_field)
	fields.add_child(_build_bool_field("Priority Override", stage_data.priority_override_enabled, func(next_value: bool) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "priority_override_enabled", next_value, true):
			_render_all()
	))
	fields.add_child(_build_option_field("Resume Mode", EnemyEditorSchema.resume_mode_options(), stage_data.resume_mode, func(next_value: Variant) -> void:
		if service.set_stage_property(current_session, stage_data.object_id, "resume_mode", str(next_value), true):
			_render_all()
	))
	fields.add_child(_build_option_field("Resume Stage", _prepend_none(_base_stage_options(), "Resume Previous"), stage_data.resume_stage_id, func(next_value: Variant) -> void:
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
		if field_name in ["enemy_health", "enemy_poise"]:
			continue
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
	var fields := _add_two_column_fields(section)
	fields.add_child(_build_option_field("Planned Stage", _base_stage_options(), state.planned_stage_id, func(next_value: Variant) -> void:
		state.planned_stage_id = str(next_value)
		_render_all()
	))
	fields.add_child(_build_option_field("Previous Executed Stage", _prepend_none(_stage_id_options(), "None"), state.previous_executed_stage_id, func(next_value: Variant) -> void:
		state.previous_executed_stage_id = str(next_value)
		_render_all()
	))
	fields.add_child(_build_int_field("Turn Count", state.turn_count, 1, 99, func(next_value: int) -> void:
		state.turn_count = next_value
		_render_all()
	))
	fields.add_child(_build_int_field("Stage Started Turn", state.planned_stage_started_turn_count, 1, 99, func(next_value: int) -> void:
		state.planned_stage_started_turn_count = next_value
		_render_all()
	))
	fields.add_child(_build_int_field("PC Energy", state.player_energy, 0, 20, func(next_value: int) -> void:
		state.player_energy = next_value
		_render_all()
	))
	fields.add_child(_build_int_field("Preview Difficulty", state.difficulty_level, 0, 99, func(next_value: int) -> void:
		state.difficulty_level = next_value
		_render_all()
	))
	var status_section := _add_section(parent, "Enemy Statuses")
	_render_status_dictionary_editor(status_section, state.enemy_status_effects, func(next_value: Dictionary[String, int]) -> void:
		state.enemy_status_effects = next_value
		_render_all()
	)

	var party_section := _add_section(parent, "PC State")
	var party_grid := _add_three_column_fields(party_section)
	for party_index: int in range(state.player_party_members.size()):
		var member: Dictionary = state.player_party_members[party_index]
		var row := VBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 4)
		row.add_child(_make_inline_title("PC %s" % (party_index + 1)))
		row.add_child(_build_int_field("Health", int(member.get("health", 0)), 0, 999, func(next_value: int) -> void:
			state.player_party_members[party_index]["health"] = clampi(next_value, 0, 100)
			state.player_party_members[party_index]["health_max"] = 100
			_render_all()
		))
		party_grid.add_child(row)

	var ally_section := _add_section(parent, "Allies And Minions")
	var ally_grid := _add_two_column_fields(ally_section)
	var counts: Dictionary = _ally_count_summary(state.living_ally_enemy_states)
	ally_grid.add_child(_build_int_field("Living Allies", int(counts.get("living_allies", 0)), 0, 6, func(next_value: int) -> void:
		state.living_ally_enemy_states = _build_ally_state_array(next_value, int(counts.get("living_minions", 0)))
		_render_all()
	))
	ally_grid.add_child(_build_int_field("Living Minions", int(counts.get("living_minions", 0)), 0, 6, func(next_value: int) -> void:
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
	button.text = "%s ⇒ %s" % [stage_data.object_id, stage_data.next_stage_id]
	button.tooltip_text = EnemyEditorSchema.summarize_stage(stage_data)
	button.disabled = stage_data.object_id == selected_base_stage_id
	button.button_down.connect(func() -> void:
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
	button.button_down.connect(func() -> void:
		selected_reactive_stage_id = stage_data.object_id
		selected_base_stage_id = ""
		selected_difficulty_index = -1
		_render_all()
	)
	var reactive_index: int = current_session.working_enemy_data.reactive_stages.find(stage_data)
	var up_button := Button.new()
	up_button.text = "Up"
	up_button.disabled = reactive_index <= 0
	up_button.button_up.connect(func() -> void:
		if service.move_reactive_stage(current_session, reactive_index, reactive_index - 1):
			_render_all()
	)
	var down_button := Button.new()
	down_button.text = "Down"
	down_button.disabled = reactive_index < 0 or reactive_index >= current_session.working_enemy_data.reactive_stages.size() - 1
	down_button.button_up.connect(func() -> void:
		if service.move_reactive_stage(current_session, reactive_index, reactive_index + 1):
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
	row.add_child(up_button)
	row.add_child(down_button)
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
	button.button_down.connect(func() -> void:
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
	var move_up_button := Button.new()
	move_up_button.text = "Up"
	move_up_button.disabled = variant_index <= 0
	move_up_button.button_up.connect(func() -> void:
		if service.move_intent_variant(current_session, stage_id, variant_index, variant_index - 1, is_reactive):
			_render_all()
	)
	var move_down_button := Button.new()
	move_down_button.text = "Down"
	var variant_count: int = 0
	var stage_data: Variant = current_session.working_enemy_data.get_reactive_stage(stage_id) if is_reactive else current_session.working_enemy_data.get_stage(stage_id)
	if stage_data != null:
		variant_count = stage_data.intents.size()
	move_down_button.disabled = variant_index >= variant_count - 1
	move_down_button.button_up.connect(func() -> void:
		if service.move_intent_variant(current_session, stage_id, variant_index, variant_index + 1, is_reactive):
			_render_all()
	)
	remove_button.button_up.connect(func() -> void:
		if service.remove_intent_variant(current_session, stage_id, variant_index, is_reactive):
			_render_all()
	)
	header.add_child(label)
	header.add_child(move_up_button)
	header.add_child(move_down_button)
	header.add_child(remove_button)
	box.add_child(header)
	var variant_fields := _add_two_column_fields(box)
	variant_fields.add_child(_build_bool_field("Priority Override", variant.priority_override_enabled, func(next_value: bool) -> void:
		if service.set_variant_field(current_session, stage_id, variant_index, "priority_override_enabled", next_value, is_reactive):
			_render_all()
	))
	var priority_field := _build_int_field("Priority", variant.priority, -999, 999, func(next_value: int) -> void:
		if variant.priority_override_enabled and service.set_variant_field(current_session, stage_id, variant_index, "priority", next_value, is_reactive):
			_render_all()
	)
	_set_controls_disabled(priority_field, not variant.priority_override_enabled)
	variant_fields.add_child(priority_field)
	var condition_section := _add_section(box, "Conditions")
	_render_condition_entries(condition_section, variant.conditions, func(next_entries: Array[Dictionary]) -> void:
		if service.patch_variant_conditions(current_session, stage_id, variant_index, next_entries, "overwrite", is_reactive):
			_render_all()
	)
	var actions_section := _add_section(box, "Extra Actions")
	_render_action_entries(actions_section, variant.extra_actions, BaseAction.EDITOR_CONTEXT_ENEMY_ACTIONS, func(next_entries: Array[Dictionary]) -> void:
		if service.patch_variant_extra_actions(current_session, stage_id, variant_index, next_entries, "overwrite", is_reactive):
			_render_all()
	)
	var intent_section := _add_section(box, "Intent")
	var intent_fields := _add_two_column_fields(intent_section)
	intent_fields.add_child(_build_int_field("Damage", variant.intent.damage, 0, 999, func(next_value: int) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "damage", next_value, is_reactive):
			_render_all()
	))
	intent_fields.add_child(_build_int_field("Attacks", variant.intent.number_of_attacks, 0, 20, func(next_value: int) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "number_of_attacks", next_value, is_reactive):
			_render_all()
	))
	intent_fields.add_child(_build_option_field("Targeting Rule", EnemyEditorSchema.targeting_rule_options(), variant.intent.targeting_rule, func(next_value: Variant) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "targeting_rule", str(next_value), is_reactive):
			_render_all()
		))
	intent_fields.add_child(_build_int_field("Target Count", variant.intent.target_count, 1, 8, func(next_value: int) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "target_count", next_value, is_reactive):
			_render_all()
		))
	intent_fields.add_child(_build_int_field("Block", variant.intent.block, 0, 999, func(next_value: int) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "block", next_value, is_reactive):
			_render_all()
	))
	intent_fields.add_child(_build_bool_field("Allow Repeat Targets", variant.intent.allow_repeat_targets, func(next_value: bool) -> void:
		if service.set_intent_field(current_session, stage_id, variant_index, "allow_repeat_targets", next_value, is_reactive):
			_render_all()
	))
	return panel

func _render_condition_entries(parent: VBoxContainer, entries: Array[Dictionary], on_set_entries: Callable) -> void:
	var quick_grid := _add_three_column_fields(parent)
	quick_grid.add_child(_build_bool_field("Poise Broken", _has_quick_condition(entries, Scripts.VALIDATOR_SOURCE_BROKEN_POISE), func(enabled: bool) -> void:
		on_set_entries.call(_set_quick_condition(entries, Scripts.VALIDATOR_SOURCE_BROKEN_POISE, {}, enabled))
	))
	quick_grid.add_child(_build_bool_field("50% HP Or Lower", _has_quick_condition(entries, Scripts.VALIDATOR_SOURCE_HEALTH_PERCENT, {"operator": "<=", "comparison_value": 0.5}), func(enabled: bool) -> void:
		on_set_entries.call(_set_quick_condition(entries, Scripts.VALIDATOR_SOURCE_HEALTH_PERCENT, {"operator": "<=", "comparison_value": 0.5}, enabled))
	))
	quick_grid.add_child(_build_int_field("PC Energy At Least", _get_quick_pc_energy(entries), 0, 20, func(next_value: int) -> void:
		on_set_entries.call(_set_quick_pc_energy(entries, next_value))
	))
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
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)
	row.add_child(_make_inline_title(label_text))
	var line_edit := LineEdit.new()
	line_edit.text = value
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var last_committed_text: String = value
	var commit_text := func(next_text: String) -> void:
		if next_text == last_committed_text:
			return
		last_committed_text = next_text
		on_commit.call(next_text)
	line_edit.text_submitted.connect(func(next_text: String) -> void:
		commit_text.call(next_text)
	)
	line_edit.focus_exited.connect(func() -> void:
		commit_text.call(line_edit.text)
	)
	row.add_child(line_edit)
	return row

func _build_multiline_field(label_text: String, value: String, on_commit: Callable) -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)
	row.add_child(_make_inline_title(label_text))
	var text_edit := TextEdit.new()
	text_edit.custom_minimum_size = Vector2(0, 84)
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.text = value
	var last_committed_text: String = value
	text_edit.focus_exited.connect(func() -> void:
		if text_edit.text == last_committed_text:
			return
		last_committed_text = text_edit.text
		on_commit.call(text_edit.text)
	)
	row.add_child(text_edit)
	return row

func _build_int_field(label_text: String, value: int, min_value: int, max_value: int, on_change: Callable) -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	check_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check_box.text = label_text
	check_box.button_pressed = value
	check_box.toggled.connect(func(next_value: bool) -> void:
		on_change.call(next_value)
	)
	return check_box

func _build_option_field(label_text: String, options: Array[Dictionary], current_value: Variant, on_change: Callable) -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	if title.strip_edges() != "":
		var label := Label.new()
		label.text = title
		label.add_theme_font_size_override("font_size", SECTION_TITLE_SIZE)
		section.add_child(label)
	parent.add_child(section)
	return section

func _add_two_column_fields(parent: VBoxContainer) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = _resolved_form_columns(parent)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	return grid

func _add_three_column_fields(parent: VBoxContainer) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	return grid

func _make_inline_title(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	return label

func _make_note_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _enemy_role_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for type_option: Dictionary in EnemyEditorSchema.enemy_type_options():
		var type_value: int = int(type_option.get("value", EnemyData.ENEMY_TYPES.STANDARD))
		var type_label: String = str(type_option.get("label", type_value))
		options.append({"label": type_label, "value": _enemy_role_value(type_value, false)})
		options.append({"label": "%s Minion" % type_label, "value": _enemy_role_value(type_value, true)})
	return options

func _enemy_role_value(enemy_type: int, enemy_is_minion: bool) -> String:
	return "%s|%s" % [enemy_type, 1 if enemy_is_minion else 0]

func _decode_enemy_role_value(value: Variant) -> Dictionary:
	var raw_value: String = str(value)
	var parts: PackedStringArray = raw_value.split("|")
	return {
		"enemy_type": int(parts[0]) if parts.size() > 0 else EnemyData.ENEMY_TYPES.STANDARD,
		"enemy_is_minion": parts.size() > 1 and parts[1] == "1",
	}

func _load_library_entry_texture(resource_path: String) -> Texture2D:
	if resource_path.strip_edges() == "":
		return null
	var enemy_resource: Resource = load(resource_path)
	if not (enemy_resource is EnemyData):
		return null
	var texture_path: String = str((enemy_resource as EnemyData).enemy_texture_path)
	if texture_path.strip_edges() == "":
		return null
	return FileLoader.load_texture(texture_path)

func _resolved_form_columns(context: Control) -> int:
	var is_preview_context: bool = preview_content != null and (context == preview_content or preview_content.is_ancestor_of(context))
	var is_left_context: bool = navigator_content != null and (context == navigator_content or navigator_content.is_ancestor_of(context))
	var width_source: Control = preview_content if is_preview_context else navigator_content if is_left_context else editor_content
	if width_source == null:
		width_source = context
	var available_width: float = width_source.size.x
	if available_width <= 0.0 and width_source.get_parent() is Control:
		available_width = (width_source.get_parent() as Control).size.x
	return 2 if available_width >= TWO_COLUMN_MIN_WIDTH else 1

func _on_form_layout_resized() -> void:
	if current_session == null:
		return
	var next_left_columns: int = _resolved_form_columns(navigator_content)
	var next_editor_columns: int = _resolved_form_columns(editor_content)
	var next_preview_columns: int = _resolved_form_columns(preview_content)
	if next_left_columns == last_left_layout_columns and next_editor_columns == last_editor_layout_columns and next_preview_columns == last_preview_layout_columns:
		return
	_render_all()

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
	_cache_current_session_if_needed()
	if draft_sessions_by_resource_path.has(resource_path):
		current_session = draft_sessions_by_resource_path[resource_path]
	else:
		current_session = service.load_session(resource_path)
		if current_session != null:
			draft_sessions_by_resource_path[resource_path] = current_session
	selected_library_path = resource_path
	_select_default_navigation_targets()
	_set_status("Loaded %s." % str(entry.get("enemy_name", entry.get("object_id", "enemy"))), "success")
	_render_all()

func _ensure_preview_defaults() -> void:
	if current_session == null or current_session.preview_state == null or current_session.working_enemy_data == null:
		return
	var state: EnemyEditorPreviewState = current_session.preview_state
	state.ensure_defaults(current_session.working_enemy_data)
	state.enemy_health = state.enemy_health_max
	state.enemy_poise = state.enemy_poise_max
	if state.player_party_members.is_empty():
		for party_index: int in range(DEFAULT_PC_HEALTHS.size()):
			state.player_party_members.append({
				"party_member_index": party_index,
				"health": DEFAULT_PC_HEALTHS[party_index],
				"health_max": 100,
			})
	elif state.player_party_members.size() < DEFAULT_PC_HEALTHS.size():
		for party_index: int in range(state.player_party_members.size(), DEFAULT_PC_HEALTHS.size()):
			state.player_party_members.append({
				"party_member_index": party_index,
				"health": DEFAULT_PC_HEALTHS[party_index],
				"health_max": 100,
			})
	elif state.player_party_members.size() > DEFAULT_PC_HEALTHS.size():
		state.player_party_members.resize(DEFAULT_PC_HEALTHS.size())
	for party_index: int in range(state.player_party_members.size()):
		state.player_party_members[party_index]["party_member_index"] = party_index
		state.player_party_members[party_index]["health_max"] = 100
		state.player_party_members[party_index]["health"] = clampi(int(state.player_party_members[party_index].get("health", DEFAULT_PC_HEALTHS[min(party_index, DEFAULT_PC_HEALTHS.size() - 1)])), 0, 100)

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

func _enemy_texture_options(include_empty: bool = false, current_value: String = "") -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if include_empty:
		options.append({"label": "None", "value": ""})
	var directory: DirAccess = DirAccess.open("res://external/sprites/enemies")
	if directory != null:
		directory.list_dir_begin()
		while true:
			var file_name: String = directory.get_next()
			if file_name == "":
				break
			if directory.current_is_dir():
				continue
			var resource_path: String = "external/sprites/enemies/%s" % file_name
			options.append({"label": file_name, "value": resource_path})
		directory.list_dir_end()
	options.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if str(left.get("value", "")) == "":
			return true
		if str(right.get("value", "")) == "":
			return false
		return str(left.get("label", "")) < str(right.get("label", ""))
	)
	if current_value.strip_edges() != "":
		var has_current: bool = false
		for option: Dictionary in options:
			if str(option.get("value", "")) == current_value:
				has_current = true
				break
		if not has_current:
			options.append({"label": current_value.get_file(), "value": current_value})
	return options

func _supported_condition_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for metadata: Dictionary in service.list_validator_options():
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

func _find_quick_condition_index(entries: Array[Dictionary], token_or_path: String, expected_values: Dictionary = {}) -> int:
	var normalized_target: String = Scripts.normalize_script_reference(token_or_path)
	for entry_index: int in range(entries.size()):
		var entry: Dictionary = entries[entry_index]
		if len(entry.keys()) != 1:
			continue
		var token: String = str(entry.keys()[0])
		if Scripts.normalize_script_reference(token) != normalized_target:
			continue
		var values: Dictionary = entry[token]
		var matches_expected: bool = true
		for value_key: String in expected_values.keys():
			var expected_value: Variant = expected_values[value_key]
			var current_value: Variant = values.get(value_key, null)
			if expected_value is float and current_value is float:
				if not is_equal_approx(float(current_value), float(expected_value)):
					matches_expected = false
					break
			elif current_value != expected_value:
				matches_expected = false
				break
		if matches_expected:
			return entry_index
	return -1

func _has_quick_condition(entries: Array[Dictionary], token_or_path: String, expected_values: Dictionary = {}) -> bool:
	return _find_quick_condition_index(entries, token_or_path, expected_values) >= 0

func _set_quick_condition(entries: Array[Dictionary], token_or_path: String, values: Dictionary, enabled: bool) -> Array[Dictionary]:
	var next_entries: Array[Dictionary] = entries.duplicate(true)
	var condition_index: int = _find_quick_condition_index(next_entries, token_or_path, values)
	if enabled:
		if condition_index < 0:
			var entry: Dictionary = service.create_validator_entry(token_or_path)
			if entry.is_empty():
				entry = {Scripts.normalize_script_reference(token_or_path): {}}
			var entry_token: String = str(entry.keys()[0])
			var next_values: Dictionary = {}
			next_values.assign(entry[entry_token])
			next_values.merge(values.duplicate(true), true)
			next_entries.append({entry_token: next_values})
	else:
		if condition_index >= 0:
			next_entries.remove_at(condition_index)
	return next_entries

func _get_quick_pc_energy(entries: Array[Dictionary]) -> int:
	var condition_index: int = _find_quick_condition_index(entries, Scripts.VALIDATOR_PLAYER_CURRENT_ENERGY, {"operator": ">="})
	if condition_index < 0:
		return 0
	var token: String = str(entries[condition_index].keys()[0])
	var values: Dictionary = entries[condition_index][token]
	return int(values.get("comparison_value", 0))

func _set_quick_pc_energy(entries: Array[Dictionary], required_energy: int) -> Array[Dictionary]:
	var next_entries: Array[Dictionary] = entries.duplicate(true)
	var condition_index: int = _find_quick_condition_index(next_entries, Scripts.VALIDATOR_PLAYER_CURRENT_ENERGY, {"operator": ">="})
	if required_energy <= 0:
		if condition_index >= 0:
			next_entries.remove_at(condition_index)
		return next_entries
	var next_entry: Dictionary = service.create_validator_entry(Scripts.VALIDATOR_PLAYER_CURRENT_ENERGY)
	if next_entry.is_empty():
		next_entry = {Scripts.normalize_script_reference(Scripts.VALIDATOR_PLAYER_CURRENT_ENERGY): {}}
	var token: String = str(next_entry.keys()[0])
	var next_values: Dictionary = {}
	next_values.assign(next_entry[token])
	next_values["operator"] = ">="
	next_values["comparison_value"] = required_energy
	next_entry = {token: next_values}
	if condition_index >= 0:
		next_entries[condition_index] = next_entry
	else:
		next_entries.append(next_entry)
	return next_entries

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
	_cache_current_session_if_needed()
	current_session.refresh_diagnostics(service)
	_render_all()

func _cache_current_session_if_needed() -> void:
	if current_session == null:
		return
	var cache_key: String = selected_library_path
	if cache_key == "":
		cache_key = current_session.original_resource_path
	if cache_key == "":
		return
	draft_sessions_by_resource_path[cache_key] = current_session

func _update_save_buttons() -> void:
	var has_session: bool = current_session != null
	if not has_session:
		save_triage_button.disabled = true
		promote_button.disabled = true
		save_triage_button.text = "Save To Triage"
		promote_button.text = "Promote To Content"
		return
	var is_dirty: bool = current_session.dirty
	var active_path: String = current_session.original_resource_path
	var is_triage_resource: bool = EnemyEditorPathUtils.path_is_within_root(active_path, current_session.triage_root)
	var is_content_resource: bool = EnemyEditorPathUtils.path_is_within_root(active_path, current_session.content_root)
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

func _set_controls_disabled(root: Node, disabled: bool) -> void:
	if root is BaseButton:
		(root as BaseButton).disabled = disabled
	elif root is SpinBox:
		(root as SpinBox).editable = not disabled
	elif root is LineEdit:
		(root as LineEdit).editable = not disabled
	elif root is OptionButton:
		(root as OptionButton).disabled = disabled
	elif root is TextEdit:
		(root as TextEdit).editable = not disabled
	for child: Node in root.get_children():
		_set_controls_disabled(child, disabled)

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
	_end_simulation_context()
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
		if current_session != null and selected_library_path != "":
			draft_sessions_by_resource_path[selected_library_path] = current_session
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
