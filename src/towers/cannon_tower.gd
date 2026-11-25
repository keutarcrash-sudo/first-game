## Cannon tower (story 004): fires at the nearest enemy within range, every
## [member TowerStats.cannon_fire_interval] seconds. Its shots are
## [HeroBullet]s configured from the tower data, so they hit through the same
## contract (physics layer 2, [code]take_damage[/code]).
## Towers T1: its [TowerRecord] (level, branch) is read at every shot, so an upgrade acts
## at once. Incendiaire (level 2+): its own burn, tagged with the record id. Perforant:
## shells hit [code]pierce_total[/code] enemies (level 2+), [code]l3_shots[/code] shells spread
## over [code]l3_spread_degrees[/code] at level 3. Level 3 fires faster with « Surcharge ».
class_name CannonTower
extends Tower

const COLOR := Color(1.0, 0.65, 0.25)
const INCENDIAIRE := &"incendiaire"
const PERFORANT := &"perforant"

var _stats: TowerStats
var _enemies: Node2D
var _bullets: Node2D
var _arena_rect: Rect2
var _rules: ProcRules
var _modifiers: PlayerModifiers
var _designator: TargetDesignator
var _record: TowerRecord
var _cooldown := 0.0


## Sets the tuning values, the node holding the enemies, the node the shots are
## added to, the arena the shots must stay in, the combo rules (source [code]&"cannon"[/code]), and the card modifiers, read at every shot (fire rate, damage, burn), the designator whose target is shot first when in range, and the [TowerRecord] of this tower (shared, never copied: its level and branch are read at every shot). Call before adding the tower to the tree.
func setup(stats: TowerStats, enemies: Node2D, bullets: Node2D, arena_rect: Rect2, rules: ProcRules, modifiers: PlayerModifiers, designator: TargetDesignator, record: TowerRecord) -> void:
	_record = record
	_designator = designator
	_modifiers = modifiers
	_rules = rules
	_stats = stats
	_enemies = enemies
	_bullets = bullets
	_arena_rect = arena_rect
	radius = stats.cannon_radius
	attack_range = stats.cannon_range * modifiers.tower_range_factor()
	_halo_color = COLOR


func _physics_process(delta: float) -> void:
	var current_range: float = _stats.cannon_range * _modifiers.tower_range_factor()
	if not is_equal_approx(current_range, attack_range):
		attack_range = current_range
		queue_redraw()  # The range ring follows (items, étape 5a).
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0:
		return
	var target: Enemy = _designated_in_range()
	if target == null:
		target = _find_nearest_enemy()
	if target == null:
		return
	_fire(target)
	_cooldown = _stats.cannon_fire_interval * _modifiers.cannon_interval_factor()
	if _record.level >= TowerRecord.MAX_LEVEL:
		_cooldown *= _modifiers.tier3_fire_rate_factor()  # « Surcharge ».


## The designated enemy when it is within this cannon's range, else null.
func _designated_in_range() -> Enemy:
	var designated: Enemy = _designator.target()
	if designated == null:
		return null
	if global_position.distance_squared_to(designated.global_position) > attack_range * attack_range:
		return null
	return designated


func _find_nearest_enemy() -> Enemy:
	var nearest: Enemy = null
	var nearest_sq: float = attack_range * attack_range
	for i: int in _enemies.get_child_count():
		var enemy := _enemies.get_child(i) as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var distance_sq: float = global_position.distance_squared_to(enemy.global_position)
		if distance_sq <= nearest_sq:
			nearest_sq = distance_sq
			nearest = enemy
	return nearest


func _fire(target: Enemy) -> void:
	var direction: Vector2 = global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:  # An enemy walking over the tower.
		direction = Vector2.RIGHT
	set_facing(direction.angle())
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
	var bullet := HeroBullet.new()
	bullet.configure(
		_stats.cannon_damage * _modifiers.damage_multiplier(), _stats.cannon_bullet_speed, _stats.cannon_bullet_max_range,
		_stats.cannon_bullet_radius, direction, _arena_rect
	)
	bullet.set_proc_source(&"cannon", _rules)
	if branch == INCENDIAIRE:
		# The branch's own burn; « Munitions incendiaires » makes it last longer.
		var duration: float = _branch_number(INCENDIAIRE, "burn_duration")
		if _modifiers.burn_duration() > 0.0:
			duration *= _branch_number(INCENDIAIRE, "card_duration_mult")
		bullet.set_burn(duration, _branch_number(INCENDIAIRE, "burn_dps"), _record.id)
	else:
		bullet.set_burn(_modifiers.burn_duration(), _modifiers.burn_damage_per_second(), _record.id)
	if branch == PERFORANT:
		bullet.set_pierce(int(_branch_number(PERFORANT, "pierce_total")))
	_bullets.add_child(bullet)
	bullet.global_position = global_position


## Number [param key] of branch [param branch] of the cannon (required and validated by [constant TowerStats.BRANCH_KEYS]).
func _branch_number(branch: StringName, key: String) -> float:
	return float(_stats.branch_value(TowerStats.Kind.CANNON, branch, key))
