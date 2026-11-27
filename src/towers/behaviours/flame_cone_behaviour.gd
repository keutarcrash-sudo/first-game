## Flame cone behaviour, the flamethrower (towers T2a, spec §5.2): every physics frame, a
## cone of fire of [code]range[/code] and [code]angle_degrees[/code] points at the designated
## enemy when in range, else at the nearest one. Every enemy inside takes [code]dps[/code]
## damage per second (through [code]take_dot_damage(..., &"tower_dot")[/code]: cyan, grouped
## numbers) and is set burning ([code]burn_dps[/code] for [code]burn_duration[/code] s) with
## burner id -1, so the last cannon burner is kept (Incendiaire combo). Napalm (level 2+): a
## stronger, longer burn; level 3 lets it stack up to [code]l3_stack_max[/code]. Souffle
## (level 2+): a wider cone that pushes the enemies along its axis at [code]push_speed[/code];
## level 3 reaches further. Branch and level are read every frame ([method TowerDef.value]).
## The amplifier bonuses ([member TowerBehaviour.TowerContext.amp_at]) are read every frame:
## dps x (1 + rate) x (1 + damage), burn duration x (1 + state). « Balles lourdes » multiplies
## the dps and « Surcharge » speeds it up at level 3 (dps / its interval factor).
## Towers T2b, Dragon (evolved Napalm): the cone opens to the evolution's
## [code]angle_degrees[/code] (360): the fire burns all around the tower, without aiming, and
## is drawn as a ring. Fournaise (evolved Souffle) is a death effect: see [TowerEffects].
class_name FlameConeBehaviour
extends TowerBehaviour

const CONE_POINTS := 12  # Points along the cone's outer arc.
const FLAME_OUTER := Color(1.0, 0.45, 0.1, 0.22)
const FLAME_INNER := Color(1.0, 0.85, 0.35, 0.3)
const FLAME_INNER_RATIO := 0.6  # The bright core reaches this fraction of the range.
const FLICKER := 0.12  # Random variation of the drawn reach, as a fraction of the range.
const NAPALM := &"napalm"
const ALL_AROUND_EPSILON := 0.001  # Radians: a half angle this close to PI covers the full circle.
const RING_POINTS := 32  # Points of the Dragon ring.
const RING_INNER_RATIO := 0.35  # The Dragon ring's hole, as a fraction of the reach.
## Seconds between two « hits » of the continuous fire for the Nexus shared states (towers
## T2b): applied every frame, a 0.2 s stun would lock every enemy in the cone.
const SHARE_INTERVAL := 1.0

var _tower: Tower
var _def: TowerDef
var _record: TowerRecord
var _ctx: TowerBehaviour.TowerContext
var _active := false  # The cone is firing this frame.
var _direction := Vector2.RIGHT  # Axis of the cone, world space.
var _half_angle := 0.0  # Radians.
var _share_left := 0.0  # Seconds until the fire sets the Nexus shared states again.


## See [method TowerBehaviour.setup].
func setup(tower: Tower, def: TowerDef, record: TowerRecord, ctx: TowerBehaviour.TowerContext) -> void:
	_tower = tower
	_def = def
	_record = record
	_ctx = ctx


## Range with the card and item bonuses and the Souffle level 3 range.
func range_now() -> float:
	return _number("range", 0.0) * _ctx.modifiers.tower_range_factor()


