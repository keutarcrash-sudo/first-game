## On-screen display: crystal hit points (story 002), wave number, gold, phase
## and the build-phase prompt (story 003), the chosen specialization (story 008), the world
## and the wave's rank in it, the per-type wave preview and the big banners (étape 5a). The defeat is shown by [DeathScreen]
## (story 007), not here. Only listens
## to signals; never changes game state. Extended rather than duplicated so the
## game keeps a single CanvasLayer.
class_name CrystalHud
extends CanvasLayer

## Emitted when the player clicks one of the two tower purchase buttons (build phase).
signal tower_kind_chosen(kind: TowerStats.Kind)
## Emitted when the player clicks a tower of the reserve bar (build phase).
signal reserve_record_chosen(record: TowerRecord)

const BUTTON_FONT_SIZE := 22
const BUTTON_SIZE := Vector2(220.0, 44.0)
const BUTTON_SPACING := 16
const BUTTON_BOTTOM_MARGIN := 70.0
const BUTTON_SELECTED_COLOR := Color(1.0, 0.9, 0.35)
const BUTTON_SHORT_COLOR := Color(1.0, 0.45, 0.4)  # Purchase price above the gold.
## Gap between the top of the tower buttons and the reserve bar above them.
const RESERVE_BAR_GAP := 6.0
const MESSAGE_FONT_SIZE := 28
const MESSAGE_BOTTOM_MARGIN := 186.0  # Above the ability bar.
const MESSAGE_COLOR := Color(1.0, 0.45, 0.4)
const MESSAGE_SECONDS := 1.0
const INFO_FONT_SIZE := 20
## Layout (1280 x 720 reference, everything anchored top-left or top-right so it
## holds at any ratio with the [code]expand[/code] stretch):
## top band (height [constant TOP_BAND_HEIGHT]): crystal line, hero line, wave line on
## the left, specialization line on the right. Under it, the left column (width
## [constant LEFT_COLUMN_WIDTH]) holds the cards then the items, the right column the
## stats panel ([constant StatsPanel.WIDTH]). BUILD fits the field between the
## bands and the columns ([method top_band_height], [method side_column_width]).
const LEFT_MARGIN := 40.0
const TOP_BAND_HEIGHT := 100.0  # Three 30 px lines from y = 4, plus a small gap.
const LEFT_COLUMN_WIDTH := 290.0
const COLUMN_GAP := 16.0  # Kept between a side column and the field in BUILD.
const HP_POSITION := Vector2(LEFT_MARGIN, 4.0)
const HERO_BAR_POSITION := Vector2(LEFT_MARGIN, 34.0)  # Under the crystal line.
const INFO_POSITION := Vector2(LEFT_MARGIN, 64.0)  # Under the hero line, last line of the band.
const CARDS_TOP := TOP_BAND_HEIGHT + 4.0
const CARDS_POSITION := Vector2(LEFT_MARGIN, CARDS_TOP)
const CARDS_MAX_LINES := 3
const CARDS_LINE_HEIGHT := 30.0  # A 20 px Bungee line is about 30 px tall.
const ITEMS_POSITION := Vector2(LEFT_MARGIN, CARDS_TOP + CARDS_MAX_LINES * CARDS_LINE_HEIGHT + 6.0)  # Under the cards.
const PROMPT_FONT_SIZE := 32
const PROMPT_BOTTOM_MARGIN := 24.0
## Height of a text line as a share of its font size.
const LINE_HEIGHT_RATIO := 1.2
## Gap kept between the top of the tower buttons and the field in BUILD.
const BUILD_BAND_MARGIN := 18.0
const PROMPT_COLOR := Color(0.55, 0.9, 1.0)
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const SPEC_COLOR := Color(1.0, 0.9, 0.35)
const SPEC_RIGHT_MARGIN := 40.0
const SPEC_TOP := 4.0
const BANNER_FONT_SIZE := 96
const BANNER_COLOR := Color(1.0, 0.3, 0.75)  # Neon pink, a shout over the field.
const BANNER_SECONDS := 1.5  # Whole life of a banner, fades included.
const BANNER_FADE_SECONDS := 0.2

