extends RefCounted

static func render_inspector(screen) -> void:
	for child in screen.inspector_container.get_children():
		child.queue_free()
	if screen.current_session == null or screen.current_session.working_card_data == null:
		return
	screen.inspector_container.add_child(build_editor_hero(screen))
	for group_data: Dictionary in screen.ESSENTIAL_FIELD_GROUPS:
		screen.inspector_container.add_child(build_property_section(screen, group_data))
	for group_data: Dictionary in screen.ADVANCED_FIELD_GROUPS:
		screen.inspector_container.add_child(build_property_section(screen, group_data))

static func build_editor_hero(screen) -> Control:
	var card_data: CardData = screen.current_session.working_card_data
	var counts: Dictionary = screen._get_diagnostic_counts()
	var severity_text: String = "Ready"
	if counts["errors"] > 0:
		severity_text = "%s error(s)" % counts["errors"]
	elif counts["warnings"] > 0:
		severity_text = "%s warning(s)" % counts["warnings"]
	var target_text: String = "No clicked target"
	if card_data.card_requires_target:
		target_text = "Needs %s target" % format_clicked_target_mode(card_data.get_effective_clicked_target_mode())
	var lines: Array[String] = [
		"%s" % card_data.get_card_name(),
		"%s | %s | %s" % [
			screen._enum_label_from_value(CardData.CARD_TYPES, card_data.card_type).capitalize(),
			screen._enum_label_from_value(CardData.CARD_RARITIES, card_data.card_rarity).capitalize(),
			card_data.card_color_id,
		],
		"Cost %s | %s | %s" % [
			"X" if card_data.card_energy_cost_is_variable else str(card_data.card_energy_cost),
			target_text,
			severity_text,
		],
	]
	return screen._build_section_intro("Card Focus", "\n".join(lines))

static func build_property_section(screen, group_data: Dictionary) -> Control:
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
	collapse_button.text = screen.COLLAPSED_ARROW if bool(screen.collapsed_property_groups.get(group_title, false)) else screen.EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		screen.collapsed_property_groups[group_title] = not bool(screen.collapsed_property_groups.get(group_title, false))
		render_inspector(screen)
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
	if bool(screen.collapsed_property_groups.get(group_title, false)):
		return panel
	var grid := GridContainer.new()
	grid.columns = int(group_data.get("columns", 1))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var field_definitions: Dictionary = screen.service.get_card_field_definitions()
	for property_name: String in group_data.get("fields", []):
		var field_definition: Dictionary = field_definitions.get(property_name, {})
		grid.add_child(build_property_card(screen, property_name, field_definition))
	wrapper.add_child(grid)
	return panel

static func build_property_card(screen, property_name: String, field_definition: Dictionary) -> Control:
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
	padding.add_child(build_property_editor(screen, property_name, field_definition))
	return panel

