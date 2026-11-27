## Arena (stories 001-003): neon floor with visible arena bounds ([NeonFloor]), the hero,
## the crystal and the wave spawner. Loads the tuning data once and hands it
## to each part. When the crystal is destroyed the whole tree is paused, which
## stops spawning, enemies, bullets and the hero, and the defeat screen opens
## (story 007): points are added to the saved progression, the player buys
## permanent upgrades, and « Rejouer » reloads this scene, which applies them.
## Start of a game (story 008): specialization choice, then the « Départ en
## trombe » card choice when owned, then the world map, then the build phase of wave 1. Étape 5a: the game's
## [WorldRun] (world 1 map generated at start), « Monde X — Vague Y/8 », per-type wave
## preview and the « VAGUE FINALE ! » banner; after each card choice the world map
## ([WorldMapScreen]): consultation before wave 1 and after a world's final wave (new
## world, « MONDE N »), otherwise the choice of the next place (shop, treasure, rest),
## then the build phase.
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
const RARITIES_PATH := "res://assets/data/card_rarities.json"
const SKILL_TREE_PATH := "res://assets/data/skill_tree.json"
const SPECS_PATH := "res://assets/data/specializations.json"
const ABILITIES_PATH := "res://assets/data/abilities.json"
const VISUALS_PATH := "res://assets/data/visuals.json"
const DECOR_PATH := "res://assets/data/decor.json"
const ENEMY_TYPES_PATH := "res://assets/data/enemy_types.json"
const IMPACT_PATH := "res://assets/data/impact.json"
const WORLD_MAP_PATH := "res://assets/data/world_map.json"
const ITEMS_PATH := "res://assets/data/items.json"
const ABILITY_BAR_PATH := "res://assets/data/ability_bar.json"
const DAMAGE_NUMBERS_PATH := "res://assets/data/damage_numbers.json"
const CURSOR_PATH := "res://assets/data/cursor.json"
## Banner shown when a world's final wave is announced (étape 5a, spec §5).
const FINAL_WAVE_BANNER := "VAGUE FINALE !"
## Banner shown when a new world starts, with its number (étape 5a, spec §5).
const WORLD_BANNER := "MONDE %d"
## Banner shown when an empty treasure gives gold instead, with the amount (spec §7.4).
const TREASURE_GOLD_BANNER := "+%d OR"
const SAVE_PATH := "user://progress.json"
## Seconds the hero's death animation plays before the defeat screen opens.
const HERO_DEATH_SECONDS := 0.8
## Id prefix of the "Nouvelle compétence" cards, followed by the slot (a, e, r).
const UNLOCK_CARD_PREFIX := "unlock_ability_"

var _field_rect: Rect2
var _applied_max_hp_bonus := 0.0  # Card max-HP bonus already given to the hero.
var _lost := false  # The defeat already happened: _lose() must not run twice.
var _cycle: WaveCycle
var _state: GameState
var _card_pool: CardPool  # Built once the specialization is chosen: its cards depend on it.
var _catalog: CardCatalog
var _rarities: CardRarities
var _specs: SpecializationCatalog
var _spec_screen: SpecializationChoiceScreen
var _rules: ProcRules
var _modifiers: PlayerModifiers
var _reserve: TowerReserve
var _rng: RandomNumberGenerator
var _card_screen: CardChoiceScreen
var _skill_tree: SkillTree
var _progress: SaveProgress
var _death_screen: DeathScreen
var _path_view: PathView
var _decor: DecorField
var _camera: GameCamera
var _ability_catalog: AbilityCatalog
var _caster: AbilityCaster
var _impact: ImpactFeedback
var _visuals: VisualStats
var _sheets: Dictionary = {}  # Folder -> SpriteSheet, each loaded once and shared.
var _map_generator: WorldMapGenerator
var _world_run: WorldRun  # The game's world and map (étape 5a).
var _enemy_types: EnemyTypes
var _item_catalog: ItemCatalog
var _item_pool: ItemPool  # Built once the specialization is chosen: its items depend on it.
var _map_screen: WorldMapScreen
var _shop_screen: ShopScreen
var _treasure_screen: TreasureScreen
var _rest_screen: RestScreen

