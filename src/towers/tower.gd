## Base of the placed towers (story 004): a coloured halo on the ground, the
## tower image on top of it, and a faint ring showing its range. Subclasses set
## [member _halo_color] in their setup and add their behaviour in
## [method Node._physics_process]. The image is a [DirectionalSprite] child, drawn
## after (so over) the halo.
class_name Tower
extends Node2D

const RING_COLOR := Color(1.0, 1.0, 1.0, 0.18)
const RING_WIDTH := 2.0
const RING_POINTS := 48
const HALO_FILL_ALPHA := 0.25
const HALO_EDGE_ALPHA := 0.7
const HALO_EDGE_WIDTH := 3.0

## Body radius in pixels (placement footprint and halo size).
var radius: float
## Range in pixels.
var attack_range: float
var _halo_color: Color
var _sprite: DirectionalSprite


## Gives the tower its image: [param sheet] drawn [param height_px] tall.
func set_visual(sheet: SpriteSheet, height_px: float) -> void:
	if _sprite == null:
		_sprite = DirectionalSprite.new()
		add_child(_sprite)
	_sprite.setup(sheet, height_px)
	_sprite.play(&"idle")


## Turns the tower image toward [param angle] (radians, as [method Vector2.angle]).
func set_facing(angle: float) -> void:
	if _sprite != null:
		_sprite.set_facing(angle)


func _draw() -> void:
	var fill := Color(_halo_color, HALO_FILL_ALPHA)
	var edge := Color(_halo_color, HALO_EDGE_ALPHA)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, RING_POINTS, edge, HALO_EDGE_WIDTH, true)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, RING_POINTS, RING_COLOR, RING_WIDTH)
