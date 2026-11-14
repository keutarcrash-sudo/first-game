## Enemy (story 002): walks straight to the crystal, wherever it is now. Sits on physics layer 2
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
const BURNING_TINT := Color(1.0, 0.75, 0.15)
const BURNING_TINT_AMOUNT := 0.5  # Fill tint, used when the enemy is not also slowed (blue fill wins).
const BURNING_RING_WIDTH := 4.0  # The orange ring is always drawn while burning, so both states stay readable together.
const BURNING_RING_POINTS := 24
const MARKED_COLOR := Color(1.0, 0.95, 0.2)  # Small yellow ring around the body (story 008).
const MARKED_RING_GAP := 5.0  # Drawn outside the body, so it stays visible next to the burning ring.
const MARKED_RING_WIDTH := 3.0  # Lines have no antialiasing feather since 4.7, so not thinner than this.
const WET_TINT := Color(0.08, 0.2, 0.65)  # Darker and deeper than SLOWED_TINT, so wet and slowed read apart (story 009).
const WET_TINT_AMOUNT := 0.55
const WET_DROP_COLOR := Color(0.55, 0.85, 1.0)
const WET_DROP_RADIUS := 3.0
const WET_DROP_COUNT := 3
const FROZEN_TINT := Color(0.88, 0.97, 1.0)  # Whitish ice look, wins over every other fill tint.
const FROZEN_TINT_AMOUNT := 0.85
const FROZEN_OUTLINE_COLOR := Color(0.75, 0.95, 1.0)
const FROZEN_OUTLINE_WIDTH := 7.0  # Thick outline, clearly wider than the other rings.

var _burn_left := 0.0  # Seconds of burning remaining.
var _burn_damage_per_second := 0.0
var _mark_left := 0.0  # Seconds of « marqué » remaining (story 008).

var _wet_left := 0.0  # Seconds of « trempé » remaining (story 009).
var _frozen_left := 0.0  # Seconds of « gelé » remaining: the enemy cannot move.
var _freeze_cooldown_left := 0.0  # Seconds during which the enemy cannot be frozen again.
var _freeze_cooldown_after := 0.0  # Cooldown that starts when the current freeze ends.

var _slow_factor := 1.0  # Speed fraction in effect this frame.
var _requested_slow_factor := 1.0  # Lowest factor asked for since the last physics step.
var _crystal: Crystal
var _touch_distance_sq: float
var _contact_damage: float
var _speed: float
var _radius: float
var _hp: float
var _max_hp: float


## Sets stats, hit points ([param hp]), spawn position and target. Call before adding the enemy to the tree.
func setup(stats: DefenceStats, hp: float, start_position: Vector2, crystal: Crystal) -> void:
	_crystal = crystal
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
	if _burn_left > 0.0:
		# Damage over time goes through take_damage (a burn kill still emits died) and triggers no combo.
		var burn_time: float = minf(delta, _burn_left)
		_burn_left -= burn_time
		take_damage(_burn_damage_per_second * burn_time)
		if is_queued_for_deletion():
			return
		if _burn_left <= 0.0:
			queue_redraw()
	if _mark_left > 0.0:
		_mark_left -= delta
		if _mark_left <= 0.0:
			queue_redraw()
	if _wet_left > 0.0:
		_wet_left -= delta
		if _wet_left <= 0.0:
			queue_redraw()
	# Every freeze timer only counts down here, with the physics delta: a freeze
	# always ends by itself, whatever the towers do (or whether they still exist).
	_freeze_cooldown_left = maxf(_freeze_cooldown_left - delta, 0.0)
	if _frozen_left > 0.0:
		_frozen_left -= delta
		if _frozen_left <= 0.0:
			_freeze_cooldown_left = _freeze_cooldown_after
			queue_redraw()
	# The crystal moves, so the target is read again every frame.
	var target: Vector2 = _crystal.global_position
	if _frozen_left <= 0.0:
		position = position.move_toward(target, _speed * _slow_factor * delta)
	if position.distance_squared_to(target) <= _touch_distance_sq:
		_crystal.take_damage(_contact_damage)
		queue_free()