@onready var _towers: Node2D = $Towers
@onready var _placer: TowerPlacer = $TowerPlacer
@onready var _hero: Hero = $Hero
@onready var _bullets: Node2D = $Bullets
@onready var _enemies: Node2D = $Enemies
@onready var _crystal: Crystal = $Crystal
@onready var _spawner: WaveSpawner = $WaveSpawner
@onready var _hud: CrystalHud = $Hud


func _ready() -> void:
	add_child(FullscreenToggle.new())  # F11, and full screen on the first gesture on the web.
	var stats: HeroStats = HeroStats.load_from_file(STATS_PATH)
	var defence: DefenceStats = DefenceStats.load_from_file(DEFENCE_PATH)
	var curve: WaveCurve = WaveCurve.load_from_file(WAVES_PATH)
	var economy: EconomyStats = EconomyStats.load_from_file(ECONOMY_PATH)
	var towers: TowerStats = TowerStats.load_from_file(TOWERS_PATH)
	var rules: ProcRules = ProcRules.load_from_file(PROCS_PATH)
	_specs = null if rules == null else SpecializationCatalog.load_from_file(SPECS_PATH, rules)
	_ability_catalog = null if _specs == null else AbilityCatalog.load_from_file(ABILITIES_PATH, _specs)
	_rarities = CardRarities.load_from_file(RARITIES_PATH)
	_catalog = null if _ability_catalog == null or _rarities == null else CardCatalog.load_from_file(CARDS_PATH, rules, _specs, _rarities, _ability_catalog)
	_skill_tree = null if _catalog == null else SkillTree.load_from_file(SKILL_TREE_PATH, _catalog, _specs)
	_visuals = VisualStats.load_from_file(VISUALS_PATH)
	var impact_stats: ImpactStats = ImpactStats.load_from_file(IMPACT_PATH)
	var bar_style: AbilityBarStyle = AbilityBarStyle.load_from_file(ABILITY_BAR_PATH)
	_map_generator = WorldMapGenerator.load_from_file(WORLD_MAP_PATH)
	_item_catalog = null if _catalog == null else ItemCatalog.load_from_file(ITEMS_PATH, _rarities, _specs, rules, _ability_catalog)
	var default_sheet: SpriteSheet = null if _visuals == null else _sheet_for(_visuals.hero_sheet("default"))
	var enemy_types: EnemyTypes = EnemyTypes.load_from_file(ENEMY_TYPES_PATH)
	var enemy_sheets: Dictionary = {}  # Type id -> SpriteSheet.
	if enemy_types != null:
		for type: Dictionary in enemy_types.all():
			var type_sheet: SpriteSheet = _sheet_for(type["sheet"])
			if type_sheet == null:
				enemy_types = null
				break
			enemy_sheets[type["id"]] = type_sheet
	var crystal_sheet: SpriteSheet = null if _visuals == null else _sheet_for(_visuals.crystal_sheet)
	if _item_catalog == null or default_sheet == null or enemy_types == null or crystal_sheet == null or impact_stats == null or bar_style == null or _map_generator == null or _skill_tree == null or _ability_catalog == null or stats == null or defence == null or curve == null or economy == null or towers == null:
		_hero.queue_free()
		_crystal.queue_free()
		_placer.queue_free()
		return
	_field_rect = Rect2(Vector2.ZERO, stats.arena_size)
	_enemy_types = enemy_types
	_progress = SaveProgress.load_from_file(SAVE_PATH, _skill_tree)
	var owned: PackedStringArray = _progress.owned_ids
	_rules = rules
	var modifiers := PlayerModifiers.new(rules)
	modifiers.set_starting_towers(towers.starting_unlocked)
	_modifiers = modifiers
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_world_run = WorldRun.new(curve.waves_per_world)
	_world_run.start_world(_map_generator.generate(_rng))
	_hero.setup(stats, _field_rect, _bullets, rules)
	_hero.set_visual(default_sheet, _visuals.height("hero"))
	_crystal.global_position = _field_rect.get_center()
	_crystal.setup(defence, _skill_tree.crystal_max_hp_bonus(owned))
	_crystal.set_visual(crystal_sheet, _visuals.height("crystal"))
	# The hero starts below the crystal, not on top of it.
	_hero.global_position = _crystal.global_position + Vector2(0.0, defence.crystal_radius + stats.hero_radius + defence.hero_start_gap)
	_hud.bind(_crystal)
	_hud.bind_hero(_hero.health())
	_hero.died.connect(_on_hero_died)
	_crystal.destroyed.connect(_lose)
	modifiers.heal_requested.connect(_crystal.heal)
	modifiers.hero_heal_requested.connect(_hero.health().heal)
	modifiers.free_tower_requested.connect(_on_free_tower_requested)
	_hero.health().set_regen_active(false)
	_spawner.wave_started.connect(func(_wave_number: int) -> void: _hero.health().set_regen_active(true))
	_spawner.wave_finished.connect(func(_wave_number: int) -> void: _hero.health().set_regen_active(false))
	modifiers.changed.connect(_apply_hero_survival.bind(modifiers))
	# Items (étape 5a spec §8): Pansement doré heals at each wave start, Bouclier du cristal
	# lowers the crystal's damage, Seconde chance arms the hero's one-time rescue.
	_spawner.wave_started.connect(func(_wave_number: int) -> void: _hero.health().heal(modifiers.hero_heal_per_wave()))
	modifiers.changed.connect(func() -> void: _crystal.set_damage_factor(modifiers.crystal_damage_factor()))
	modifiers.items_changed.connect(_arm_second_chance.bind(modifiers))
	_spawner.enemy_killed.connect(func(_position: Vector2) -> void: _hero.health().heal(modifiers.hero_heal_on_kill()))
	_state = GameState.new(economy.starting_gold + _skill_tree.starting_gold_bonus(owned))
	_cycle = WaveCycle.new()
	_spawner.setup(curve, defence, _field_rect, _crystal, _enemies)
	# Announced attacks: first child for now, so under every character; the floor, the path view and
	# the decor are moved to the indexes below it afterwards, so they stay under the announcements.
	var hazards := Node2D.new()
	hazards.name = "Hazards"
	add_child(hazards)
	move_child(hazards, 0)
	_spawner.set_modifiers(modifiers)
	_spawner.set_frozen_vulnerability(towers.frozen_vulnerability)
	var card_effects := CardEffects.new()
	add_child(card_effects)
	card_effects.setup(_enemies, modifiers)
	# The gold field sits just before Enemies, so coins are drawn under the enemies.
	var gold_field := GoldField.new()
	add_child(gold_field)
	move_child(gold_field, _enemies.get_index())
	gold_field.setup(_state, _hero, economy, modifiers)
	_spawner.wave_finished.connect(func(_wave_number: int) -> void: gold_field.clear())
	_cycle.setup(_state, _spawner, economy, modifiers, curve, _crystal, _field_rect, _rng, gold_field)
	# The path view is moved to index 0 so it is drawn under every child (crystal, Towers, ...).
	_path_view = PathView.new()
	add_child(_path_view)
	move_child(_path_view, 0)
	_path_view.setup(_state)
	# The floor goes under everything, the path view included.
	var floor_view := NeonFloor.new()
	add_child(floor_view)
	move_child(floor_view, 0)
	floor_view.setup(_field_rect)
	# The decor sits right above the floor and under the path view. It is optional:
	# a missing or invalid decor.json (error already logged) leaves the field bare.
	var decor_stats: DecorStats = DecorStats.load_from_file(DECOR_PATH)
	if decor_stats != null:
		_decor = DecorField.new()
		add_child(_decor)
		move_child(_decor, 1)
		_decor.setup(decor_stats, _field_rect, _crystal.global_position, _rng)
	_camera = GameCamera.new()
	add_child(_camera)
	_camera.setup(_hero, _crystal, _field_rect, _state, AbilityBar.bottom_band_height(bar_style), CrystalHud.build_bottom_band_height(), CrystalHud.top_band_height(), CrystalHud.side_column_width())
	_impact = ImpactFeedback.new()
	add_child(_impact)
	_impact.setup(impact_stats, _camera, _state)
	_spawner.set_enemy_types(enemy_types, enemy_sheets, _hero, _impact, hazards, _state, _rng)
	# Floating damage numbers are optional: a missing or invalid damage_numbers.json
	# (error already logged) only leaves the hits without numbers.
	var damage_number_model: DamageNumberModel = DamageNumberModel.load_from_file(DAMAGE_NUMBERS_PATH)
	var damage_numbers: DamageNumbers = null
	if damage_number_model != null:
		damage_numbers = DamageNumbers.new()
		damage_numbers.name = "DamageNumbers"
		add_child(damage_numbers)
		damage_numbers.setup(damage_number_model, _state)
		_spawner.set_damage_numbers(damage_numbers)
	# The styled cursor is optional too: a missing or invalid cursor.json (error already
	# logged) leaves the system mouse cursor.
	var cursor_art: CursorArt = CursorArt.load_from_file(CURSOR_PATH)
	if cursor_art != null:
		var cursor := CursorController.new()
		cursor.name = "CursorController"
		add_child(cursor)
		cursor.setup(cursor_art, _state, _enemies)
	_impact.watch_enemies(_enemies)
	_impact.watch_crystal(_crystal)
	_hero.set_impact(_impact)
	_cycle.wave_prepared.connect(_on_wave_prepared)
	_spawner.wave_finished.connect(_on_wave_finished)
	_hud.bind_enemy_types(enemy_types)
	_hud.bind_world_run(_world_run)
	_hud.bind_game_state(_state)
	_hud.bind_modifiers(modifiers)
	_hud.bind_items(modifiers, _hero.health())
	_hud.bind_stats(_hero, modifiers, economy, stats, towers)
	_card_screen = CardChoiceScreen.new()
	add_child(_card_screen)
	_card_screen.setup(_rarities, _ability_catalog)
	_card_screen.card_chosen.connect(_on_card_chosen.bind(modifiers))
	_card_screen.reroll_requested.connect(_on_reroll_requested)
	_state.phase_changed.connect(_on_phase_changed)
	_build_world_screens()
	# Added after Enemies, so the mark is drawn over the enemies.
	var designator := TargetDesignator.new()
	add_child(designator)
	move_child(designator, _enemies.get_index() + 1)
	designator.setup(_state, _enemies, towers)
	_spawner.wave_finished.connect(func(_wave_number: int) -> void: designator.clear())
	_reserve = TowerReserve.new(towers)  # Empty at the start of a run.
	_placer.setup(towers, _state, _field_rect, _crystal, _towers, _enemies, _bullets, rules, modifiers, designator, _reserve)
	var tower_sheets: Dictionary = {}  # Tower id -> SpriteSheet; a tower whose sheet fails is shown without an image.
	for def: TowerDef in towers.defs():
		var tower_sheet: SpriteSheet = _sheet_for(def.sheet_path)
		if tower_sheet != null:
			tower_sheets[def.id] = tower_sheet
	_placer.set_visuals(tower_sheets)
	var tower_effects := TowerEffects.new()
	add_child(tower_effects)
	tower_effects.setup(_enemies, towers, modifiers, _placer.records_by_id)
	_placer.set_chain_limiter(tower_effects.limiter())
	_placer.set_damage_numbers(damage_numbers)
	_placer.set_ground(hazards)
	tower_effects.set_amp_source(_placer.amp_of_tower)
	_hud.bind_tower_build(towers, modifiers, _reserve, _placer, _state)
	_hud.tower_kind_chosen.connect(_placer.select_purchase)
	_hud.reserve_record_chosen.connect(_placer.select_record)
	_placer.not_enough_gold.connect(_hud.show_not_enough_gold)
	var upgrade_panel: TowerUpgradePanel = _hud.upgrade_panel()
	_placer.tower_clicked.connect(upgrade_panel.open)
	_placer.tower_clicked.connect(func(_record: TowerRecord, _at: Vector2) -> void: _placer.set_panel_open(true))
	upgrade_panel.closed.connect(_placer.set_panel_open.bind(false))
	_placer.panel_dismiss_requested.connect(upgrade_panel.close)
	upgrade_panel.upgrade_requested.connect(_on_tower_upgrade_requested)
	upgrade_panel.pick_up_requested.connect(_placer.pick_up)
	_caster = AbilityCaster.new()
	add_child(_caster)
	_caster.set_impact(_impact)
	_caster.setup(_state, _hero, _enemies, _bullets, _field_rect, modifiers, rules)
	_hud.bind_abilities(_caster, bar_style)
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


