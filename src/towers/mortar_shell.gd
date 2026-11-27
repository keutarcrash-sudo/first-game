## A mortar shell in flight (towers T2a, spec §5.3): drawn as a ball on an arc from
## [member from] to [member to] with its shadow on the ground, under a cyan [TelegraphZone]
## announcing the impact. When the announcement completes, the shell explodes at its
## centre: [member damage] to every enemy within [member blast_radius] (x [member slowed_mult]
## on a slowed or frozen one), then [member bomblets] small blasts around it (each counts
## against the [ChainLimiter]; the ones past the cap are dropped), then a [Crater] when
## [member crater_duration] is above 0. The shell vanishes without damage when the
## announcement is cancelled (wave end) or the phase leaves COMBAT. Set every member, then add
## it to the tree (the bullets node).
class_name MortarShell
extends Node2D

const FRIENDLY_COLOR := Color(0.2, 0.9, 1.0)  # Cyan announcement: a friendly shot.
const ARC_HEIGHT_RATIO := 0.35  # Top of the arc above the ground, as a fraction of the distance.
const BALL_RADIUS := 6.0
const BALL_COLOR := Color(0.2, 0.2, 0.22)
const BALL_EDGE := Color(0.95, 0.95, 0.95, 0.8)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.3)
const SHADOW_SCALE := Vector2(1.4, 0.6)  # Ellipse of the shadow relative to the ball.
const BLAST_WORD := "BOUM !"
const BLAST_COLOR := Color(1.0, 0.6, 0.2)
const BOMBLET_WORD := "pof"
const VISUAL_RADIUS_RATIO := 0.5  # The burst is drawn at half the blast radius.

## Phase source: the shell vanishes as soon as the phase is not COMBAT. May be null.
var state: GameState
## Node holding the enemies.
var enemies: Node2D
## Layer the announcement and the crater are added to.
var ground: Node2D
## Cap of the chained effects; may be null (no cap).
var chain_limiter: ChainLimiter
## Launch point and impact point, world space.
var from: Vector2
var to: Vector2
## Seconds of flight (and of announcement).
var flight: float = 1.0
## Damage and radius of the main blast; damage factor on a slowed or frozen enemy.
var damage: float
var blast_radius: float
var slowed_mult: float = 1.0
## Grappe: number, damage and radius of the small blasts (0 bomblets: none).
var bomblets: int = 0
var bomblet_damage: float
var bomblet_radius: float
## Sismique: lifetime in seconds (0: no crater), speed factor and radius of the crater.
var crater_duration: float = 0.0
var crater_slow: float = 1.0
var crater_radius: float
## Tremblement (towers T2b): seconds of stun of every enemy of the main blast (0: none).
var impact_stun: float = 0.0
## Nexus (towers T2b): states set on every enemy of the main blast ([method NexusRules.apply_states]).
var shared_states: Array = []

var _time := 0.0
var _landed := false
var _zone: TelegraphZone


func _ready() -> void:
	global_position = from
	if ground == null or not is_instance_valid(ground):
		queue_free()
		return
	_zone = TelegraphZone.new()
	_zone.setup(blast_radius, flight, state, null, FRIENDLY_COLOR)
	_zone.impacted.connect(_on_zone_impacted)
	_zone.tree_exiting.connect(_on_zone_exiting)
	ground.add_child(_zone)
	_zone.global_position = to


func _physics_process(delta: float) -> void:
	if _landed:
		return
	if state != null and state.phase != GameState.Phase.COMBAT:
		_vanish()
		return
	_time += delta
	var t: float = 1.0 if flight <= 0.0 else clampf(_time / flight, 0.0, 1.0)
	global_position = from.lerp(to, t)
	queue_redraw()


func _draw() -> void:
	var t: float = 1.0 if flight <= 0.0 else clampf(_time / flight, 0.0, 1.0)
	var height: float = from.distance_to(to) * ARC_HEIGHT_RATIO * 4.0 * t * (1.0 - t)
	draw_set_transform(Vector2.ZERO, 0.0, SHADOW_SCALE)
	draw_circle(Vector2.ZERO, BALL_RADIUS, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var ball := Vector2(0.0, -height)
	draw_circle(ball, BALL_RADIUS, BALL_COLOR)
	draw_arc(ball, BALL_RADIUS, 0.0, TAU, 16, BALL_EDGE, 1.5, true)


## Frees the shell and its announcement without any damage.
func _vanish() -> void:
	_landed = true
	if is_instance_valid(_zone) and not _zone.is_queued_for_deletion():
		_zone.cancel()
	queue_free()


func _on_zone_impacted(center: Vector2) -> void:
	if _landed:
		return
	_landed = true
	_explode(center)
	queue_free()


# The announcement left without impacting (cancelled at the wave end): no damage.
func _on_zone_exiting() -> void:
	if not _landed:
		_landed = true
		queue_free()


func _explode(center: Vector2) -> void:
	_show(center, BLAST_WORD, blast_radius)
	for enemy: Enemy in _living_enemies_near(center, blast_radius):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue  # Killed earlier in this loop.
		var slowed: bool = enemy.has_state(&"slowed") or enemy.has_state(&"frozen")
		enemy.take_damage(damage * (slowed_mult if slowed else 1.0), false, &"cannon")
		if impact_stun > 0.0 and is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			enemy.stun(impact_stun)
		if not shared_states.is_empty():
			NexusRules.apply_states(enemy, shared_states)
	if bomblets > 0:
		var turn: float = randf() * TAU
		for i: int in bomblets:
			if chain_limiter != null and not chain_limiter.try_consume(Engine.get_process_frames()):
				break  # Past the cap: the rest are dropped.
			var at: Vector2 = center + Vector2.from_angle(turn + TAU * float(i) / float(bomblets)) * blast_radius
			_show(at, BOMBLET_WORD, bomblet_radius)
			for enemy: Enemy in _living_enemies_near(at, bomblet_radius):
				if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
					enemy.take_damage(bomblet_damage, false, &"cannon")
	if crater_duration > 0.0 and is_instance_valid(ground):
		var crater := Crater.new()
		crater.setup(crater_radius, crater_duration, crater_slow, state, enemies)
		ground.add_child(crater)
		crater.global_position = center


## Enemies still alive within [param radius] of [param at] (a snapshot).
func _living_enemies_near(at: Vector2, radius: float) -> Array[Enemy]:
	var found: Array[Enemy] = []
	if not is_instance_valid(enemies):
		return found
	var radius_sq: float = radius * radius
	for child: Node in enemies.get_children():
		var enemy := child as Enemy
		if enemy != null and not enemy.is_queued_for_deletion() and enemy.global_position.distance_squared_to(at) <= radius_sq:
			found.append(enemy)
	return found


func _show(at: Vector2, word: String, radius: float) -> void:
	if is_instance_valid(enemies) and enemies.get_parent() != null:
		PopBurst.spawn(enemies.get_parent(), at, word, BLAST_COLOR, radius * VISUAL_RADIUS_RATIO)