static func build_property_editor(screen, property_name: String, field_definition: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_constant_override("separation", 6)
	var description := property_description(property_name, field_definition)
	wrapper.tooltip_text = description
	var label := Label.new()
	label.text = property_label(property_name, field_definition)
	label.add_theme_font_size_override("font_size", 14)
	label.tooltip_text = description
	wrapper.add_child(label)
	var value_type: String = str(field_definition.get("value_type", "string"))
	var card_data: CardData = screen.current_session.working_card_data
	var property_value: Variant = card_data.get(property_name)
	if property_name == "card_color_id":
		wrapper.add_child(build_card_color_editor(screen, property_name, str(property_value), description))
		return wrapper
	if property_name == "card_keyword_object_ids":
		var keyword_values: Array[String] = []
		keyword_values.assign(property_value)
		wrapper.add_child(build_keyword_editor(screen, property_name, keyword_values))
		return wrapper
	if property_name == "card_values":
		wrapper.add_child(build_card_values_editor(screen, property_name, property_value))
		return wrapper
	if value_type == "dictionary":
		wrapper.add_child(build_dictionary_editor(screen, property_name, property_value))
		return wrapper
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(property_value)
			screen._setup_checkbox(checkbox)
			screen._style_checkbox(checkbox, bool(property_value))
			checkbox.toggled.connect(func(pressed: bool):
				screen.service.set_card_property(screen.current_session, property_name, pressed)
				screen._request_editor_panels_refresh()
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
				screen.service.set_card_property(screen.current_session, property_name, dropdown.get_item_metadata(index))
				screen._request_editor_panels_refresh()
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
				screen.service.set_card_property(screen.current_session, property_name, int(value))
				screen._request_editor_panels_refresh()
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
				screen.service.set_card_property(screen.current_session, property_name, text_edit.text)
				screen._request_editor_panels_refresh()
			)
			wrapper.add_child(text_edit)
		"string_array":
			var line_edit := LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.text = ",".join(property_value)
			line_edit.placeholder_text = "comma,separated,values"
			line_edit.tooltip_text = description
			line_edit.text_submitted.connect(func(_text: String):
				screen.service.set_card_property(screen.current_session, property_name, screen._parse_csv_strings(line_edit.text))
				screen._request_editor_panels_refresh()
			)
			line_edit.focus_exited.connect(func():
				screen.service.set_card_property(screen.current_session, property_name, screen._parse_csv_strings(line_edit.text))
				screen._request_editor_panels_refresh()
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
					screen.service.set_card_property(screen.current_session, property_name, parsed_value)
					screen._request_editor_panels_refresh()
			)
			wrapper.add_child(text_edit)
		_:
			var line_edit := LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.text = str(property_value)
			line_edit.tooltip_text = description
			line_edit.text_submitted.connect(func(new_text: String):
				screen.service.set_card_property(screen.current_session, property_name, new_text)
				screen._request_editor_panels_refresh()
			)
			line_edit.focus_exited.connect(func():
				screen.service.set_card_property(screen.current_session, property_name, line_edit.text)
				screen._request_editor_panels_refresh()
			)
			wrapper.add_child(line_edit)
	return wrapper

static func build_keyword_editor(screen, property_name: String, values: Array[String]) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var add_row := HBoxContainer.new()
	var dropdown := OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen._populate_option_button(dropdown, get_keyword_options(values))
	add_row.add_child(dropdown)
	var add_button := Button.new()
	add_button.text = "Add Keyword"
	add_button.disabled = dropdown.get_item_count() == 0
	add_button.button_up.connect(func():
		var keyword_id: Variant = screen._get_option_button_value(dropdown)
		if keyword_id == null:
			return
		if screen.service.add_string_array_value(screen.current_session, property_name, str(keyword_id)):
			screen._refresh_editor_panels()
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
			if screen.service.remove_array_value(screen.current_session, property_name, keyword_id):
				screen._refresh_editor_panels()
		)
		row.add_child(remove_button)
		wrapper.add_child(row)
	return wrapper

static func build_card_color_editor(screen, property_name: String, current_color_id: String, description: String) -> Control:
	var dropdown := OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dropdown.tooltip_text = description
	screen._populate_option_button(dropdown, get_card_color_options(screen), current_color_id)
	dropdown.item_selected.connect(func(_index: int):
		var selected_color_id: Variant = screen._get_option_button_value(dropdown)
		if selected_color_id == null:
			return
		screen.service.set_card_property(screen.current_session, property_name, str(selected_color_id))
		screen._request_editor_panels_refresh()
	)
	return dropdown

static func build_card_values_editor(screen, property_name: String, dictionary_value: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)
	var definitions: Dictionary[String, Dictionary] = screen.service.get_card_value_definitions()
	var suggested_keys: Array[String] = collect_card_value_suggestions(screen)
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
	suggestion_vbox.add_child(build_card_value_suggestion_row(screen, property_name, missing_suggested_keys, definitions))
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
		wrapper.add_child(build_card_value_row(screen, property_name, key_name, dictionary_value.get(key_name), definitions.get(key_name, {}), bool(used_key_lookup.get(key_name, false))))
	wrapper.add_child(build_card_value_add_panel(screen, property_name, dictionary_value, definitions))
	return wrapper

static func build_card_value_suggestion_row(screen, property_name: String, suggested_keys: Array[String], definitions: Dictionary[String, Dictionary]) -> Control:
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
			if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, resolved_definition.get("default_value", null)):
				screen._request_editor_panels_refresh()
		)
		flow.add_child(button)
	return flow

