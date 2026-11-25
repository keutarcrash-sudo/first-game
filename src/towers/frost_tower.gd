## Frost tower (story 004): every physics frame, asks each enemy within range
## to be slowed to [member TowerStats.frost_slow_factor]. It never remembers
## which enemies it slowed: the enemy drops the slow by itself as soon as no
## tower refreshes it (see [method Enemy.apply_slow]). Slow and range are read
## from the card modifiers every frame (story 006), so cards act on placed towers.
## Story 009: with the Maître de l'eau (freeze enabled in the modifiers), each wet
## enemy in range is also offered to [method Enemy.try_freeze].
## Towers T1: each enemy in range is also asked for the tower freeze ([method Enemy.apply_chill],
## « Gel profond » lengthens it), tagged with this tower's [TowerRecord] id, read every frame so
## an upgrade acts at once. Blizzard (level 2+): range x [code]range_mult[/code] and a shorter
## dwell; at level 3 an enemy this tower freezes is also wet for [code]l3_wet_duration[/code]
## seconds. Éclats acts at the enemy's death ([TowerEffects]).
class_name FrostTower
extends Tower

const COLOR := Color(0.1, 0.89, 1.0)
const BLIZZARD := &"blizzard"

var _stats: TowerStats
var _base_slow_factor: float
var _base_range: float
var _enemies: Node2D
var _modifiers: PlayerModifiers
var _record: TowerRecord
var _wetted: Dictionary = {}  # Instance ids of the enemies frozen by this tower and already wet for it (Blizzard 3).
var _still_frozen: Dictionary = {}  # Same, built during the current frame, then swapped with _wetted.


## Sets the tuning values, the node holding the enemies, the card modifiers and the
## [TowerRecord] of this tower (shared, never copied: its level and branch are read every
## frame). Call before adding the tower to the tree.
func setup(stats: TowerStats, enemies: Node2D, modifiers: PlayerModifiers, record: TowerRecord) -> void:
	_stats = stats
	_record = record
	_enemies = enemies
	_modifiers = modifiers
	_base_slow_factor = stats.frost_slow_factor
	_base_range = stats.frost_range
	radius = stats.frost_radius
	attack_range = _current_range()
	_halo_color = COLOR


func _physics_process(_delta: float) -> void:
	var current_range: float = _current_range()
	if not is_equal_approx(current_range, attack_range):
		attack_range = current_range
		queue_redraw()  # The range ring follows.
	var blizzard: bool = _is_blizzard()
	var wet_on_freeze: bool = blizzard and _record.level >= TowerRecord.MAX_LEVEL
	var slow_factor: float = _modifiers.frost_slow_factor(_base_slow_factor)
	var water_duration: float = _modifiers.freeze_duration()
	var water_cooldown: float = _modifiers.freeze_cooldown()
	var dwell: float = _blizzard_number("dwell") if blizzard else _stats.freeze_dwell
	var chill_duration: float = _stats.freeze_duration + _modifiers.freeze_duration_bonus()
	var range_sq: float = attack_range * attack_range
	_still_frozen.clear()
	for i: int in _enemies.get_child_count():
		var enemy := _enemies.get_child(i) as Enemy
		if enemy == null or global_position.distance_squared_to(enemy.global_position) > range_sq:
			continue
		enemy.apply_slow(slow_factor)
		enemy.apply_chill(dwell, chill_duration, _stats.freeze_cooldown, _record.id)
		if water_duration > 0.0:
			enemy.try_freeze(water_duration, water_cooldown, _record.id)
		if wet_on_freeze and enemy.has_state(&"frozen") and enemy.last_freezer_id() == _record.id:
			var key: int = enemy.get_instance_id()
			_still_frozen[key] = true
			if not _wetted.has(key):  # Once per freeze, when it is first seen.
				enemy.apply_wet(_blizzard_number("l3_wet_duration"))
	var previous: Dictionary = _wetted
	_wetted = _still_frozen
	_still_frozen = previous


## Range with the card and item bonuses and the Blizzard bonus.
func _current_range() -> float:
	var factor: float = _modifiers.frost_range_factor() * _modifiers.tower_range_factor()
	if _is_blizzard():
		factor *= _blizzard_number("range_mult")
	return _base_range * factor


func _is_blizzard() -> bool:
	return _record.level >= 2 and _record.branch == BLIZZARD


## Number [param key] of the Blizzard branch (required and validated by [constant TowerStats.BRANCH_KEYS]).
func _blizzard_number(key: String) -> float:
	return float(_stats.branch_value(TowerStats.Kind.FROST, BLIZZARD, key))