## The sheet of [param dir], loaded the first time and shared afterwards
## ([code]null[/code] after an error, which is reported once per try).
func _sheet_for(dir: String) -> SpriteSheet:
	if not _sheets.has(dir):
		var sheet: SpriteSheet = SpriteSheet.load_from_dir(dir)
		if sheet == null:
			return null
		_sheets[dir] = sheet
	return _sheets[dir]


## Space launches the next wave during the build phase. This node stops
## receiving input once the tree is paused (defeat), so Space then does nothing.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"start_wave") and _cycle != null:
		_cycle.request_next_wave()


## Equips the hero, switches on the specialization's combos, builds the card pool
## for it, then goes on with the start sequence: the opening card choice when
## owned, then the world map in consultation, then the build phase of wave 1.
func _on_spec_chosen(spec: SpecializationDef) -> void:
	var owned: PackedStringArray = _progress.owned_ids
	for combo_id: String in spec.combo_ids:
		_rules.activate(combo_id)
	if spec.freeze_duration > 0.0:
		_modifiers.enable_freeze(spec.freeze_duration, spec.freeze_cooldown)
	var spec_sheet: SpriteSheet = _sheet_for(_visuals.hero_sheet(spec.id))
	if spec_sheet != null:  # On a load error the default look stays.
		_hero.set_visual(spec_sheet, _visuals.height("hero"))
	_hero.equip(spec, _modifiers, _rng)
	_caster.equip(_ability_catalog.for_spec(spec.id))
	_hud.show_specialization(spec)
	_hud.refresh_stats()
	var abilities: Dictionary = _ability_catalog.for_spec(spec.id)
	var is_unlocked := func(ability_id: String) -> bool:
		for slot: StringName in abilities:
			if (abilities[slot] as AbilityDef).id == ability_id:
				return _caster.is_unlocked(slot)
		return false
	_item_pool = ItemPool.new(_item_catalog, _modifiers, _rng, spec.id, _rarities)
	_card_pool = CardPool.new(_catalog, _modifiers, _rng, _skill_tree.unlocked_card_ids(owned), _skill_tree.cards_offered_bonus(owned), spec.id, _rarities, is_unlocked)
	if _skill_tree.has_start_card_choice(owned):
		_state.begin_card_choice()
		return
	_end_card_choice()


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
	_card_pool.begin_choice()
	if not _present_offer(_card_pool.draw(_choice_wave())):
		_end_card_choice()


