extends Node2D

const CardEditorWebSidecar = preload("res://scripts/tools/card_editor_web/CardEditorWebSidecar.gd")

func _ready() -> void:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	var all_args: PackedStringArray = OS.get_cmdline_args()
	if not user_args.has("--card-editor-sidecar") and not all_args.has("--card-editor-sidecar"):
		return
	var sidecar := CardEditorWebSidecar.new()
	add_child(sidecar)
