## Combat/build cycle (story 003, étape 1). Wires the wave spawner's signals to
## the [GameState]: kill gold, end-of-wave bonus, phase changes, and the wave and
## kill counts used for the end-of-game points (story 007). At every BUILD phase
## it prepares the next wave's crystal path; the build phase ends only when the
## player asks for the next wave ([method request_next_wave]). Holds no UI.
class_name WaveCycle
extends RefCounted

## Emitted when the next wave's path is ready (at the start of each BUILD phase).
signal wave_prepared(wave_number: int, enemy_count: int, path: CrystalPath)

var _state: GameState
var _spawner: WaveSpawner
var _economy: EconomyStats
var _modifiers: PlayerModifiers
var _curve: WaveCurve
var _crystal: Crystal
var _field_rect: Rect2
var _rng: RandomNumberGenerator
var _prepared_path: CrystalPath
var _prepared_wave := 0


## Connects to [param spawner]'s signals and to the phase changes of [param state].
## [param modifiers] adds its gold-per-kill bonus (story 006). A finished wave
## leads to CARD_CHOICE; whoever shows the cards then calls
## [method GameState.begin_build]. If the game is already in BUILD, the first
## wave is prepared now. Call once.
func setup(state: GameState, spawner: WaveSpawner, economy: EconomyStats, modifiers: PlayerModifiers, curve: WaveCurve, crystal: Crystal, field_rect: Rect2, rng: RandomNumberGenerator) -> void:
	_modifiers = modifiers
	_state = state
	_spawner = spawner
	_economy = economy
	_curve = curve
	_crystal = crystal
	_field_rect = field_rect
	_rng = rng
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_finished.connect(_on_wave_finished)
	spawner.enemy_killed.connect(_on_enemy_killed)
	state.phase_changed.connect(_on_phase_changed)
	if state.phase == GameState.Phase.BUILD:
		_prepare_wave()


## Starts the prepared wave if the game is in BUILD; does nothing otherwise.
func request_next_wave() -> void:
	if _state.phase == GameState.Phase.BUILD and _prepared_path != null:
		_spawner.start_wave(_prepared_wave, _prepared_path)


## The path prepared for the next wave, or [code]null[/code] before the first preparation.
func prepared_path() -> CrystalPath:
	return _prepared_path


func _on_phase_changed(phase: GameState.Phase) -> void:
	if phase == GameState.Phase.BUILD:
		_prepare_wave()


func _prepare_wave() -> void:
	_prepared_wave = _state.waves_completed + 1
	var wave: Dictionary = _curve.get_wave(_prepared_wave)
	_prepared_path = CrystalPath.generate(_crystal.global_position, wave["path_length"], _field_rect, _curve.path_settings, _rng)
	wave_prepared.emit(_prepared_wave, wave["enemy_count"], _prepared_path)


func _on_wave_started(wave_number: int) -> void:
	_state.begin_combat(wave_number)


func _on_wave_finished(_wave_number: int) -> void:
	_state.waves_completed += 1
	_state.add_gold(_economy.gold_per_wave_bonus)
	_state.begin_card_choice()


func _on_enemy_killed() -> void:
	_state.kills += 1
	_state.add_gold(_economy.gold_per_kill + _modifiers.gold_per_kill_bonus())
