extends RefCounted

static func refresh_library(screen) -> void:
	screen.library_entries = screen.service.list_library_cards()
	populate_dynamic_filters(screen)
	apply_library_filters(screen)

static func apply_library_filters(screen) -> void:
	var filters: Dictionary = {}
	screen._add_filter_value(filters, "source_bucket", screen.source_filter)
	screen._add_filter_value(filters, "owner_bucket", screen.owner_filter)
	screen._add_filter_value(filters, "card_color_id", screen.color_filter)
	screen._add_filter_value(filters, "card_type", screen.type_filter)
	screen._add_filter_value(filters, "card_rarity", screen.rarity_filter)
	screen._add_filter_value(filters, "card_kind", screen.kind_filter)
	screen.filtered_entries = screen.service.filter_library_cards(screen.library_entries, filters, screen.library_search.text)
	render_library_sections(screen)
	screen._refresh_overview()

static func populate_static_filters(screen) -> void:
	var source_options: Array[Dictionary] = [
		{"label": "All Sources", "value": null},
		{"label": "Content", "value": "content"},
		{"label": "Triage", "value": "triage"},
	]
	var type_options: Array[Dictionary] = screen._prepend_option(
		CardEditorSchema.get_card_field_definitions()["card_type"]["options"],
		"All Types",
		null
	)
	var rarity_options: Array[Dictionary] = screen._prepend_option(
		CardEditorSchema.get_card_field_definitions()["card_rarity"]["options"],
		"All Rarities",
		null
	)
	var kind_options: Array[Dictionary] = screen._prepend_option(
		CardEditorSchema.get_card_field_definitions()["card_kind"]["options"],
		"All Kinds",
		null
	)
	screen._populate_option_button(screen.source_filter, source_options)
	screen._populate_option_button(screen.type_filter, type_options)
	screen._populate_option_button(screen.rarity_filter, rarity_options)
	screen._populate_option_button(screen.kind_filter, kind_options)

static func populate_dynamic_filters(screen) -> void:
	var selected_owner: Variant = screen._get_option_button_value(screen.owner_filter)
	var selected_color: Variant = screen._get_option_button_value(screen.color_filter)
	var owner_options: Array[Dictionary] = [{"label": "All Owners", "value": null}]
	var color_options: Array[Dictionary] = [{"label": "All Colors", "value": null}]
	var seen_owners: Dictionary = {}
	var seen_colors: Dictionary = {}
	for entry: Dictionary in screen.library_entries:
		var owner_bucket: String = str(entry.get("owner_bucket", ""))
		if owner_bucket != "" and not seen_owners.has(owner_bucket):
			seen_owners[owner_bucket] = true
			owner_options.append({"label": owner_bucket, "value": owner_bucket})
		var color_id: String = str(entry.get("card_color_id", ""))
		if color_id != "" and not seen_colors.has(color_id):
			seen_colors[color_id] = true
			color_options.append({"label": color_id, "value": color_id})
	screen._populate_option_button(screen.owner_filter, owner_options, selected_owner)
	screen._populate_option_button(screen.color_filter, color_options, selected_color)

static func render_library_sections(screen) -> void:
	for child in screen.library_sections.get_children():
		child.queue_free()
	var grouped_entries: Dictionary = {}
	for entry: Dictionary in screen.filtered_entries:
		var group_name: String = get_library_group_name(entry)
		if not grouped_entries.has(group_name):
			grouped_entries[group_name] = []
		grouped_entries[group_name].append(entry)
	var group_names: Array[String] = []
	group_names.assign(grouped_entries.keys())
	group_names.sort()
	if group_names.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No cards match the current filters."
		screen.library_sections.add_child(empty_label)
		return
	for group_name: String in group_names:
		screen.library_sections.add_child(build_library_group(screen, group_name, grouped_entries[group_name]))

static func build_library_group(screen, group_name: String, entries: Array) -> Control:
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
	collapse_button.text = screen.COLLAPSED_ARROW if screen.collapsed_library_groups.get(group_name, false) else screen.EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		screen.collapsed_library_groups[group_name] = not bool(screen.collapsed_library_groups.get(group_name, false))
		render_library_sections(screen)
	)
	header.add_child(collapse_button)
	wrapper.add_child(header)
	if bool(screen.collapsed_library_groups.get(group_name, false)):
		return panel
	var grid := VBoxContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("separation", 8)
	for entry: Dictionary in entries:
		grid.add_child(build_library_card_tile(screen, entry))
	wrapper.add_child(grid)
	return panel