var _hp_bar: HeroHealthBar
var _info_label: Label
var _prompt_label: Label
var _state: GameState
var _build_box: HBoxContainer
var _cannon_button: Button
var _frost_button: Button
var _message_label: Label
var _message_timer: Timer
var _cards_label: Label
var _modifiers: PlayerModifiers
var _spec_label: Label
var _wave_preview: String = ""
var _stats_panel: StatsPanel
var _tower_stats: TowerStats
var _tower_modifiers: PlayerModifiers
var _world_run: WorldRun
var _enemy_types: EnemyTypes
var _banner_label: Label
var _banner_tween: Tween
var _ability_bar: AbilityBar  # Shown in COMBAT only (abilities are cast in COMBAT only).
var _reserve: TowerReserve
var _placer: TowerPlacer
var _reserve_bar: TowerReserveBar
var _upgrade_panel: TowerUpgradePanel


func _ready() -> void:
	_build_tower_ui()
	_hp_bar = HeroHealthBar.new()
	_hp_bar.title = "Cristal"
	_hp_bar.position = HP_POSITION
	add_child(_hp_bar)
	_info_label = Label.new()
	_info_label.position = INFO_POSITION
	_info_label.add_theme_font_size_override(&"font_size", INFO_FONT_SIZE)
	_info_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	NeonFonts.style_label(_info_label, NeonFonts.title())
	add_child(_info_label)
	_cards_label = Label.new()
	_cards_label.position = CARDS_POSITION
	_cards_label.custom_minimum_size = Vector2(LEFT_COLUMN_WIDTH, 0.0)
	_cards_label.size = Vector2(LEFT_COLUMN_WIDTH, 0.0)
	_cards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cards_label.max_lines_visible = CARDS_MAX_LINES
	_cards_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_cards_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_label.add_theme_font_size_override(&"font_size", INFO_FONT_SIZE)
	_cards_label.add_theme_color_override(&"font_color", PROMPT_COLOR)
	NeonFonts.style_label(_cards_label, NeonFonts.title())
	add_child(_cards_label)
	_spec_label = Label.new()
	# Right half of the top band only, so a long name never runs into the hit-point lines.
	_spec_label.anchor_left = 0.5
	_spec_label.anchor_right = 1.0
	_spec_label.offset_top = SPEC_TOP
	_spec_label.offset_right = -SPEC_RIGHT_MARGIN
	_spec_label.clip_text = true
	_spec_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_spec_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_spec_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spec_label.add_theme_font_size_override(&"font_size", INFO_FONT_SIZE)
	_spec_label.add_theme_color_override(&"font_color", SPEC_COLOR)
	NeonFonts.style_label(_spec_label, NeonFonts.title())
	add_child(_spec_label)
	_prompt_label = Label.new()
	_prompt_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prompt_label.offset_bottom = -PROMPT_BOTTOM_MARGIN
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_prompt_label.add_theme_font_size_override(&"font_size", PROMPT_FONT_SIZE)
	_prompt_label.add_theme_color_override(&"font_color", PROMPT_COLOR)
	NeonFonts.style_label(_prompt_label, NeonFonts.title())
	add_child(_prompt_label)
	_banner_label = Label.new()
	_banner_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Never blocks a click.
	_banner_label.add_theme_font_size_override(&"font_size", BANNER_FONT_SIZE)
	_banner_label.add_theme_color_override(&"font_color", BANNER_COLOR)
	NeonFonts.style_label(_banner_label, NeonFonts.title())
	_banner_label.visible = false
	add_child(_banner_label)


func _build_tower_ui() -> void:
	_build_box = HBoxContainer.new()
	_build_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_build_box.offset_top = -(BUTTON_BOTTOM_MARGIN + BUTTON_SIZE.y)
	_build_box.offset_bottom = -BUTTON_BOTTOM_MARGIN
	_build_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_build_box.add_theme_constant_override(&"separation", BUTTON_SPACING)
	_build_box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Only the buttons take clicks, not the whole strip.
	_build_box.visible = false
	add_child(_build_box)
	# Pressed state set from the placer's selection ([method _refresh_tower_selection]).
	_cannon_button = _make_tower_button(TowerStats.Kind.CANNON)
	_frost_button = _make_tower_button(TowerStats.Kind.FROST)
	_cannon_button.set_pressed_no_signal(true)  # The cannon purchase is selected by default.
	_message_label = Label.new()
	_message_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_message_label.offset_bottom = -MESSAGE_BOTTOM_MARGIN
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_message_label.add_theme_font_size_override(&"font_size", MESSAGE_FONT_SIZE)
	_message_label.add_theme_color_override(&"font_color", MESSAGE_COLOR)
	NeonFonts.style_label(_message_label, NeonFonts.title())
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_label.visible = false
	add_child(_message_label)
	_message_timer = Timer.new()
	_message_timer.one_shot = true
	_message_timer.wait_time = MESSAGE_SECONDS
	_message_timer.timeout.connect(_message_label.hide)
	add_child(_message_timer)


