extends RefCounted

static func render_behavior(screen) -> void:
	screen.behavior_render_queued = false
	for child in screen.behavior_container.get_children():
		screen.behavior_container.remove_child(child)
		child.queue_free()
	if screen.current_session == null or screen.current_session.working_card_data == null:
		return
	screen.behavior_container.add_child(screen._build_section_intro(
		"Behavior",
		"Keep the main card flow visible. Secondary hooks stay tucked away until you need them."
	))
	for property_name: String in screen.PRIMARY_BEHAVIOR_GROUPS:
		screen.behavior_container.add_child(build_entry_group(screen, property_name, not property_name.contains("validators")))
	screen.behavior_container.add_child(build_additional_action_group(screen))
	var secondary_toggle: Control = screen._build_simple_toggle_row(
		"Internal and triggered hooks",
		"Internal actions, right-click behavior, and discard/draw/deck hooks are usually niche. Open them only when the card needs them.",
		screen.show_secondary_behavior_groups,
		func():
			screen.show_secondary_behavior_groups = not screen.show_secondary_behavior_groups
			request_behavior_render(screen)
	)
	screen.behavior_container.add_child(secondary_toggle)
	if screen.show_secondary_behavior_groups:
		for property_name: String in screen.SECONDARY_BEHAVIOR_GROUPS:
			var entries: Array = screen.current_session.working_card_data.get(property_name)
			if entries.is_empty():
				continue
			screen.behavior_container.add_child(build_entry_group(screen, property_name, true))

static func build_entry_group(screen, property_name: String, is_action: bool) -> Control:
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
	var entries: Array = screen.current_session.working_card_data.get(property_name)
	title.text = "%s (%s)" % [screen.PROPERTY_GROUP_LABELS.get(property_name, property_name), len(entries)]
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var collapse_button := Button.new()
	collapse_button.text = screen.COLLAPSED_ARROW if screen.collapsed_behavior_groups.get(property_name, false) else screen.EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		screen.collapsed_behavior_groups[property_name] = not bool(screen.collapsed_behavior_groups.get(property_name, false))
		request_behavior_render(screen)
	)
	header.add_child(collapse_button)
	vbox.add_child(header)
	if screen.BEHAVIOR_GROUP_DESCRIPTIONS.has(property_name):
		var description := Label.new()
		description.text = str(screen.BEHAVIOR_GROUP_DESCRIPTIONS[property_name])
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.modulate = Color(0.8, 0.82, 0.86, 0.9)
		vbox.add_child(description)
	if bool(screen.collapsed_behavior_groups.get(property_name, false)):
		return panel
	if entries.is_empty():
		var no_entries := Label.new()
		no_entries.text = "No entries configured yet."
		no_entries.modulate = Color(0.78, 0.8, 0.84, 0.9)
		vbox.add_child(no_entries)
		return panel
	for index: int in range(len(entries)):
		var entry: Dictionary = entries[index]
		vbox.add_child(build_entry_editor(screen, property_name, index, entry, is_action))
	return panel

static func build_additional_action_group(screen) -> Control:
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
	var entries: Array = screen.service.get_additional_action_entries(screen.current_session)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "%s (%s)" % [screen.PROPERTY_GROUP_LABELS[property_name], len(entries)]
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var collapse_button := Button.new()
	collapse_button.text = screen.COLLAPSED_ARROW if screen.collapsed_behavior_groups.get(property_name, false) else screen.EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		screen.collapsed_behavior_groups[property_name] = not bool(screen.collapsed_behavior_groups.get(property_name, false))
		request_behavior_render(screen)
	)
	header.add_child(collapse_button)
	vbox.add_child(header)
	var description := Label.new()
	description.text = str(screen.BEHAVIOR_GROUP_DESCRIPTIONS.get(property_name, ""))
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.modulate = Color(0.8, 0.82, 0.86, 0.9)
	vbox.add_child(description)
	if bool(screen.collapsed_behavior_groups.get(property_name, false)):
		return panel
	if entries.is_empty():
		var no_entries := Label.new()
		no_entries.text = "No internal actions yet. Use an action parameter's Add Action button to create one."
		no_entries.modulate = Color(0.78, 0.8, 0.84, 0.9)
		vbox.add_child(no_entries)
		return panel
	for entry_index: int in range(len(entries)):
		var additional_action: Dictionary = entries[entry_index]
		vbox.add_child(build_additional_action_editor(screen, entry_index, additional_action))
	return panel

