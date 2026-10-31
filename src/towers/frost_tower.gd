## Frost tower (story 004): every physics frame, asks each enemy within range
## to be slowed to [member TowerStats.frost_slow_factor]. It never remembers
## which enemies it slowed: the enemy drops the slow by itself as soon as no
## tower refreshes it (see [method Enemy.apply_slow]). Slow and range are read
## from the card modifiers every frame (story 006), so cards act on placed towers.
class_name FrostTower
extends Tower

const COLOR := Color(0.4, 0.7, 1.0)

var _base_slow_factor: float
var _base_range: float
var _enemies: Node2D
var _modifiers: PlayerModifiers


## Sets the tuning values, the node holding the enemies and the card modifiers. Call before adding the tower to the tree.
func setup(stats: TowerStats, enemies: Node2D, modifiers: PlayerModifiers) -> void:
	_enemies = enemies
	_modifiers = modifiers
	_base_slow_factor = stats.frost_slow_factor
	_base_range = stats.frost_range
	radius = stats.frost_radius
	attack_range = _base_range
	_body_color = COLOR


func _physics_process(_delta: float) -> void:
	var current_range: float = _base_range * _modifiers.frost_range_factor()
	if not is_equal_approx(current_range, attack_range):
		attack_range = current_range
		queue_redraw()  # The range ring follows.
	var slow_factor: float = _modifiers.frost_slow_factor(_base_slow_factor)
	var range_sq: float = attack_range * attack_range
	for i: int in _enemies.get_child_count():
		var enemy := _enemies.get_child(i) as Enemy
		if enemy != null and global_position.distance_squared_to(enemy.global_position) <= range_sq:
			enemy.apply_slow(slow_factor)