## The wave about to be played, used for the rarity weights.
func _choice_wave() -> int:
	return _state.waves_completed + 1


## Adds the "Nouvelle compétence" card to [param drawn] when due (it takes a slot
## of a full offer) and shows the result. Returns false when there is nothing to offer.
func _present_offer(drawn: Array[CardDef]) -> bool:
	var offer: Array[CardDef] = drawn.duplicate()
	var unlock_card: CardDef = _unlock_card_if_due()
	if unlock_card != null:
		if offer.size() >= _card_pool.offer_size():
			offer.pop_back()
		offer.push_front(unlock_card)
	if offer.is_empty():
		return false
	var cost: int = _card_pool.reroll_cost()
	_card_screen.show_cards(offer, cost, _state.gold >= cost, _card_pool.can_draw())
	return true


## Pays for a reroll and replaces the offer; refused when the gold is short.
func _on_reroll_requested() -> void:
	if _state.phase != GameState.Phase.CARD_CHOICE or not _card_pool.can_draw():
		return
	if not _state.spend_gold(_card_pool.reroll_cost()):
		return
	_present_offer(_card_pool.reroll(_choice_wave()))


## The "Nouvelle compétence" card when the next locked ability (A, E, R) is due
## (étape 3b: [member AbilityCatalog.unlock_after_waves]); [code]null[/code] otherwise.
func _unlock_card_if_due() -> CardDef:
	var slot: StringName = _caster.next_locked_slot()
	if slot == &"":
		return null
	var index: int = AbilityCatalog.UNLOCK_SLOTS.find(slot)
	if _state.waves_completed < _ability_catalog.unlock_after_waves[index]:
		return null
	var def: AbilityDef = _caster.ability(slot)
	var card := CardDef.new()
	card.id = UNLOCK_CARD_PREFIX + String(slot)
	card.rarity = &""  # No rarity: the screen draws no rarity frame for it.
	card.display_name = "Nouvelle compétence : %s (%s)" % [def.display_name, String(slot).to_upper()]
	card.description = def.description
	return card