static func build_additional_action_editor(screen, entry_index: int, additional_action: Dictionary) -> Control:
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
	var option_entries: Array[Dictionary] = screen.service.get_action_options("action_children")
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
	var entry_key: String = entry_visibility_key("card_additional_actions", entry_index, additional_action_id)
	var collapse_button := Button.new()
	collapse_button.text = screen.COLLAPSED_ARROW if screen.collapsed_behavior_entries.get(entry_key, false) else screen.EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		screen.collapsed_behavior_entries[entry_key] = not bool(screen.collapsed_behavior_entries.get(entry_key, false))
		request_behavior_render(screen)
	)
	toolbar.add_child(collapse_button)
	var up_button := Button.new()
	up_button.text = "Up"
	up_button.button_up.connect(func():
		if screen.service.move_additional_action(screen.current_session, entry_index, max(entry_index - 1, 0)):
			screen._refresh_editor_panels()
	)
	toolbar.add_child(up_button)
	var down_button := Button.new()
	down_button.text = "Down"
	down_button.button_up.connect(func():
		if screen.service.move_additional_action(screen.current_session, entry_index, min(entry_index + 1, len(screen.service.get_additional_action_entries(screen.current_session)) - 1)):
			screen._refresh_editor_panels()
	)
	toolbar.add_child(down_button)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		if screen.service.remove_additional_action(screen.current_session, additional_action_id):
			screen._refresh_editor_panels()
	)
	toolbar.add_child(remove_button)
	wrapper.add_child(toolbar)
	if bool(screen.collapsed_behavior_entries.get(entry_key, false)):
		var collapsed_summary := Label.new()
		collapsed_summary.text = build_entry_summary(screen, token, action_entry[token], true)
		collapsed_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		collapsed_summary.modulate = Color(0.82, 0.82, 0.86, 0.95)
		wrapper.add_child(collapsed_summary)
		return entry_panel
	var token_metadata: Dictionary = screen.service.get_action_metadata(token)
	var token_description: String = str(token_metadata.get("description", ""))
	if token_description != "":
		var description_label := Label.new()
		description_label.text = token_description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.modulate = Color(0.82, 0.82, 0.86, 0.95)
		wrapper.add_child(description_label)
	var token_row := HBoxContainer.new()
	token_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var token_label := Label.new()
	token_label.text = "Effect"
	token_label.custom_minimum_size = Vector2(72, 0)
	token_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	token_row.add_child(token_label)
	token_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	token_row.add_child(token_option)
	wrapper.add_child(token_row)
	token_option.item_selected.connect(func(selected_index: int):
		var metadata: Dictionary = token_option.get_item_metadata(selected_index)
		var next_token: String = str(metadata.get("resolved_token", metadata.get("token_or_path", "")))
		screen.service.replace_additional_action(screen.current_session, additional_action_id, next_token)
		refresh_after_behavior_structure_change(screen)
	)
	var parameters: Array[Dictionary] = []
	parameters.assign(token_metadata.get("parameters", []))
	var values: Dictionary = action_entry[token]
	var visible_parameters: Array[Dictionary] = []
	for parameter_data: Dictionary in parameters:
		if should_show_parameter(screen, parameter_data, values):
			visible_parameters.append(parameter_data)
	if not visible_parameters.is_empty():
		var parameter_grid := GridContainer.new()
		parameter_grid.columns = screen._get_behavior_parameter_columns()
		parameter_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		parameter_grid.add_theme_constant_override("h_separation", 8)
		parameter_grid.add_theme_constant_override("v_separation", 8)
		for parameter_data: Dictionary in visible_parameters:
			parameter_grid.add_child(build_additional_action_parameter_editor(screen, additional_action_id, token, parameter_data, values))
		wrapper.add_child(parameter_grid)
	return entry_panel

