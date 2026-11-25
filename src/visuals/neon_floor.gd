## Neon floor of the arena: dark violet ground with a repeating grid of dots,
## a black border, a thin cyan line just inside it and a soft cyan glow just
## outside. The floor goes on, a little darker, [constant OUTSIDE_MARGIN] px past
## every side of the arena, so no camera view (COMBAT, BUILD zoomed out, wide
## screens with the [code]expand[/code] stretch) ever shows black. Drawn under
## every other node; display only. Gameplay bounds are unchanged (the arena).
class_name NeonFloor
extends Node2D

const FLOOR_COLOR := Color("#120c2a")
const DOT_COLOR := Color(160.0 / 255.0, 90.0 / 255.0, 255.0 / 255.0, 0.45)
const DOT_SPACING := 16
const DOT_SIZE := 2
## Offset of the dot inside its cell (centred).
const DOT_ORIGIN := 7
const BORDER_COLOR := Color.BLACK
const BORDER_WIDTH := 4.0
const EDGE_COLOR := Color("#19e3ff")
const EDGE_WIDTH := 2.0
const EDGE_GLOW_COLOR := Color(25.0 / 255.0, 227.0 / 255.0, 1.0, 0.35)
const EDGE_GLOW_WIDTH := 6.0
## How far (world px) the floor goes past each side of the arena. A multiple of
## [constant DOT_SPACING] so the outside dots line up with the arena's.
const OUTSIDE_MARGIN := 6000.0
const OUTSIDE_COLOR := Color("#0b0719")
## Tint of the dots outside the arena (darker than inside).
const OUTSIDE_DOT_TINT := Color(1.0, 1.0, 1.0, 0.45)

var _field_rect: Rect2
var _dots: ImageTexture


## Sets the arena rectangle and builds the dot pattern texture.
func setup(field_rect: Rect2) -> void:
	_field_rect = field_rect
	var image := Image.create_empty(DOT_SPACING, DOT_SPACING, false, Image.FORMAT_RGBA8)
	for x: int in DOT_SIZE:
		for y: int in DOT_SIZE:
			image.set_pixel(DOT_ORIGIN + x, DOT_ORIGIN + y, DOT_COLOR)
	_dots = ImageTexture.create_from_image(image)
	queue_redraw()


func _draw() -> void:
	if _dots == null:
		return
	var outside: Rect2 = _field_rect.grow(OUTSIDE_MARGIN)
	draw_rect(outside, OUTSIDE_COLOR)
	draw_texture_rect(_dots, outside, true, OUTSIDE_DOT_TINT)
	draw_rect(_field_rect, FLOOR_COLOR)
	draw_texture_rect(_dots, _field_rect, true)
	draw_rect(_field_rect.grow(BORDER_WIDTH * 0.5 + EDGE_GLOW_WIDTH * 0.5), EDGE_GLOW_COLOR, false, EDGE_GLOW_WIDTH)
	draw_rect(_field_rect, BORDER_COLOR, false, BORDER_WIDTH)
	draw_rect(_field_rect.grow(-BORDER_WIDTH * 0.5 - EDGE_WIDTH * 0.5), EDGE_COLOR, false, EDGE_WIDTH)
