extends RefCounted

static func render_preview(screen) -> void:
	for child in screen.preview_mount.get_children():
		child.queue_free()
	screen.preview_card = null
	if screen.current_session == null or screen.current_session.working_card_data == null:
		var empty_label := Label.new()
		empty_label.text = "Open a card from the library or create a new preset-based draft to see the live preview."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen.preview_mount.add_child(empty_label)
		return
	screen.preview_card = Scenes.CARD.instantiate()
	screen.preview_mount.add_child(screen.preview_card)
	var preview_width: float = maxf(screen.preview_panel.size.x, screen.preview_panel.custom_minimum_size.x)
	var preview_scale: float = clampf((preview_width - 48.0) / 260.0, 0.9, 1.35)
	screen.preview_card.scale = Vector2.ONE * preview_scale
	screen.preview_card.position = Vector2.ZERO
	render_preview_card(screen, screen.preview_card, screen.current_session.working_card_data)

static func render_session_summary(screen) -> void:
	if screen.current_session == null:
		screen.session_label.text = "No session"
		screen.diagnostics_text.text = ""
		return
	var summary: Dictionary = screen.service.get_card_summary(screen.current_session)
	var policy_label: String = format_save_policy(str(summary.get("save_policy", "")))
	var dirty_label: String = "Unsaved changes" if bool(summary.get("dirty", false)) else "Saved"
	screen.session_label.text = "%s\n%s | %s" % [
		"%s (%s)" % [summary.get("card_name", "Untitled Card"), summary.get("object_id", "no_id")],
		policy_label,
		dirty_label,
	]
	screen.session_label.tooltip_text = "State: %s" % dirty_label
	var diagnostics_lines: Array[String] = []
	var counts: Dictionary = get_diagnostic_counts(screen)
	if counts["errors"] == 0 and counts["warnings"] == 0:
		diagnostics_lines.append("[color=#9fe2a9]Ready to save.[/color] No editor issues are currently blocking this card.")
	else:
		var visible_diagnostics: Array = screen.current_session.diagnostics.slice(0, min(len(screen.current_session.diagnostics), screen.MAX_VISIBLE_DIAGNOSTICS))
		for diagnostic: Dictionary in visible_diagnostics:
			var severity: String = str(diagnostic.get("severity", "info"))
			var severity_color: String = status_color_hex(screen, severity)
			var field: String = str(diagnostic.get("field", ""))
			var suffix: String = "" if field == "" else " [i](%s)[/i]" % field
			diagnostics_lines.append("[color=%s][%s][/color]%s %s" % [
				severity_color,
				severity.to_upper(),
				suffix,
				str(diagnostic.get("message", "")).xml_escape(),
			])
		if len(screen.current_session.diagnostics) > screen.MAX_VISIBLE_DIAGNOSTICS:
			diagnostics_lines.append("[color=#d8d8d8]...and %s more issue(s).[/color]" % (len(screen.current_session.diagnostics) - screen.MAX_VISIBLE_DIAGNOSTICS))
	screen.diagnostics_text.text = "\n".join(diagnostics_lines)

static func refresh_overview(screen) -> void:
	screen.library_count_label.text = "Library: %s" % len(screen.library_entries)
	screen.filter_count_label.text = "Visible: %s" % len(screen.filtered_entries)
	if screen.current_session == null or screen.current_session.working_card_data == null:
		screen.selection_count_label.text = "Selection: none"
	else:
		var card_data: CardData = screen.current_session.working_card_data
		screen.selection_count_label.text = "Selection: %s" % card_data.get_card_name()
	var counts: Dictionary = get_diagnostic_counts(screen)
	if screen.current_session == null:
		screen.diagnostics_count_label.text = "Diagnostics: none"
	elif counts["errors"] == 0 and counts["warnings"] == 0:
		screen.diagnostics_count_label.text = "Diagnostics: clean"
	else:
		screen.diagnostics_count_label.text = "Diagnostics: %s error(s), %s warning(s)" % [counts["errors"], counts["warnings"]]
	refresh_status_banner(screen)