func _make_tower_button(kind: TowerStats.Kind) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE  # Space starts the wave: a focused button must not react to it.
	button.custom_minimum_size = BUTTON_SIZE
	button.add_theme_font_size_override(&"font_size", BUTTON_FONT_SIZE)
	button.add_theme_font_override(&"font", NeonFonts.title())
	button.add_theme_color_override(&"font_pressed_color", BUTTON_SELECTED_COLOR)
	button.add_theme_color_override(&"font_hover_pressed_color", BUTTON_SELECTED_COLOR)
	button.pressed.connect(_on_tower_button_pressed.bind(kind))
	_build_box.add_child(button)
	return button


func _on_tower_button_pressed(kind: TowerStats.Kind) -> void:
	tower_kind_chosen.emit(kind)
	_refresh_tower_selection()  # A click on the pressed button must not unpress it.


## Writes the real purchase prices on the two build buttons ("Acheter canon — N",
## [method TowerReserve.price_of_next] after the discounts of [param modifiers]) and
## rewrites them when the gold of [param state], the [param reserve] or the modifiers
## change. Adds the reserve bar above the buttons and the upgrade panel
## ([method upgrade_panel]); the buttons and the bar show the selection of [param placer].
## Display only: [signal tower_kind_chosen] and [signal reserve_record_chosen] carry the clicks.
func bind_tower_build(stats: TowerStats, modifiers: PlayerModifiers, reserve: TowerReserve, placer: TowerPlacer, state: GameState) -> void:
	_tower_stats = stats
	_tower_modifiers = modifiers
	_reserve = reserve
	_placer = placer
	modifiers.changed.connect(_refresh_tower_prices)
	reserve.changed.connect(_refresh_tower_prices)
	state.gold_changed.connect(_refresh_tower_prices.unbind(1))
	placer.selection_changed.connect(_refresh_tower_selection)
	_reserve_bar = TowerReserveBar.new()
	_reserve_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	# Kept clear of the side columns so a long reserve never runs off-screen or under them.
	_reserve_bar.offset_left = side_column_width()
	_reserve_bar.offset_right = -side_column_width()
	_reserve_bar.offset_bottom = -(BUTTON_BOTTOM_MARGIN + BUTTON_SIZE.y + RESERVE_BAR_GAP)
	_reserve_bar.offset_top = _reserve_bar.offset_bottom - TowerReserveBar.HEIGHT
	_reserve_bar.visible = _build_box.visible
	add_child(_reserve_bar)
	_reserve_bar.setup(reserve, placer, stats)
	_reserve_bar.record_chosen.connect(reserve_record_chosen.emit)
	if _stats_panel != null:
		_stats_panel.bind_reserve(reserve)
	_upgrade_panel = TowerUpgradePanel.new()
	add_child(_upgrade_panel)
	_upgrade_panel.setup(stats, reserve, modifiers, state)
	_refresh_tower_prices()
	_refresh_tower_selection()


## The upgrade panel of the placed towers (created by [method bind_tower_build]).
func upgrade_panel() -> TowerUpgradePanel:
	return _upgrade_panel


func _refresh_tower_prices() -> void:
	if _reserve == null:
		return
	var factor: float = _tower_modifiers.tower_cost_factor()
	var gold: int = _state.gold if _state != null else 0
	_write_price(_cannon_button, "Acheter canon — %d", _reserve.price_of_next(TowerStats.Kind.CANNON, factor), gold)
	_write_price(_frost_button, "Acheter glace — %d", _reserve.price_of_next(TowerStats.Kind.FROST, factor), gold)


func _write_price(button: Button, text_format: String, price: int, gold: int) -> void:
	button.text = text_format % price
	var color: Color = BUTTON_SHORT_COLOR if gold < price else TEXT_COLOR
	var pressed_color: Color = BUTTON_SHORT_COLOR if gold < price else BUTTON_SELECTED_COLOR
	button.add_theme_color_override(&"font_color", color)
	button.add_theme_color_override(&"font_hover_color", color)
	button.add_theme_color_override(&"font_pressed_color", pressed_color)
	button.add_theme_color_override(&"font_hover_pressed_color", pressed_color)


## Presses the purchase button of the kind the placer buys, none while it places a reserve tower.
func _refresh_tower_selection() -> void:
	if _placer == null:
		return
	var buying: bool = _placer.selected_record() == null
	_cannon_button.set_pressed_no_signal(buying and _placer.selected_kind() == TowerStats.Kind.CANNON)
	_frost_button.set_pressed_no_signal(buying and _placer.selected_kind() == TowerStats.Kind.FROST)


