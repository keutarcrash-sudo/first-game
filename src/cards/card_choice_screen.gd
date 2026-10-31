## Card choice screen (story 006): dims the game and shows the offered cards
## side by side. The player clicks one with the mouse. Buttons take no keyboard
## focus, so Space cannot pick a card or start a wave. Owns no game state: it
## only emits [signal card_chosen].
class_name CardChoiceScreen
extends CanvasLayer

## Emitted when the player clicks a card. The screen hides itself first.
signal card_chosen(card: CardDef)

const SCREEN_LAYER := 10
const DIM_COLOR := Color(0.0, 0.0, 0.05, 0.8)
const TITLE_FONT_SIZE := 38
const NAME_FONT_SIZE := 28
const TEXT_FONT_SIZE := 20
const COMBINE_FONT_SIZE := 18
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const NAME_COLOR := Color(1.0, 0.9, 0.35)
const COMBINE_COLOR := Color(0.55, 0.9, 1.0)
const CARD_SIZE := Vector2(280.0, 340.0)
const CARD_PADDING := 16.0
const CARD_SPACING := 28
const TEXT_SPACING := 14

var _row: HBoxContainer


func _init() -> void:
	layer = SCREEN_LAYER
	visible = false


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP  # Clicks never reach the arena below.
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = DIM_COLOR
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 32)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	var title := Label.new()
	title.text = "Choisis une carte"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override(&"font_color", TEXT_COLOR)
	column.add_child(title)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override(&"separation", CARD_SPACING)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_row)


## Shows [param cards] (one clickable card each) and waits for a click.
func show_cards(cards: Array[CardDef]) -> void:
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for card: CardDef in cards:
		_row.add_child(_make_card(card))
	visible = true


func _make_card(card: CardDef) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE  # Space starts the wave: a focused card must not react to it.
	button.custom_minimum_size = CARD_SIZE
	button.pressed.connect(_on_card_pressed.bind(card))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = CARD_PADDING
	box.offset_top = CARD_PADDING
	box.offset_right = -CARD_PADDING
	box.offset_bottom = -CARD_PADDING
	box.add_theme_constant_override(&"separation", TEXT_SPACING)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var name_label: Label = _make_label(card.display_name, NAME_FONT_SIZE, NAME_COLOR)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var description: Label = _make_label(card.description, TEXT_FONT_SIZE, TEXT_COLOR)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description)
	if not card.combines_with.is_empty():
		box.add_child(_make_label("Combine avec : %s" % card.combines_with, COMBINE_FONT_SIZE, COMBINE_COLOR))
	return button


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _on_card_pressed(card: CardDef) -> void:
	visible = false
	card_chosen.emit(card)