static func build_card_value_row(screen, property_name: String, key_name: String, current_value: Variant, definition: Dictionary, is_referenced: bool) -> Control:
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
	var value_type: String = str(definition.get("value_type", infer_variant_type(current_value)))
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
			if screen.service.rename_dictionary_key(screen.current_session, property_name, key_name, renamed_key):
				screen._request_editor_panels_refresh()
			else:
				key_edit.text = key_name
		)
		header.add_child(key_edit)
		var type_option := OptionButton.new()
		screen._populate_option_button(type_option, variant_type_options())
		select_option_value(type_option, value_type)
		type_option.item_selected.connect(func(_index: int):
			var next_type: String = str(screen._get_option_button_value(type_option))
			if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, coerce_variant_value(current_value, next_type)):
				screen._request_editor_panels_refresh()
		)
		header.add_child(type_option)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		if screen.service.remove_dictionary_value(screen.current_session, property_name, key_name):
			screen._request_editor_panels_refresh()
	)
	header.add_child(remove_button)
	row.add_child(header)
	row.add_child(build_card_value_value_editor(screen, property_name, key_name, current_value, definition))
	return panel

static func build_card_value_value_editor(screen, property_name: String, key_name: String, current_value: Variant, definition: Dictionary) -> Control:
	var value_type: String = str(definition.get("value_type", infer_variant_type(current_value)))
	match value_type:
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			screen._setup_checkbox(checkbox)
			screen._style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, pressed):
					screen._request_editor_panels_refresh()
			)
			return checkbox
		"int":
			var int_spin := SpinBox.new()
			int_spin.min_value = -9999
			int_spin.max_value = 99999
			int_spin.step = 1
			int_spin.value = float(current_value if current_value != null else 0)
			int_spin.value_changed.connect(func(value: float):
				if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, int(value)):
					screen._request_editor_panels_refresh()
			)
			return int_spin
		"float":
			var float_spin := SpinBox.new()
			float_spin.min_value = -9999
			float_spin.max_value = 99999
			float_spin.step = 0.1
			float_spin.value = float(current_value if current_value != null else 0)
			float_spin.value_changed.connect(func(value: float):
				if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, value):
					screen._request_editor_panels_refresh()
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
				if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, dropdown.get_item_metadata(option_index)):
					screen._request_editor_panels_refresh()
			)
			return dropdown
		_:
			var line_edit := LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, screen._coerce_string_parameter(new_text, value_type)):
					screen._request_editor_panels_refresh()
			)
			line_edit.focus_exited.connect(func():
				if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, screen._coerce_string_parameter(line_edit.text, value_type)):
					screen._request_editor_panels_refresh()
			)
			return line_edit

static func build_card_value_add_panel(screen, property_name: String, dictionary_value: Dictionary, definitions: Dictionary[String, Dictionary]) -> Control:
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
	screen._populate_option_button(known_option, get_card_value_definition_options(dictionary_value, definitions))
	known_row.add_child(known_option)
	var add_known_button := Button.new()
	add_known_button.text = "Add"
	add_known_button.disabled = known_option.get_item_count() == 0
	add_known_button.button_up.connect(func():
		var selected_key: Variant = screen._get_option_button_value(known_option)
		if selected_key == null:
			return
		var key_name: String = str(selected_key)
		var definition: Dictionary = definitions.get(key_name, {})
		if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, definition.get("default_value", null)):
			screen._refresh_editor_panels()
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
	screen._populate_option_button(add_type_option, variant_type_options())
	custom_row.add_child(add_type_option)
	var add_custom_button := Button.new()
	add_custom_button.text = "Add"
	add_custom_button.button_up.connect(func():
		var key_name: String = add_key_edit.text.strip_edges()
		if key_name == "" or dictionary_value.has(key_name):
			return
		var type_name: String = str(screen._get_option_button_value(add_type_option))
		if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, default_value_for_variant_type(type_name)):
			screen._refresh_editor_panels()
	)
	custom_row.add_child(add_custom_button)
	wrapper.add_child(custom_row)
	return panel

