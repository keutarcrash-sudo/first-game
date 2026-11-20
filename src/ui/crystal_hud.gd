## On-screen display: crystal hit points (story 002), wave number, gold, phase
## and the build-phase prompt (story 003), the chosen specialization (story 008). The defeat is shown by [DeathScreen]
## (story 007), not here. Only listens
## to signals; never changes game state. Extended rather than duplicated so the
## game keeps a single CanvasLayer.
class_name CrystalHud
extends CanvasLayer

## Emitted when the player clicks one of the two tower buttons (build phase).
signal tower_kind_chosen(kind: TowerStats.Kind)

const BUTTON_FONT_SIZE := 22
const BUTTON_SIZE := Vector2(220.0, 44.0)
const BUTTON_SPACING := 16
const BUTTON_BOTTOM_MARGIN := 70.0
const BUTTON_SELECTED_COLOR := Color(1.0, 0.9, 0.35)
const MESSAGE_FONT_SIZE := 28
const MESSAGE_BOTTOM_MARGIN := 186.0  # Above the ability bar.
const MESSAGE_COLOR := Color(1.0, 0.45, 0.4)
const MESSAGE_SECONDS := 1.0
const HP_FONT_SIZE := 20
const INFO_FONT_SIZE := 20
const INFO_POSITION := Vector2(40.0, 30.0)
const CARDS_POSITION := Vector2(40.0, 58.0)
const CARDS_WIDTH := 840.0  # Stops before the stats panel (starts at x = 920 on 1280 px).
const CARDS_MAX_LINES := 2
const PROMPT_FONT_SIZE := 32
const PROMPT_BOTTOM_MARGIN := 24.0
const PROMPT_COLOR := Color(0.55, 0.9, 1.0)
const HP_POSITION := Vector2(40.0, 2.0)
const HERO_BAR_POSITION := Vector2(300.0, 2.0)  # Right of the crystal line, before the stats panel (x = 920).
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const SPEC_COLOR := Color(1.0, 0.9, 0.35)
const SPEC_RIGHT_MARGIN := 40.0
const SPEC_TOP := 2.0

var _hp_label: Label
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


func _ready() -> void:
	_build_tower_ui()
	_hp_label = Label.new()
	_hp_label.position = HP_POSITION
	_hp_label.add_theme_font_size_override(&"font_size", HP_FONT_SIZE)
	_hp_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	NeonFonts.style_label(_hp_label, NeonFonts.title())
	add_child(_hp_label)
	_info_label = Label.new()
	_info_label.position = INFO_POSITION
	_info_label.add_theme_font_size_override(&"font_size", INFO_FONT_SIZE)
	_info_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	NeonFonts.style_label(_info_label, NeonFonts.title())
	add_child(_info_label)
	_cards_label = Label.new()
	_cards_label.position = CARDS_POSITION
	_cards_label.custom_minimum_size = Vector2(CARDS_WIDTH, 0.0)
	_cards_label.size = Vector2(CARDS_WIDTH, 0.0)
	_cards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cards_label.max_lines_visible = CARDS_MAX_LINES
	_cards_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_cards_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_label.add_theme_font_size_override(&"font_size", INFO_FONT_SIZE)
	_cards_label.add_theme_color_override(&"font_color", PROMPT_COLOR)
	NeonFonts.style_label(_cards_label, NeonFonts.title())
	add_child(_cards_label)
	_spec_label = Label.new()
	_spec_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_spec_label.offset_top = SPEC_TOP
	_spec_label.offset_right = -SPEC_RIGHT_MARGIN
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
	var group := ButtonGroup.new()
	_cannon_button = _make_tower_button(group, TowerStats.Kind.CANNON)
	_frost_button = _make_tower_button(group, TowerStats.Kind.FROST)
	_cannon_button.button_pressed = true  # The cannon is selected by default.
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


func _make_tower_button(group: ButtonGroup, kind: TowerStats.Kind) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = group
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


## Writes the tower prices on the two build buttons, after the item discounts of
## [param modifiers], and rewrites them on every [signal PlayerModifiers.changed].
func bind_tower_build(stats: TowerStats, modifiers: PlayerModifiers) -> void:
	_tower_stats = stats
	_tower_modifiers = modifiers
	modifiers.changed.connect(_refresh_tower_prices)
	_refresh_tower_prices()


func _refresh_tower_prices() -> void:
	_cannon_button.text = "Canon — %d or" % _tower_modifiers.tower_cost(_tower_stats.cannon_cost)
	_frost_button.text = "Glace — %d or" % _tower_modifiers.tower_cost(_tower_stats.frost_cost)


## Shows the four ability boxes of [param caster], above the tower buttons.
func bind_abilities(caster: AbilityCaster) -> void:
	var bar := AbilityBar.new()
	add_child(bar)
	bar.setup(caster)


## Shows "Pas assez d'or" for about a second.
func show_not_enough_gold() -> void:
	_message_label.text = "Pas assez d'or"
	_message_label.visible = true
	_message_timer.start()


## Shows the specialization chosen for this game, top right, until the end of the game.
func show_specialization(spec: SpecializationDef) -> void:
	_spec_label.text = "Spécialisation : %s" % spec.display_name


## Shows the hero's stats panel (top right, under the specialization line) during BUILD
## and COMBAT. [param towers] gives the base tower ranges and prices for the item lines.
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


## Shows the hero's hit-point bar next to the crystal's. Call after the hero's setup.
func bind_hero(health: HeroHealth) -> void:
	var bar := HeroHealthBar.new()
	bar.position = HERO_BAR_POSITION
	add_child(bar)
	bar.bind(health)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	_hp_label.text = "Cristal : %d / %d" % [ceili(current_hp), ceili(max_hp)]


## Replaces the build prompt with the preview of the coming wave (call on each entry into BUILD).
func show_wave_preview(wave_number: int, enemy_count: int) -> void:
	_wave_preview = "Vague %d : %d ennemis — place tes tours, puis Espace" % [wave_number, enemy_count]
	if _state != null:
		_refresh_info()


## Shows wave number, gold, phase and the build prompt, and keeps them up to date.
func bind_game_state(state: GameState) -> void:
	_state = state
	state.gold_changed.connect(_refresh_info.unbind(1))
	state.wave_changed.connect(_refresh_info.unbind(1))
	state.phase_changed.connect(_refresh_info.unbind(1))
	_refresh_info()


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
	_build_box.visible = building
	if _stats_panel != null:
		_stats_panel.visible = _stats_visible()
	_info_label.text = "Vague : %d   Or : %d   Phase : %s" % [_state.wave_number, _state.gold, phase_name]
	var prompt: String = "Construction — Espace : lancer la vague %d" % (_state.wave_number + 1)
	if _wave_preview != "":
		prompt = _wave_preview
	_prompt_label.text = prompt if building else ""
