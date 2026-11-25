## Hit-point line of the HUD (étape 4, spec §5): a "Héros x/y" label followed by a
## neon bar. The top-left block of [CrystalHud] stacks two of them: the crystal's
## ([member title] "Cristal", fed by [method show_values]) and the hero's
## ([method bind]). Display only: it never changes game state.
class_name HeroHealthBar
extends Control

const BAR_SIZE := Vector2(200.0, 16.0)
const FONT_SIZE := 20
const LABEL_WIDTH := 230.0  # Room for "Cristal 999/999" in the Bungee title font.
const BAR_TOP := 7.0  # Vertically centres the bar on a 20 px label line (~30 px tall).
const BACK_COLOR := Color(0.05, 0.08, 0.15, 0.8)
const FILL_COLOR := Color(0.2, 1.0, 0.55)
const LOW_COLOR := Color(1.0, 0.3, 0.3)
const LOW_FRACTION := 0.3
const BORDER_COLOR := Color(0.55, 0.9, 1.0)
const TEXT_COLOR := Color(0.9, 0.95, 1.0)

## Name written before the values. Set it before adding the bar to the tree.
var title: String = "Héros"

var _label: Label
var _fraction := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(LABEL_WIDTH + BAR_SIZE.x, BAR_SIZE.y)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	NeonFonts.style_label(_label, NeonFonts.title())
	add_child(_label)


## Shows [param health] and keeps the bar up to date.
func bind(health: HeroHealth) -> void:
	_on_changed(health.current, health.max_hp)
	health.changed.connect(_on_changed)


## Shows [param current] out of [param max_hp] (label and bar). Call after the bar is in the tree.
func show_values(current: float, max_hp: float) -> void:
	_on_changed(current, max_hp)


func _on_changed(current: float, max_hp: float) -> void:
	_fraction = clampf(current / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
	_label.text = "%s %d/%d" % [title, ceili(current), ceili(max_hp)]
	queue_redraw()


func _draw() -> void:
	var bar := Rect2(Vector2(LABEL_WIDTH, BAR_TOP), BAR_SIZE)
	draw_rect(bar, BACK_COLOR)
	var color: Color = LOW_COLOR if _fraction <= LOW_FRACTION else FILL_COLOR
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _fraction, bar.size.y)), color)
	draw_rect(bar, BORDER_COLOR, false, 2.0)
