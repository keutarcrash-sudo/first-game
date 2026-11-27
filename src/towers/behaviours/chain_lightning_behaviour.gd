## Chain lightning behaviour, the Tesla (towers T2a, spec §5.1): every [code]interval[/code]
## seconds, a bolt strikes the designated enemy when in range, else the nearest one, then
## bounces [code]jumps[/code] times to the nearest enemy not yet struck by this bolt within
## [code]jump_range[/code] of the last one. Every strike deals the full damage, x
## [code]wet_mult[/code] on a wet enemy. Surtension (level 2+): more bounces and a stronger
## wet bonus. Arc (level 2+): longer range and every enemy of the chain is stunned; level 3
## stuns longer and hits harder ([code]l3_damage_mult[/code]). Branch and level are read at
## every bolt ([method TowerDef.value]), so an upgrade acts at once. The strikes go through
## [code]take_damage(..., &"cannon")[/code] (cyan numbers). The amplifier bonuses
## ([member TowerBehaviour.TowerContext.amp_at]) are read at every bolt: damage, interval
## and stun duration. The bolt is drawn as a neon broken line for [constant BOLT_SECONDS].
class_name ChainLightningBehaviour
extends TowerBehaviour

## Seconds a bolt stays visible.
const BOLT_SECONDS := 0.15
## Broken-line points added between two struck positions, and their sideways jitter in pixels.
const BOLT_KINKS := 3
const BOLT_JITTER := 9.0
const BOLT_GLOW := Color(0.45, 0.7, 1.0, 0.45)
const BOLT_CORE := Color(0.9, 0.97, 1.0, 0.95)
const BOLT_GLOW_WIDTH := 7.0
const BOLT_CORE_WIDTH := 2.0

var _tower: Tower
var _def: TowerDef
var _record: TowerRecord
var _ctx: TowerBehaviour.TowerContext
var _cooldown := 0.0
var _bolt: PackedVector2Array = PackedVector2Array()  # World points of the last bolt's broken line.
var _bolt_left := 0.0


## See [method TowerBehaviour.setup].
func setup(tower: Tower, def: TowerDef, record: TowerRecord, ctx: TowerBehaviour.TowerContext) -> void:
	_tower = tower
	_def = def
	_record = record
	_ctx = ctx


## Range with the card and item bonuses and the Arc range.
func range_now() -> float:
	return _number("range", 0.0) * _ctx.modifiers.tower_range_factor()


## Counts the cooldown and the bolt display down, and fires when an enemy is in range.
func physics_tick(delta: float) -> void:
	if _bolt_left > 0.0:
		_bolt_left -= delta
		_tower.queue_redraw()  # Also once after it ends, to clear it.
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	var target: Enemy = _designated_in_range()
	if target == null:
		target = _nearest_enemy(_tower.global_position, _tower.attack_range, {})
	if target == null:
		return
	var amp: Dictionary = _ctx.amp_at.call(_tower.global_position, _record.id)
	_strike_chain(target, amp)
	_cooldown = _number("interval", 1.0) / (1.0 + float(amp["rate"]))
	if _record.level >= TowerRecord.MAX_LEVEL:
		_cooldown *= _ctx.modifiers.tier3_fire_rate_factor()  # « Surcharge ».


## The last bolt as a neon broken line, while it is visible.
func draw(canvas: CanvasItem) -> void:
	if _bolt_left <= 0.0 or _bolt.size() < 2:
		return
	var local := PackedVector2Array()
	for point: Vector2 in _bolt:
		local.append(_tower.to_local(point))
	canvas.draw_polyline(local, BOLT_GLOW, BOLT_GLOW_WIDTH, true)
	canvas.draw_polyline(local, BOLT_CORE, BOLT_CORE_WIDTH, true)


## Strikes [param first] then bounces, never twice on the same enemy, and keeps the line to draw.
func _strike_chain(first: Enemy, amp: Dictionary) -> void:
	var damage: float = _number("damage", 0.0) * _number("damage_mult", 1.0) \
		* _ctx.modifiers.damage_multiplier() * (1.0 + float(amp["damage"]))
	var wet_mult: float = _number("wet_mult", 1.0)
	var stun: float = _number("stun", 0.0) * (1.0 + float(amp["state"]))
	var jumps: int = int(_number("jumps", 0.0))
	var jump_range: float = _number("jump_range", 0.0)
	var struck: Dictionary = {}  # Instance ids of the enemies this bolt already hit.
	var from: Vector2 = _tower.global_position
	var points := PackedVector2Array()
	points.append(from)
	var enemy: Enemy = first
	var strikes_left: int = jumps + 1
	while enemy != null and strikes_left > 0:
		strikes_left -= 1
		struck[enemy.get_instance_id()] = true
		var at: Vector2 = enemy.global_position
		points.append_array(_broken_segment(from, at))  # Packed arrays are copied, not shared.
		from = at
		var dealt: float = damage * (wet_mult if enemy.has_state(&"wet") else 1.0)
		enemy.take_damage(dealt, false, &"cannon")
		if stun > 0.0 and is_instance_valid(enemy):
			enemy.stun(stun)  # Ignored on an enemy that just died.
		if strikes_left > 0:
			enemy = _nearest_enemy(at, jump_range, struck)
	var direction: Vector2 = _tower.global_position.direction_to(first.global_position) if is_instance_valid(first) else Vector2.ZERO
	if direction != Vector2.ZERO:
		_tower.set_facing(direction.angle())
	_bolt = points
	_bolt_left = BOLT_SECONDS
	_tower.queue_redraw()


## The points of a jagged line from [param from] (left out) to [param to] (included).
func _broken_segment(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var side: Vector2 = (to - from).orthogonal().normalized()
	for i: int in BOLT_KINKS:
		var t: float = float(i + 1) / float(BOLT_KINKS + 1)
		points.append(from.lerp(to, t) + side * randf_range(-BOLT_JITTER, BOLT_JITTER))
	points.append(to)
	return points


## The designated enemy when it is within this tower's range, else null.
func _designated_in_range() -> Enemy:
	var designated: Enemy = _ctx.designator.target()
	if designated == null or designated.is_queued_for_deletion():
		return null
	var attack_range: float = _tower.attack_range
	if _tower.global_position.distance_squared_to(designated.global_position) > attack_range * attack_range:
		return null
	return designated


## The living enemy nearest to [param at] within [param max_distance] whose instance id
## is not a key of [param skip], or null.
func _nearest_enemy(at: Vector2, max_distance: float, skip: Dictionary) -> Enemy:
	var nearest: Enemy = null
	var nearest_sq: float = max_distance * max_distance
	var enemies: Node2D = _ctx.enemies
	for i: int in enemies.get_child_count():
		var enemy := enemies.get_child(i) as Enemy
		if enemy == null or enemy.is_queued_for_deletion() or skip.has(enemy.get_instance_id()):
			continue
		var distance_sq: float = at.distance_squared_to(enemy.global_position)
		if distance_sq <= nearest_sq:
			nearest_sq = distance_sq
			nearest = enemy
	return nearest


## Value [param key] for this tower's branch and level ([method TowerDef.value]), or
## [param fallback] when neither the branch nor the base has it (such as [code]stun[/code]
## off the Arc branch). Required keys are validated by [TowerStats].
func _number(key: String, fallback: float) -> float:
	var value: Variant = _def.value(key, _record.branch, _record.level)
	return fallback if value == null else float(value)
