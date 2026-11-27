## Mortar behaviour (towers T2a, spec §5.3): every [code]interval[/code] seconds, fires a
## [MortarShell] at the spot where the target stands at the moment of the shot. The target
## is the designated enemy when it is between [code]min_range[/code] and the range, else the
## nearest enemy in that ring. The shell flies [code]flight[/code] s under a cyan
## [TelegraphZone] of [code]blast_radius[/code], then deals [code]damage[/code] (x
## [code]slowed_mult[/code] on a slowed or frozen enemy). Grappe (level 2+): [code]bomblets[/code]
## small blasts around the impact. Sismique (level 2+): a [Crater] slowing the enemies.
## Every value is read at the shot ([method TowerDef.value]), so an upgrade acts at once.
## Amplifier bonuses at the shot: damage x (1 + damage), interval / (1 + rate), crater
## lifetime x (1 + state). « Balles lourdes » multiplies the damage, « Surcharge » shortens
## the interval at level 3.
class_name MortarBehaviour
extends TowerBehaviour

var _tower: Tower
var _def: TowerDef
var _record: TowerRecord
var _ctx: TowerBehaviour.TowerContext
var _cooldown := 0.0


## See [method TowerBehaviour.setup].
func setup(tower: Tower, def: TowerDef, record: TowerRecord, ctx: TowerBehaviour.TowerContext) -> void:
	_tower = tower
	_def = def
	_record = record
	_ctx = ctx


## Range with the card and item bonuses (the minimum range is not scaled).
func range_now() -> float:
	return _number("range", 0.0) * _ctx.modifiers.tower_range_factor()


## Counts the cooldown down and fires when it is over and an enemy stands in the ring.
func physics_tick(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	var target: Enemy = _designated_in_ring()
	if target == null:
		target = _nearest_in_ring()
	if target == null:
		return
	var amp: Dictionary = _ctx.amp_at.call(_tower.global_position, _record.id)
	_fire(target.global_position, amp)
	_cooldown = _number("interval", 1.0) / (1.0 + float(amp["rate"]))
	if _record.level >= TowerRecord.MAX_LEVEL:
		_cooldown *= _ctx.modifiers.tier3_fire_rate_factor()  # « Surcharge ».


## Launches a shell at [param at], every value of the impact taken now.
func _fire(at: Vector2, amp: Dictionary) -> void:
	var direction: Vector2 = _tower.global_position.direction_to(at)
	if direction != Vector2.ZERO:
		_tower.set_facing(direction.angle())
	var damage_factor: float = _ctx.modifiers.damage_multiplier() * (1.0 + float(amp["damage"]))
	var shell := MortarShell.new()
	shell.state = _ctx.state
	shell.enemies = _ctx.enemies
	shell.ground = _ctx.ground if _ctx.ground != null else _ctx.bullets
	shell.chain_limiter = _ctx.chain_limiter
	shell.from = _tower.global_position
	shell.to = at
	shell.flight = _number("flight", 1.0)
	shell.damage = _number("damage", 0.0) * damage_factor
	shell.blast_radius = _number("blast_radius", 0.0)
	shell.slowed_mult = _number("slowed_mult", 1.0)
	shell.bomblets = int(_number("bomblets", 0.0))  # Grappe only.
	shell.bomblet_damage = _number("bomblet_damage", 0.0) * damage_factor
	shell.bomblet_radius = _number("bomblet_radius", 0.0)
	shell.crater_duration = _number("crater_duration", 0.0) * (1.0 + float(amp["state"]))  # Sismique only; Catalyseur.
	shell.crater_slow = _number("crater_slow", 1.0)
	shell.crater_radius = _number("crater_radius", 0.0)
	_ctx.bullets.add_child(shell)


## The designated enemy when it stands in this tower's firing ring, else null.
func _designated_in_ring() -> Enemy:
	var designated: Enemy = _ctx.designator.target()
	if designated == null or designated.is_queued_for_deletion():
		return null
	return designated if _in_ring(designated.global_position) else null


## The living enemy in the firing ring nearest to the tower, or null.
func _nearest_in_ring() -> Enemy:
	var nearest: Enemy = null
	var nearest_sq: float = INF
	var enemies: Node2D = _ctx.enemies
	for i: int in enemies.get_child_count():
		var enemy := enemies.get_child(i) as Enemy
		if enemy == null or enemy.is_queued_for_deletion() or not _in_ring(enemy.global_position):
			continue
		var distance_sq: float = _tower.global_position.distance_squared_to(enemy.global_position)
		if distance_sq < nearest_sq:
			nearest_sq = distance_sq
			nearest = enemy
	return nearest


## True when [param at] is between the minimum range and the range of the tower.
func _in_ring(at: Vector2) -> bool:
	var distance_sq: float = _tower.global_position.distance_squared_to(at)
	var min_range: float = _number("min_range", 0.0)
	return distance_sq >= min_range * min_range and distance_sq <= _tower.attack_range * _tower.attack_range


## Value [param key] for this tower's branch and level ([method TowerDef.value]), or
## [param fallback] when neither the branch nor the base has it (such as [code]bomblets[/code]
## off the Grappe branch). Required keys are validated by [TowerStats].
func _number(key: String, fallback: float) -> float:
	var value: Variant = _def.value(key, _record.branch, _record.level)
	return fallback if value == null else float(value)
