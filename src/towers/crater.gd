## Crater left by a Sismique mortar shell (towers T2a, spec §5.3): for its lifetime, every
## physics frame, asks each enemy within its radius to be slowed to its speed factor
## ([method Enemy.apply_slow]: the enemy drops the slow by itself once no one refreshes it).
## Drawn as a dark disc fading out. Frees itself at the end of its lifetime or as soon as the
## phase leaves COMBAT. Place it in the ground layer.
class_name Crater
extends Node2D

const FILL_COLOR := Color(0.18, 0.14, 0.1, 0.45)
const EDGE_COLOR := Color(0.45, 0.35, 0.25, 0.7)
const EDGE_WIDTH := 3.0
const ARC_POINTS := 40

var _radius := 0.0
var _duration := 0.0
var _slow := 1.0
var _state: GameState
var _enemies: Node2D
var _time := 0.0


## Disc of [param radius] pixels lasting [param duration] seconds, slowing to
## [param slow_factor] (0.6 = 40 % slower) the enemies under [param enemies]; it vanishes
## when [param state]'s phase is not COMBAT ([param state] may be null). Call before
## adding to the tree, then set global_position.
func setup(radius: float, duration: float, slow_factor: float, state: GameState, enemies: Node2D) -> void:
	_radius = radius
	_duration = duration
	_slow = slow_factor
	_state = state
	_enemies = enemies


func _physics_process(delta: float) -> void:
	if (_state != null and _state.phase != GameState.Phase.COMBAT) or not is_instance_valid(_enemies):
		queue_free()
		return
	_time += delta
	if _time >= _duration:
		queue_free()
		return
	var radius_sq: float = _radius * _radius
	for i: int in _enemies.get_child_count():
		var enemy := _enemies.get_child(i) as Enemy
		if enemy != null and not enemy.is_queued_for_deletion() and enemy.global_position.distance_squared_to(global_position) <= radius_sq:
			enemy.apply_slow(_slow)
	queue_redraw()


func _draw() -> void:
	var fade: float = 1.0 if _duration <= 0.0 else clampf(1.0 - _time / _duration, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius, Color(FILL_COLOR, FILL_COLOR.a * fade))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, ARC_POINTS, Color(EDGE_COLOR, EDGE_COLOR.a * fade), EDGE_WIDTH, true)
