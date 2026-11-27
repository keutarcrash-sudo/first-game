## Lava pool left by the death blast of a Volcan cannon (evolved Incendiaire, towers T2b,
## spec §5 and §7bis): for its lifetime, every physics frame, hurts each enemy within its
## radius by [code]dps x delta[/code] through [method Enemy.take_dot_damage] (cyan, grouped
## numbers). It never sets a cannon burn, so it cannot start endless explosion chains.
## Drawn as a glowing orange disc fading out. Frees itself at the end of its lifetime or as
## soon as the phase leaves COMBAT. Place it in the ground layer.
class_name LavaPool
extends Node2D

const FILL_COLOR := Color(1.0, 0.35, 0.05, 0.45)
const EDGE_COLOR := Color(1.0, 0.7, 0.2, 0.85)
const EDGE_WIDTH := 3.0
const ARC_POINTS := 40

var _radius := 0.0
var _duration := 0.0
var _dps := 0.0
var _state: GameState
var _enemies: Node2D
var _time := 0.0


## Disc of [param radius] pixels lasting [param duration] seconds, hurting by [param dps]
## damage per second the enemies under [param enemies]; it vanishes when [param state]'s
## phase is not COMBAT ([param state] may be null). Call before adding to the tree, then
## set global_position.
func setup(radius: float, duration: float, dps: float, state: GameState, enemies: Node2D) -> void:
	_radius = radius
	_duration = duration
	_dps = dps
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
	# Snapshot first: an enemy killed here only queues its deletion, but stay safe against removals.
	var inside: Array[Enemy] = []
	for i: int in _enemies.get_child_count():
		var enemy := _enemies.get_child(i) as Enemy
		if enemy != null and not enemy.is_queued_for_deletion() and enemy.global_position.distance_squared_to(global_position) <= radius_sq:
			inside.append(enemy)
	for enemy: Enemy in inside:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			enemy.take_dot_damage(_dps * delta, &"tower_dot")
	queue_redraw()


func _draw() -> void:
	var fade: float = 1.0 if _duration <= 0.0 else clampf(1.0 - _time / _duration, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius, Color(FILL_COLOR, FILL_COLOR.a * fade))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, ARC_POINTS, Color(EDGE_COLOR, EDGE_COLOR.a * fade), EDGE_WIDTH, true)