## Survival cards (étape 4 §7): gives the hero the extra maximum (healing as much, once per
## new bonus) and sets the regeneration from the modifiers.
func _apply_hero_survival(modifiers: PlayerModifiers) -> void:
	var health: HeroHealth = _hero.health()
	var extra: float = modifiers.hero_max_hp_bonus() - _applied_max_hp_bonus
	if extra > 0.0:
		health.add_max(extra)
		_applied_max_hp_bonus += extra
	health.set_regen(modifiers.hero_regen())


## Seconde chance (étape 5a spec §8): once the item is owned, arms the hero's rescue.
## [method HeroHealth.arm_rescue] ignores later calls once the rescue has been used.
func _arm_second_chance(modifiers: PlayerModifiers) -> void:
	if modifiers.has_flag(&"second_chance"):
		_hero.health().arm_rescue(modifiers.flag_value(&"second_chance", "hp_fraction"))


func _on_card_chosen(card: CardDef, modifiers: PlayerModifiers) -> void:
	if card.id.begins_with(UNLOCK_CARD_PREFIX):
		_caster.unlock(StringName(card.id.trim_prefix(UNLOCK_CARD_PREFIX)))
	else:
		modifiers.take(card)
	_end_card_choice()


## After a card choice (or the specialization, without opening choice), étape 5a §5:
## before wave 1, the map in consultation; after a world's final wave, the next world
## (new map, « MONDE N ») in consultation; otherwise the choice of the next place.
## Every way ends in [method GameState.begin_build], once: [signal WorldMapScreen.closed]
## or the end of the place ([method _end_place]).
func _end_card_choice() -> void:
	_state.begin_map()
	if _state.waves_completed == 0:
		_open_map(false)
		return
	if _world_run.is_final_wave(_state.waves_completed):
		_world_run.world += 1
		_world_run.start_world(_map_generator.generate(_rng))
		_hud.show_banner(WORLD_BANNER % _world_run.world)
		# The map covers the HUD layer: it opens once the banner has been seen.
		get_tree().create_timer(CrystalHud.BANNER_SECONDS).timeout.connect(_open_new_world_map)
		return
	_open_map(not _world_run.reachable().is_empty())


