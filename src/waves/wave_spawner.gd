## Wave spawner (story 002, design/game-brief.md MVP feature 2). Spawns each
## wave's enemies over time on the arena border. A wave is finished when all
## its enemies are spawned and every one has left the tree (killed, or freed
## after touching the crystal); counting leaving enemies, not signals from the
## crystal, means no enemy can hold a wave open.
class_name WaveSpawner
extends Node

## Emitted when a wave starts spawning.
signal wave_started(wave_number: int)
## Emitted when every enemy of the wave is dead or has touched the crystal.
signal wave_finished(wave_number: int)

# Transitions: WAITING -> SPAWNING (timer elapsed) -> CLEARING (all spawned)
# -> WAITING (wave finished, via _schedule_next_wave).
enum State { WAITING, SPAWNING, CLEARING }

var _curve: WaveCurve
var _stats: DefenceStats
var _crystal: Crystal
var _enemies_parent: Node
var _spawn_rect: Rect2
var _state := State.WAITING
var _timer := 0.0
var _wave_number := 0
var _to_spawn := 0
var _alive := 0
var _spawn_interval := 0.0
var _hp_multiplier := 1.0


func _ready() -> void:
	set_physics_process(false)


## Gives the spawner its data and starts the first wave countdown.
## Enemies walk to [param crystal] and are added to [param enemies_parent].
func setup(curve: WaveCurve, stats: DefenceStats, arena_rect: Rect2, crystal: Crystal, enemies_parent: Node) -> void:
	_curve = curve
	_stats = stats
	_crystal = crystal
	_enemies_parent = enemies_parent
	_spawn_rect = arena_rect.grow(-stats.spawn_margin)
	_timer = curve.first_wave_delay
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	match _state:
		State.WAITING:
			_timer -= delta
			if _timer <= 0.0:
				_begin_wave()
		State.SPAWNING:
			_timer -= delta
			while _timer <= 0.0 and _to_spawn > 0:
				_spawn_enemy()
				_timer += _spawn_interval
			if _to_spawn == 0:
				_state = State.CLEARING
				_finish_wave_if_cleared()
		State.CLEARING:
			pass  # Waiting for _on_enemy_left.


func _begin_wave() -> void:
	_wave_number += 1
	var wave: Dictionary = _curve.get_wave(_wave_number)
	_to_spawn = wave["enemy_count"]
	_hp_multiplier = wave["hp_multiplier"]
	_spawn_interval = wave["spawn_interval"]
	_timer = 0.0
	_state = State.SPAWNING
	wave_started.emit(_wave_number)


func _spawn_enemy() -> void:
	_to_spawn -= 1
	_alive += 1
	var enemy := Enemy.new()
	enemy.setup(_stats, _stats.enemy_base_hp * _hp_multiplier, _random_border_point(), _crystal)
	enemy.tree_exited.connect(_on_enemy_left)
	_enemies_parent.add_child(enemy)


func _on_enemy_left() -> void:
	_alive -= 1
	if _state == State.CLEARING:
		_finish_wave_if_cleared()


func _finish_wave_if_cleared() -> void:
	if _alive > 0:
		return
	wave_finished.emit(_wave_number)
	_schedule_next_wave()


## Temporary rule until story 003 adds the build phase: the next wave starts
## after a fixed delay. Story 003 replaces this function.
func _schedule_next_wave() -> void:
	_state = State.WAITING
	_timer = _curve.delay_between_waves


## A random point on the border of the spawn rectangle, uniform along its perimeter.
func _random_border_point() -> Vector2:
	var size: Vector2 = _spawn_rect.size
	var along: float = randf() * 2.0 * (size.x + size.y)
	var origin: Vector2 = _spawn_rect.position
	if along < size.x:
		return origin + Vector2(along, 0.0)
	along -= size.x
	if along < size.y:
		return origin + Vector2(size.x, along)
	along -= size.y
	if along < size.x:
		return origin + Vector2(size.x - along, size.y)
	along -= size.x
	return origin + Vector2(0.0, size.y - along)
