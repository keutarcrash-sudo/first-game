## Announced attack (étape 4, spec §6.3): a translucent red circle on the ground that
## fills from the centre to the edge over [code]duration[/code] seconds, then emits
## [signal impacted] and frees itself. The owner of the attack decides what the impact
## does (damage, flash, onomatopoeia) by listening to the signal. The zone frees itself
## without impacting when the phase leaves COMBAT or when [method cancel] is called.
## Place it in a layer drawn above the decor and below the characters.
class_name TelegraphZone
extends Node2D

## Emitted once when the announcement completes, with the global centre of the zone.
signal impacted(center: Vector2)

const FILL_COLOR := Color(1.0, 0.2, 0.3, 0.25)
const OUTLINE_COLOR := Color(1.0, 0.25, 0.35)
const BACK_OUTLINE_COLOR := Color(0.0, 0.0, 0.0)
const OUTLINE_WIDTH := 3.0
const BACK_OUTLINE_WIDTH := 5.0
const ARC_POINTS := 48

var _radius := 0.0
var _duration := 0.0
var _time := 0.0
var _state: GameState
var _follow: Node2D
var _done := false


## True when a body of [param body_radius] at [param body_pos] touches the disc of
## [param radius] around [param center] (edge included).
static func hits_body(center: Vector2, radius: float, body_pos: Vector2, body_radius: float) -> bool:
	return center.distance_to(body_pos) <= radius + body_radius


## True when [param point] lies inside the disc of [param radius] around [param center] (edge included).
static func hits_point(center: Vector2, radius: float, point: Vector2) -> bool:
	return center.distance_to(point) <= radius


## Configures the zone: disc of [param radius] pixels announced for [param duration]
## seconds. It frees itself without impact as soon as [param state]'s phase is not COMBAT.
## If [param follow] is given, the zone follows its global position while that node is
## valid; once it is gone the zone stays at its last position. Call before adding to the
## tree, then set global_position (unless following).
func setup(radius: float, duration: float, state: GameState, follow: Node2D = null) -> void:
	_radius = radius
	_duration = duration
	_state = state
	_follow = follow


## Frees the zone without emitting [signal impacted].
func cancel() -> void:
	_done = true
	queue_free()


func _physics_process(delta: float) -> void:
	if _done:
		return
	if _state != null and _state.phase != GameState.Phase.COMBAT:
		cancel()
		return
	if _follow != null and is_instance_valid(_follow) and not _follow.is_queued_for_deletion():
		global_position = _follow.global_position
	_time += delta
	queue_redraw()
	if _time >= _duration:
		_done = true
		impacted.emit(global_position)
		queue_free()


func _draw() -> void:
	var progress: float = 1.0 if _duration <= 0.0 else clampf(_time / _duration, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius * progress, FILL_COLOR)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, ARC_POINTS, BACK_OUTLINE_COLOR, BACK_OUTLINE_WIDTH)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, ARC_POINTS, OUTLINE_COLOR, OUTLINE_WIDTH)
