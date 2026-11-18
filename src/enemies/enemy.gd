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

const COLOR := Color(1.0, 0.35, 0.3)  # Disc colour, only used when no sprite sheet was given.
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
const RING_HEIGHT_RATIO := 0.32  # With a sprite, state rings have radius height_px x this, around the silhouette centre.
const RING_UNDER_WIDTH := 2.0  # Black under-ring: this many pixels wider on each side of every ring.
const HIT_POSE_SECONDS := 0.2  # The hit animation plays this long, once per hit.

var _sprite: DirectionalSprite
var _visual_height := 0.0
var _hit_left := 0.0  # Seconds of hit pose remaining (visual only).

var _burn_left := 0.0  # Seconds of burning remaining.
var _burn_damage_per_second := 0.0
var _mark_left := 0.0  # Seconds of « marqué » remaining (story 008).

var _wet_left := 0.0  # Seconds of « trempé » remaining (story 009).
var _frozen_left := 0.0  # Seconds of « gelé » remaining: the enemy cannot move.
var _freeze_cooldown_left := 0.0  # Seconds during which the enemy cannot be frozen again.
var _freeze_cooldown_after := 0.0  # Cooldown that starts when the current freeze ends.

var _push_left := 0.0  # Seconds of push remaining (étape 3a, Vague).
var _push_velocity := Vector2.ZERO  # Pixels per second added to the walk while pushed.
var _push_bounds := Rect2()  # Global rect the pushed enemy stays in; no area = unbounded.

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


## Draws the enemy with [param sheet] at [param height_px] on screen instead of a disc
## (graphics only: the collision radius and every rule stay the same). Call before
## adding the enemy to the tree and after [method setup]; the sheet may be shared by all enemies.
func set_visual(sheet: SpriteSheet, height_px: float) -> void:
	_visual_height = height_px
	_sprite = DirectionalSprite.new()
	_sprite.show_behind_parent = true  # The state marks drawn by this node stay over the sprite.
	add_child(_sprite)
	_sprite.setup(sheet, height_px)
	_sprite.play(&"run")
	_refresh_look()


## Angle in radians (as [method Vector2.angle]) from the enemy toward the crystal.
func facing_angle() -> float:
	return (_crystal.global_position - global_position).angle()


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
		_refresh_look()
	if _burn_left > 0.0:
		# Damage over time goes through _damage, without the hit pose (a burn kill still emits died) and triggers no combo.
		var burn_time: float = minf(delta, _burn_left)
		_burn_left -= burn_time
		_damage(_burn_damage_per_second * burn_time, false)
		if is_queued_for_deletion():
			return
		if _burn_left <= 0.0:
			_refresh_look()
	if _mark_left > 0.0:
		_mark_left -= delta
		if _mark_left <= 0.0:
			_refresh_look()
	if _wet_left > 0.0:
		_wet_left -= delta
		if _wet_left <= 0.0:
			_refresh_look()
	# Every freeze timer only counts down here, with the physics delta: a freeze
	# always ends by itself, whatever the towers do (or whether they still exist).
	_freeze_cooldown_left = maxf(_freeze_cooldown_left - delta, 0.0)
	if _frozen_left > 0.0:
		_frozen_left -= delta
		if _frozen_left <= 0.0:
			_freeze_cooldown_left = _freeze_cooldown_after
			_refresh_look()
	if _push_left > 0.0:
		var push_time: float = minf(delta, _push_left)
		_push_left -= push_time
		_move_pushed(_push_velocity * push_time)
	# The crystal moves, so the target is read again every frame.
	var target: Vector2 = _crystal.global_position
	if _frozen_left <= 0.0:
		position = position.move_toward(target, _speed * _slow_factor * delta)
	if _sprite != null:
		_update_visual(target)
	if position.distance_squared_to(target) <= _touch_distance_sq:
		_crystal.take_damage(_contact_damage)
		queue_free()


## Tint of the body for the current state: darker when hurt, then one fill tint
## (frozen > slowed > wet > burning).
func _body_color() -> Color:
	var shade: float = lerpf(DAMAGED_DARKEN, 1.0, _hp / _max_hp)
	var color := Color(COLOR.r * shade, COLOR.g * shade, COLOR.b * shade)
	if _sprite != null:
		color = Color(shade, shade, shade)  # Neutral base: the sprite keeps its own colours.
	if _frozen_left > 0.0:
		color = color.lerp(FROZEN_TINT, FROZEN_TINT_AMOUNT)
	elif is_slowed():
		color = color.lerp(SLOWED_TINT, SLOWED_TINT_AMOUNT)
	elif _wet_left > 0.0:
		color = color.lerp(WET_TINT, WET_TINT_AMOUNT)
	elif _burn_left > 0.0:
		color = color.lerp(BURNING_TINT, BURNING_TINT_AMOUNT)
	return color


## Called whenever a state or the hit points change: updates the sprite tint at once and redraws the marks.
func _refresh_look() -> void:
	if _sprite != null:
		_sprite.tint = _body_color()
	queue_redraw()


