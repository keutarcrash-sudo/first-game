## Hero projectile (story 001): travels in a straight line, deals [member damage]
## to the first enemy it touches, and is freed on impact or after
## [member HeroStats.bullet_max_range] pixels. Story 008: an Archer arrow
## ([method set_pierce], [method set_archer]) passes through several enemies,
## never the same one twice, and each hit may be critical and mark the enemy.
## Contract for story 002: enemies sit on physics layer 2 ("enemies") and
## implement [code]take_damage(amount: float)[/code].
class_name HeroBullet
extends Area2D

const COLOR := Color(1.0, 0.9, 0.35)
const ENEMY_LAYER := 2  # Bit value of physics layer 2, "enemies".
const CRIT_COLOR := Color(1.0, 0.95, 0.2)
const CRIT_EFFECT_OFFSET := Vector2(0.0, 26.0)  # Below the combo label when both show on one hit.

## Damage dealt to the target hit.
var damage: float
var _velocity: Vector2
var _max_range: float
var _radius: float
var _arena_rect: Rect2
var _travelled := 0.0
var _source: StringName
var _rules: ProcRules
var _burn_duration := 0.0
var _burn_damage_per_second := 0.0
var _hits_left := 1  # Enemies this projectile can still hit.
var _hit_ids: Dictionary = {}  # Instance ids of the targets already hit.
var _archer: ArcherWeapon
var _wet_duration := 0.0
var _color := COLOR


## Sets the damage source tag (for example [code]&"cannon"[/code]) and the combo
## rules applied at impact. Call before adding the bullet to the tree.
func set_proc_source(source: StringName, rules: ProcRules) -> void:
	_source = source
	_rules = rules


## Makes the bullet set its target burning at impact (story 006). Burning is not
## a bullet hit: it triggers no combo. Call before adding the bullet to the tree.
func set_burn(duration: float, damage_per_second: float) -> void:
	_burn_duration = duration
	_burn_damage_per_second = damage_per_second


## Makes the bullet soak its target (state « trempé ») for [param duration] seconds
## at impact (story 009). Call before adding the bullet to the tree.
func set_wet(duration: float) -> void:
	_wet_duration = duration


## Sets the colour the projectile is drawn with (default [constant COLOR]).
func set_color(color: Color) -> void:
	_color = color


## Lets the projectile hit [param count] different enemies (at least 1) before
## it is freed. Call before adding the bullet to the tree.
func set_pierce(count: int) -> void:
	_hits_left = maxi(count, 1)


## Makes each hit roll a critical with [param archer]: a critical hit is
## multiplied by its critical multiplier and marks the enemy. Call before adding the bullet to the tree.
func set_archer(archer: ArcherWeapon) -> void:
	_archer = archer


## Sets the values (used by the hero's weapon and the cannon tower, story 004): [param hit_damage],
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
	draw_circle(Vector2.ZERO, _radius, _color)


func _on_hit(target: Node2D) -> void:
	# Once its last hit is used the bullet ignores every other target, even one
	# touched in the same frame; a piercing arrow never hits the same enemy twice.
	if is_queued_for_deletion() or _hit_ids.has(target.get_instance_id()):
		return
	_hit_ids[target.get_instance_id()] = true
	if target.has_method(&"take_damage"):
		var dealt: float = damage
		var enemy := target as Enemy
		var crit: bool = _archer != null and _archer.roll_crit()
		if crit:
			dealt *= _archer.crit_multiplier()
			_show_effect(target, CRIT_EFFECT_OFFSET, "Critique ×%s" % String.num(_archer.crit_multiplier()), CRIT_COLOR)
		if _rules != null and enemy != null:
			# Resolved now, at impact: the state is the one the enemy has this instant.
			var proc: ProcRules.Result = _rules.resolve(_source, enemy.has_state)
			if not proc.combo_ids.is_empty():
				dealt *= proc.multiplier
				_show_effect(target, Vector2.ZERO, "×%s" % String.num(proc.multiplier), ProcEffect.COLOR)
		target.call(&"take_damage", dealt)
		# After the hit, so this bullet's own combo ignores its burn or mark; both ignore an enemy the hit killed.
		if enemy != null and _burn_duration > 0.0:
			enemy.apply_burn(_burn_duration, _burn_damage_per_second)
		if enemy != null and _wet_duration > 0.0:
			enemy.apply_wet(_wet_duration)
		if enemy != null and crit:
			enemy.apply_mark(_archer.mark_duration())
	_hits_left -= 1
	if _hits_left <= 0:
		queue_free()


func _show_effect(target: Node2D, offset: Vector2, text: String, color: Color) -> void:
	var parent := get_parent() as Node2D
	if parent == null:
		return
	var effect := ProcEffect.new()
	effect.setup(parent.to_local(target.global_position) + offset, text, color)
	# Deferred: this runs inside a physics signal, where the tree must not change.
	parent.add_child.call_deferred(effect)