static func build_entry_editor(screen, property_name: String, index: int, entry: Dictionary, is_action: bool) -> Control:
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
	var option_entries: Array[Dictionary] = screen.service.get_action_options(screen.service.get_entry_context(property_name)) if is_action else screen.service.get_validator_options(screen.service.get_entry_context(property_name))
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
	var entry_key: String = entry_visibility_key(property_name, index, token)
	var collapse_button := Button.new()
	collapse_button.text = screen.COLLAPSED_ARROW if screen.collapsed_behavior_entries.get(entry_key, false) else screen.EXPANDED_ARROW
	collapse_button.button_up.connect(func():
		screen.collapsed_behavior_entries[entry_key] = not bool(screen.collapsed_behavior_entries.get(entry_key, false))
		request_behavior_render(screen)
	)
	toolbar.add_child(collapse_button)
	var up_button := Button.new()
	up_button.text = "Up"
	up_button.button_up.connect(func():
		if screen.service.move_entry(screen.current_session, property_name, index, max(index - 1, 0)):
			screen._refresh_editor_panels()
	)
	toolbar.add_child(up_button)
	var down_button := Button.new()
	down_button.text = "Down"
	down_button.button_up.connect(func():
		if screen.service.move_entry(screen.current_session, property_name, index, min(index + 1, len(screen.current_session.working_card_data.get(property_name)) - 1)):
			screen._refresh_editor_panels()
	)
	toolbar.add_child(down_button)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		if screen.service.remove_entry(screen.current_session, property_name, index):
			screen._refresh_editor_panels()
	)
	toolbar.add_child(remove_button)
	wrapper.add_child(toolbar)
	if bool(screen.collapsed_behavior_entries.get(entry_key, false)):
		var collapsed_summary := Label.new()
		collapsed_summary.text = build_entry_summary(screen, token, entry[token], is_action)
		collapsed_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		collapsed_summary.modulate = Color(0.82, 0.82, 0.86, 0.95)
		wrapper.add_child(collapsed_summary)
		return entry_panel
	var token_metadata: Dictionary = screen.service.get_action_metadata(token) if is_action else screen.service.get_validator_metadata(token)
	var token_description: String = str(token_metadata.get("description", ""))
	if token_description != "":
		var description_label := Label.new()
		description_label.text = token_description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.modulate = Color(0.82, 0.82, 0.86, 0.95)
		wrapper.add_child(description_label)
	var token_row := HBoxContainer.new()
	token_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var token_label := Label.new()
	token_label.text = "Effect"
	token_label.custom_minimum_size = Vector2(72, 0)
	token_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	token_row.add_child(token_label)
	token_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	token_row.add_child(token_option)
	wrapper.add_child(token_row)
	token_option.item_selected.connect(func(selected_index: int):
		var metadata: Dictionary = token_option.get_item_metadata(selected_index)
		var next_token: String = str(metadata.get("resolved_token", metadata.get("token_or_path", "")))
		screen.service.replace_entry(screen.current_session, property_name, index, next_token)
		refresh_after_behavior_structure_change(screen)
	)
	var parameters: Array[Dictionary] = []
	parameters.assign(token_metadata.get("parameters", []))
	var values: Dictionary = entry[token]
	var visible_parameters: Array[Dictionary] = []
	for parameter_data: Dictionary in parameters:
		if should_show_parameter(screen, parameter_data, values):
			visible_parameters.append(parameter_data)
	if not visible_parameters.is_empty():
		var parameter_grid := GridContainer.new()
		parameter_grid.columns = screen._get_behavior_parameter_columns()
		parameter_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		parameter_grid.add_theme_constant_override("h_separation", 8)
		parameter_grid.add_theme_constant_override("v_separation", 8)
		for parameter_data: Dictionary in visible_parameters:
			parameter_grid.add_child(build_entry_parameter_editor(screen, property_name, index, token, parameter_data, values))
		wrapper.add_child(parameter_grid)
	var advanced_toggle: Control = build_advanced_parameter_toggle(screen, property_name, index, token, is_action, values)
	if advanced_toggle != null:
		wrapper.add_child(advanced_toggle)
	return entry_panel