## Height in screen pixels of the top HUD band (crystal and hero lines, wave line,
## specialization line): BUILD keeps the field below it ([GameCamera]). Twin of
## [method AbilityBar.bottom_band_height].
static func top_band_height() -> float:
	return TOP_BAND_HEIGHT


## Height in screen pixels of the bottom HUD band in BUILD: the prompt line, the
## tower buttons above it, the reserve bar above them ([TowerReserveBar]) and a
## small margin. BUILD keeps the field above it ([GameCamera]); the ability bar is
## hidden in BUILD.
static func build_bottom_band_height() -> float:
	var prompt_top: float = PROMPT_BOTTOM_MARGIN + PROMPT_FONT_SIZE * LINE_HEIGHT_RATIO
	var buttons_top: float = maxf(BUTTON_BOTTOM_MARGIN, prompt_top) + BUTTON_SIZE.y
	return buttons_top + RESERVE_BAR_GAP + TowerReserveBar.HEIGHT + BUILD_BAND_MARGIN


## Width in screen pixels kept free on each side of the field in BUILD: the wider of
## the left column (cards, items) and the right one (stats panel), margins included.
static func side_column_width() -> float:
	var left: float = LEFT_MARGIN + LEFT_COLUMN_WIDTH
	var right: float = StatsPanel.RIGHT_MARGIN + StatsPanel.WIDTH
	return maxf(left, right) + COLUMN_GAP


## Shows the four ability discs of [param caster], drawn with [param style], at the
## bottom of the screen, in COMBAT only.
func bind_abilities(caster: AbilityCaster, style: AbilityBarStyle) -> void:
	_ability_bar = AbilityBar.new()
	add_child(_ability_bar)
	_ability_bar.setup(caster, style)
	_ability_bar.visible = _state != null and _state.phase == GameState.Phase.COMBAT


## Shows "Pas assez d'or" for about a second.
func show_not_enough_gold() -> void:
	_message_label.text = "Pas assez d'or"
	_message_label.visible = true
	_message_timer.start()


## Shows the specialization chosen for this game, top right, until the end of the game.
func show_specialization(spec: SpecializationDef) -> void:
	_spec_label.text = "Spécialisation : %s" % spec.display_name


## Shows the hero's stats panel (top right, under the specialization line) during BUILD
## and COMBAT (hidden during the card, specialization, map and place screens). [param towers] gives the base tower ranges and prices for the item lines.
## Call after [method bind_game_state]; call [method refresh_stats] once the hero is equipped.
func bind_stats(hero: Hero, modifiers: PlayerModifiers, economy: EconomyStats, stats: HeroStats, towers: TowerStats) -> void:
	_stats_panel = StatsPanel.new()
	add_child(_stats_panel)
	_stats_panel.setup(hero, modifiers, economy, stats, towers)
	_stats_panel.visible = _stats_visible()


## Rereads the stats panel (the specialization lines appear when the hero is equipped).
func refresh_stats() -> void:
	if _stats_panel != null:
		_stats_panel.refresh()


func _stats_visible() -> bool:
	return _state != null and (_state.phase == GameState.Phase.BUILD or _state.phase == GameState.Phase.COMBAT)


## Shows the crystal's hit points and keeps them up to date. Call after the crystal's setup.
func bind(crystal: Crystal) -> void:
	_on_health_changed(crystal.current_hp, crystal.max_hp)
	crystal.health_changed.connect(_on_health_changed)
	var pointer := CrystalPointer.new()
	add_child(pointer)
	pointer.setup(crystal)


## Shows the hero's hit-point line under the crystal's. Call after the hero's setup.
func bind_hero(health: HeroHealth) -> void:
	var bar := HeroHealthBar.new()
	bar.position = HERO_BAR_POSITION
	add_child(bar)
	bar.bind(health)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	_hp_bar.show_values(current_hp, max_hp)


## Replaces the build prompt with the preview of the coming wave (call on each entry into BUILD):
## its enemies by type ([param composition], see [method WaveSpawner.composition_for]),
## named with the types given to [method bind_enemy_types].
func show_wave_preview(wave_number: int, composition: Dictionary) -> void:
	var enemies: String = "%d ennemis" % _total(composition)
	if _enemy_types != null:
		enemies = _enemy_types.preview_text(composition)
	_wave_preview = "Vague %d : %s — place tes tours, puis Espace" % [wave_number, enemies]
	if _state != null:
		_refresh_info()


