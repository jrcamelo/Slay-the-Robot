extends RefCounted

static func build_string_array_parameter_editor(screen, property_name: String, index: int, parameter_name: String, current_value: Variant, placeholder_text: String) -> Control:
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = placeholder_text
	line_edit.text = ",".join(variant_to_string_array(current_value))
	line_edit.text_submitted.connect(func(_text: String):
		screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: screen._parse_csv_strings(line_edit.text)})
		screen._refresh_after_behavior_change()
	)
	line_edit.focus_exited.connect(func():
		screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: screen._parse_csv_strings(line_edit.text)})
		screen._refresh_after_behavior_change()
	)
	return line_edit

static func build_enum_array_parameter_editor(screen, property_name: String, index: int, parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
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
		screen._setup_checkbox(checkbox)
		screen._style_checkbox(checkbox, checkbox.button_pressed)
		checkbox.toggled.connect(func(pressed: bool):
			var next_values: Array = []
			next_values.assign(current_values)
			if pressed and not next_values.has(option_value):
				next_values.append(option_value)
			elif not pressed:
				next_values.erase(option_value)
			screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: next_values})
			screen._refresh_after_behavior_change()
		)
		wrapper.add_child(checkbox)
	return wrapper

static func build_nested_validator_array_editor(screen, property_name: String, index: int, parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var entries: Array = []
	entries.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var validator_dropdown := OptionButton.new()
	validator_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen._populate_option_button(validator_dropdown, screen._metadata_options(screen.service.get_validator_options("card_pick")))
	add_row.add_child(validator_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Validator"
	add_button.button_up.connect(func():
		var selected_token: Variant = screen._get_option_button_value(validator_dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries.append(screen.service.create_validator_entry(str(selected_token)))
		screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: next_entries})
		screen._refresh_after_behavior_structure_change()
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
		screen._populate_option_button(dropdown, screen._metadata_options(screen.service.get_validator_options("card_pick")), nested_token)
		dropdown.item_selected.connect(func(_selected: int):
			var selected_token: Variant = screen._get_option_button_value(dropdown)
			if selected_token == null:
				return
			var replacement: Dictionary = screen.service.create_validator_entry(str(selected_token))
			if replacement.is_empty():
				return
			var next_entries: Array = entries.duplicate(true)
			next_entries[nested_index] = replacement
			screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: next_entries})
			screen._refresh_after_behavior_structure_change()
		)
		header.add_child(dropdown)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func():
			var next_entries: Array = entries.duplicate(true)
			next_entries.remove_at(nested_index)
			screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: next_entries})
			screen._refresh_after_behavior_structure_change()
		)
		header.add_child(remove_button)
		nested_vbox.add_child(header)
		var metadata: Dictionary = screen.service.get_validator_metadata(nested_token)
		var parameters: Array[Dictionary] = []
		parameters.assign(metadata.get("parameters", []))
		for parameter_data: Dictionary in parameters:
			var nested_parameter_name: String = str(parameter_data.get("name", ""))
			if nested_parameter_name == "":
				continue
			nested_vbox.add_child(build_nested_validator_parameter_row(screen, property_name, index, parameter_name, nested_index, nested_token, nested_values, parameter_data))
		wrapper.add_child(nested_panel)
	return wrapper

