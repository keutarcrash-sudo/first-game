## The hero (story 001, design/game-brief.md MVP feature 1): moves with the
## move_* actions (ZQSD as printed on an AZERTY keyboard, or arrows), stays
## inside the arena and fires automatically toward the mouse cursor.
class_name Hero
extends CharacterBody2D

const BODY_COLOR := Color(0.3, 0.8, 1.0)
const AIM_COLOR := Color(0.3, 0.8, 1.0, 0.6)
const AIM_LINE_LENGTH := 14.0
const AIM_LINE_WIDTH := 3.0
const HERO_LAYER := 1

var _stats: HeroStats
var _bullet_parent: Node
var _min_position: Vector2
var _max_position: Vector2
var _aim_direction := Vector2.RIGHT
var _fire_cooldown := 0.0


## Gives the hero its tuning values, the arena it must stay in, and the node
## its projectiles are added to. Call once, before the first physics frame.
func setup(stats: HeroStats, arena_rect: Rect2, bullet_parent: Node) -> void:
	_stats = stats
	_bullet_parent = bullet_parent
	var margin := Vector2(stats.hero_radius, stats.hero_radius)
	_min_position = arena_rect.position + margin
	_max_position = arena_rect.end - margin
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = HERO_LAYER
	collision_mask = 0
	var shape := CircleShape2D.new()
	shape.radius = stats.hero_radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func _physics_process(delta: float) -> void:
	# get_vector caps the length at 1, so diagonals are as fast as straight lines;
	# with no key held it returns zero and the hero stops.
	var input_dir: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = input_dir * _stats.hero_speed
	move_and_slide()
	global_position = global_position.clamp(_min_position, _max_position)

	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	if to_mouse != Vector2.ZERO:
		_aim_direction = to_mouse.normalized()

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		_fire()
		_fire_cooldown += 1.0 / _stats.fire_rate
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _stats.hero_radius, BODY_COLOR)
	var aim_start: Vector2 = _aim_direction * _stats.hero_radius
	draw_line(aim_start, aim_start + _aim_direction * AIM_LINE_LENGTH, AIM_COLOR, AIM_LINE_WIDTH)


func _fire() -> void:
	var bullet := HeroBullet.new()
	bullet.setup(_stats, _aim_direction)
	_bullet_parent.add_child(bullet)
	bullet.global_position = global_position
