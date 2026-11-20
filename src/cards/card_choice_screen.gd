## Card choice screen (story 006): dims the game and shows the offered cards
## side by side. The player clicks one with the mouse. Buttons take no keyboard
## focus, so Space cannot pick a card or start a wave. Owns no game state: it
## only emits [signal card_chosen].
class_name CardChoiceScreen
extends CanvasLayer

## Emitted when the player clicks a card. The screen hides itself first.
signal card_chosen(card: CardDef)
## Emitted when the player clicks the reroll button. The screen stays open.
signal reroll_requested

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
const SCREEN_SIDE_MARGIN := 40.0  # Minimum free space left and right of the row (4 cards with the skill tree bonus).
const TEXT_SPACING := 14
const REROLL_FONT_SIZE := 24
const RARITY_FONT_SIZE := 26
const UNAFFORDABLE_COLOR := Color(1.0, 0.3, 0.3)
const CARD_BG_COLOR := Color(0.1, 0.1, 0.16)
const CARD_BG_HOVER_COLOR := Color(0.16, 0.16, 0.24)
const FRAME_WIDTH := 4
const FRAME_RADIUS := 8
const PULSE_MIN_SIZE := 4
const PULSE_MAX_SIZE := 18
const PULSE_HALF_PERIOD := 0.6
const ABILITY_KEY_LABELS := {&"primary": "clic droit", &"a": "A", &"e": "E", &"r": "R"}

var _row: HBoxContainer
var _reroll_button: Button
var _rarities: CardRarities
var _abilities: AbilityCatalog


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
	_reroll_button = Button.new()
	_reroll_button.focus_mode = Control.FOCUS_NONE
	_reroll_button.custom_minimum_size = Vector2(260.0, 52.0)
	_reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reroll_button.add_theme_font_size_override(&"font_size", REROLL_FONT_SIZE)
	_reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	column.add_child(_reroll_button)


## Gives the screen the rarities (frame colours, labels) and the abilities (name
## and key shown on ability cards). Call once before [method show_cards].
func setup(rarities: CardRarities, abilities: AbilityCatalog) -> void:
	_rarities = rarities
	_abilities = abilities


## Shows [param cards] (one clickable card each) and waits for a click. Cards
## narrow when needed so the whole row fits the screen width. The reroll button
## shows [param reroll_cost] and is greyed, price in red, unless [param can_afford]
## (enough gold and at least one card left to draw). Can be called again to
## replace the cards after a reroll.
func show_cards(cards: Array[CardDef], reroll_cost: int, can_afford: bool) -> void:
	_reroll_button.text = "Relancer (%d or)" % reroll_cost
	_reroll_button.disabled = not can_afford
	_reroll_button.add_theme_color_override(&"font_disabled_color", TEXT_COLOR if can_afford else UNAFFORDABLE_COLOR)
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var free_width: float = get_viewport().get_visible_rect().size.x - 2.0 * SCREEN_SIDE_MARGIN - CARD_SPACING * (cards.size() - 1)
	var card_width: float = minf(CARD_SIZE.x, free_width / cards.size())
	for card: CardDef in cards:
		_row.add_child(_make_card(card, card_width))
	visible = true


func _make_card(card: CardDef, width: float) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE  # Space starts the wave: a focused card must not react to it.
	button.custom_minimum_size = Vector2(width, CARD_SIZE.y)
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
	if _rarities != null and _rarities.has_rarity(card.rarity):
		var rarity_color: Color = _rarities.color(card.rarity)
		var rarity_text: String = _rarities.label(card.rarity)
		if card.rarity == &"legendary":
			rarity_text += " !"
		var rarity_label: Label = _make_label(rarity_text, RARITY_FONT_SIZE, rarity_color)
		rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var title_font: Font = NeonFonts.title()
		if title_font != null:
			rarity_label.add_theme_font_override(&"font", title_font)
		box.add_child(rarity_label)
		_apply_frame(button, rarity_color, card.rarity == &"legendary")
	var ability: AbilityDef = _ability_of(card)
	if ability != null:
		var key: String = ABILITY_KEY_LABELS.get(ability.slot, String(ability.slot).to_upper())
		var ability_label: Label = _make_label("%s — %s" % [ability.display_name, key], COMBINE_FONT_SIZE, NAME_COLOR)
		ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(ability_label)
	var description: Label = _make_label(card.description, TEXT_FONT_SIZE, TEXT_COLOR)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description)
	if not card.combines_with.is_empty():
		box.add_child(_make_label("Combine avec : %s" % card.combines_with, COMBINE_FONT_SIZE, COMBINE_COLOR))
	return button


## The ability a card belongs to (its [member CardDef.requires_ability]), or null.
func _ability_of(card: CardDef) -> AbilityDef:
	if _abilities == null or card.requires_ability.is_empty():
		return null
	for def: AbilityDef in _abilities.abilities:
		if def.id == card.requires_ability:
			return def
	return null


## Draws a frame of [param color] around [param button]; a legendary frame pulses.
func _apply_frame(button: Button, color: Color, pulse: bool) -> void:
	var normal: StyleBoxFlat = _frame_style(color, CARD_BG_COLOR)
	var hover: StyleBoxFlat = _frame_style(color, CARD_BG_HOVER_COLOR)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	if pulse:
		for style: StyleBoxFlat in [normal, hover]:
			style.shadow_color = Color(color, 0.8)
		var tween: Tween = button.create_tween().set_loops()  # Bound to the button: stops when it is freed.
		tween.set_parallel(true)
		tween.tween_property(normal, "shadow_size", PULSE_MAX_SIZE, PULSE_HALF_PERIOD).from(PULSE_MIN_SIZE)
		tween.tween_property(hover, "shadow_size", PULSE_MAX_SIZE, PULSE_HALF_PERIOD).from(PULSE_MIN_SIZE)
		tween.chain().tween_property(normal, "shadow_size", PULSE_MIN_SIZE, PULSE_HALF_PERIOD)
		tween.tween_property(hover, "shadow_size", PULSE_MIN_SIZE, PULSE_HALF_PERIOD)


func _frame_style(color: Color, background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = color
	style.set_border_width_all(FRAME_WIDTH)
	style.set_corner_radius_all(FRAME_RADIUS)
	return style


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
