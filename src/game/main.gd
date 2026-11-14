## Arena (stories 001-003): dark background, visible arena bounds, the hero,
## the crystal and the wave spawner. Loads the tuning data once and hands it
## to each part. When the crystal is destroyed the whole tree is paused, which
## stops spawning, enemies, bullets and the hero, and the defeat screen opens
## (story 007): points are added to the saved progression, the player buys
## permanent upgrades, and « Rejouer » reloads this scene, which applies them.
## Start of a game (story 008): specialization choice, then the « Départ en
## trombe » card choice when owned, then the build phase of wave 1.
## Step 1 flow: build (zoomed-out camera, the wave's crystal path shown, towers
## placed) -> Space -> the crystal travels the path while enemies attack ->
## it arrives: leftovers and towers are cleared, card choice, next build.
extends Node2D

const STATS_PATH := "res://assets/data/hero_stats.json"
const DEFENCE_PATH := "res://assets/data/defence_stats.json"
const WAVES_PATH := "res://assets/data/waves.json"
const ECONOMY_PATH := "res://assets/data/economy.json"
const TOWERS_PATH := "res://assets/data/towers.json"
const PROCS_PATH := "res://assets/data/procs.json"
const CARDS_PATH := "res://assets/data/cards.json"
const SKILL_TREE_PATH := "res://assets/data/skill_tree.json"
const SPECS_PATH := "res://assets/data/specializations.json"
const SAVE_PATH := "user://progress.json"
const FLOOR_COLOR := Color(0.09, 0.09, 0.13)
const BORDER_COLOR := Color(0.4, 0.45, 0.6)
const BORDER_WIDTH := 4.0

var _field_rect: Rect2
var _cycle: WaveCycle
var _state: GameState
var _card_pool: CardPool  # Built once the specialization is chosen: its cards depend on it.
var _catalog: CardCatalog
var _specs: SpecializationCatalog
var _spec_screen: SpecializationChoiceScreen
var _rules: ProcRules
var _modifiers: PlayerModifiers
var _rng: RandomNumberGenerator
var _card_screen: CardChoiceScreen
var _skill_tree: SkillTree
var _progress: SaveProgress
var _death_screen: DeathScreen
var _path_view: PathView
var _camera: GameCamera

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
	var rules: ProcRules = ProcRules.load_from_file(PROCS_PATH)
	_specs = null if rules == null else SpecializationCatalog.load_from_file(SPECS_PATH, rules)
	_catalog = null if _specs == null else CardCatalog.load_from_file(CARDS_PATH, rules, _specs)
	_skill_tree = null if _catalog == null else SkillTree.load_from_file(SKILL_TREE_PATH, _catalog, _specs)
	if _skill_tree == null or stats == null or defence == null or curve == null or economy == null or towers == null:
		_hero.queue_free()
		_crystal.queue_free()
		_placer.queue_free()
		return
	_field_rect = Rect2(Vector2.ZERO, stats.arena_size)
	_progress = SaveProgress.load_from_file(SAVE_PATH, _skill_tree)
	var owned: PackedStringArray = _progress.owned_ids
	_rules = rules
	var modifiers := PlayerModifiers.new(rules)
	_modifiers = modifiers
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_hero.setup(stats, _field_rect, _bullets, rules)
	_crystal.global_position = _field_rect.get_center()
	_crystal.setup(defence, _skill_tree.crystal_max_hp_bonus(owned))
	# The hero starts below the crystal, not on top of it.
	_hero.global_position = _crystal.global_position + Vector2(0.0, defence.crystal_radius + stats.hero_radius + defence.hero_start_gap)
	_hud.bind(_crystal)
	_crystal.destroyed.connect(_on_crystal_destroyed)
	modifiers.heal_requested.connect(_crystal.heal)
	_state = GameState.new(economy.starting_gold + _skill_tree.starting_gold_bonus(owned))
	_cycle = WaveCycle.new()
	_spawner.setup(curve, defence, _field_rect, _crystal, _enemies)
	# The gold field sits just before Enemies, so coins are drawn under the enemies.
	var gold_field := GoldField.new()
	add_child(gold_field)
	move_child(gold_field, _enemies.get_index())
	gold_field.setup(_state, _hero, economy)
	_spawner.wave_finished.connect(func(_wave_number: int) -> void: gold_field.clear())
	_cycle.setup(_state, _spawner, economy, modifiers, curve, _crystal, _field_rect, _rng, gold_field)
	# The path view is moved to index 0 so it is drawn under every child (crystal, Towers, ...).
	_path_view = PathView.new()
	add_child(_path_view)
	move_child(_path_view, 0)
	_path_view.setup(_state)
	_camera = GameCamera.new()
	add_child(_camera)
	_camera.setup(_hero, _field_rect, _state)
	_cycle.wave_prepared.connect(_on_wave_prepared)
	_spawner.wave_finished.connect(_on_wave_finished)
	_hud.bind_game_state(_state)
	_hud.bind_modifiers(modifiers)
	_card_screen = CardChoiceScreen.new()
	add_child(_card_screen)
	_card_screen.card_chosen.connect(_on_card_chosen.bind(modifiers))
	_state.phase_changed.connect(_on_phase_changed)
	_placer.setup(towers, _state, _field_rect, _crystal, _towers, _enemies, _bullets, rules, modifiers)
	_hud.bind_tower_build(towers)
	_hud.tower_kind_chosen.connect(_placer.select_kind)
	_placer.not_enough_gold.connect(_hud.show_not_enough_gold)
	_death_screen = DeathScreen.new()
	add_child(_death_screen)
	_death_screen.setup(_skill_tree)
	_death_screen.node_clicked.connect(_on_upgrade_clicked)
	_death_screen.replay_pressed.connect(_on_replay_pressed)
	_spec_screen = SpecializationChoiceScreen.new()
	add_child(_spec_screen)
	_spec_screen.specialization_chosen.connect(_on_spec_chosen)
	_state.begin_spec_choice()
	_spec_screen.show_specs(_specs.unlocked(_skill_tree.unlocked_spec_ids(owned)))
	queue_redraw()


