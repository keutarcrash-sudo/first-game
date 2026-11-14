## Piercing arrow of the Archer's primary ability (étape 3a, « Flèche perforante »):
## flies in a straight line, hits every enemy it touches exactly once without
## stopping, and disappears after [code]range[/code] pixels or on leaving the field.
## Each enemy hit takes the damage and is then marked.
## Enemies sit on physics layer 2 and implement [code]take_damage(amount: float)[/code].
class_name PiercingArrow
extends Area2D

const COLOR := Color(1.0, 0.95, 0.6)
const LENGTH := 28.0
const ENEMY_LAYER := 2  # Bit value of physics layer 2, "enemies".

var _damage: float
var _mark_duration: float
var _velocity: Vector2
var _direction: Vector2
var _range: float
var _radius: float
var _field_rect: Rect2
var _travelled := 0.0
var _hit_ids: Dictionary = {}  # Instance ids of the enemies already hit.


## Sets the arrow up from [param def] (values speed, range, radius), a normalised
## [param direction], the [param field_rect] it is freed on leaving, the
## [param damage] dealt to each enemy and the [param mark_duration] it applies.
## Call before adding the arrow to the tree.
func setup(def: AbilityDef, direction: Vector2, field_rect: Rect2, damage: float, mark_duration: float) -> void:
	_direction = direction
	_velocity = direction * float(def.values["speed"])
	_range = float(def.values["range"])
	_radius = float(def.values["radius"])
	_field_rect = field_rect
	_damage = damage
	_mark_duration = mark_duration


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
	if _travelled >= _range or not _field_rect.has_point(global_position):
		queue_free()


func _draw() -> void:
	var half: Vector2 = _direction * (LENGTH * 0.5)
	draw_line(-half, half, COLOR, _radius)


func _on_hit(target: Node2D) -> void:
	if is_queued_for_deletion() or _hit_ids.has(target.get_instance_id()):
		return
	_hit_ids[target.get_instance_id()] = true
	if not target.has_method(&"take_damage"):
		return
	target.call(&"take_damage", _damage)
	# After the damage: Enemy.apply_mark ignores an enemy the hit just killed.
	var enemy := target as Enemy
	if enemy != null:
		enemy.apply_mark(_mark_duration)
