## Visual feedback of a triggered combo (story 005): a flash, an expanding ring
## and a floating "x3"-style label at the hit position, then frees itself after
## [constant DURATION] seconds. Built in code; one small node per proc. Also
## used, in yellow and with its own text, for the Archer's critical hits (story 008).
class_name ProcEffect
extends Node2D

const DURATION := 0.3
const COLOR := Color(1.0, 0.35, 0.9)
const START_RADIUS := 10.0
const END_RADIUS := 42.0
const RING_WIDTH := 4.0
const RING_POINTS := 24
const LABEL_OFFSET := Vector2(-20.0, -50.0)
const LABEL_RISE := 24.0
const LABEL_FONT_SIZE := 22

var _age := 0.0
var _label: Label
var _color := COLOR


## Sets the position (in the parent's space), the [param text] shown (such as
## "×3") and its [param color]. Call before adding to the tree.
func setup(at: Vector2, text: String, color: Color = COLOR) -> void:
	position = at
	_color = color
	_label = Label.new()
	_label.text = text
	_label.position = LABEL_OFFSET
	_label.add_theme_font_size_override(&"font_size", LABEL_FONT_SIZE)
	_label.add_theme_color_override(&"font_color", color)
	add_child(_label)


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	_label.position = LABEL_OFFSET + Vector2(0.0, -LABEL_RISE * _age / DURATION)
	queue_redraw()


func _draw() -> void:
	var t: float = clampf(_age / DURATION, 0.0, 1.0)
	var fade := Color(_color.r, _color.g, _color.b, 1.0 - t)
	draw_circle(Vector2.ZERO, lerpf(START_RADIUS, END_RADIUS, t) * 0.6, Color(1.0, 1.0, 1.0, 0.5 * (1.0 - t)))
	draw_arc(Vector2.ZERO, lerpf(START_RADIUS, END_RADIUS, t), 0.0, TAU, RING_POINTS, fade, RING_WIDTH)
