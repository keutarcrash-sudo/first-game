## Arena (stories 001-003): dark background, visible arena bounds, the hero,
## the crystal and the wave spawner. Loads the tuning data once and hands it
## to each part. When the crystal is destroyed the whole tree is paused, which
## stops spawning, enemies, bullets and the hero.
extends Node2D

const STATS_PATH := "res://assets/data/hero_stats.json"
const DEFENCE_PATH := "res://assets/data/defence_stats.json"
const WAVES_PATH := "res://assets/data/waves.json"
const ECONOMY_PATH := "res://assets/data/economy.json"
const TOWERS_PATH := "res://assets/data/towers.json"
const FLOOR_COLOR := Color(0.09, 0.09, 0.13)
const BORDER_COLOR := Color(0.4, 0.45, 0.6)
const BORDER_WIDTH := 4.0

var _arena_rect: Rect2
var _cycle: WaveCycle
var _state: GameState

@onready var _towers: Node2D = $Towers
@onready var _placer: TowerPlacer = $TowerPlacer
@onready var _hero: Hero = $Hero
@onready var _bullets: Node2D = $Bullets
@onready var _enemies: Node2D = $Enemies
@onready var _crystal: Crystal = $Crystal
@onready var _spawner: WaveSpawner = $WaveSpawner
@onready var _hud: CrystalHud = $Hud


func _ready() -> void:
	var stats: HeroStats = HeroStats.load_from_file(STATS_PATH)
	var defence: DefenceStats = DefenceStats.load_from_file(DEFENCE_PATH)
	var curve: WaveCurve = WaveCurve.load_from_file(WAVES_PATH)
	var economy: EconomyStats = EconomyStats.load_from_file(ECONOMY_PATH)
	var towers: TowerStats = TowerStats.load_from_file(TOWERS_PATH)
	if stats == null or defence == null or curve == null or economy == null or towers == null:
		_hero.queue_free()
		_crystal.queue_free()
		_placer.queue_free()
		return
	_arena_rect = Rect2((get_viewport_rect().size - stats.arena_size) / 2.0, stats.arena_size)
	_hero.setup(stats, _arena_rect, _bullets)
	_crystal.global_position = _arena_rect.get_center()
	_crystal.setup(defence)
	# The hero starts below the crystal, not on top of it.
	_hero.global_position = _crystal.global_position + Vector2(0.0, defence.crystal_radius + stats.hero_radius + defence.hero_start_gap)
	_hud.bind(_crystal)
	_crystal.destroyed.connect(_on_crystal_destroyed)
	_state = GameState.new(economy.starting_gold)
	_cycle = WaveCycle.new()
	_cycle.setup(_state, _spawner, economy)
	_hud.bind_game_state(_state)
	_placer.setup(towers, _state, _arena_rect, _crystal, _towers, _enemies, _bullets)
	_hud.bind_tower_build(towers)
	_hud.tower_kind_chosen.connect(_placer.select_kind)
	_placer.not_enough_gold.connect(_hud.show_not_enough_gold)
	_spawner.setup(curve, defence, _arena_rect, _crystal, _enemies)
	queue_redraw()


func _draw() -> void:
	draw_rect(_arena_rect, FLOOR_COLOR)
	draw_rect(_arena_rect, BORDER_COLOR, false, BORDER_WIDTH)


## Space launches the next wave during the build phase. This node stops
## receiving input once the tree is paused (defeat), so Space then does nothing.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"start_wave") and _cycle != null:
		_cycle.request_next_wave()


func _on_crystal_destroyed() -> void:
	get_tree().paused = true