static func refresh_status_banner(screen) -> void:
	screen.status_banner.text = screen.status_message
	screen.status_banner.modulate = screen.STATUS_COLORS.get(screen.status_severity, screen.STATUS_COLORS["info"])
	screen.save_status_label.text = screen.status_message
	screen.save_status_label.modulate = screen.STATUS_COLORS.get(screen.status_severity, screen.STATUS_COLORS["info"])

static func get_diagnostic_counts(screen) -> Dictionary:
	var counts := {"errors": 0, "warnings": 0}
	if screen.current_session == null:
		return counts
	for diagnostic: Dictionary in screen.current_session.diagnostics:
		var severity: String = str(diagnostic.get("severity", ""))
		if severity == "error":
			counts["errors"] += 1
		elif severity == "warning":
			counts["warnings"] += 1
	return counts

static func format_save_policy(save_policy: String) -> String:
	match save_policy:
		CardEditorSession.SAVE_POLICY_MANAGED_CONTENT:
			return "Content save"
		CardEditorSession.SAVE_POLICY_MANAGED_TRIAGE:
			return "Triage save"
		CardEditorSession.SAVE_POLICY_MANUAL:
			return "Manual save"
		_:
			return save_policy

static func status_color_hex(screen, severity: String) -> String:
	var color: Color = screen.STATUS_COLORS.get(severity, screen.STATUS_COLORS["info"])
	return "#" + color.to_html()

static func apply_split_layout(screen) -> void:
	pass

static func get_body_split_offset(_screen, _total_width: int) -> int:
	return 0

# static func _get_library_width(screen, total_width: int, editor_width: int, preview_width: int) -> int:
# 	var remaining_width: int = total_width - editor_width - preview_width
# 	if total_width >= screen.RESPONSIVE_FOUR_COLUMN_BREAKPOINT:
# 		return clampi(int(total_width * 0.17), screen.LIBRARY_PANEL_MIN_WIDTH, max(remaining_width, screen.LIBRARY_PANEL_MIN_WIDTH))
# 	if total_width >= screen.RESPONSIVE_COMPACT_BREAKPOINT:
# 		return clampi(int(total_width * 0.18), screen.LIBRARY_PANEL_MIN_WIDTH, max(remaining_width, screen.LIBRARY_PANEL_MIN_WIDTH))
# 	return max(screen.LIBRARY_PANEL_MIN_WIDTH, remaining_width)

# static func _get_editor_host_width(screen, total_width: int) -> int:
# 	var target_width: int = int(total_width * 0.56)
# 	if total_width >= screen.RESPONSIVE_FOUR_COLUMN_BREAKPOINT:
# 		target_width = int(total_width * 0.60)
# 	elif total_width >= screen.RESPONSIVE_COMPACT_BREAKPOINT:
# 		target_width = int(total_width * 0.62)
# 	elif total_width >= screen.RESPONSIVE_TWO_COLUMN_BREAKPOINT:
# 		target_width = int(total_width * 0.64)
# 	return max(target_width, screen.INSPECTOR_PANEL_MIN_WIDTH + screen.BEHAVIOR_PANEL_MIN_WIDTH + 24)

# static func _get_preview_width(screen, total_width: int, editor_width: int) -> int:
# 	var target_width: int = int(total_width * 0.18)
# 	if total_width < screen.RESPONSIVE_FOUR_COLUMN_BREAKPOINT:
# 		target_width = int(total_width * 0.20)
# 	if total_width < screen.RESPONSIVE_COMPACT_BREAKPOINT:
# 		target_width = int(total_width * 0.18)
# 	var max_preview_width: int = total_width - editor_width - screen.LIBRARY_PANEL_MIN_WIDTH
# 	return clampi(target_width, screen.PREVIEW_PANEL_MIN_WIDTH, max(max_preview_width, screen.PREVIEW_PANEL_MIN_WIDTH))

