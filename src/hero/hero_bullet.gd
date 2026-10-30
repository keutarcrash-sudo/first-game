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
var _arena_rect: Rect2
var _travelled := 0.0


## Sets damage, speed, range and size from [param stats], and the flight
## direction (a normalised vector). The bullet is freed as soon as it leaves
## [param arena_rect]. Call before adding the bullet to the tree.
func setup(stats: HeroStats, direction: Vector2, arena_rect: Rect2) -> void:
	configure(stats.bullet_damage, stats.bullet_speed, stats.bullet_max_range, stats.bullet_radius, direction, arena_rect)


## Sets the values directly (used by the cannon tower, story 004): [param hit_damage],
## [param speed] in pixels per second, [param max_range] and [param radius] in pixels,
## a normalised [param direction], freed on leaving [param arena_rect]. Call before adding the bullet to the tree.
func configure(hit_damage: float, speed: float, max_range: float, radius: float, direction: Vector2, arena_rect: Rect2) -> void:
	_arena_rect = arena_rect
	damage = hit_damage
	_velocity = direction * speed
	_max_range = max_range
	_radius = radius


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
	if _travelled >= _max_range or not _arena_rect.has_point(global_position):
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
