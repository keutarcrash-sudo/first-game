## Zone on the ground (étape 3b): a disc or a thick segment that lasts [code]duration[/code]
## seconds, then frees itself. Each physics frame it emits [signal enemy_inside] for every
## valid enemy whose body touches it (distance from the enemy centre to the shape
## <= zone radius or half thickness + enemy radius). Drawn as a semi-transparent
## fill in the effect colour. Used by the flame trail, and by later zones.
class_name GroundZone
extends Node2D

## Emitted every physics frame for each valid enemy touching the zone.
signal enemy_inside(enemy: Enemy, delta: float)

const FILL_ALPHA := 0.35

var _enemies: Node2D
var _state: GameState
var _color: Color
var _duration := 0.0
var _time := 0.0
var _is_segment := false
var _radius := 0.0  # Disc radius, or half thickness of the segment.
var _from := Vector2.ZERO  # Global points; the disc uses _from as its centre.
var _to := Vector2.ZERO


## Makes a disc of [param radius] centred on the zone's global position (place the
## zone with global_position after adding it). Lasts [param duration] seconds.
## The zone frees itself as soon as [param state]'s phase is not COMBAT. Call before adding to the tree.
func setup_circle(radius: float, duration: float, color: Color, state: GameState, enemies: Node2D) -> void:
	_is_segment = false
	_radius = radius
	_duration = duration
	_color = color
	_state = state
	_enemies = enemies


## Makes a segment from [param from] to [param to] (global points) of total width
## [param thickness]. The zone sits at [param from]. Frees itself outside COMBAT like [method setup_circle]. Call before adding to the tree.
func setup_segment(from: Vector2, to: Vector2, thickness: float, duration: float, color: Color, state: GameState, enemies: Node2D) -> void:
	_is_segment = true
	_from = from
	_to = to
	_radius = thickness * 0.5
	_duration = duration
	_color = color
	_state = state
	_enemies = enemies
	position = from


func _physics_process(delta: float) -> void:
	if _state != null and _state.phase != GameState.Phase.COMBAT:
		queue_free()
		return
	_time += delta
	if _enemies != null:
		for child: Node in _enemies.get_children():
			var enemy := child as Enemy
			if enemy == null or enemy.is_queued_for_deletion():
				continue
			if _touches(enemy):
				enemy_inside.emit(enemy, delta)
	if _time >= _duration:
		queue_free()


func _draw() -> void:
	var fill := Color(_color.r, _color.g, _color.b, FILL_ALPHA)
	if not _is_segment:
		draw_circle(Vector2.ZERO, _radius, fill)
		return
	var local_to: Vector2 = _to - _from
	draw_line(Vector2.ZERO, local_to, fill, _radius * 2.0)
	draw_circle(Vector2.ZERO, _radius, fill)
	draw_circle(local_to, _radius, fill)


func _touches(enemy: Enemy) -> bool:
	var reach: float = _radius + enemy.radius()
	var point: Vector2 = enemy.global_position
	if not _is_segment:
		return point.distance_to(global_position) <= reach
	var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, _from, _to)
	return point.distance_to(closest) <= reach
