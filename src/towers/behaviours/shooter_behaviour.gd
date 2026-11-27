## Shooter behaviour, the cannon (story 004, moved from the T1 CannonTower): fires at
## the designated enemy when in range, else at the nearest one, every
## [code]fire_interval[/code] seconds. Its shots are [HeroBullet]s configured from the
## tower values, so they hit through the same contract (physics layer 2,
## [code]take_damage[/code]).
## Towers T1: its [TowerRecord] (level, branch) is read at every shot, so an upgrade acts
## at once. Incendiaire (level 2+): its own burn, tagged with the record id. Perforant:
## shells hit [code]pierce_total[/code] enemies (level 2+), [code]l3_shots[/code] shells spread
## over [code]l3_spread_degrees[/code] at level 3. Level 3 fires faster with « Surcharge ».
class_name ShooterBehaviour
extends TowerBehaviour

const INCENDIAIRE := &"incendiaire"
const PERFORANT := &"perforant"

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


## Range with the card and item bonuses.
func range_now() -> float:
	return _def.range * _ctx.modifiers.tower_range_factor()


## Counts the cooldown down and fires when it is over and an enemy is in range.
func physics_tick(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	var target: Enemy = _designated_in_range()
	if target == null:
		target = _find_nearest_enemy()
	if target == null:
		return
	_fire(target)
	_cooldown = _number("fire_interval") * _ctx.modifiers.cannon_interval_factor()
	if _record.level >= TowerRecord.MAX_LEVEL:
		_cooldown *= _ctx.modifiers.tier3_fire_rate_factor()  # « Surcharge ».


## The designated enemy when it is within this tower's range, else null.
func _designated_in_range() -> Enemy:
	var designated: Enemy = _ctx.designator.target()
	if designated == null:
		return null
	var attack_range: float = _tower.attack_range
	if _tower.global_position.distance_squared_to(designated.global_position) > attack_range * attack_range:
		return null
	return designated


func _find_nearest_enemy() -> Enemy:
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


func _fire(target: Enemy) -> void:
	var direction: Vector2 = _tower.global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:  # An enemy walking over the tower.
		direction = Vector2.RIGHT
	_tower.set_facing(direction.angle())
	var branch: StringName = _record.branch if _record.level >= 2 else &""
	var shots: int = 1
	var spread: float = 0.0
	if branch == PERFORANT and _record.level >= TowerRecord.MAX_LEVEL:
		shots = maxi(int(_branch_number(PERFORANT, "l3_shots")), 1)
		spread = deg_to_rad(_branch_number(PERFORANT, "l3_spread_degrees"))
	for i: int in shots:
		# Spread evenly around the aim: 2 shells of 8 degrees = -4 and +4.
		var offset: float = 0.0 if shots == 1 else spread * (float(i) / float(shots - 1) - 0.5)
		_fire_shell(direction.rotated(offset), branch)


## One shell along [param direction], set up for this tower's [param branch] (&"" below level 2).
func _fire_shell(direction: Vector2, branch: StringName) -> void:
	var modifiers: PlayerModifiers = _ctx.modifiers
	var bullet := HeroBullet.new()
	bullet.configure(
		_number("damage") * modifiers.damage_multiplier(), _number("bullet_speed"), _number("bullet_max_range"),
		_number("bullet_radius"), direction, _ctx.arena_rect
	)
	bullet.set_proc_source(&"cannon", _ctx.rules)
	if branch == INCENDIAIRE:
		# The branch's own burn; « Munitions incendiaires » makes it last longer.
		var duration: float = _branch_number(INCENDIAIRE, "burn_duration")
		if modifiers.burn_duration() > 0.0:
			duration *= _branch_number(INCENDIAIRE, "card_duration_mult")
		bullet.set_burn(duration, _branch_number(INCENDIAIRE, "burn_dps"), _record.id)
	else:
		bullet.set_burn(modifiers.burn_duration(), modifiers.burn_damage_per_second(), _record.id)
	if branch == PERFORANT:
		bullet.set_pierce(int(_branch_number(PERFORANT, "pierce_total")))
	_ctx.bullets.add_child(bullet)
	bullet.global_position = _tower.global_position


## Base value [param key] of the tower (required and validated by [constant TowerStats.BEHAVIOUR_KEYS]).
func _number(key: String) -> float:
	return float(_def.values[key])


## Number [param key] of branch [param branch] (required and validated by [constant TowerStats.BRANCH_KEYS]).
func _branch_number(branch: StringName, key: String) -> float:
	return float(_def.branch_value(branch, key))