func _draw() -> void:
	draw_rect(_field_rect, FLOOR_COLOR)
	draw_rect(_field_rect, BORDER_COLOR, false, BORDER_WIDTH)


## Space launches the next wave during the build phase. This node stops
## receiving input once the tree is paused (defeat), so Space then does nothing.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"start_wave") and _cycle != null:
		_cycle.request_next_wave()


## Equips the hero, switches on the specialization's combos, builds the card pool
## for it, then goes on with the start sequence: the opening card choice when
## owned, otherwise the build phase of wave 1.
func _on_spec_chosen(spec: SpecializationDef) -> void:
	var owned: PackedStringArray = _progress.owned_ids
	for combo_id: String in spec.combo_ids:
		_rules.activate(combo_id)
	if spec.freeze_duration > 0.0:
		_modifiers.enable_freeze(spec.freeze_duration, spec.freeze_cooldown)
	_hero.equip(spec, _modifiers, _rng)
	_hud.show_specialization(spec)
	_card_pool = CardPool.new(_catalog, _modifiers, _rng, _skill_tree.unlocked_card_ids(owned), _skill_tree.cards_offered_bonus(owned), spec.id)
	if _skill_tree.has_start_card_choice(owned):
		_state.begin_card_choice()
		return
	_state.begin_build()


func _on_phase_changed(phase: GameState.Phase) -> void:
	if phase == GameState.Phase.CARD_CHOICE:
		# Deferred: begin_build() may be called right away (no card left) and must not
		# run inside the emission of this phase change, or other listeners would see the phases out of order.
		_open_card_choice.call_deferred()


## Offers the drawn cards (3, or more with the skill tree), or ends the choice at
## once when none is left. Nothing is shown once the crystal is destroyed.
func _open_card_choice() -> void:
	if _state.phase != GameState.Phase.CARD_CHOICE or _crystal.current_hp <= 0.0:
		return
	var offer: Array[CardDef] = _card_pool.draw()
	if offer.is_empty():
		_end_card_choice()
		return
	_card_screen.show_cards(offer)


func _on_card_chosen(card: CardDef, modifiers: PlayerModifiers) -> void:
	modifiers.take(card)
	_end_card_choice()


## Both after a wave and after the opening choice the game goes to BUILD.
func _end_card_choice() -> void:
	_state.begin_build()


## Shows the prepared wave's path and its preview text.
func _on_wave_prepared(wave_number: int, enemy_count: int, path: CrystalPath) -> void:
	_path_view.show_path(path)
	_hud.show_wave_preview(wave_number, enemy_count)


## The crystal arrived: the towers do not carry over to the next wave.
func _on_wave_finished(_wave_number: int) -> void:
	_placer.clear_towers()


## Stops the game, banks this game's points (saved at once) and opens the defeat
## screen. Points use only the waves and kills counted up to this moment.
func _on_crystal_destroyed() -> void:
	get_tree().paused = true
	var earned: int = _skill_tree.points_for_game(_state.waves_completed, _state.kills)
	_progress.total_points += earned
	_progress.save_to_file(SAVE_PATH)
	_death_screen.open(_state.wave_number, earned, _progress)


func _on_upgrade_clicked(upgrade_id: String) -> void:
	var refusal: String = _skill_tree.buy(upgrade_id, _progress)
	if not refusal.is_empty():
		_death_screen.show_refusal(refusal)
		return
	_progress.save_to_file(SAVE_PATH)
	_death_screen.refresh(_progress)


## A fresh game: reloading the scene rebuilds the crystal (full, with the new
## max), the gold, the wave and the card pool from the data and the saved progression.
func _on_replay_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
