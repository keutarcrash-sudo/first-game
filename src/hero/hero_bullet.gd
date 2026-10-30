## Hero projectile (story 001): travels in a straight line, deals [member damage]
## to the first enemy it touches, and is freed on impact or after
## [member HeroStats.bullet_max_range] pixels.
## Contract for story 002: enemies sit on physics layer 2 ("enemies") and
## implement [code]take_damage(amount: float)[/code].
class_name HeroBullet
extends Area2D

const COLOR := Color(1.0, 0.9, 0.35)
const ENEMY_LAYER := 2  # Bit value of physics layer 2, "enemies".

## Damage dealt to the target hit.
var damage: float
var _velocity: Vector2
var _max_range: float
var _radius: float
var _travelled := 0.0


## Sets damage, speed, range and size from [param stats], and the flight
## direction (a normalised vector). Call before adding the bullet to the tree.
func setup(stats: HeroStats, direction: Vector2) -> void:
	damage = stats.bullet_damage
	_velocity = direction * stats.bullet_speed
	_max_range = stats.bullet_max_range
	_radius = stats.bullet_radius


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
	var step: Vector2 = _velocity * delta
	position += step
	_travelled += step.length()
	if _travelled >= _max_range:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _radius, COLOR)


func _on_hit(target: Node2D) -> void:
	# A bullet hits one target only, even if it touches two in the same frame.
	if is_queued_for_deletion():
		return
	if target.has_method(&"take_damage"):
		target.call(&"take_damage", damage)
	queue_free()