## Gives the enemy type names used by [method show_wave_preview]. Call before the first preview.
func bind_enemy_types(types: EnemyTypes) -> void:
	_enemy_types = types


## Shows the world and the wave's rank in it ("Monde X — Vague Y/8") instead of the
## plain wave number. Call before [method bind_game_state].
func bind_world_run(run: WorldRun) -> void:
	_world_run = run
	if _state != null:
		_refresh_info()


## Shows [param text] in big neon letters at the centre of the screen for about
## [constant BANNER_SECONDS] s. Clicks go through it. A new banner replaces the current one.
func show_banner(text: String) -> void:
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_label.text = text
	_banner_label.modulate.a = 0.0
	_banner_label.visible = true
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner_label, "modulate:a", 1.0, BANNER_FADE_SECONDS)
	_banner_tween.tween_interval(BANNER_SECONDS - 2.0 * BANNER_FADE_SECONDS)
	_banner_tween.tween_property(_banner_label, "modulate:a", 0.0, BANNER_FADE_SECONDS)
	_banner_tween.tween_callback(_banner_label.hide)


static func _total(composition: Dictionary) -> int:
	var total: int = 0
	for count: int in composition.values():
		total += count
	return total


## Shows wave number, gold, phase and the build prompt, and keeps them up to date.
func bind_game_state(state: GameState) -> void:
	_state = state
	state.gold_changed.connect(_refresh_info.unbind(1))
	state.wave_changed.connect(_refresh_info.unbind(1))
	state.phase_changed.connect(_refresh_info.unbind(1))
	_refresh_info()


## Shows the passive items owned ([ItemBar]) under the cards, wrapped to the left column. Call once.
func bind_items(modifiers: PlayerModifiers, health: HeroHealth) -> void:
	var bar := ItemBar.new()
	bar.position = ITEMS_POSITION
	bar.wrap_width = LEFT_COLUMN_WIDTH
	add_child(bar)
	bar.setup(modifiers, health)


## Shows the cards taken and their stacks, and keeps the line up to date (story 006).
func bind_modifiers(modifiers: PlayerModifiers) -> void:
	_modifiers = modifiers
	modifiers.changed.connect(_refresh_cards)
	_refresh_cards()


func _refresh_cards() -> void:
	var labels: PackedStringArray = _modifiers.owned_labels()
	_cards_label.text = "" if labels.is_empty() else "Cartes : %s" % ", ".join(labels)


func _refresh_info() -> void:
	var building: bool = _state.phase == GameState.Phase.BUILD
	var phase_name: String = "Combat"
	if building:
		phase_name = "Construction"
	elif _state.phase == GameState.Phase.CARD_CHOICE:
		phase_name = "Choix d'une carte"
	elif _state.phase == GameState.Phase.SPEC_CHOICE:
		phase_name = "Choix de la spécialisation"
	elif _state.phase == GameState.Phase.MAP:
		phase_name = "Carte du monde"
	elif _state.phase == GameState.Phase.PLACE:
		phase_name = "Lieu"
	_build_box.visible = building
	if _reserve_bar != null:
		_reserve_bar.visible = building
	if _upgrade_panel != null and not building:
		_upgrade_panel.close()  # Wave launch, card choice, map...: the panel is BUILD only.
	_refresh_tower_prices()
	if _ability_bar != null:
		_ability_bar.visible = _state.phase == GameState.Phase.COMBAT
	if _stats_panel != null:
		_stats_panel.visible = _stats_visible()
	_info_label.text = "%s · Or %d · %s" % [_wave_text(), _state.gold, phase_name]
	var prompt: String = "Construction — Espace : lancer la vague %d" % (_state.waves_completed + 1)
	if _wave_preview != "":
		prompt = _wave_preview
	_prompt_label.text = prompt if building else ""


## "Monde X — Vague Y/8" for the wave being played, or the coming one on the map, in a
## place and in BUILD (the plain "Vague : N" before [method bind_world_run]).
func _wave_text() -> String:
	var coming: bool = _state.phase == GameState.Phase.BUILD or _state.phase == GameState.Phase.MAP or _state.phase == GameState.Phase.PLACE
	var wave: int = _state.waves_completed + 1 if coming else maxi(_state.wave_number, 1)
	if _world_run == null:
		return "Vague : %d" % wave
	return "Monde %d — Vague %d/%d" % [_world_run.world_of(wave), _world_run.wave_in_world(wave), _world_run.waves_per_world()]