static func build_nested_action_array_editor(screen, property_name: String, index: int, parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var entries: Array = []
	entries.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	var action_dropdown := OptionButton.new()
	action_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen._populate_option_button(action_dropdown, screen._metadata_options(screen.service.get_action_options("action_children")))
	add_row.add_child(action_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Child Action"
	add_button.button_up.connect(func():
		var selected_token: Variant = screen._get_option_button_value(action_dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries.append(screen.service.create_action_entry(str(selected_token)))
		screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: next_entries})
		screen._refresh_after_behavior_structure_change()
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
		wrapper.add_child(build_nested_action_entry_editor(screen, property_name, index, parameter_name, nested_index, nested_entry, entries))
	return wrapper

static func build_nested_action_entry_editor(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_entry: Dictionary, entries: Array) -> Control:
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
	screen._populate_option_button(dropdown, screen._metadata_options(screen.service.get_action_options("action_children")), nested_token)
	dropdown.item_selected.connect(func(_selected: int):
		var selected_token: Variant = screen._get_option_button_value(dropdown)
		if selected_token == null:
			return
		var replacement: Dictionary = screen.service.create_action_entry(str(selected_token))
		if replacement.is_empty():
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries[nested_index] = replacement
		screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: next_entries})
		screen._refresh_after_behavior_structure_change()
	)
	header.add_child(dropdown)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		var next_entries: Array = entries.duplicate(true)
		next_entries.remove_at(nested_index)
		screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: next_entries})
		screen._refresh_after_behavior_structure_change()
	)
	header.add_child(remove_button)
	vbox.add_child(header)
	var metadata: Dictionary = screen.service.get_action_metadata(nested_token)
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
		vbox.add_child(build_nested_action_parameter_row(screen, property_name, index, parameter_name, nested_index, nested_token, nested_values, child_parameter))
	return panel

static func build_nested_action_parameter_row(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_values: Dictionary, parameter_data: Dictionary) -> Control:
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
			screen._setup_checkbox(checkbox)
			screen._style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, pressed)
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
				update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, dropdown.get_item_metadata(option_index))
			)
			row.add_child(dropdown)
		"enum_array":
			row.add_child(build_nested_action_enum_array_editor(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, parameter_data, current_value))
		"validator_array":
			row.add_child(build_nested_action_validator_array_editor(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value))
		"array":
			if is_action_array_parameter(nested_parameter_name, current_value):
				row.add_child(build_deep_nested_action_array_editor(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value))
			else:
				var text_edit := TextEdit.new()
				text_edit.custom_minimum_size = Vector2(0, 72)
				text_edit.text = JSON.stringify(current_value, "\t")
				text_edit.focus_exited.connect(func():
					var parsed_value: Variant = JSON.parse_string(text_edit.text)
					if parsed_value != null:
						update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, parsed_value)
				)
				row.add_child(text_edit)
		"card_array":
			row.add_child(build_nested_action_string_array_editor(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value, "card_1,card_2"))
		"string_array":
			row.add_child(build_nested_action_string_array_editor(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value, "value_1,value_2"))
		"int", "float":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1 if value_type == "int" else 0.1
			spin.value = float(current_value if current_value != null else 0)
			spin.value_changed.connect(func(value: float):
				update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, int(value) if value_type == "int" else value)
			)
			row.add_child(spin)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, screen._coerce_string_parameter(new_text, value_type))
			)
			line_edit.focus_exited.connect(func():
				update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, screen._coerce_string_parameter(line_edit.text, value_type))
			)
			row.add_child(line_edit)
	return row

static func build_nested_action_enum_array_editor(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
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
			update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_values)
		)
		wrapper.add_child(checkbox)
	return wrapper

static func build_nested_action_string_array_editor(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant, placeholder_text: String) -> Control:
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = placeholder_text
	line_edit.text = ",".join(variant_to_string_array(current_value))
	line_edit.text_submitted.connect(func(_text: String):
		update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, screen._parse_csv_strings(line_edit.text))
	)
	line_edit.focus_exited.connect(func():
		update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, screen._parse_csv_strings(line_edit.text))
	)
	return line_edit

