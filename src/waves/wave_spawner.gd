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
var _types: EnemyTypes
var _sheets: Dictionary = {}  # Type id -> SpriteSheet.
var _hero: Hero
var _impact: ImpactFeedback
var _hazards_parent: Node
var _game_state: GameState
var _field_rect: Rect2
var _rng: RandomNumberGenerator
var _queue: Array[Dictionary] = []  # Types still to spawn this wave, in spawn order.
var _state := State.IDLE
var _timer := 0.0
var _wave_number := 0
var _spawn_interval := 0.0
var _hp_multiplier := 1.0
var _modifiers: PlayerModifiers
var _damage_numbers: DamageNumbers
var _frozen_vulnerability := 0.0


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
	_field_rect = field_rect
	crystal.arrived.connect(_on_crystal_arrived)


## Gives the spawner the enemy types of the waves ([param sheets]: type id -> SpriteSheet, each
## loaded once by the caller, also used for the death animation), what the types need
## ([param hero], [param impact], [param rng] for the artillery's aim) and the node that
## holds the announced attacks ([param hazards_parent], which vanish when [param game_state] leaves COMBAT). Call once, after [method setup].
func set_enemy_types(types: EnemyTypes, sheets: Dictionary, hero: Hero, impact: ImpactFeedback, hazards_parent: Node, game_state: GameState, rng: RandomNumberGenerator) -> void:
	_types = types
	_sheets = sheets
	_hero = hero
	_impact = impact
	_hazards_parent = hazards_parent
	_game_state = game_state
	_rng = rng


## Gives every enemy spawned from now on the card modifiers (Combustion, Marée montante). Optional.
func set_modifiers(modifiers: PlayerModifiers) -> void:
	_modifiers = modifiers


## Gives every enemy spawned from now on the extra damage fraction it takes while frozen
## ([member TowerStats.frozen_vulnerability]). Optional: 0 without this call.
func set_frozen_vulnerability(value: float) -> void:
	_frozen_vulnerability = value


func _physics_process(delta: float) -> void:
	if _state != State.SPAWNING:
		return
	_timer -= delta
	while _timer <= 0.0 and not _queue.is_empty():
		_spawn_enemy()
		_timer += _spawn_interval
	if _queue.is_empty():
		_state = State.TRAVELLING
		set_physics_process(false)


## Starts wave [param wave_number] with the crystal following [param path].
## Ignored while a wave is in progress.
func start_wave(wave_number: int, path: CrystalPath) -> void:
	if _state != State.IDLE:
		return
	var wave: Dictionary = _curve.get_wave(wave_number)
	_wave_number = wave_number
	_queue = _compose_wave(wave_number)
	_hp_multiplier = wave["hp_multiplier"]
	_spawn_interval = path.length() / _crystal.speed * _curve.spawn_window / _queue.size()
	_timer = 0.0  # The first enemy appears on the next physics frame.
	_state = State.SPAWNING
	set_physics_process(true)
	_crystal.travel(path)
	wave_started.emit(wave_number)


## How many enemies of each type wave [param wave_number] holds (type id -> count, see
## [method EnemyTypes.composition]): goblins = the wave's enemy_count, the others by
## [method EnemyTypes.count_for], every count x [member WaveCurve.final_count_mult] when the
## wave is a world's final wave (étape 5a). Empty before [method set_enemy_types].
func composition_for(wave_number: int) -> Dictionary:
	if _types == null or _curve == null:
		return {}
	var mult: float = _curve.final_count_mult if _curve.is_final_wave(wave_number) else 1.0
	return _types.composition(wave_number, _curve.get_wave(wave_number)["enemy_count"], mult)


## The types of every enemy of the wave ([method composition_for]), shuffled with the
## passed RNG so they share one spawn window.
func _compose_wave(wave_number: int) -> Array[Dictionary]:
	var queue: Array[Dictionary] = []
	var counts: Dictionary = composition_for(wave_number)
	for type_id: String in counts:
		var type: Dictionary = _types.get_type(type_id)
		for i: int in counts[type_id]:
			queue.append(type)
	for i: int in range(queue.size() - 1, 0, -1):  # Fisher-Yates.
		var j: int = _rng.randi_range(0, i)
		var swap: Dictionary = queue[i]
		queue[i] = queue[j]
		queue[j] = swap
	return queue


## Gives every enemy spawned from now on the node that shows its damage numbers. Optional.
func set_damage_numbers(numbers: DamageNumbers) -> void:
	_damage_numbers = numbers


func _spawn_enemy() -> void:
	var type: Dictionary = _queue.pop_back()
	var enemy := Enemy.new()
	enemy.setup(_stats, _stats.enemy_base_hp * _hp_multiplier, _random_spawn_point(), _crystal)
	enemy.setup_type(type, _hero, _impact, _hazards_parent, _game_state, _field_rect, _rng)
	enemy.set_modifiers(_modifiers)
	enemy.set_frozen_vulnerability(_frozen_vulnerability)
	enemy.set_damage_numbers(_damage_numbers)
	var sheet: SpriteSheet = _sheets.get(type["id"])
	var height: float = type["height_px"]
	if sheet != null:
		enemy.set_visual(sheet, height)
	enemy.died.connect(func() -> void:
		_play_death(enemy, sheet, height)
		enemy_killed.emit(enemy.global_position))
	_enemies_parent.add_child(enemy)


## Plays the death animation where [param enemy] fell, with the sheet of its own type. The effect is a sibling of
## the enemies node, never its child, so nothing mistakes it for an enemy.
func _play_death(enemy: Enemy, sheet: SpriteSheet, height: float) -> void:
	var host: Node = _enemies_parent.get_parent()
	if sheet == null or host == null:
		return
	if not sheet.has_animation(&"death"):
		push_error("WaveSpawner: the enemy sheet has no 'death' animation.")
		return
	var effect := DeathEffect.new()
	effect.setup(sheet, height, enemy.facing_angle())
	host.add_child(effect)
	host.move_child(effect, _enemies_parent.get_index() + 1)
	effect.global_position = enemy.global_position


func _on_crystal_arrived() -> void:
	if _state == State.IDLE:
		return
	_state = State.IDLE
	set_physics_process(false)
	_queue.clear()
	for child: Node in _enemies_parent.get_children():
		if child is Enemy:
			child.queue_free()  # No died signal: no gold for these.
	if _hazards_parent != null:
		for zone: Node in _hazards_parent.get_children():
			if zone is TelegraphZone:
				(zone as TelegraphZone).cancel()  # Announced attacks vanish without striking.
	wave_finished.emit(_wave_number)


## A random point at spawn_distance from the crystal, clamped inside the spawn rectangle.
func _random_spawn_point() -> Vector2:
	var point: Vector2 = _crystal.global_position + Vector2.from_angle(randf() * TAU) * _stats.spawn_distance
	return point.clamp(_spawn_rect.position, _spawn_rect.end)