static func build_entry_summary(screen, token: String, values: Dictionary, is_action: bool) -> String:
	var metadata: Dictionary = screen.service.get_action_metadata(token) if is_action else screen.service.get_validator_metadata(token)
	var fragments: Array[String] = []
	var parameters: Array[Dictionary] = []
	parameters.assign(metadata.get("parameters", []))
	for parameter_data: Dictionary in parameters:
		var parameter_name: String = str(parameter_data.get("name", ""))
		if parameter_name == "" or not values.has(parameter_name):
			continue
		if not should_show_parameter(screen, parameter_data, values):
			continue
		fragments.append("%s: %s" % [str(parameter_data.get("label", parameter_name)), screen._format_inline_value(values[parameter_name])])
		if len(fragments) >= 3:
			break
	if fragments.is_empty():
		return "No edited parameters."
	return " | ".join(fragments)

static func build_entry_parameter_editor(screen, property_name: String, index: int, token: String, parameter_data: Dictionary, values: Dictionary) -> Control:
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
			screen._setup_checkbox(checkbox)
			screen._style_checkbox(checkbox, bool(current_value))
			checkbox.toggled.connect(func(pressed: bool):
				screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: pressed})
				refresh_after_behavior_change(screen)
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
				screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: dropdown.get_item_metadata(option_index)})
				refresh_after_behavior_change(screen)
			)
			dropdown.tooltip_text = description
			wrapper.add_child(dropdown)
		"enum_array":
			wrapper.add_child(screen._build_enum_array_parameter_editor(property_name, index, parameter_name, parameter_data, current_value))
		"int", "float":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1 if value_type == "int" else 0.1
			spin.value = float(current_value if current_value != null else 0)
			spin.value_changed.connect(func(value: float):
				screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: int(value) if value_type == "int" else value})
				refresh_after_behavior_change(screen)
			)
			spin.tooltip_text = description
			wrapper.add_child(spin)
		"validator_array":
			wrapper.add_child(screen._build_nested_validator_array_editor(property_name, index, parameter_name, current_value))
		"array":
			if screen._is_action_reference_parameter(parameter_name):
				wrapper.add_child(build_action_reference_array_editor(screen, "card_entry", card_entry_owner_key(property_name, index), parameter_name, current_value))
				return panel
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 72)
			text_edit.text = JSON.stringify(current_value, "\t")
			text_edit.tooltip_text = description
			text_edit.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(text_edit.text)
				if parsed_value != null:
					screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: parsed_value})
					refresh_after_behavior_change(screen)
			)
			wrapper.add_child(text_edit)
		"card_array":
			wrapper.add_child(screen._build_string_array_parameter_editor(property_name, index, parameter_name, current_value, "card_1,card_2"))
		"string_array":
			wrapper.add_child(screen._build_string_array_parameter_editor(property_name, index, parameter_name, current_value, "value_1,value_2"))
		"dictionary":
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 72)
			text_edit.text = JSON.stringify(current_value, "\t")
			text_edit.tooltip_text = description
			text_edit.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(text_edit.text)
				if parsed_value != null:
					screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: parsed_value})
					refresh_after_behavior_change(screen)
			)
			wrapper.add_child(text_edit)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.tooltip_text = description
			line_edit.text_submitted.connect(func(new_text: String):
				screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: screen._coerce_string_parameter(new_text, value_type)})
				refresh_after_behavior_change(screen)
			)
			line_edit.focus_exited.connect(func():
				screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: screen._coerce_string_parameter(line_edit.text, value_type)})
				refresh_after_behavior_change(screen)
			)
			wrapper.add_child(line_edit)
	return panel