## Aims the cone and burns, hurts and (Souffle) pushes every enemy inside it.
func physics_tick(delta: float) -> void:
	var was_active: bool = _active
	var target: Enemy = _designated_in_range()
	if target == null:
		target = _nearest_enemy()
	_active = target != null
	if not _active:
		if was_active:
			_tower.queue_redraw()  # Clears the cone.
		return
	var degrees: Variant = _def.value("angle_degrees", _record.branch, _record.level, _is_dragon())
	_half_angle = deg_to_rad(0.0 if degrees == null else float(degrees)) * 0.5
	var all_around: bool = _is_all_around()
	if not all_around:  # Dragon: no aiming, the fire burns all around.
		var direction: Vector2 = _tower.global_position.direction_to(target.global_position)
		if direction != Vector2.ZERO:
			_direction = direction
		_tower.set_facing(_direction.angle())
	var amp: Dictionary = _ctx.amp_at.call(_tower.global_position, _record.id)
	var modifiers: PlayerModifiers = _ctx.modifiers
	var dps: float = _number("dps", 0.0) * modifiers.damage_multiplier() \
		* (1.0 + float(amp["damage"])) * (1.0 + float(amp["rate"]))
	if _record.level >= TowerRecord.MAX_LEVEL:
		dps /= modifiers.tier3_fire_rate_factor()  # « Surcharge »: an interval factor, so it divides.
	var burn_dps: float = _number("burn_dps", 0.0)
	var burn_duration: float = _number("burn_duration", 0.0) * (1.0 + float(amp["state"]))  # Catalyseur.
	var stack_max: float = _number("stack_max", 1.0)  # Only Napalm level 3 has it (l3_stack_max).
	var push_speed: float = _number("push_speed", 0.0)  # Only Souffle has it.
	_share_left = maxf(_share_left - delta, 0.0)
	var share: bool = amp.has("shared") and _share_left <= 0.0  # Nexus (towers T2b).
	if share:
		_share_left = SHARE_INTERVAL
	var cos_half: float = cos(_half_angle)
	var range_sq: float = _tower.attack_range * _tower.attack_range
	var origin: Vector2 = _tower.global_position
	var enemies: Node2D = _ctx.enemies
	var inside: Array[Enemy] = []  # A snapshot: a kill cannot disturb the loop below.
	for i: int in enemies.get_child_count():
		var enemy := enemies.get_child(i) as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var offset: Vector2 = enemy.global_position - origin
		var distance_sq: float = offset.length_squared()
		if distance_sq > range_sq:
			continue
		# An enemy on the tower itself is inside; otherwise within the half angle of the axis.
		if not all_around and distance_sq > 0.0 and offset.normalized().dot(_direction) < cos_half:
			continue
		inside.append(enemy)
	for enemy: Enemy in inside:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		enemy.take_dot_damage(dps * delta, &"tower_dot")
		if enemy.is_queued_for_deletion():
			continue
		enemy.apply_burn(burn_duration, burn_dps, -1, stack_max)
		if push_speed > 0.0:
			enemy.push_along(_direction, push_speed)
		if share:
			NexusRules.apply_amp(enemy, amp)
	_tower.queue_redraw()


## The cone while it fires: a flickering outer fan and a brighter core (Dragon: a ring).
func draw(canvas: CanvasItem) -> void:
	if not _active:
		return
	var reach: float = _tower.attack_range * (1.0 - randf() * FLICKER)
	if _is_all_around():
		_draw_ring(canvas, reach * RING_INNER_RATIO, reach, FLAME_OUTER)
		_draw_ring(canvas, reach * RING_INNER_RATIO, reach * FLAME_INNER_RATIO, FLAME_INNER)
		return
	_draw_fan(canvas, reach, _half_angle, FLAME_OUTER)
	_draw_fan(canvas, reach * FLAME_INNER_RATIO, _half_angle * FLAME_INNER_RATIO, FLAME_INNER)


func _draw_fan(canvas: CanvasItem, reach: float, half_angle: float, color: Color) -> void:
	if reach <= 0.0:
		return
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var axis: float = _direction.angle()  # The tower node is never rotated: local axes = world axes.
	for i: int in CONE_POINTS + 1:
		var angle: float = axis - half_angle + 2.0 * half_angle * float(i) / float(CONE_POINTS)
		points.append(Vector2.from_angle(angle) * reach)
	canvas.draw_colored_polygon(points, color)


## A flame ring around the tower from [param inner] to [param outer] pixels.
func _draw_ring(canvas: CanvasItem, inner: float, outer: float, color: Color) -> void:
	if outer <= inner:
		return
	canvas.draw_arc(Vector2.ZERO, (inner + outer) * 0.5, 0.0, TAU, RING_POINTS, color, outer - inner)


## True when the fire covers the full circle (Dragon): no aiming, no angle test, drawn as a ring.
func _is_all_around() -> bool:
	return _half_angle >= PI - ALL_AROUND_EPSILON


## True for a Dragon: an evolved level 3 Napalm flamethrower (towers T2b).
func _is_dragon() -> bool:
	return _record.evolved and _record.level >= TowerRecord.MAX_LEVEL and _record.branch == NAPALM


## The designated enemy when it is within this tower's range, else null.
func _designated_in_range() -> Enemy:
	var designated: Enemy = _ctx.designator.target()
	if designated == null or designated.is_queued_for_deletion():
		return null
	var attack_range: float = _tower.attack_range
	if _tower.global_position.distance_squared_to(designated.global_position) > attack_range * attack_range:
		return null
	return designated


func _nearest_enemy() -> Enemy:
	var nearest: Enemy = null
	var nearest_sq: float = _tower.attack_range * _tower.attack_range
	var enemies: Node2D = _ctx.enemies
	for i: int in enemies.get_child_count():
		var enemy := enemies.get_child(i) as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var distance_sq: float = _tower.global_position.distance_squared_to(enemy.global_position)
		if distance_sq <= nearest_sq:
			nearest_sq = distance_sq
			nearest = enemy
	return nearest


## Value [param key] for this tower's branch and level ([method TowerDef.value]), or
## [param fallback] when neither the branch nor the base has it. Required keys are
## validated by [TowerStats].
func _number(key: String, fallback: float) -> float:
	var value: Variant = _def.value(key, _record.branch, _record.level)
	return fallback if value == null else float(value)
