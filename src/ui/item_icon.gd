## Icon of a passive item (étape 5a): a neon circle in the colour of the item's
## category (attack pink-red, survival green, utility cyan) with the item's
## [member ItemDef.glyph] at its centre. A dimmed icon is drawn in grey (a used
## Seconde chance). Drawn in code, no texture.
class_name ItemIcon
extends Control

## Ring and glyph colour of each item category.
const CATEGORY_COLORS := {&"attack": Color("#ff3b6b"), &"survival": Color("#3bff7a"), &"utility": Color("#19e3ff")}
## Category name shown to the player.
const CATEGORY_LABELS := {&"attack": "ATTAQUE", &"survival": "SURVIE", &"utility": "UTILITÉ"}
const FILL_COLOR := Color("#1c1340")
const DIMMED_COLOR := Color(0.45, 0.45, 0.5)
const RING_WIDTH := 3.0
const GLOW_ALPHA := 0.35
const GLYPH_SIZE_RATIO := 0.9  # Glyph font size as a share of the circle radius.
const ARC_POINTS := 48

## The item shown.
var item: ItemDef
## True draws the icon in grey.
var dimmed := false:
	set(value):
		dimmed = value
		queue_redraw()


## Shows [param def] in a square of [param diameter] pixels.
func _init(def: ItemDef = null, diameter: float = 48.0) -> void:
	item = def
	custom_minimum_size = Vector2(diameter, diameter)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Colour of [param category]; white for an unknown category.
static func category_color(category: StringName) -> Color:
	return CATEGORY_COLORS.get(category, Color.WHITE)


## Name of [param category] shown to the player.
static func category_label(category: StringName) -> String:
	return CATEGORY_LABELS.get(category, String(category).to_upper())


func _draw() -> void:
	if item == null:
		return
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - RING_WIDTH * 1.5
	var color: Color = DIMMED_COLOR if dimmed else category_color(item.category)
	draw_circle(center, radius, FILL_COLOR)
	if not dimmed:
		draw_arc(center, radius, 0.0, TAU, ARC_POINTS, Color(color, GLOW_ALPHA), RING_WIDTH * 3.0, true)
	draw_arc(center, radius, 0.0, TAU, ARC_POINTS, color, RING_WIDTH, true)
	var font: Font = NeonFonts.title()
	if font == null:
		font = ThemeDB.fallback_font
	var font_size: int = maxi(1, roundi(radius * GLYPH_SIZE_RATIO))
	var baseline: float = center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(0.0, baseline), item.glyph, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, color)