func _draw() -> void:
	var center := Vector2.ZERO
	var ring_radius: float = _radius
	if _sprite != null:
		center = Vector2(0.0, -_visual_height * 0.5)  # The sprite stands on the position: its middle is above it.
		ring_radius = _visual_height * RING_HEIGHT_RATIO
	else:
		draw_circle(Vector2.ZERO, _radius, _body_color())
	if _burn_left > 0.0:
		_draw_ring(center, ring_radius, BURNING_TINT, BURNING_RING_WIDTH)
	if _wet_left > 0.0:
		for i: int in WET_DROP_COUNT:
			var angle: float = TAU * i / WET_DROP_COUNT - PI / 2.0
			var drop_at: Vector2 = center + Vector2.from_angle(angle) * (ring_radius * 0.55)
			draw_circle(drop_at, WET_DROP_RADIUS + RING_UNDER_WIDTH, Color.BLACK)
			draw_circle(drop_at, WET_DROP_RADIUS, WET_DROP_COLOR)
	if _frozen_left > 0.0:
		_draw_ring(center, ring_radius, FROZEN_OUTLINE_COLOR, FROZEN_OUTLINE_WIDTH)
	if _mark_left > 0.0:
		_draw_ring(center, ring_radius + MARKED_RING_GAP, MARKED_COLOR, MARKED_RING_WIDTH)


## A ring over a black ring [constant RING_UNDER_WIDTH] pixels wider on each side, so it reads on any background.
func _draw_ring(center: Vector2, ring_radius: float, color: Color, width: float) -> void:
	draw_arc(center, ring_radius, 0.0, TAU, BURNING_RING_POINTS, Color.BLACK, width + RING_UNDER_WIDTH * 2.0)
	draw_arc(center, ring_radius, 0.0, TAU, BURNING_RING_POINTS, color, width)


## Faces the crystal and goes back from the hit pose to the run animation.
func _update_visual(target: Vector2) -> void:
	_sprite.set_facing((target - global_position).angle())
	if _hit_left > 0.0:
		_hit_left -= get_physics_process_delta_time()
		if _hit_left <= 0.0:
			_sprite.play(&"run")


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
		_refresh_look()


## Marks the enemy for [param duration] seconds (story 008, Archer critical hit).
## A new call refreshes the duration; it never stacks.
func apply_mark(duration: float) -> void:
	if is_queued_for_deletion():
		return
	var was_marked: bool = _mark_left > 0.0
	_mark_left = duration
	if not was_marked:
		_refresh_look()


## Marks the enemy for at least [param duration] seconds: keeps the longer of the current
## and the new duration (étape 3b, Œil du chasseur), unlike [method apply_mark].
func extend_mark(duration: float) -> void:
	if is_queued_for_deletion():
		return
	var was_marked: bool = _mark_left > 0.0
	_mark_left = maxf(_mark_left, duration)
	if not was_marked and _mark_left > 0.0:
		_refresh_look()


## Makes the enemy wet (« trempé ») for [param duration] seconds (story 009,
## Maître de l'eau). A new call refreshes the duration; it never stacks.
func apply_wet(duration: float) -> void:
	if is_queued_for_deletion():
		return
	var was_wet: bool = _wet_left > 0.0
	_wet_left = duration
	if not was_wet:
		_refresh_look()


## « trempé + glace = gelé » (story 009): if the enemy is wet, not frozen and not
## in its freeze cooldown, freezes it (it cannot move; it can still be hit and die)
## for [param duration] seconds, then forbids a new freeze for [param cooldown]
## seconds. Returns [code]true[/code] when the enemy was frozen by this call.
func try_freeze(duration: float, cooldown: float) -> bool:
	if is_queued_for_deletion() or _wet_left <= 0.0 or _frozen_left > 0.0 or _freeze_cooldown_left > 0.0:
		return false
	_frozen_left = duration
	_freeze_cooldown_after = cooldown
	_push_left = 0.0  # A frozen enemy stops dead, even mid-push.
	_refresh_look()
	return true


## Freezes the enemy for [param duration] seconds whatever its freeze cooldown or
## wetness (étape 3b, Raz-de-marée); same look and rules as [method try_freeze]. A
## freeze already running is only extended, never shortened. The cooldown that
## follows the freeze is left unchanged.
func force_freeze(duration: float) -> void:
	if is_queued_for_deletion():
		return
	_frozen_left = maxf(_frozen_left, duration)
	_freeze_cooldown_left = 0.0
	_push_left = 0.0
	_refresh_look()


## Shoves the enemy by [param offset] pixels, spread over [param duration] seconds, on top
## of its walk (étape 3a, Vague). Does nothing while frozen. A new push replaces the
## current one. While pushed, the position stays inside [param bounds] (a global rect)
## unless it has no area, in which case it is not limited.
func push(offset: Vector2, duration: float, bounds: Rect2 = Rect2()) -> void:
	if is_queued_for_deletion() or _frozen_left > 0.0:
		return
	_push_bounds = bounds
	if duration <= 0.0:
		_push_left = 0.0
		_move_pushed(offset)
		return
	_push_velocity = offset / duration
	_push_left = duration


func _move_pushed(step: Vector2) -> void:
	var target: Vector2 = global_position + step
	if _push_bounds.has_area():
		# Shrunk by the radius so the whole body stays in the field.
		var inner: Rect2 = _push_bounds.grow(-_radius)
		if inner.has_area():
			target.x = clampf(target.x, inner.position.x, inner.end.x)
			target.y = clampf(target.y, inner.position.y, inner.end.y)
	global_position = target


## Removes [param amount] hit points; the enemy is freed at zero.
func take_damage(amount: float) -> void:
	_damage(amount, true)


## Shared by [method take_damage] and the burn (which must not replay the hit pose every frame).
func _damage(amount: float, show_hit: bool) -> void:
	if is_queued_for_deletion():
		return
	_hp -= amount
	if _hp <= 0.0:
		died.emit()
		queue_free()
	else:
		if show_hit and _sprite != null and _hit_left <= 0.0:
			_hit_left = HIT_POSE_SECONDS
			_sprite.play(&"hit")
		_refresh_look()