## The new world's map in consultation, after the « MONDE N » banner.
func _open_new_world_map() -> void:
	if _lost or _state.phase != GameState.Phase.MAP:
		return
	_open_map(false)


## Shows the world map with the next wave's preview; [param choosing] false = consultation.
func _open_map(choosing: bool) -> void:
	var wave: int = _choice_wave()
	var preview: String = "Vague %d : %s" % [wave, _enemy_types.preview_text(_spawner.composition_for(wave))]
	if _world_run.is_final_wave(wave):
		preview += " — " + FINAL_WAVE_BANNER
	_map_screen.open(_world_run, preview, choosing, _rest_tooltip())


## The rest places' tooltip on the map, with the current hit points (rounded down,
## so « 99/100 » is shown whenever the rest still has something to heal).
func _rest_tooltip() -> String:
	var health: HeroHealth = _hero.health()
	return "Repos — Héros %d/%d · Cristal %d/%d" % [
		floori(health.current), floori(health.max_hp), floori(_crystal.current_hp), floori(_crystal.max_hp)]


## Creates the map and place screens and connects them (once, in [method _ready]).
func _build_world_screens() -> void:
	_map_screen = WorldMapScreen.new()
	add_child(_map_screen)
	_map_screen.closed.connect(_on_map_closed)
	_map_screen.place_chosen.connect(_on_place_chosen)
	_shop_screen = ShopScreen.new()
	add_child(_shop_screen)
	_shop_screen.setup(_rarities)
	_shop_screen.item_bought.connect(_on_item_bought)
	_shop_screen.repair_requested.connect(_on_repair_requested)
	_shop_screen.left.connect(_end_place)
	_treasure_screen = TreasureScreen.new()
	add_child(_treasure_screen)
	_treasure_screen.setup(_rarities)
	_treasure_screen.item_chosen.connect(_on_treasure_item_chosen)
	_rest_screen = RestScreen.new()
	add_child(_rest_screen)
	_rest_screen.hero_chosen.connect(_on_rest_hero_chosen)
	_rest_screen.crystal_chosen.connect(_on_rest_crystal_chosen)
	_rest_screen.back_requested.connect(_on_rest_back_requested)


