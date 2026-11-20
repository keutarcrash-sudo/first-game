## Shared look of the place screens (étape 5a: shop, treasure, rest), in the
## style of [CardChoiceScreen]: a dimmed overlay with a title, and item cards
## framed in their rarity colour showing icon, name, rarity, category,
## description and an optional price. Static helpers only.
class_name ItemCard
extends RefCounted

const SCREEN_LAYER := 10
const DIM_COLOR := Color(0.0, 0.0, 0.05, 0.8)
const TITLE_FONT_SIZE := 38
const NAME_FONT_SIZE := 26
const RARITY_FONT_SIZE := 22
const CATEGORY_FONT_SIZE := 16
const TEXT_FONT_SIZE := 18
const PRICE_FONT_SIZE := 24
const BUTTON_FONT_SIZE := 22
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const NAME_COLOR := Color(1.0, 0.9, 0.35)
const PRICE_COLOR := Color(1.0, 0.85, 0.2)
const UNAFFORDABLE_COLOR := Color(1.0, 0.3, 0.3)
const DISABLED_COLOR := Color(0.5, 0.5, 0.55)
const DISABLED_MODULATE := Color(1.0, 1.0, 1.0, 0.45)
const CARD_SIZE := Vector2(250.0, 340.0)
const CARD_PADDING := 14.0
const CARD_SPACING := 24
const COLUMN_SPACING := 28
const TEXT_SPACING := 8
const ICON_DIAMETER := 64.0
const CARD_BG_COLOR := Color(0.1, 0.1, 0.16)
const CARD_BG_HOVER_COLOR := Color(0.16, 0.16, 0.24)
const FRAME_WIDTH := 4
const FRAME_RADIUS := 8
const LEGENDARY_GLOW_SIZE := 12


## Builds the dimmed full-screen overlay of [param screen] with [param title] on
## top and returns the centred column where the screen adds its content.
static func build_overlay(screen: CanvasLayer, title: String) -> VBoxContainer:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP  # Clicks never reach the game below.
	screen.add_child(root)
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
	column.add_theme_constant_override(&"separation", COLUMN_SPACING)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	var title_label: Label = make_label(title, TITLE_FONT_SIZE, TEXT_COLOR)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var font: Font = NeonFonts.title()
	if font != null:
		NeonFonts.style_label(title_label, font)
	column.add_child(title_label)
	return column


## A centred row for cards or buttons.
static func make_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", CARD_SPACING)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


## Hides and frees every child of [param container]. The children stay in the
## tree until freed, so this is safe from the pressed signal of one of them.
static func clear(container: Node) -> void:
	for child: Node in container.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		child.queue_free()


## A clickable card for [param item], framed in its rarity colour (white when
## [param rarities] is null). [param price] above 0 adds a price line, in red when
## [param affordable] is false. A card that cannot be taken is greyed and disabled.
static func build(item: ItemDef, rarities: CardRarities, price: int = 0, affordable: bool = true) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE  # Space starts the wave: a focused card must not react to it.
	button.custom_minimum_size = CARD_SIZE
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = CARD_PADDING
	box.offset_top = CARD_PADDING
	box.offset_right = -CARD_PADDING
	box.offset_bottom = -CARD_PADDING
	box.add_theme_constant_override(&"separation", TEXT_SPACING)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var icon := ItemIcon.new(item, ICON_DIAMETER)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var name_label: Label = make_label(item.display_name, NAME_FONT_SIZE, NAME_COLOR)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var rarity_color: Color = Color.WHITE
	var rarity_text: String = String(item.rarity).to_upper()
	if rarities != null and rarities.has_rarity(item.rarity):
		rarity_color = rarities.color(item.rarity)
		rarity_text = rarities.label(item.rarity)
	if item.rarity == &"legendary":
		rarity_text += " !"
	var rarity_label: Label = make_label(rarity_text, RARITY_FONT_SIZE, rarity_color)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_font: Font = NeonFonts.title()
	if title_font != null:
		rarity_label.add_theme_font_override(&"font", title_font)
	box.add_child(rarity_label)
	var category_label: Label = make_label(ItemIcon.category_label(item.category), CATEGORY_FONT_SIZE, ItemIcon.category_color(item.category))
	category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(category_label)
	var description: Label = make_label(item.description, TEXT_FONT_SIZE, TEXT_COLOR)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description)
	if price > 0:
		var price_label: Label = make_label("%d or" % price, PRICE_FONT_SIZE, PRICE_COLOR if affordable else UNAFFORDABLE_COLOR)
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(price_label)
	apply_frame(button, rarity_color, item.rarity == &"legendary")
	if not affordable:
		button.disabled = true
		button.modulate = DISABLED_MODULATE
	return button


## A plain neon button with [param text] (place screen actions: repair, leave, rest choices).
static func make_button(text: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = min_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override(&"font_size", BUTTON_FONT_SIZE)
	button.add_theme_color_override(&"font_disabled_color", DISABLED_COLOR)
	return button


## Draws a frame of [param color] around [param button]; [param glow] adds a halo
## (legendary).
static func apply_frame(button: Button, color: Color, glow: bool = false) -> void:
	var normal: StyleBoxFlat = frame_style(color, CARD_BG_COLOR)
	var hover: StyleBoxFlat = frame_style(color, CARD_BG_HOVER_COLOR)
	var disabled: StyleBoxFlat = frame_style(DISABLED_COLOR, CARD_BG_COLOR)
	if glow:
		for style: StyleBoxFlat in [normal, hover]:
			style.shadow_color = Color(color, 0.8)
			style.shadow_size = LEGENDARY_GLOW_SIZE
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	button.add_theme_stylebox_override(&"disabled", disabled)


## A flat style with a [param color] border on [param background].
static func frame_style(color: Color, background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = color
	style.set_border_width_all(FRAME_WIDTH)
	style.set_corner_radius_all(FRAME_RADIUS)
	return style


## A wrapping label that lets clicks through.
static func make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
