extends Control

@onready var title_screen: Control = $%TitleScreen

@onready var character_name_label = $CharacterNameLabel
@onready var character_health_label = $CharacterHealthLabel
@onready var character_money_label = $CharacterMoneyLabel
@onready var character_description_label = $CharacterDescriptionLabel

@onready var character_artifact_texture_rect = $CharacterArtifactTextureRect
@onready var character_artifact_name_label = $CharacterArtifactNameLabel
@onready var character_artifact_description_label = $CharacterArtifactDescriptionLabel

@onready var decrease_difficulty_button = $DifficultySelect/DecreaseDifficultyButton
@onready var difficulty_label = $DifficultySelect/DifficultyLabel
@onready var increase_difficulty_button = $DifficultySelect/IncreaseDifficultyButton

@onready var custom_run_modifier_button_container = $CustomRunModifierButtonContainer

@onready var character_button_container = $CharacterButtonContainer
@onready var selected_characters_container: ScrollContainer = $SelectedCharactersContainer
@onready var selected_characters_grid_container: GridContainer = $SelectedCharactersContainer/GridContainer
@onready var select_character_button: Button = $SelectCharacterButton

@onready var start_run_button: Button = $StartRunButton
@onready var seed_input: LineEdit = $SeedInput
@onready var back_button: Button = $BackButton

var selected_character_object_id: String = ""
var selected_difficulty_level: int = 0
var selected_party_character_object_ids: Array[String] = []

func _ready():
	start_run_button.button_up.connect(_on_start_run_button_up)
	back_button.button_up.connect(_on_back_button_up)
	select_character_button.button_up.connect(_on_select_character_button_up)
	
	decrease_difficulty_button.button_up.connect(_on_decrease_difficulty_button)
	increase_difficulty_button.button_up.connect(_on_increase_difficulty_button)
	
	seed_input.text_changed.connect(_on_seed_input_text_changed)
	
	Signals.character_selected.connect(_on_character_selected)
	Signals.run_ended.connect(_on_run_ended)
	_update_party_ui()

func _on_seed_input_text_changed(new_text: String):
	# validate the input of the line edit
	var caret_column: int = seed_input.caret_column	# store cursor position as changing text resets it
	seed_input.text = str(new_text.to_int()) # validate inputs to only int
	seed_input.caret_column = min(caret_column, len(seed_input.text)) # reset the cursor position

func _on_character_selected(character_object_id: String):
	selected_character_object_id = character_object_id
	populate_character_info(selected_character_object_id)
	_update_party_ui()

func _on_decrease_difficulty_button():
	selected_difficulty_level = max(0, selected_difficulty_level -1)
	difficulty_label.text = "Difficulty " + str(selected_difficulty_level)
func _on_increase_difficulty_button():
	selected_difficulty_level = min(selected_difficulty_level + 1, len(PlayerData.DIFFICULTY_RUN_MODIFIER_OBJECT_IDS))
	difficulty_label.text = "Difficulty " + str(selected_difficulty_level)

func populate_new_run_menu() -> void:
	selected_party_character_object_ids.clear()
	character_button_container.populate_character_buttons()
	custom_run_modifier_button_container.populate_custom_run_modifiers()
	_update_party_ui()

func populate_character_info(character_object_id: String) -> void:
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data != null:
		character_name_label.text = character_data.character_name
		character_health_label.text = "HP: {0}".format([character_data.character_starting_health])
		character_money_label.text = "Money: {0}".format([character_data.character_starting_money])
		character_description_label.text = character_data.character_description
		character_artifact_texture_rect.texture = null
		character_artifact_texture_rect.tooltip_text = ""
		character_artifact_name_label.text = ""
		character_artifact_description_label.text = ""
		if len(character_data.character_passive_status_effect_ids) > 0:
			var status_effect_data: StatusEffectData = Global.get_status_effect_data(character_data.character_passive_status_effect_ids[0])
			if status_effect_data != null:
				character_artifact_texture_rect.texture = FileLoader.load_texture(status_effect_data.status_effect_texture_path)
				character_artifact_texture_rect.tooltip_text = _build_passive_tooltip(status_effect_data)
				character_artifact_name_label.text = status_effect_data.status_effect_name
				character_artifact_description_label.text = status_effect_data.status_effect_description
		elif len(character_data.character_starting_artifact_ids) > 0:
			var artifact_data: ArtifactData = Global.get_artifact_data(character_data.character_starting_artifact_ids[0])
			if artifact_data != null:
				character_artifact_texture_rect.texture = FileLoader.load_texture(artifact_data.artifact_texture_path)
				character_artifact_texture_rect.tooltip_text = artifact_data.artifact_name + "\n" + artifact_data.artifact_description
				character_artifact_name_label.text = artifact_data.artifact_name
				character_artifact_description_label.text = artifact_data.artifact_description

func _on_start_run_button_up():
	if len(selected_party_character_object_ids) == 0:
		return
	# get the seed and start the run
	var run_seed: int = seed_input.text.to_int()
	Global.start_party_run(selected_party_character_object_ids, run_seed, selected_difficulty_level, custom_run_modifier_button_container.selected_custom_run_modififers)

func _on_back_button_up():
	title_screen.show_main_menu()

func _on_run_ended():
	# go back to tile screen on failed run, but not abandoned run
	var has_save_file: bool = FileLoader.has_save_file()
	visible = not has_save_file
	populate_new_run_menu()

func _on_select_character_button_up() -> void:
	if selected_character_object_id == "":
		return
	if selected_party_character_object_ids.has(selected_character_object_id):
		selected_party_character_object_ids.erase(selected_character_object_id)
	else:
		selected_party_character_object_ids.append(selected_character_object_id)
	_update_party_ui()

func _update_party_ui() -> void:
	_clear_selected_characters()
	for character_object_id: String in selected_party_character_object_ids:
		var character_selection_button: TextureButton = Scenes.CHARACTER_SELECTION_BUTTON.instantiate()
		selected_characters_grid_container.add_child(character_selection_button)
		character_selection_button.init(character_object_id)
		character_selection_button.disabled = true
	start_run_button.disabled = len(selected_party_character_object_ids) == 0
	select_character_button.disabled = selected_character_object_id == ""
	if selected_character_object_id == "":
		select_character_button.text = "Select Character"
	else:
		var character_data: CharacterData = Global.get_character_data(selected_character_object_id)
		var character_name: String = selected_character_object_id
		if character_data != null:
			character_name = character_data.character_name
		if selected_party_character_object_ids.has(selected_character_object_id):
			select_character_button.text = "Remove %s from party" % character_name
		else:
			select_character_button.text = "Add %s to party" % character_name

func _clear_selected_characters() -> void:
	for child in selected_characters_grid_container.get_children():
		child.queue_free()

func _build_passive_tooltip(status_effect_data: StatusEffectData) -> String:
	var tooltip_lines: Array[String] = [status_effect_data.status_effect_name]
	if status_effect_data.status_effect_description != "":
		tooltip_lines.append(status_effect_data.status_effect_description)
	return "\n".join(tooltip_lines)
