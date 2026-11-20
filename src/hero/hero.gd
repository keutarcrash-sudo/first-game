## The hero (story 001, design/game-brief.md MVP feature 1): moves with the
## move_* actions (ZQSD as printed on an AZERTY keyboard, or arrows), stays
## inside the arena and fires automatically toward the mouse cursor.
## Story 008: the weapon comes from the specialization chosen at the start of the
## game ([method equip]); the hero neither moves nor fires before that.
class_name Hero
extends CharacterBody2D

## Emitted when a [method dash] ends (duration elapsed).
signal dash_finished
## Emitted once, when the hero's hit points reach 0 (étape 4). The hero then stops
## moving and firing and plays its [code]death[/code] animation.
signal died

const HIT_FLASH_SECONDS := 0.12  # Red tint after a hit (visual only).
const HIT_FLASH_COLOR := Color(1.0, 0.25, 0.25)
const BLINK_HALF_PERIOD := 0.05  # Invulnerability blink: 10 Hz (visual only).
const BLINK_ALPHA := 0.35
const SHOOT_MAX_SPEED_SCALE := 4.0  # Fastest the shoot clip is played to fit a short fire interval.
const HERO_LAYER := 1
const FIRE_BOLT_COLOR := Color(1.0, 0.55, 0.15)
const WATER_JET_COLOR := Color(0.35, 0.65, 1.0)
const GHOST_PIERCE := 1000000  # Flèches fantômes: « all enemies » in practice.

var _stats: HeroStats
var _modifiers: PlayerModifiers
var _sprite: DirectionalSprite
var _sheet: SpriteSheet
var _shot_now := false  # A shot was fired since the last visual update (visual only).
var _shooting := false  # The shoot clip is playing and has not ended (visual only).
var _fire_interval := 1.0
var _bullet_parent: Node
var _arena_rect: Rect2
var _rules: ProcRules
var _archer: ArcherWeapon
var _rng: RandomNumberGenerator
var _elemental: ElementalWeapon
var _bullet_color := HeroBullet.COLOR
var _min_position: Vector2
var _max_position: Vector2
var _aim_direction := Vector2.RIGHT
var _fire_cooldown := 0.0
var _dash_direction := Vector2.ZERO
var _dash_speed := 0.0
var _dash_left := 0.0  # Seconds of dash remaining; 0 = not dashing.
var _health: HeroHealth
var _impact: ImpactFeedback  # Optional: shakes the screen when the hero is hit.
var _flash_left := 0.0  # Seconds of red tint remaining (visual only).
var _blink_time := 0.0  # Clock of the invulnerability blink (visual only).


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
	_health = HeroHealth.new(stats.hero_max_hp, stats.hit_invulnerability)
	_health.died.connect(_on_died)
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


## Sets the sprite sheet the hero is drawn with and its on-screen height in
## pixels (graphics only: nothing in the game rules depends on it). May be
## called again to change the look, for example when the specialization is chosen.
func set_visual(sheet: SpriteSheet, height_px: float) -> void:
	if _sprite == null:
		_sprite = DirectionalSprite.new()
		add_child(_sprite)
	_sheet = sheet
	_shooting = false
	_sprite.setup(sheet, height_px)
	if not _sprite.animation_finished.is_connected(_on_animation_finished):
		_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.set_facing(_aim_direction.angle())
	_sprite.play(&"idle")


## Gives the hero the weapon of [param spec] and lets it move and fire. Card
## bonuses are read from [param modifiers] at each shot; [param rng] rolls the
## critical hits. Call once, when the specialization is chosen.
## A new weapon type (see [constant SpecializationCatalog.WEAPON_NUMBER_KEYS])
## is built here from [member SpecializationDef.weapon_type].
func equip(spec: SpecializationDef, modifiers: PlayerModifiers, rng: RandomNumberGenerator) -> void:
	_modifiers = modifiers
	_rng = rng
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


## The hero's hit points (null before [method setup]).
func health() -> HeroHealth:
	return _health


## Gives the hero the screen-shake feedback played when it is hit. Optional.
func set_impact(impact: ImpactFeedback) -> void:
	_impact = impact


## Hits the hero for [param amount]. Nothing happens while jumping (dash), invulnerable
## or dead; otherwise the hero flashes red, the screen shakes a little, and it
## is invulnerable for a moment (it blinks).
func hurt(amount: float) -> void:
	if _health == null or not _health.take_hit(amount, is_dashing()):
		return
	_flash_left = HIT_FLASH_SECONDS
	if _impact != null:
		_impact.shake(&"small")


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
	_health.tick(delta)
	_update_hit_visual(delta)
	var finished_dash := false
	var was_dashing := _dash_left > 0.0
	var moving := false
	if _dash_left > 0.0:
		var step: float = minf(delta, _dash_left)
		_dash_left -= step
		global_position += _dash_direction * _dash_speed * step
		global_position = global_position.clamp(_min_position, _max_position)
		if _dash_left <= 0.0:
			_dash_left = 0.0
			finished_dash = true
	else:
		var wanted: Vector2 = move_direction()
		moving = wanted != Vector2.ZERO
		velocity = wanted * _stats.hero_speed * (_modifiers.move_speed_factor() if _modifiers != null else 1.0)
		move_and_slide()
		global_position = global_position.clamp(_min_position, _max_position)

	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	if to_mouse != Vector2.ZERO:
		_aim_direction = to_mouse.normalized()

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		_fire()
		_fire_interval = 1.0 / (_archer.fire_rate() if _archer != null else _elemental.fire_rate())
		_fire_cooldown += _fire_interval
	_update_visual(was_dashing, moving)
	if finished_dash:
		dash_finished.emit()