static func build_library_card_tile(screen, entry: Dictionary) -> Control:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(0, 84)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	var entry_path: String = str(entry.get("resource_path", ""))
	var is_selected: bool = screen.current_session != null and (entry_path == screen.current_session.original_resource_path or entry_path == screen.current_session.get_active_save_path())
	apply_library_tile_style(tile, is_selected, false)
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
	cost_badge.text = "X" if is_variable_cost else str(load_library_entry_cost(entry_path))
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
	meta_label.text = format_library_meta(screen, entry)
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
	var art_texture := load_library_entry_texture(entry_path)
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
		open_library_entry(screen, entry)
	)
	click_overlay.mouse_entered.connect(func():
		apply_library_tile_style(tile, is_selected, true)
	)
	click_overlay.mouse_exited.connect(func():
		apply_library_tile_style(tile, is_selected, false)
	)
	tile.add_child(click_overlay)
	return tile

static func load_library_entry_cost(entry_path: String) -> int:
	var card_resource: Resource = load(entry_path)
	if card_resource is CardData:
		return (card_resource as CardData).card_energy_cost
	return 0

static func load_library_entry_texture(entry_path: String) -> Texture2D:
	var card_resource: Resource = load(entry_path)
	if card_resource is CardData:
		var texture_path: String = str((card_resource as CardData).card_texture_path)
		if texture_path != "":
			return FileLoader.load_texture(texture_path)
	return null

static func get_library_grid_columns(screen) -> int:
	if screen.library_scroll.size.x >= 540:
		return 2
	return 1

static func get_library_group_name(entry: Dictionary) -> String:
	var owner_bucket: String = str(entry.get("owner_bucket", "Unsorted"))
	var source_bucket: String = str(entry.get("source_bucket", ""))
	if source_bucket == "triage":
		return "Triage"
	if owner_bucket == "" or owner_bucket == "unknown":
		return "Misc"
	return owner_bucket.replace("/", " / ")

static func open_library_entry(screen, entry: Dictionary) -> void:
	screen.current_session = screen.service.load_session(str(entry.get("resource_path", "")))
	if screen.current_session != null and screen.current_session.working_card_data != null:
		screen._set_status_message("Loaded %s from the library." % screen.current_session.working_card_data.get_card_name(), "info")
	screen._refresh_editor_panels()

static func format_library_entry_label(screen, entry: Dictionary) -> String:
	var parts: Array[String] = [str(entry.get("card_name", entry.get("object_id", "")))]
	var type_label: String = screen._enum_label_from_value(CardData.CARD_TYPES, entry.get("card_type", null))
	if type_label != "":
		parts.append(type_label.capitalize())
	var rarity_label: String = screen._enum_label_from_value(CardData.CARD_RARITIES, entry.get("card_rarity", null))
	if rarity_label != "":
		parts.append(rarity_label.capitalize())
	if str(entry.get("source_bucket", "")) == "triage":
		parts.append("triage")
	return " | ".join(parts)

static func format_library_meta(screen, entry: Dictionary) -> String:
	var parts: Array[String] = []
	var owner_bucket: String = str(entry.get("owner_bucket", ""))
	if owner_bucket != "" and owner_bucket != "unknown":
		parts.append(owner_bucket.replace("/", " / "))
	var type_label: String = screen._enum_label_from_value(CardData.CARD_TYPES, entry.get("card_type", null))
	var rarity_label: String = screen._enum_label_from_value(CardData.CARD_RARITIES, entry.get("card_rarity", null))
	if rarity_label != "":
		parts.append(rarity_label.capitalize())
	if type_label != "":
		parts.append(type_label.capitalize())
	return " | ".join(parts)

static func apply_library_tile_style(tile: PanelContainer, is_selected: bool, is_hovered: bool) -> void:
	if is_selected and is_hovered:
		tile.modulate = Color(1.0, 0.9, 0.66, 1.0)
	elif is_selected:
		tile.modulate = Color(1.0, 0.96, 0.8, 1.0)
	elif is_hovered:
		tile.modulate = Color(0.86, 0.93, 1.0, 1.0)
	else:
		tile.modulate = Color(1.0, 1.0, 1.0, 1.0)