static func build_additional_action_parameter_editor(screen, additional_action_id: String, token: String, parameter_data: Dictionary, values: Dictionary) -> Control:
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
			screen._setup_checkbox(checkbox)
			screen._style_checkbox(checkbox, bool(current_value))
			checkbox.toggled.connect(func(pressed: bool):
				screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: pressed})
				refresh_after_behavior_change(screen)
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
				screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: dropdown.get_item_metadata(option_index)})
				refresh_after_behavior_change(screen)
			)
			wrapper.add_child(dropdown)
		"enum_array":
			wrapper.add_child(build_additional_action_enum_array_editor(screen, additional_action_id, parameter_name, parameter_data, current_value))
		"validator_array":
			var text_edit := TextEdit.new()
			text_edit.custom_minimum_size = Vector2(0, 72)
			text_edit.text = JSON.stringify(current_value, "\t")
			text_edit.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(text_edit.text)
				if parsed_value != null:
					screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: parsed_value})
					refresh_after_behavior_change(screen)
			)
			wrapper.add_child(text_edit)
		"array":
			if screen._is_action_reference_parameter(parameter_name):
				wrapper.add_child(build_action_reference_array_editor(screen, "additional_action", additional_action_id, parameter_name, current_value))
				return panel
			var array_text := TextEdit.new()
			array_text.custom_minimum_size = Vector2(0, 72)
			array_text.text = JSON.stringify(current_value, "\t")
			array_text.focus_exited.connect(func():
				var parsed_value: Variant = JSON.parse_string(array_text.text)
				if parsed_value != null:
					screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: parsed_value})
					refresh_after_behavior_change(screen)
			)
			wrapper.add_child(array_text)
		"card_array":
			wrapper.add_child(build_additional_action_string_array_editor(screen, additional_action_id, parameter_name, current_value, "card_1,card_2"))
		"string_array":
			wrapper.add_child(build_additional_action_string_array_editor(screen, additional_action_id, parameter_name, current_value, "value_1,value_2"))
		"int", "float":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1 if value_type == "int" else 0.1
			spin.value = float(current_value if current_value != null else 0)
			spin.value_changed.connect(func(value: float):
				screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: int(value) if value_type == "int" else value})
				refresh_after_behavior_change(screen)
			)
			wrapper.add_child(spin)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: screen._coerce_string_parameter(new_text, value_type)})
				refresh_after_behavior_change(screen)
			)
			line_edit.focus_exited.connect(func():
				screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: screen._coerce_string_parameter(line_edit.text, value_type)})
				refresh_after_behavior_change(screen)
			)
			wrapper.add_child(line_edit)
	return panel

static func build_action_reference_array_editor(screen, owner_type: String, owner_key: String, parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var reference_ids: Array = []
	reference_ids.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var action_dropdown := OptionButton.new()
	action_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen._populate_option_button(action_dropdown, screen._metadata_options(screen.service.get_action_options("action_children")))
	add_row.add_child(action_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Action"
	add_button.button_up.connect(func():
		var selected_token: Variant = screen._get_option_button_value(action_dropdown)
		if selected_token == null:
			return
		if screen.service.create_additional_action_reference(screen.current_session, owner_type, owner_key, parameter_name, str(selected_token)) != "":
			refresh_after_behavior_structure_change(screen)
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
		reference_label.text = get_action_reference_label(screen, reference_id, reference_value)
		row.add_child(reference_label)
		var up_button := Button.new()
		up_button.text = "Up"
		up_button.button_up.connect(func():
			if screen.service.move_action_reference(screen.current_session, owner_type, owner_key, parameter_name, reference_index, max(reference_index - 1, 0)):
				refresh_after_behavior_structure_change(screen)
		)
		row.add_child(up_button)
		var down_button := Button.new()
		down_button.text = "Down"
		down_button.button_up.connect(func():
			if screen.service.move_action_reference(screen.current_session, owner_type, owner_key, parameter_name, reference_index, min(reference_index + 1, len(reference_ids) - 1)):
				refresh_after_behavior_structure_change(screen)
		)
		row.add_child(down_button)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func():
			if screen.service.remove_action_reference(screen.current_session, owner_type, owner_key, parameter_name, reference_index):
				refresh_after_behavior_structure_change(screen)
		)
		row.add_child(remove_button)
		wrapper.add_child(row)
	return wrapper

static func build_additional_action_enum_array_editor(screen, additional_action_id: String, parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
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
		screen._setup_checkbox(checkbox)
		screen._style_checkbox(checkbox, checkbox.button_pressed)
		checkbox.toggled.connect(func(pressed: bool):
			var next_values: Array = current_values.duplicate(true)
			if pressed and not next_values.has(option_value):
				next_values.append(option_value)
			elif not pressed:
				next_values.erase(option_value)
			screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: next_values})
			refresh_after_behavior_change(screen)
		)
		wrapper.add_child(checkbox)
	return wrapper

static func build_additional_action_string_array_editor(screen, additional_action_id: String, parameter_name: String, current_value: Variant, placeholder_text: String) -> Control:
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = placeholder_text
	line_edit.text = ",".join(screen._variant_to_string_array(current_value))
	line_edit.text_submitted.connect(func(_text: String):
		screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: screen._parse_csv_strings(line_edit.text)})
		refresh_after_behavior_change(screen)
	)
	line_edit.focus_exited.connect(func():
		screen.service.update_additional_action_values(screen.current_session, additional_action_id, {parameter_name: screen._parse_csv_strings(line_edit.text)})
		refresh_after_behavior_change(screen)
	)
	return line_edit