static func build_nested_action_validator_array_editor(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var entries: Array = []
	entries.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	var validator_dropdown := OptionButton.new()
	validator_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen._populate_option_button(validator_dropdown, screen._metadata_options(screen.service.get_validator_options("card_pick")))
	add_row.add_child(validator_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Validator"
	add_button.button_up.connect(func():
		var selected_token: Variant = screen._get_option_button_value(validator_dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries.append(screen.service.create_validator_entry(str(selected_token)))
		update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
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
		screen._populate_option_button(dropdown, screen._metadata_options(screen.service.get_validator_options("card_pick")), validator_token)
		dropdown.item_selected.connect(func(_selected: int):
			var selected_token: Variant = screen._get_option_button_value(dropdown)
			if selected_token == null:
				return
			var next_entries: Array = entries.duplicate(true)
			next_entries[validator_index] = screen.service.create_validator_entry(str(selected_token))
			update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
		)
		header.add_child(dropdown)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.button_up.connect(func():
			var next_entries: Array = entries.duplicate(true)
			next_entries.remove_at(validator_index)
			update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
		)
		header.add_child(remove_button)
		vbox.add_child(header)
		for child_parameter: Dictionary in screen.service.get_validator_metadata(validator_token).get("parameters", []):
			var child_parameter_name: String = str(child_parameter.get("name", ""))
			if child_parameter_name == "":
				continue
			vbox.add_child(build_nested_action_validator_parameter_row(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, validator_values, child_parameter))
		wrapper.add_child(panel)
	return wrapper

static func build_nested_action_validator_parameter_row(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, validator_index: int, validator_token: String, validator_values: Dictionary, parameter_data: Dictionary) -> Control:
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
			screen._setup_checkbox(checkbox)
			screen._style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				update_deep_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, child_parameter_name, pressed)
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
				update_deep_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, child_parameter_name, dropdown.get_item_metadata(option_index))
			)
			row.add_child(dropdown)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				update_deep_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, child_parameter_name, screen._coerce_string_parameter(new_text, value_type))
			)
			line_edit.focus_exited.connect(func():
				update_deep_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, validator_index, validator_token, child_parameter_name, screen._coerce_string_parameter(line_edit.text, value_type))
			)
			row.add_child(line_edit)
	return row

static func build_deep_nested_action_array_editor(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	var entries: Array = []
	entries.assign(current_value if current_value is Array else [])
	var add_row := HBoxContainer.new()
	var action_dropdown := OptionButton.new()
	action_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen._populate_option_button(action_dropdown, screen._metadata_options(screen.service.get_action_options("action_children")))
	add_row.add_child(action_dropdown)
	var add_button := Button.new()
	add_button.text = "Add Child Action"
	add_button.button_up.connect(func():
		var selected_token: Variant = screen._get_option_button_value(action_dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries.append(screen.service.create_action_entry(str(selected_token)))
		update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
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
		wrapper.add_child(build_deep_nested_action_entry_editor(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_entry, entries))
	return wrapper

static func build_deep_nested_action_entry_editor(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, deep_index: int, deep_entry: Dictionary, entries: Array) -> Control:
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
	screen._populate_option_button(dropdown, screen._metadata_options(screen.service.get_action_options("action_children")), deep_token)
	dropdown.item_selected.connect(func(_selected: int):
		var selected_token: Variant = screen._get_option_button_value(dropdown)
		if selected_token == null:
			return
		var next_entries: Array = entries.duplicate(true)
		next_entries[deep_index] = screen.service.create_action_entry(str(selected_token))
		update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
	)
	header.add_child(dropdown)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.button_up.connect(func():
		var next_entries: Array = entries.duplicate(true)
		next_entries.remove_at(deep_index)
		update_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_entries, true)
	)
	header.add_child(remove_button)
	vbox.add_child(header)
	for child_parameter: Dictionary in screen.service.get_action_metadata(deep_token).get("parameters", []):
		var child_parameter_name: String = str(child_parameter.get("name", ""))
		if child_parameter_name == "":
			continue
		vbox.add_child(build_deep_nested_action_parameter_row(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, deep_values, child_parameter))
	return panel

static func build_deep_nested_action_parameter_row(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, deep_index: int, deep_token: String, deep_values: Dictionary, parameter_data: Dictionary) -> Control:
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
			screen._setup_checkbox(checkbox)
			screen._style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				update_deep_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, child_parameter_name, pressed)
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
				update_deep_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, child_parameter_name, dropdown.get_item_metadata(option_index))
			)
			row.add_child(dropdown)
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				update_deep_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, child_parameter_name, screen._coerce_string_parameter(new_text, value_type))
			)
			line_edit.focus_exited.connect(func():
				update_deep_nested_action_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, deep_index, deep_token, child_parameter_name, screen._coerce_string_parameter(line_edit.text, value_type))
			)
			row.add_child(line_edit)
	return row

