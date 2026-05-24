## UI menu to display all content in the game such as all cards
extends Control

@onready var title_screen: Control = $%TitleScreen
@onready var back_button: Button = $BackButton
@onready var codex_card_container: GridContainer = $ScrollContainer/MarginContainer/CodexCardContainer
@onready var cards_button: Button = $VBoxContainer/CardsButton
@onready var card_editor_button: Button = $VBoxContainer/CardEditorButton

func _ready():
	back_button.button_up.connect(_on_back_button_up)
	cards_button.button_up.connect(_on_cards_button_up)
	card_editor_button.button_up.connect(_on_card_editor_button_up)

func populate_codex_menu() -> void:
	populate_codex_card_container()

func populate_codex_card_container() -> void:
	clear_codex_card_container()
	# creates all cards in the game to display
	var card_object_ids: Array = Global._id_to_card_data.keys()
	card_object_ids.sort()

	for card_object_id: String in card_object_ids:
		var card_data: CardData = Global.get_card_data(card_object_id)
		
		# generate an un-interactable card object for display
		var card: Card = Scenes.CARD.instantiate()
		codex_card_container.add_child(card)
		card.init(card_data, 0, false, false)

func clear_codex_card_container() -> void:
	for child in codex_card_container.get_children():
		child.queue_free()

func _on_back_button_up():
	clear_codex_card_container()
	title_screen.show_main_menu()

func _on_cards_button_up() -> void:
	populate_codex_card_container()

func _on_card_editor_button_up() -> void:
	clear_codex_card_container()
	title_screen.show_card_editor()
