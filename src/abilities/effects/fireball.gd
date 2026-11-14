## Fireball of the Maître du feu's primary ability (étape 3a, « Boule de feu »):
## flies toward the mouse and explodes on the first enemy touched, at the end of
## its range or on leaving the field. The explosion damages and sets on fire every
## enemy within [code]explosion_radius[/code], then fades out and frees the fireball.
## Enemies sit on physics layer 2 and implement [code]take_damage(amount: float)[/code].
class_name Fireball
extends Area2D

const COLOR := Color(1.0, 0.55, 0.1)
const EXPLOSION_DURATION := 0.3  # Seconds the explosion circle takes to expand and fade.
const ENEMY_LAYER := 2  # Bit value of physics layer 2, "enemies".

var _damage: float
var _burn_duration: float
var _burn_dps: float
var _velocity: Vector2
var _range: float
var _radius: float
var _explosion_radius: float
var _field_rect: Rect2
var _enemies: Node2D
var _travelled := 0.0
var _exploded := false
var _explosion_time := 0.0


## Sets the fireball up from [param def] (values speed, range, radius, explosion_radius),
## a normalised [param direction], the [param field_rect] it explodes on leaving, the
## [param enemies] parent, the [param damage] dealt to each enemy in the explosion and
## the burn it applies ([param burn_duration] seconds at [param burn_dps] per second).
## Call before adding the fireball to the tree.
func setup(def: AbilityDef, direction: Vector2, field_rect: Rect2, enemies: Node2D, damage: float, burn_duration: float, burn_dps: float) -> void:
	_velocity = direction * float(def.values["speed"])
	_range = float(def.values["range"])
	_radius = float(def.values["radius"])
	_explosion_radius = float(def.values["explosion_radius"])
	_field_rect = field_rect
	_enemies = enemies
	_damage = damage
	_burn_duration = burn_duration
	_burn_dps = burn_dps


func _ready() -> void:
	collision_layer = 0
	collision_mask = ENEMY_LAYER
	var shape := CircleShape2D.new()
	shape.radius = _radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	if _exploded:
		_explosion_time += delta
		if _explosion_time >= EXPLOSION_DURATION:
			queue_free()
		else:
			queue_redraw()
		return
	var step: Vector2 = _velocity * delta
	position += step
	_travelled += step.length()
	if _travelled >= _range or not _field_rect.has_point(global_position):
		_explode()


func _draw() -> void:
	if _exploded:
		var t: float = clampf(_explosion_time / EXPLOSION_DURATION, 0.0, 1.0)
		var color := Color(COLOR.r, COLOR.g, COLOR.b, 1.0 - t)
		draw_circle(Vector2.ZERO, _explosion_radius * t, color)
	else:
		draw_circle(Vector2.ZERO, _radius, COLOR)


func _on_hit(_target: Node2D) -> void:
	_explode()


func _explode() -> void:
	if _exploded or is_queued_for_deletion():
		return
	_exploded = true
	_velocity = Vector2.ZERO
	if _enemies != null:
		for child: Node in _enemies.get_children():
			var enemy := child as Enemy
			if enemy == null or enemy.is_queued_for_deletion():
				continue
			if enemy.global_position.distance_to(global_position) > _explosion_radius + enemy.radius():
				continue
			enemy.take_damage(_damage)
			# After the damage: Enemy.apply_burn ignores an enemy the blast just killed.
			enemy.apply_burn(_burn_duration, _burn_dps)
	queue_redraw()
