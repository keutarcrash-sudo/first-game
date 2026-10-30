## On-screen display (story 002): crystal hit points and the defeat message.
## Only listens to the crystal's signals; knows nothing else about the game.
class_name CrystalHud
extends CanvasLayer

const HP_FONT_SIZE := 20
const DEFEAT_FONT_SIZE := 56
const HP_POSITION := Vector2(40.0, 2.0)
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const DEFEAT_COLOR := Color(1.0, 0.4, 0.35)

var _hp_label: Label
var _defeat_label: Label


func _ready() -> void:
	_hp_label = Label.new()
	_hp_label.position = HP_POSITION
	_hp_label.add_theme_font_size_override(&"font_size", HP_FONT_SIZE)
	_hp_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	add_child(_hp_label)
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