## Picks the animation (roll > shoot while still > run > idle) and the facing
## (the dash direction while rolling, the mouse otherwise). Each shot restarts the
## shoot clip, sped up so that it lasts about one fire interval; the pose is kept
## until the clip ends or the hero moves.
func _update_visual(dashing: bool, moving: bool) -> void:
	var shot: bool = _shot_now
	_shot_now = false
	if _sprite == null:
		return
	if dashing:
		_shooting = false
		_sprite.set_facing(_dash_direction.angle())
		_sprite.play(&"roll")
		return
	_sprite.set_facing(_aim_direction.angle())
	if moving:
		_shooting = false
		_sprite.play(&"run")
	elif shot:
		_shooting = true
		_sprite.play(&"shoot", true)
		var clip_length: float = float(_sheet.frame_count(&"shoot")) / _sheet.fps(&"shoot")
		_sprite.speed_scale = clampf(clip_length / _fire_interval, 1.0, SHOOT_MAX_SPEED_SCALE)
	elif _shooting:
		_sprite.play(&"shoot")
	else:
		_sprite.play(&"idle")


## Red tint right after a hit, then the sprite blinks (alpha toggling at 10 Hz)
## for as long as the hero is invulnerable.
func _update_hit_visual(delta: float) -> void:
	if _sprite == null:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	var color := HIT_FLASH_COLOR if _flash_left > 0.0 else Color.WHITE
	if _health.is_invulnerable():
		_blink_time += delta
		if int(_blink_time / BLINK_HALF_PERIOD) % 2 == 1:
			color.a = BLINK_ALPHA
	else:
		_blink_time = 0.0
	_sprite.modulate = color


## Death: the hero stops moving and firing (no more physics frames, so no input either)
## and plays its [code]death[/code] animation. It keeps processing while the game is
## paused for the death sequence, so the clip is seen (its sprite child inherits this).
func _on_died() -> void:
	set_physics_process(false)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dash_left = 0.0
	if _sprite != null:
		_sprite.modulate = Color.WHITE
		if _sheet != null and _sheet.has_animation(&"death"):
			_sprite.play(&"death")
		else:
			push_error("Hero: the hero sheet has no 'death' animation.")
	died.emit()


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"shoot":
		_shooting = false


func _fire() -> void:
	_shot_now = true
	if _elemental != null:
		var bullet := HeroBullet.new()
		bullet.configure(_elemental.damage(), _stats.bullet_speed, _elemental.max_range(), _stats.bullet_radius, _aim_direction, _arena_rect)
		bullet.set_proc_source(&"hero", _rules)
		bullet.set_pierce(_elemental.pierce())
		bullet.set_burn(_elemental.burn_duration(), _elemental.burn_damage_per_second())
		bullet.set_wet(_elemental.wet_duration())
		bullet.set_color(_bullet_color)
		_bullet_parent.add_child(bullet)
		bullet.global_position = global_position
		return
	_fire_arrow(true)


## Fires one Archer arrow. [param primary]: a normal shot (consumes a pending Roulade critical and can
## trigger Tir en rafale); the rafale's second arrow is not primary: it can crit but never starts a rafale.
func _fire_arrow(primary: bool) -> void:
	var bullet := HeroBullet.new()
	bullet.configure(_archer.damage(), _stats.bullet_speed, _archer.max_range(), _stats.bullet_radius, _aim_direction, _arena_rect)
	bullet.set_proc_source(&"hero", _rules)
	var ghost: bool = _modifiers != null and _modifiers.has_flag(&"ghost_arrows")
	bullet.set_pierce(GHOST_PIERCE if ghost else _archer.pierce())
	bullet.set_archer(_archer)
	if primary:
		bullet.set_guaranteed_crit(_archer.take_forced_crit())
		if _modifiers != null and _modifiers.has_flag(&"burst_on_crit"):
			bullet.set_on_crit(_on_arrow_crit)
	_bullet_parent.add_child(bullet)
	bullet.global_position = global_position


## Tir en rafale: a critical hit of a normal arrow fires a second arrow at once with the card's chance.
func _on_arrow_crit() -> void:
	if _archer == null or _rng == null or _modifiers == null:
		return
	if _rng.randf() < _modifiers.flag_value(&"burst_on_crit", "chance"):
		_fire_arrow(false)