static func build_dictionary_editor(screen, property_name: String, dictionary_value: Dictionary, use_suggestions: bool = false) -> Control:
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
		wrapper.add_child(build_dictionary_row(screen, property_name, key_name, dictionary_value.get(key_name)))
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
		screen._populate_option_button(suggested_key_option, get_card_value_key_options(screen, dictionary_value))
		add_vbox.add_child(suggested_key_option)
	var add_key_edit := LineEdit.new()
	add_key_edit.placeholder_text = "key_name"
	add_vbox.add_child(add_key_edit)
	var add_type_option := OptionButton.new()
	screen._populate_option_button(add_type_option, variant_type_options())
	add_vbox.add_child(add_type_option)
	if suggested_key_option != null:
		suggested_key_option.item_selected.connect(func(_index: int):
			var selected_key: Variant = screen._get_option_button_value(suggested_key_option)
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
		var type_name: String = str(screen._get_option_button_value(add_type_option))
		if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, default_value_for_variant_type(type_name)):
			screen._refresh_editor_panels()
	)
	add_vbox.add_child(add_button)
	wrapper.add_child(add_panel)
	return wrapper

static func build_dictionary_row(screen, property_name: String, key_name: String, current_value: Variant) -> Control:
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
		if screen.service.rename_dictionary_key(screen.current_session, property_name, key_name, renamed_key):
			screen._refresh_editor_panels()
		else:
			key_edit.text = key_name
	)
	header.add_child(key_edit)
	var type_option := OptionButton.new()
	screen._populate_option_button(type_option, variant_type_options())
	select_option_value(type_option, infer_variant_type(current_value))
	type_option.item_selected.connect(func(_index: int):
		var next_type: String = str(screen._get_option_button_value(type_option))
		if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, coerce_variant_value(current_value, next_type)):
			screen._refresh_editor_panels()
	)
	header.add_child(type_option)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		if screen.service.remove_dictionary_value(screen.current_session, property_name, key_name):
			screen._refresh_editor_panels()
	)
	header.add_child(remove_button)
	row.add_child(header)
	row.add_child(build_variant_value_editor(
		screen,
		current_value,
		func(next_value: Variant):
			if screen.service.set_dictionary_value(screen.current_session, property_name, key_name, next_value):
				screen._refresh_editor_panels()
	))
	return panel

static func get_card_color_options(screen) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var seen: Dictionary = {}
	for color_id: String in screen.DEFAULT_CARD_COLOR_IDS:
		var color_in_library: bool = false
		for entry: Dictionary in screen.library_entries:
			if str(entry.get("card_color_id", "")) == color_id:
				color_in_library = true
				break
		if Global.get_color_data(color_id) == null and not color_in_library:
			continue
		options.append({"label": color_id, "value": color_id})
		seen[color_id] = true
	for entry: Dictionary in screen.library_entries:
		var color_id: String = str(entry.get("card_color_id", ""))
		if color_id == "" or seen.has(color_id):
			continue
		options.append({"label": color_id, "value": color_id})
		seen[color_id] = true
	return options

static func get_card_value_key_options(screen, existing_values: Dictionary) -> Array[Dictionary]:
	var suggestions: Array[Dictionary] = []
	var seen: Dictionary = {}
	for placeholder_name: String in collect_card_value_suggestions(screen):
		if placeholder_name == "" or existing_values.has(placeholder_name) or seen.has(placeholder_name):
			continue
		suggestions.append({"label": placeholder_name, "value": placeholder_name})
		seen[placeholder_name] = true
	return suggestions

static func get_card_value_definition_options(existing_values: Dictionary, definitions: Dictionary[String, Dictionary]) -> Array[Dictionary]:
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

static func collect_card_value_suggestions(screen) -> Array[String]:
	var suggestions: Array[String] = []
	for placeholder_name: String in collect_description_placeholders(screen):
		if not suggestions.has(placeholder_name):
			suggestions.append(placeholder_name)
	for parameter_name: String in collect_action_value_suggestions(screen):
		if not suggestions.has(parameter_name):
			suggestions.append(parameter_name)
	return suggestions