## « C'est parti ! » on the map in consultation: the build phase.
func _on_map_closed() -> void:
	if _state.phase == GameState.Phase.MAP:
		_state.begin_build()


## Moves to the chosen place and opens it (spec §7). An unreachable index (never sent
## by the screen) shows the choice again.
func _on_place_chosen(index: int) -> void:
	if _state.phase != GameState.Phase.MAP:
		return
	if not _world_run.move_to(index):
		_open_map(true)
		return
	_state.begin_place()
	var type: StringName = _world_run.map.type_of(_world_run.column, index)
	if type == WorldMap.SHOP:
		_shop_screen.open(_item_pool.draw(_item_catalog.shop_slots, _choice_wave()), _item_catalog, _state.gold, _crystal_full())
	elif type == WorldMap.TREASURE:
		_open_treasure()
	else:
		var health: HeroHealth = _hero.health()
		_rest_screen.open(health.max_hp * _item_catalog.rest_hero_heal_fraction, _item_catalog.rest_crystal_heal, health.current >= health.max_hp, _crystal_full())


## Free items to pick one from; none left: the fallback gold and its banner instead.
func _open_treasure() -> void:
	var items: Array[ItemDef] = _item_pool.draw(_item_catalog.treasure_slots, _choice_wave())
	if items.is_empty():
		_state.add_gold(_item_catalog.treasure_fallback_gold)
		_hud.show_banner(TREASURE_GOLD_BANNER % _item_catalog.treasure_fallback_gold)
		_end_place()
		return
	_treasure_screen.open(items)


func _crystal_full() -> bool:
	return _crystal.current_hp >= _crystal.max_hp


