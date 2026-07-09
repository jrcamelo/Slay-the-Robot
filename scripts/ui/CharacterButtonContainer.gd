extends ScrollContainer

@onready var grid_container = $GridContainer

const HIDDEN_CHARACTER_IDS: Array[String] = ["character_orange"]


func populate_character_buttons() -> void:
	clear_character_buttons()
	
	var character_object_ids: Array[String] = []
	for character_object_id: String in Global._id_to_character_data.keys():
		if not HIDDEN_CHARACTER_IDS.has(character_object_id):
			character_object_ids.append(character_object_id)
	character_object_ids.sort()
	
	var first_button: TextureButton = null
	
	for character_object_id: String in character_object_ids:
		var character_selection_button = Scenes.CHARACTER_SELECTION_BUTTON.instantiate()
		grid_container.add_child(character_selection_button)
		character_selection_button.init(character_object_id)
		if first_button == null:
			first_button = character_selection_button
	
	if first_button != null:
		first_button.button_pressed = true
		first_button.button_up.emit()
	
	
func clear_character_buttons() -> void:
	for child in grid_container.get_children():
		child.queue_free()
