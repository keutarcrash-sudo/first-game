## Base of the placed towers (story 004): a coloured disc with a faint ring
## showing its range. Subclasses set [member _body_color] in their setup and
## add their behaviour in [method Node._physics_process].
class_name Tower
extends Node2D

const RING_COLOR := Color(1.0, 1.0, 1.0, 0.18)
const RING_WIDTH := 2.0
const RING_POINTS := 48

## Body radius in pixels (drawing and placement footprint).
var radius: float
## Range in pixels.
var attack_range: float
var _body_color: Color


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, _body_color)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, RING_POINTS, RING_COLOR, RING_WIDTH)