static func card_entry_owner_key(property_name: String, index: int) -> String:
	return "%s::%s" % [property_name, index]

static func get_action_reference_label(screen, reference_id: String, reference_value: Variant) -> String:
	var additional_entries: Array = screen.service.get_additional_action_entries(screen.current_session)
	for additional_action: Dictionary in additional_entries:
		if str(additional_action.get("id", "")) != reference_id:
			continue
		var action_entry: Dictionary = additional_action.get("action", {})
		if action_entry.is_empty():
			break
		var token: String = str(action_entry.keys()[0])
		var metadata: Dictionary = screen.service.get_action_metadata(token)
		var display_name: String = str(metadata.get("display_name", token))
		return "%s (%s)" % [display_name, reference_id]
	if reference_value is Dictionary:
		var legacy_entry: Dictionary = reference_value
		if not legacy_entry.is_empty():
			return "Legacy inline action"
	return "Missing action (%s)" % reference_id

static func should_show_parameter(screen, parameter_data: Dictionary, values: Dictionary) -> bool:
	var parameter_name: String = str(parameter_data.get("name", ""))
	if parameter_name == "":
		return false
	if not screen.NOISY_PARAMETER_DEFAULTS.has(parameter_name):
		return true
	if values.has(parameter_name):
		return values[parameter_name] != screen.NOISY_PARAMETER_DEFAULTS[parameter_name]
	return false

static func build_advanced_parameter_toggle(screen, property_name: String, index: int, token: String, is_action: bool, values: Dictionary) -> Control:
	var metadata: Dictionary = screen.service.get_action_metadata(token) if is_action else screen.service.get_validator_metadata(token)
	var parameters: Array[Dictionary] = []
	parameters.assign(metadata.get("parameters", []))
	var hidden_parameters: Array[String] = []
	for parameter_data: Dictionary in parameters:
		var parameter_name: String = str(parameter_data.get("name", ""))
		if parameter_name == "":
			continue
		if should_show_parameter(screen, parameter_data, values):
			continue
		hidden_parameters.append(parameter_name)
	if hidden_parameters.is_empty():
		return null
	var entry_key: String = entry_visibility_key(property_name, index, token)
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var toggle_button := Button.new()
	toggle_button.text = "Hide advanced fields" if bool(screen.expanded_entry_parameters.get(entry_key, false)) else "Show advanced fields"
	toggle_button.button_up.connect(func():
		screen.expanded_entry_parameters[entry_key] = not bool(screen.expanded_entry_parameters.get(entry_key, false))
		request_behavior_render(screen)
	)
	wrapper.add_child(toggle_button)
	if not bool(screen.expanded_entry_parameters.get(entry_key, false)):
		return wrapper
	var parameter_grid := GridContainer.new()
	parameter_grid.columns = screen._get_behavior_parameter_columns()
	parameter_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameter_grid.add_theme_constant_override("h_separation", 8)
	parameter_grid.add_theme_constant_override("v_separation", 8)
	for parameter_data: Dictionary in parameters:
		if should_show_parameter(screen, parameter_data, values):
			continue
		parameter_grid.add_child(build_entry_parameter_editor(screen, property_name, index, token, parameter_data, values))
	wrapper.add_child(parameter_grid)
	return wrapper

static func entry_visibility_key(property_name: String, index: int, token: String) -> String:
	return "%s:%s:%s" % [property_name, index, token]

static func refresh_after_behavior_change(screen) -> void:
	screen._render_preview()
	screen._render_session_summary()
	screen._refresh_overview()

static func refresh_after_behavior_structure_change(screen) -> void:
	request_behavior_render(screen)
	refresh_after_behavior_change(screen)

static func request_behavior_render(screen) -> void:
	if screen.behavior_render_queued:
		return
	screen.behavior_render_queued = true
	screen.call_deferred("_render_behavior")
