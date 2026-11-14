## Wave spawner (story 002, étape 1 — le cristal qui avance). A wave lasts as
## long as the crystal travels along its path: enemies appear around the crystal
## during the first part of the trip, and when the crystal arrives the wave ends
## and every enemy still alive is freed without gold.
class_name WaveSpawner
extends Node

## Emitted when a wave starts (the crystal sets off).
signal wave_started(wave_number: int)
## Emitted once per wave, when the crystal arrives at the end of its path.
signal wave_finished(wave_number: int)
## Emitted when an enemy is killed (not when one touches the crystal or is freed at the end of the wave).
signal enemy_killed(position: Vector2)

# Transitions: IDLE -> SPAWNING (start_wave) -> TRAVELLING (all spawned) -> IDLE (crystal arrived).
# The crystal arriving ends the wave from SPAWNING or TRAVELLING.
enum State { IDLE, SPAWNING, TRAVELLING }

var _curve: WaveCurve
var _stats: DefenceStats
var _crystal: Crystal
var _enemies_parent: Node
var _spawn_rect: Rect2
var _state := State.IDLE
var _timer := 0.0
var _wave_number := 0
var _to_spawn := 0
var _spawn_interval := 0.0
var _hp_multiplier := 1.0


func _ready() -> void:
	set_physics_process(false)


## Gives the spawner its data. Starts nothing: see [method start_wave].
## Enemies walk to [param crystal] and are added to [param enemies_parent].
## Call once.
func setup(curve: WaveCurve, stats: DefenceStats, field_rect: Rect2, crystal: Crystal, enemies_parent: Node) -> void:
	_curve = curve
	_stats = stats
	_crystal = crystal
	_enemies_parent = enemies_parent
	_spawn_rect = field_rect.grow(-stats.spawn_margin)
	crystal.arrived.connect(_on_crystal_arrived)


func _physics_process(delta: float) -> void:
	if _state != State.SPAWNING:
		return
	_timer -= delta
	while _timer <= 0.0 and _to_spawn > 0:
		_spawn_enemy()
		_timer += _spawn_interval
	if _to_spawn == 0:
		_state = State.TRAVELLING
		set_physics_process(false)


## Starts wave [param wave_number] with the crystal following [param path].
## Ignored while a wave is in progress.
func start_wave(wave_number: int, path: CrystalPath) -> void:
	if _state != State.IDLE:
		return
	var wave: Dictionary = _curve.get_wave(wave_number)
	_wave_number = wave_number
	_to_spawn = wave["enemy_count"]
	_hp_multiplier = wave["hp_multiplier"]
	_spawn_interval = path.length() / _crystal.speed * _curve.spawn_window / _to_spawn
	_timer = 0.0  # The first enemy appears on the next physics frame.
	_state = State.SPAWNING
	set_physics_process(true)
	_crystal.travel(path)
	wave_started.emit(wave_number)


func _spawn_enemy() -> void:
	_to_spawn -= 1
	var enemy := Enemy.new()
	enemy.setup(_stats, _stats.enemy_base_hp * _hp_multiplier, _random_spawn_point(), _crystal)
	enemy.died.connect(func() -> void: enemy_killed.emit(enemy.global_position))
	_enemies_parent.add_child(enemy)


func _on_crystal_arrived() -> void:
	if _state == State.IDLE:
		return
	_state = State.IDLE
	set_physics_process(false)
	_to_spawn = 0
	for child: Node in _enemies_parent.get_children():
		if child is Enemy:
			child.queue_free()  # No died signal: no gold for these.
	wave_finished.emit(_wave_number)


## A random point at spawn_distance from the crystal, clamped inside the spawn rectangle.
func _random_spawn_point() -> Vector2:
	var point: Vector2 = _crystal.global_position + Vector2.from_angle(randf() * TAU) * _stats.spawn_distance
	return point.clamp(_spawn_rect.position, _spawn_rect.end)