static func build_nested_validator_parameter_row(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_values: Dictionary, parameter_data: Dictionary) -> Control:
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
			screen._setup_checkbox(checkbox)
			screen._style_checkbox(checkbox, checkbox.button_pressed)
			checkbox.toggled.connect(func(pressed: bool):
				update_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, pressed)
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
				update_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, dropdown.get_item_metadata(option_index))
			)
			row.add_child(dropdown)
		"enum_array":
			row.add_child(build_nested_validator_enum_array_editor(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, parameter_data, current_value))
		"int", "float":
			var spin := SpinBox.new()
			spin.min_value = -999
			spin.max_value = 9999
			spin.step = 1 if value_type == "int" else 0.1
			spin.value = float(current_value if current_value != null else 0)
			spin.value_changed.connect(func(value: float):
				update_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, int(value) if value_type == "int" else value)
			)
			row.add_child(spin)
		"string_array":
			row.add_child(build_nested_validator_string_array_editor(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, current_value))
		_:
			var line_edit := LineEdit.new()
			line_edit.text = "" if current_value == null else str(current_value)
			line_edit.text_submitted.connect(func(new_text: String):
				update_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, screen._coerce_string_parameter(new_text, value_type))
			)
			line_edit.focus_exited.connect(func():
				update_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, screen._coerce_string_parameter(line_edit.text, value_type))
			)
			row.add_child(line_edit)
	return row

static func build_nested_validator_enum_array_editor(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, parameter_data: Dictionary, current_value: Variant) -> Control:
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
			update_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, next_values)
		)
		wrapper.add_child(checkbox)
	return wrapper

static func build_nested_validator_string_array_editor(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, current_value: Variant) -> Control:
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = "value_1,value_2"
	line_edit.text = ",".join(variant_to_string_array(current_value))
	line_edit.text_submitted.connect(func(_text: String):
		update_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, screen._parse_csv_strings(line_edit.text))
	)
	line_edit.focus_exited.connect(func():
		update_nested_validator_value(screen, property_name, index, parameter_name, nested_index, nested_token, nested_parameter_name, screen._parse_csv_strings(line_edit.text))
	)
	return line_edit

static func update_nested_validator_value(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, next_value: Variant) -> void:
	var entries: Array = []
	var root_entry: Dictionary = screen.current_session.working_card_data.get(property_name)[index]
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
	screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: entries})
	screen._refresh_after_behavior_change()

static func update_nested_action_value(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, next_value: Variant, rerender_behavior: bool = false) -> void:
	var entries: Array = []
	var root_entry: Dictionary = screen.current_session.working_card_data.get(property_name)[index]
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
	screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: entries})
	if rerender_behavior:
		screen._refresh_after_behavior_structure_change()
	else:
		screen._refresh_after_behavior_change()

static func update_deep_nested_validator_value(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, validator_index: int, validator_token: String, child_parameter_name: String, next_value: Variant) -> void:
	var nested_actions: Array = []
	var root_entry: Dictionary = screen.current_session.working_card_data.get(property_name)[index]
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
	screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: nested_actions})
	screen._refresh_after_behavior_change()

static func update_deep_nested_action_value(screen, property_name: String, index: int, parameter_name: String, nested_index: int, nested_token: String, nested_parameter_name: String, deep_index: int, deep_token: String, child_parameter_name: String, next_value: Variant) -> void:
	var nested_actions: Array = []
	var root_entry: Dictionary = screen.current_session.working_card_data.get(property_name)[index]
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
	screen.service.update_entry_values(screen.current_session, property_name, index, {parameter_name: nested_actions})
	screen._refresh_after_behavior_change()

static func variant_to_string_array(value: Variant) -> Array[String]:
	var values: Array[String] = []
	if value is Array:
		for item: Variant in value:
			values.append(str(item))
	return values

static func is_action_reference_parameter(parameter_name: String) -> bool:
	return parameter_name in ["action_data", "passed_action_data", "failed_action_data", "actions_on_lethal"]

static func is_action_array_parameter(parameter_name: String, current_value: Variant) -> bool:
	if not (current_value is Array):
		return false
	return is_action_reference_parameter(parameter_name)
