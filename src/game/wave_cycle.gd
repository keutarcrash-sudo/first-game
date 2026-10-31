## Combat/build cycle (story 003). Wires the wave spawner's signals to the
## [GameState]: kill gold, end-of-wave bonus, phase changes. Build phase ends
## only when the player asks for the next wave ([method request_next_wave],
## bound to the Space bar in main.gd). Holds no UI.
class_name WaveCycle
extends RefCounted

var _state: GameState
var _spawner: WaveSpawner
var _economy: EconomyStats
var _modifiers: PlayerModifiers


## Connects to [param spawner]'s signals. [param modifiers] adds its gold-per-kill
## bonus (story 006). A finished wave leads to CARD_CHOICE; whoever shows the
## cards then calls [method GameState.begin_build]. Call once.
func setup(state: GameState, spawner: WaveSpawner, economy: EconomyStats, modifiers: PlayerModifiers) -> void:
	_modifiers = modifiers
	_state = state
	_spawner = spawner
	_economy = economy
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_finished.connect(_on_wave_finished)
	spawner.enemy_killed.connect(_on_enemy_killed)


## Starts the next wave if the game is in BUILD; does nothing otherwise.
func request_next_wave() -> void:
	if _state.phase == GameState.Phase.BUILD:
		_spawner.start_next_wave()


func _on_wave_started(wave_number: int) -> void:
	_state.begin_combat(wave_number)


func _on_wave_finished(_wave_number: int) -> void:
	_state.add_gold(_economy.gold_per_wave_bonus)
	_state.begin_card_choice()


func _on_enemy_killed() -> void:
	_state.add_gold(_economy.gold_per_kill + _modifiers.gold_per_kill_bonus())
