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
	screen.preview_card.scale = Vector2(1.5, 1.5)
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
	if not screen.visible:
		return
	var total_width: float = screen.body_split.size.x
	if total_width > 960 and not screen.library_panel_collapsed and (not screen.editor_panel_collapsed or not screen.preview_panel_collapsed):
		screen.body_split.split_offset = get_body_split_offset(screen, int(total_width))
	var middle_width: float = screen.editor_split.size.x
	if not screen.editor_panel_collapsed and middle_width > 480:
		screen.editor_split.split_offset = int(middle_width * 0.42)
	if is_instance_valid(screen.library_sections):
		screen.call_deferred("_render_library_sections")

static func get_body_split_offset(screen, total_width: int) -> int:
	var target_library_width: int = int(total_width * 0.16)
	target_library_width = max(target_library_width, screen.LIBRARY_PANEL_MIN_WIDTH)
	var max_library_width: int = total_width - (screen.PREVIEW_PANEL_MIN_WIDTH if not screen.preview_panel_collapsed else 0) - (screen.EDITOR_PANEL_MIN_WIDTH if not screen.editor_panel_collapsed else 0)
	if max_library_width < screen.LIBRARY_PANEL_MIN_WIDTH:
		max_library_width = screen.LIBRARY_PANEL_MIN_WIDTH
	return min(target_library_width, max_library_width)

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
		card_energy_cost.text = str(preview_data.card_energy_cost)
