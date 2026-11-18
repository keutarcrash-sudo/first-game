## Meteor of the Maître du feu's ultimate (étape 3b, « Météore »): a red announcement
## circle fills up during [code]delay[/code] seconds, then the explosion damages and
## sets on fire every enemy inside, fades out and frees the node. It frees itself as soon
## as the phase is not COMBAT, so it never hits enemies of a finished wave.
class_name Meteor
extends Node2D

const WARNING_COLOR := Color(1.0, 0.15, 0.1)
const OUTLINE_WIDTH := 3.0
const OUTLINE_POINTS := 48
const EXPLOSION_DURATION := 0.3  # Seconds the explosion circle takes to fade.

var _radius := 0.0
var _delay := 0.0
var _damage := 0.0
var _burn_duration := 0.0
var _burn_dps := 0.0
var _enemies: Node2D
var _state: GameState
var _time := 0.0
var _exploded := false
var _impact: ImpactFeedback


## Sets the meteor up: [param state] (it frees itself outside COMBAT), explosion [param radius], announcement [param delay] in seconds,
## [param damage] to each enemy inside plus a burn of [param burn_duration] seconds at
## [param burn_dps] per second; [param enemies] is the enemies' parent.
## Call before adding to the tree, then place it with global_position.
func setup(state: GameState, radius: float, delay: float, damage: float, burn_duration: float, burn_dps: float, enemies: Node2D) -> void:
	_state = state
	_radius = radius
	_delay = delay
	_damage = damage
	_burn_duration = burn_duration
	_burn_dps = burn_dps
	_enemies = enemies


## Gives the meteor the feedback node (big shake and hit-stop on impact). Optional.
func set_impact(impact: ImpactFeedback) -> void:
	_impact = impact


func _physics_process(delta: float) -> void:
	if _state != null and _state.phase != GameState.Phase.COMBAT:
		queue_free()
		return
	_time += delta
	if not _exploded and _time >= _delay:
		_exploded = true
		_time = 0.0
		_explode()
	elif _exploded and _time >= EXPLOSION_DURATION:
		queue_free()
		return
	queue_redraw()


func _explode() -> void:
	PopBurst.spawn(get_parent(), global_position, "BOUM !", WARNING_COLOR, _radius)
	if _impact != null:
		_impact.shake(&"big")
		_impact.hitstop()
	if _enemies == null:
		return
	# Collected first: a kill frees the enemy but never changes the child list mid-loop.
	for child: Node in _enemies.get_children():
		var enemy := child as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_to(global_position) <= _radius + enemy.radius():
			enemy.apply_burn(_burn_duration, _burn_dps)
			enemy.take_damage(_damage, true)


func _draw() -> void:
	if _exploded:
		var fade: float = 1.0 - clampf(_time / EXPLOSION_DURATION, 0.0, 1.0)
		draw_circle(Vector2.ZERO, _radius, Color(WARNING_COLOR.r, 0.55, 0.1, 0.8 * fade))
		return
	var progress: float = clampf(_time / maxf(_delay, 0.001), 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius * progress, Color(WARNING_COLOR.r, WARNING_COLOR.g, WARNING_COLOR.b, 0.45))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, OUTLINE_POINTS, WARNING_COLOR, OUTLINE_WIDTH)