# static func _apply_split_offsets(screen, total_width: int, library_width: int, editor_width: int, _preview_width: int, layout_band: String) -> void:
# 	var should_retarget: bool = not screen.layout_initialized
# 	if not should_retarget and screen.last_layout_band != layout_band:
# 		should_retarget = true
# 	elif not should_retarget and abs(total_width - screen.last_layout_width) >= 140:
# 		should_retarget = true
# 	if should_retarget:
# 		screen.body_split.split_offset = library_width
# 		screen.workspace_split.split_offset = editor_width
# 		screen.editor_split.split_offset = _get_editor_split_target(screen, editor_width, layout_band)
# 		screen.layout_initialized = true
# 	screen.last_layout_width = total_width
# 	screen.last_layout_band = layout_band
# 	var min_editor_split: int = screen.INSPECTOR_PANEL_MIN_WIDTH
# 	var max_editor_split: int = max(editor_width - screen.BEHAVIOR_PANEL_MIN_WIDTH, min_editor_split)
# 	screen.editor_split.split_offset = clampi(screen.editor_split.split_offset, min_editor_split, max_editor_split)
# 	var min_workspace_split: int = screen.INSPECTOR_PANEL_MIN_WIDTH + screen.BEHAVIOR_PANEL_MIN_WIDTH + 24
# 	var max_workspace_split: int = max(total_width - screen.LIBRARY_PANEL_MIN_WIDTH - screen.PREVIEW_PANEL_MIN_WIDTH, min_workspace_split)
# 	screen.workspace_split.split_offset = clampi(screen.workspace_split.split_offset, min_workspace_split, max_workspace_split)
# 	var max_body_split: int = max(total_width - screen.PREVIEW_PANEL_MIN_WIDTH - min_workspace_split, screen.LIBRARY_PANEL_MIN_WIDTH)
# 	screen.body_split.split_offset = clampi(screen.body_split.split_offset, screen.LIBRARY_PANEL_MIN_WIDTH, max_body_split)

static func _get_layout_band(screen, total_width: int) -> String:
	if total_width >= screen.RESPONSIVE_FOUR_COLUMN_BREAKPOINT:
		return "wide"
	if total_width >= screen.RESPONSIVE_COMPACT_BREAKPOINT:
		return "regular"
	if total_width >= screen.RESPONSIVE_TWO_COLUMN_BREAKPOINT:
		return "compact"
	return "tight"

static func _get_editor_split_target(screen, editor_width: int, layout_band: String) -> int:
	var ratio: float = 0.25
	if layout_band == "wide":
		ratio = 0.40
	elif layout_band == "regular":
		ratio = 0.35
	elif layout_band == "compact":
		ratio = 0.30
	return clampi(int(editor_width * ratio), screen.INSPECTOR_PANEL_MIN_WIDTH, max(editor_width - screen.BEHAVIOR_PANEL_MIN_WIDTH, screen.INSPECTOR_PANEL_MIN_WIDTH))

static func render_preview_card(screen, card: Card, card_data: CardData) -> void:
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
	if preview_data.card_owner_character_object_id == "" and Global.get_character_data(screen.PREVIEW_FALLBACK_CHARACTER_ID) != null:
		preview_data.card_owner_character_object_id = screen.PREVIEW_FALLBACK_CHARACTER_ID
	if preview_data.card_owner_character_object_id != "" and card_owner_sprite != null:
		var character_data: CharacterData = Global.get_character_data(preview_data.card_owner_character_object_id)
		if character_data != null:
			card_owner_sprite.texture = FileLoader.load_texture(character_data.character_icon_texture_path)
	card_name.set_bbcode("[center]" + preview_data.get_card_name() + "[/center]")
	card_kind.set_bbcode("[center]" + preview_data.get_card_kind_display_name() + "[/center]")
	card_description.set_bbcode(preview_data.get_card_description())
	card_type.text = "%s %s" % [
		screen._enum_label_from_value(CardData.CARD_RARITIES, preview_data.card_rarity).capitalize(),
		screen._enum_label_from_value(CardData.CARD_TYPES, preview_data.card_type).capitalize(),
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
		if preview_data.card_values.has("display_energy_cost_override"):
			card_energy_cost.text = str(preview_data.card_values["display_energy_cost_override"])
		else:
			card_energy_cost.text = str(preview_data.card_energy_cost)
