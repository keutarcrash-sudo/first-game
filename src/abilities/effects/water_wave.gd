## Wave of the Maître de l'eau's primary ability (étape 3a, « Vague »): instant cone
## in front of the hero toward the mouse. Every enemy within [code]range[/code] and
## within half of [code]angle_degrees[/code] of the direction takes damage, gets wet
## and is pushed away from the hero. A light-blue arc then expands and frees the wave.
## The effect is applied on the first physics frame, once the caller has placed the
## wave on the hero.
class_name WaterWave
extends Node2D

const COLOR := Color(0.55, 0.85, 1.0)
const ARC_DURATION := 0.25  # Seconds the arc takes to expand up to the range.
const ARC_WIDTH := 8.0
const ARC_POINTS := 24

var _direction: Vector2
var _enemies: Node2D
var _damage: float
var _wet_duration: float
var _field_rect: Rect2
var _range: float
var _half_angle: float  # Radians.
var _push_distance: float
var _push_duration: float
var _applied := false
var _time := 0.0


## Sets the wave up from [param def] (values range, angle_degrees, push_distance,
## push_duration), a normalised [param direction], the [param enemies] parent, the
## [param damage] dealt and the [param wet_duration] applied to each enemy hit.
## [param field_rect] (optional) keeps pushed enemies inside the field.
## Call before adding the wave to the tree, then place it on the hero.
func setup(def: AbilityDef, direction: Vector2, enemies: Node2D, damage: float, wet_duration: float, field_rect: Rect2 = Rect2()) -> void:
	_direction = direction
	_enemies = enemies
	_damage = damage
	_wet_duration = wet_duration
	_field_rect = field_rect
	_range = float(def.values["range"])
	_half_angle = deg_to_rad(float(def.values["angle_degrees"])) * 0.5
	_push_distance = float(def.values["push_distance"])
	_push_duration = float(def.values["push_duration"])


func _physics_process(delta: float) -> void:
	if not _applied:
		_applied = true
		_apply()
	_time += delta
	if _time >= ARC_DURATION:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var t: float = clampf(_time / ARC_DURATION, 0.0, 1.0)
	var color := Color(COLOR.r, COLOR.g, COLOR.b, 1.0 - t * 0.5)
	var angle: float = _direction.angle()
	draw_arc(Vector2.ZERO, _range * t, angle - _half_angle, angle + _half_angle, ARC_POINTS, color, ARC_WIDTH)


func _apply() -> void:
	if _enemies == null:
		return
	for child: Node in _enemies.get_children():
		var enemy := child as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > _range:
			continue
		if to_enemy != Vector2.ZERO and absf(_direction.angle_to(to_enemy)) > _half_angle:
			continue
		var away: Vector2 = to_enemy.normalized() if to_enemy != Vector2.ZERO else _direction
		enemy.take_damage(_damage)
		# After the damage: wet and push ignore an enemy the hit just killed.
		enemy.apply_wet(_wet_duration)
		enemy.push(away * _push_distance, _push_duration, _field_rect)
