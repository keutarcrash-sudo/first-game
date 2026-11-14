## Cannon tower (story 004): fires at the nearest enemy within range, every
## [member TowerStats.cannon_fire_interval] seconds. Its shots are
## [HeroBullet]s configured from the tower data, so they hit through the same
## contract (physics layer 2, [code]take_damage[/code]).
class_name CannonTower
extends Tower

const COLOR := Color(1.0, 0.65, 0.25)

var _stats: TowerStats
var _enemies: Node2D
var _bullets: Node2D
var _arena_rect: Rect2
var _rules: ProcRules
var _modifiers: PlayerModifiers
var _designator: TargetDesignator
var _cooldown := 0.0


## Sets the tuning values, the node holding the enemies, the node the shots are
## added to, the arena the shots must stay in, the combo rules (source [code]&"cannon"[/code]), and the card modifiers, read at every shot (fire rate, damage, burn), and the designator whose target is shot first when in range. Call before adding the tower to the tree.
func setup(stats: TowerStats, enemies: Node2D, bullets: Node2D, arena_rect: Rect2, rules: ProcRules, modifiers: PlayerModifiers, designator: TargetDesignator) -> void:
	_designator = designator
	_modifiers = modifiers
	_rules = rules
	_stats = stats
	_enemies = enemies
	_bullets = bullets
	_arena_rect = arena_rect
	radius = stats.cannon_radius
	attack_range = stats.cannon_range
	_body_color = COLOR


func _physics_process(delta: float) -> void:
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
	var bullet := HeroBullet.new()
	bullet.configure(
		_stats.cannon_damage * _modifiers.damage_multiplier(), _stats.cannon_bullet_speed, _stats.cannon_bullet_max_range,
		_stats.cannon_bullet_radius, direction, _arena_rect
	)
	bullet.set_proc_source(&"cannon", _rules)
	bullet.set_burn(_modifiers.burn_duration(), _modifiers.burn_damage_per_second())
	_bullets.add_child(bullet)
	bullet.global_position = global_position