static func collect_description_placeholders(screen) -> Array[String]:
	var suggestions: Array[String] = []
	if screen.current_session == null or screen.current_session.working_card_data == null:
		return suggestions
	var regex := RegEx.new()
	if regex.compile("\\[([A-Za-z0-9_]+)\\]") == OK:
		for result: RegExMatch in regex.search_all(screen.current_session.working_card_data.card_description):
			var placeholder_name: String = result.get_string(1)
			if placeholder_name != "" and placeholder_name != "energy_icon" and not suggestions.has(placeholder_name):
				suggestions.append(placeholder_name)
	return suggestions

static func collect_action_value_suggestions(screen) -> Array[String]:
	var suggestions: Array[String] = []
	if screen.current_session == null or screen.current_session.working_card_data == null:
		return suggestions
	var card_value_definitions: Dictionary[String, Dictionary] = screen.service.get_card_value_definitions()
	for property_name: String in CardEditorSchema.get_action_property_names():
		for entry: Dictionary in screen.current_session.working_card_data.get(property_name):
			if entry.is_empty():
				continue
			var token: String = str(entry.keys()[0])
			var metadata: Dictionary = screen.service.get_action_metadata(token)
			var relevant_value_names: Array[String] = []
			relevant_value_names.assign(metadata.get("relevant_value_names", []))
			for value_name: String in relevant_value_names:
				if value_name == "":
					continue
				if not card_value_definitions.has(value_name):
					continue
				if not suggestions.has(value_name):
					suggestions.append(value_name)
	return suggestions

static func property_label(property_name: String, field_definition: Dictionary) -> String:
	if property_name == "card_requires_target":
		return "Needs Clicked Target"
	if property_name == "card_clicked_target_mode":
		return "Clicked Target Mode"
	return str(field_definition.get("label", property_name))

static func property_description(property_name: String, field_definition: Dictionary) -> String:
	if property_name == "card_requires_target":
		return "Turn this on only if the player must click a combatant when playing the card. Leave it off for self-buffs, draw, block, or effects that pick their own targets."
	if property_name == "card_clicked_target_mode":
		return "When clicked targeting is enabled, this decides whether the card may click enemies only, allies only, or any combatant."
	return str(field_definition.get("description", ""))

static func format_clicked_target_mode(target_mode: String) -> String:
	match target_mode:
		CardData.CARD_TARGET_MODE_ALLY_ONLY:
			return "ally"
		CardData.CARD_TARGET_MODE_ANY_COMBATANT:
			return "combatant"
		_:
			return "enemy"

static func get_keyword_options(existing_keywords: Array[String]) -> Array[Dictionary]:
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

static func variant_type_options() -> Array[Dictionary]:
	return [
		{"label": "String", "value": "string"},
		{"label": "Int", "value": "int"},
		{"label": "Float", "value": "float"},
		{"label": "Bool", "value": "bool"},
	]

static func build_variant_value_editor(screen, current_value: Variant, on_change: Callable) -> Control:
	match infer_variant_type(current_value):
		"bool":
			var checkbox := CheckBox.new()
			checkbox.button_pressed = bool(current_value)
			screen._setup_checkbox(checkbox)
			screen._style_checkbox(checkbox, checkbox.button_pressed)
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

static func default_value_for_variant_type(type_name: String) -> Variant:
	match type_name:
		"bool":
			return false
		"int":
			return 0
		"float":
			return 0.0
		_:
			return ""

static func infer_variant_type(value: Variant) -> String:
	if value is bool:
		return "bool"
	if value is int:
		return "int"
	if value is float:
		return "float"
	return "string"

static func coerce_variant_value(value: Variant, type_name: String) -> Variant:
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

static func select_option_value(option_button: OptionButton, desired_value: Variant) -> void:
	for index: int in range(option_button.get_item_count()):
		if option_button.get_item_metadata(index) == desired_value:
			option_button.select(index)
			return
