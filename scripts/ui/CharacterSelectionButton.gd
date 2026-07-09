extends TextureButton

var character_object_id: String = ""	# the character id this button represents

func _ready():
	button_up.connect(_on_button_up)
	
func init(_character_object_id: String) -> void:
	character_object_id = _character_object_id
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data != null:
		if character_data.character_icon_texture_path != "":
			texture_normal = FileLoader.load_texture(character_data.character_icon_texture_path)
		tooltip_text = _build_character_tooltip(character_data)

func _on_button_up():
	Signals.character_selected.emit(character_object_id)

func _build_character_tooltip(character_data: CharacterData) -> String:
	var tooltip_lines: Array[String] = [character_data.character_name]
	if len(character_data.character_passive_status_effect_ids) > 0:
		var passive_status_data: StatusEffectData = Global.get_status_effect_data(character_data.character_passive_status_effect_ids[0])
		if passive_status_data != null:
			tooltip_lines.append(passive_status_data.status_effect_name)
			if passive_status_data.status_effect_description != "":
				tooltip_lines.append(passive_status_data.status_effect_description)
	return "\n".join(tooltip_lines)