## Shop purchase: the gold first, then the item (the screen already took it off the stall).
func _on_item_bought(item: ItemDef) -> void:
	if _state.spend_gold(_item_catalog.price_of(item)):
		_modifiers.take_item(item)
	_shop_screen.refresh(_state.gold, _crystal_full())


## Shop crystal repair: no limit, never above the maximum (refused when full).
func _on_repair_requested() -> void:
	if not _crystal_full() and _state.spend_gold(_item_catalog.crystal_repair_cost):
		_crystal.heal(_item_catalog.crystal_repair_hp)
	_shop_screen.refresh(_state.gold, _crystal_full())


func _on_treasure_item_chosen(item: ItemDef) -> void:
	_modifiers.take_item(item)
	_end_place()


func _on_rest_hero_chosen() -> void:
	var health: HeroHealth = _hero.health()
	health.heal(health.max_hp * _item_catalog.rest_hero_heal_fraction)
	_end_place()


func _on_rest_crystal_chosen() -> void:
	_crystal.heal(_item_catalog.rest_crystal_heal)
	_end_place()


## « Retour à la carte » from a rest where hero and crystal are both full (the
## only place offering it: no free peeking at a shop or a treasure). The move is
## undone and the same choice is shown again.
func _on_rest_back_requested() -> void:
	if _state.phase != GameState.Phase.PLACE:
		return
	if not _world_run.undo_move():
		_end_place()  # Never expected: leave the place rather than stay stuck on a hidden screen.
		return
	_state.begin_map()
	_open_map(true)


## The place is left (shop « Partir », treasure item, rest choice): the build phase.
func _end_place() -> void:
	if _state.phase == GameState.Phase.PLACE:
		_state.begin_build()


## Shows the prepared wave's path and its preview text, and the « VAGUE FINALE ! »
## banner when it is the last wave of its world.
func _on_wave_prepared(wave_number: int, composition: Dictionary, path: CrystalPath) -> void:
	_path_view.show_path(path)
	if _decor != null:
		_decor.show_path(path)
	_hud.show_wave_preview(wave_number, composition)
	if _world_run.is_final_wave(wave_number):
		_hud.show_banner(FINAL_WAVE_BANNER)


## The crystal arrived: the placed towers go back to the reserve (they do not stay on
## the old path) and the upgrade panel closes.
func _on_wave_finished(_wave_number: int) -> void:
	_hud.upgrade_panel().close()
	_placer.return_all_towers()


## Upgrades [param record] when the gold covers the price: [method TowerReserve.try_upgrade]
## checks and applies it, then its returned price is spent. A refusal spends nothing.
func _on_tower_upgrade_requested(record: TowerRecord, branch: StringName) -> void:
	var price: int = _reserve.try_upgrade(record, branch, _state.gold, _modifiers.upgrade_cost_factor())
	if price < 0:
		_hud.show_not_enough_gold()
		return
	_state.spend_gold(price)


## The hero died: the whole world freezes at once (the tree is paused: spawns, enemies,
## towers, bullets, abilities), except the hero, which keeps playing its death clip
## ([constant Node.PROCESS_MODE_ALWAYS], set by the hero itself). Then the usual defeat.
func _on_hero_died() -> void:
	if _lost:
		return
	get_tree().paused = true
	# Always processed, real time: a running hit-stop must not stretch the delay.
	await get_tree().create_timer(HERO_DEATH_SECONDS, true, false, true).timeout
	_lose()


## Stops the game, banks this game's points (saved at once) and opens the defeat
## screen. Points use only the waves and kills counted up to this moment. Shared by
## the crystal's destruction and the hero's death; runs only once.
func _lose() -> void:
	if _lost:
		return
	_lost = true
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


## « Tour de renfort »: a free base tower of the least owned unlocked kind joins the reserve.
func _on_free_tower_requested() -> void:
	if _reserve == null or _modifiers == null:
		return
	var kind: StringName = _reserve.least_owned_kind(_modifiers.unlocked_towers())
	if kind != &"":
		_reserve.add_free(kind)
