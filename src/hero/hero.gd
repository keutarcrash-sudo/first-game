## The hero (story 001, design/game-brief.md MVP feature 1): moves with the
## move_* actions (ZQSD as printed on an AZERTY keyboard, or arrows), stays
## inside the arena and fires automatically toward the mouse cursor.
## Story 008: the weapon comes from the specialization chosen at the start of the
## game ([method equip]); the hero neither moves nor fires before that.
class_name Hero
extends CharacterBody2D

## Emitted when a [method dash] ends (duration elapsed).
signal dash_finished

const BODY_COLOR := Color(0.3, 0.8, 1.0)
const AIM_COLOR := Color(0.3, 0.8, 1.0, 0.6)
const AIM_LINE_LENGTH := 14.0
const AIM_LINE_WIDTH := 3.0
const HERO_LAYER := 1
const FIRE_BOLT_COLOR := Color(1.0, 0.55, 0.15)
const WATER_JET_COLOR := Color(0.35, 0.65, 1.0)

var _stats: HeroStats
var _bullet_parent: Node
var _arena_rect: Rect2
var _rules: ProcRules
var _archer: ArcherWeapon
var _elemental: ElementalWeapon
var _bullet_color := HeroBullet.COLOR
var _min_position: Vector2
var _max_position: Vector2
var _aim_direction := Vector2.RIGHT
var _fire_cooldown := 0.0
var _dash_direction := Vector2.ZERO
var _dash_speed := 0.0
var _dash_left := 0.0  # Seconds of dash remaining; 0 = not dashing.


## Gives the hero its tuning values (movement, size, projectile speed and size),
## the arena it must stay in, the node its projectiles are added to, and the
## combo rules its shots use (source [code]&"hero"[/code]). Call once, before the
## first physics frame. The hero stays still until [method equip].
func setup(stats: HeroStats, arena_rect: Rect2, bullet_parent: Node, rules: ProcRules) -> void:
	set_physics_process(false)
	_rules = rules
	_stats = stats
	_bullet_parent = bullet_parent
	_arena_rect = arena_rect
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


## Gives the hero the weapon of [param spec] and lets it move and fire. Card
## bonuses are read from [param modifiers] at each shot; [param rng] rolls the
## critical hits. Call once, when the specialization is chosen.
## A new weapon type (see [constant SpecializationCatalog.WEAPON_NUMBER_KEYS])
## is built here from [member SpecializationDef.weapon_type].
func equip(spec: SpecializationDef, modifiers: PlayerModifiers, rng: RandomNumberGenerator) -> void:
	match spec.weapon_type:
		"arrows":
			_archer = ArcherWeapon.new(spec.weapon, modifiers, rng)
		"fire_bolts":
			_elemental = ElementalWeapon.new(spec.weapon, modifiers)
			_bullet_color = FIRE_BOLT_COLOR
		"water_jets":
			_elemental = ElementalWeapon.new(spec.weapon, modifiers)
			_bullet_color = WATER_JET_COLOR
	set_physics_process(true)


## The Archer's weapon, or [code]null[/code] for another specialization (or before [method equip]).
func archer_weapon() -> ArcherWeapon:
	return _archer


## The elemental weapon (fire or water), or [code]null[/code] for another specialization (or before [method equip]).
func elemental_weapon() -> ElementalWeapon:
	return _elemental


## Radius of the hero's body in pixels (0 before [method setup]).
func body_radius() -> float:
	return _stats.hero_radius if _stats != null else 0.0


## Current movement direction from the move_* actions (length up to 1),
## [code]Vector2.ZERO[/code] when no key is held.
func move_direction() -> Vector2:
	# get_vector caps the length at 1, so diagonals are as fast as straight lines.
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


## Jumps [param distance] pixels along [param direction] (normalised here) at constant
## speed over [param duration] seconds. The arena edge blocks the jump. Movement keys
## are ignored meanwhile; the hero keeps firing. Emits [signal dash_finished] at the end.
## Does nothing while already dashing or when the direction, distance or duration is zero.
func dash(direction: Vector2, distance: float, duration: float) -> void:
	if is_dashing() or direction == Vector2.ZERO or distance <= 0.0 or duration <= 0.0:
		return
	_dash_direction = direction.normalized()
	_dash_speed = distance / duration
	_dash_left = duration


## Stops a dash in progress where the hero stands, without emitting [signal dash_finished].
func cancel_dash() -> void:
	_dash_left = 0.0


## True while a [method dash] is in progress.
func is_dashing() -> bool:
	return _dash_left > 0.0


func _physics_process(delta: float) -> void:
	var finished_dash := false
	if _dash_left > 0.0:
		var step: float = minf(delta, _dash_left)
		_dash_left -= step
		global_position += _dash_direction * _dash_speed * step
		global_position = global_position.clamp(_min_position, _max_position)
		if _dash_left <= 0.0:
			_dash_left = 0.0
			finished_dash = true
	else:
		velocity = move_direction() * _stats.hero_speed
		move_and_slide()
		global_position = global_position.clamp(_min_position, _max_position)

	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	if to_mouse != Vector2.ZERO:
		_aim_direction = to_mouse.normalized()

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		_fire()
		_fire_cooldown += 1.0 / (_archer.fire_rate() if _archer != null else _elemental.fire_rate())
	queue_redraw()
	if finished_dash:
		dash_finished.emit()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _stats.hero_radius, BODY_COLOR)
	var aim_start: Vector2 = _aim_direction * _stats.hero_radius
	draw_line(aim_start, aim_start + _aim_direction * AIM_LINE_LENGTH, AIM_COLOR, AIM_LINE_WIDTH)


func _fire() -> void:
	var bullet := HeroBullet.new()
	if _elemental != null:
		bullet.configure(_elemental.damage(), _stats.bullet_speed, _elemental.max_range(), _stats.bullet_radius, _aim_direction, _arena_rect)
		bullet.set_proc_source(&"hero", _rules)
		bullet.set_pierce(_elemental.pierce())
		bullet.set_burn(_elemental.burn_duration(), _elemental.burn_damage_per_second())
		bullet.set_wet(_elemental.wet_duration())
		bullet.set_color(_bullet_color)
		_bullet_parent.add_child(bullet)
		bullet.global_position = global_position
		return
	bullet.configure(_archer.damage(), _stats.bullet_speed, _archer.max_range(), _stats.bullet_radius, _aim_direction, _arena_rect)
	bullet.set_proc_source(&"hero", _rules)
	bullet.set_pierce(_archer.pierce())
	bullet.set_archer(_archer)
	bullet.set_guaranteed_crit(_archer.take_forced_crit())
	_bullet_parent.add_child(bullet)
	bullet.global_position = global_position
