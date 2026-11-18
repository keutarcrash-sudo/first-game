## Neon floor of the arena: dark violet ground with a repeating grid of dots,
## a black border and a thin cyan line just inside it. Drawn under every other
## node; display only.
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
	draw_rect(_field_rect, FLOOR_COLOR)
	draw_texture_rect(_dots, _field_rect, true)
	draw_rect(_field_rect, BORDER_COLOR, false, BORDER_WIDTH)
	draw_rect(_field_rect.grow(-BORDER_WIDTH * 0.5 - EDGE_WIDTH * 0.5), EDGE_COLOR, false, EDGE_WIDTH)
