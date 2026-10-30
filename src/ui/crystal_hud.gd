## On-screen display: crystal hit points and the defeat message (story 002),
## wave number, gold, phase and the build-phase prompt (story 003). Only listens
## to signals; never changes game state. Extended rather than duplicated so the
## game keeps a single CanvasLayer.
class_name CrystalHud
extends CanvasLayer

const HP_FONT_SIZE := 20
const DEFEAT_FONT_SIZE := 56
const INFO_FONT_SIZE := 20
const INFO_POSITION := Vector2(40.0, 30.0)
const PROMPT_FONT_SIZE := 32
const PROMPT_BOTTOM_MARGIN := 24.0
const PROMPT_COLOR := Color(0.55, 0.9, 1.0)
const HP_POSITION := Vector2(40.0, 2.0)
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const DEFEAT_COLOR := Color(1.0, 0.4, 0.35)

var _hp_label: Label
var _defeat_label: Label
var _info_label: Label
var _prompt_label: Label
var _state: GameState


func _ready() -> void:
	_hp_label = Label.new()
	_hp_label.position = HP_POSITION
	_hp_label.add_theme_font_size_override(&"font_size", HP_FONT_SIZE)
	_hp_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	add_child(_hp_label)
	_info_label = Label.new()
	_info_label.position = INFO_POSITION
	_info_label.add_theme_font_size_override(&"font_size", INFO_FONT_SIZE)
	_info_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	add_child(_info_label)
	_prompt_label = Label.new()
	_prompt_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prompt_label.offset_bottom = -PROMPT_BOTTOM_MARGIN
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_prompt_label.add_theme_font_size_override(&"font_size", PROMPT_FONT_SIZE)
	_prompt_label.add_theme_color_override(&"font_color", PROMPT_COLOR)
	add_child(_prompt_label)
	_defeat_label = Label.new()
	_defeat_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_defeat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_defeat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_defeat_label.add_theme_font_size_override(&"font_size", DEFEAT_FONT_SIZE)
	_defeat_label.add_theme_color_override(&"font_color", DEFEAT_COLOR)
	_defeat_label.text = "Cristal détruit"
	_defeat_label.visible = false
	add_child(_defeat_label)


## Shows the crystal's hit points and keeps them up to date. Call after the crystal's setup.
func bind(crystal: Crystal) -> void:
	_on_health_changed(crystal.current_hp, crystal.max_hp)
	crystal.health_changed.connect(_on_health_changed)
	crystal.destroyed.connect(_on_crystal_destroyed)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	_hp_label.text = "Cristal : %d / %d" % [ceili(current_hp), ceili(max_hp)]


func _on_crystal_destroyed() -> void:
	_defeat_label.visible = true


## Shows wave number, gold, phase and the build prompt, and keeps them up to date.
func bind_game_state(state: GameState) -> void:
	_state = state
	state.gold_changed.connect(_refresh_info.unbind(1))
	state.wave_changed.connect(_refresh_info.unbind(1))
	state.phase_changed.connect(_refresh_info.unbind(1))
	_refresh_info()


func _refresh_info() -> void:
	var building: bool = _state.phase == GameState.Phase.BUILD
	var phase_name: String = "Construction" if building else "Combat"
	_info_label.text = "Vague : %d   Or : %d   Phase : %s" % [_state.wave_number, _state.gold, phase_name]
	_prompt_label.text = "Construction — Espace : lancer la vague %d" % (_state.wave_number + 1) if building else ""
