## Enemy (story 002): walks straight to the crystal. Sits on physics layer 2
## ("enemies") so hero bullets hit it, and implements [method take_damage].
## Contact with the crystal is tested here, by distance, on every physics
## frame: an enemy never depends on a one-shot signal, so it cannot get stuck
## against the crystal (known bug of the GDevelop prototype).
class_name Enemy
extends Area2D

## Emitted when hero fire brings the hit points to zero. Not emitted when the
## enemy frees itself by touching the crystal.
signal died

const COLOR := Color(1.0, 0.35, 0.3)
const DAMAGED_DARKEN := 0.55  # Colour brightness at 0 HP, scaled up to 1 at full HP.
const ENEMY_LAYER := 2  # Bit value of physics layer 2, "enemies".
const SLOWED_TINT := Color(0.3, 0.55, 1.0)
const SLOWED_TINT_AMOUNT := 0.6  # 0 = no tint, 1 = fully blue.

var _slow_factor := 1.0  # Speed fraction in effect this frame.
var _requested_slow_factor := 1.0  # Lowest factor asked for since the last physics step.
var _crystal: Crystal
var _target: Vector2
var _touch_distance_sq: float
var _contact_damage: float
var _speed: float
var _radius: float
var _hp: float
var _max_hp: float


## Sets stats, hit points ([param hp]), spawn position and target. Call before adding the enemy to the tree.
func setup(stats: DefenceStats, hp: float, start_position: Vector2, crystal: Crystal) -> void:
	_crystal = crystal
	_target = crystal.global_position
	_contact_damage = stats.enemy_contact_damage
	_speed = stats.enemy_speed
	_radius = stats.enemy_radius
	_hp = hp
	_max_hp = hp
	var touch_distance: float = crystal.radius + _radius
	_touch_distance_sq = touch_distance * touch_distance
	position = start_position


func _ready() -> void:
	collision_layer = ENEMY_LAYER
	collision_mask = 0
	monitoring = false
	var shape := CircleShape2D.new()
	shape.radius = _radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func _physics_process(delta: float) -> void:
	# An enemy killed this frame (queued for deletion) must not hurt the crystal.
	if is_queued_for_deletion():
		return
	# The slow is only what the towers asked for since the last frame: when no
	# tower refreshes it, it ends here, together with the blue tint.
	var was_slowed: bool = is_slowed()
	_slow_factor = _requested_slow_factor
	_requested_slow_factor = 1.0
	if is_slowed() != was_slowed:
		queue_redraw()
	position = position.move_toward(_target, _speed * _slow_factor * delta)
	if position.distance_squared_to(_target) <= _touch_distance_sq:
		_crystal.take_damage(_contact_damage)
		queue_free()


func _draw() -> void:
	var shade: float = lerpf(DAMAGED_DARKEN, 1.0, _hp / _max_hp)
	var color := Color(COLOR.r * shade, COLOR.g * shade, COLOR.b * shade)
	if is_slowed():
		color = color.lerp(SLOWED_TINT, SLOWED_TINT_AMOUNT)
	draw_circle(Vector2.ZERO, _radius, color)


## Asks for a slow to [param factor] (a fraction of normal speed, 0.45 = 45 %)
## for the next physics step only. Towers call it every physics frame while the
## enemy is in range; several callers do not stack, the lowest factor wins.
func apply_slow(factor: float) -> void:
	_requested_slow_factor = minf(_requested_slow_factor, factor)


## True while a tower is slowing this enemy (as of this enemy's last physics
## step). Meant to be read by other effects, such as the cannon combo.
func is_slowed() -> bool:
	return _slow_factor < 1.0


## Removes [param amount] hit points; the enemy is freed at zero.
func take_damage(amount: float) -> void:
	if is_queued_for_deletion():
		return
	_hp -= amount
	if _hp <= 0.0:
		died.emit()
		queue_free()
	else:
		queue_redraw()