func _draw() -> void:
	var shade: float = lerpf(DAMAGED_DARKEN, 1.0, _hp / _max_hp)
	var color := Color(COLOR.r * shade, COLOR.g * shade, COLOR.b * shade)
	if _frozen_left > 0.0:
		color = color.lerp(FROZEN_TINT, FROZEN_TINT_AMOUNT)
	elif is_slowed():
		color = color.lerp(SLOWED_TINT, SLOWED_TINT_AMOUNT)
	elif _wet_left > 0.0:
		color = color.lerp(WET_TINT, WET_TINT_AMOUNT)
	elif _burn_left > 0.0:
		color = color.lerp(BURNING_TINT, BURNING_TINT_AMOUNT)
	draw_circle(Vector2.ZERO, _radius, color)
	if _burn_left > 0.0:
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, BURNING_RING_POINTS, BURNING_TINT, BURNING_RING_WIDTH)
	if _wet_left > 0.0:
		for i: int in WET_DROP_COUNT:
			var angle: float = TAU * i / WET_DROP_COUNT - PI / 2.0
			draw_circle(Vector2.from_angle(angle) * (_radius * 0.55), WET_DROP_RADIUS, WET_DROP_COLOR)
	if _frozen_left > 0.0:
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, BURNING_RING_POINTS, FROZEN_OUTLINE_COLOR, FROZEN_OUTLINE_WIDTH)
	if _mark_left > 0.0:
		draw_arc(Vector2.ZERO, _radius + MARKED_RING_GAP, 0.0, TAU, BURNING_RING_POINTS, MARKED_COLOR, MARKED_RING_WIDTH)


## Body radius in pixels.
func radius() -> float:
	return _radius


## Asks for a slow to [param factor] (a fraction of normal speed, 0.45 = 45 %)
## for the next physics step only. Towers call it every physics frame while the
## enemy is in range; several callers do not stack, the lowest factor wins.
func apply_slow(factor: float) -> void:
	_requested_slow_factor = minf(_requested_slow_factor, factor)


## True while a tower is slowing this enemy (as of this enemy's last physics
## step). Meant to be read by other effects, such as the cannon combo.
func is_slowed() -> bool:
	return _slow_factor < 1.0


## True while this enemy carries [param state]. Other effects (see [ProcRules])
## read states through this. To add a state, add a case to the match below.
func has_state(state: StringName) -> bool:
	match state:
		&"slowed":
			return is_slowed()
		&"burning":
			return _burn_left > 0.0
		&"marked":
			return _mark_left > 0.0
		&"wet":
			return _wet_left > 0.0
		&"frozen":
			return _frozen_left > 0.0
	return false


## Sets the enemy on fire for [param duration] seconds, taking [param damage_per_second]
## per second. A new call refreshes the duration; it never stacks.
func apply_burn(duration: float, damage_per_second: float) -> void:
	if is_queued_for_deletion():
		return
	var was_burning: bool = _burn_left > 0.0
	_burn_left = duration
	_burn_damage_per_second = damage_per_second
	if not was_burning:
		queue_redraw()


## Marks the enemy for [param duration] seconds (story 008, Archer critical hit).
## A new call refreshes the duration; it never stacks.
func apply_mark(duration: float) -> void:
	if is_queued_for_deletion():
		return
	var was_marked: bool = _mark_left > 0.0
	_mark_left = duration
	if not was_marked:
		queue_redraw()


## Makes the enemy wet (« trempé ») for [param duration] seconds (story 009,
## Maître de l'eau). A new call refreshes the duration; it never stacks.
func apply_wet(duration: float) -> void:
	if is_queued_for_deletion():
		return
	var was_wet: bool = _wet_left > 0.0
	_wet_left = duration
	if not was_wet:
		queue_redraw()


## « trempé + glace = gelé » (story 009): if the enemy is wet, not frozen and not
## in its freeze cooldown, freezes it (it cannot move; it can still be hit and die)
## for [param duration] seconds, then forbids a new freeze for [param cooldown]
## seconds. Returns [code]true[/code] when the enemy was frozen by this call.
func try_freeze(duration: float, cooldown: float) -> bool:
	if is_queued_for_deletion() or _wet_left <= 0.0 or _frozen_left > 0.0 or _freeze_cooldown_left > 0.0:
		return false
	_frozen_left = duration
	_freeze_cooldown_after = cooldown
	queue_redraw()
	return true


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
