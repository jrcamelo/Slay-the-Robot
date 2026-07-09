extends Node2D

const MONK_PLACEHOLDER_TEXTURE_PATH: String = "external/sprites/characters/character_blue/character_blue.png"

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	sprite.texture = FileLoader.load_texture(MONK_PLACEHOLDER_TEXTURE_PATH)
