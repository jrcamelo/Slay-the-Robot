# UI element for a status effect
extends TextureRect
class_name StatusEffect

var status_effect_script: BaseStatusEffect

@onready var status_charge_label: Label = $StatusChargeLabel
@onready var status_secondary_charge_label = $StatusSecondaryChargeLabel
@onready var _default_texture: Texture2D = texture

func update_status_charge_display() -> void:
	visible = status_effect_script.status_effect_data.status_effect_is_visible
	_update_status_texture()
	
	if status_effect_script.is_flag_status():
		status_charge_label.text = ""
	elif status_effect_script.status_charges == 1 and not status_effect_script.status_effect_data.status_effect_stacks:
		status_charge_label.text = ""
	else:
		status_charge_label.text = str(status_effect_script.status_charges)
	
	if status_effect_script.status_secondary_charges == 0:
		status_secondary_charge_label.text = ""
	else:
		status_secondary_charge_label.text = str(status_effect_script.status_secondary_charges)
	
	
	tooltip_text = status_effect_script.get_display_name()
	var display_description: String = status_effect_script.get_display_description()
	if display_description != "":
		tooltip_text += "\n" + display_description

func _update_status_texture() -> void:
	var texture_path: String = status_effect_script.get_display_texture_path()
	if texture_path.strip_edges() == "":
		texture = _default_texture
		return
	if texture_path.begins_with("res://"):
		texture = load(texture_path)
		return
	texture = FileLoader.load_texture(texture_path)
