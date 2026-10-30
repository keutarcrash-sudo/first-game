## Frost tower (story 004): every physics frame, asks each enemy within range
## to be slowed to [member TowerStats.frost_slow_factor]. It never remembers
## which enemies it slowed: the enemy drops the slow by itself as soon as no
## tower refreshes it (see [method Enemy.apply_slow]).
class_name FrostTower
extends Tower

const COLOR := Color(0.4, 0.7, 1.0)

var _slow_factor: float
var _enemies: Node2D


## Sets the tuning values and the node holding the enemies. Call before adding the tower to the tree.
func setup(stats: TowerStats, enemies: Node2D) -> void:
	_enemies = enemies
	_slow_factor = stats.frost_slow_factor
	radius = stats.frost_radius
	attack_range = stats.frost_range
	_body_color = COLOR


func _physics_process(_delta: float) -> void:
	var range_sq: float = attack_range * attack_range
	for i: int in _enemies.get_child_count():
		var enemy := _enemies.get_child(i) as Enemy
		if enemy != null and global_position.distance_squared_to(enemy.global_position) <= range_sq:
			enemy.apply_slow(_slow_factor)
