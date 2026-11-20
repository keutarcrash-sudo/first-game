## Rest screen (étape 5a, spec §7.3): two choices, only one possible — heal the
## hero or repair the crystal. Shows the real amounts given by the caller. Owns
## no game state: it only emits [signal hero_chosen] or [signal crystal_chosen].
class_name RestScreen
extends CanvasLayer

## Emitted when the player picks the hero heal. The screen hides itself first.
signal hero_chosen
## Emitted when the player picks the crystal repair. The screen hides itself first.
signal crystal_chosen

const CHOICE_SIZE := Vector2(300.0, 160.0)

var _hero_button: Button
var _crystal_button: Button


func _init() -> void:
	layer = ItemCard.SCREEN_LAYER
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Works while the game is paused.


func _ready() -> void:
	var column: VBoxContainer = ItemCard.build_overlay(self, "Repos : un seul choix")
	var row: HBoxContainer = ItemCard.make_row()
	column.add_child(row)
	_hero_button = _make_choice(ItemIcon.category_color(&"survival"))
	_hero_button.pressed.connect(_on_choice_pressed.bind(true))
	row.add_child(_hero_button)
	_crystal_button = _make_choice(ItemIcon.category_color(&"utility"))
	_crystal_button.pressed.connect(_on_choice_pressed.bind(false))
	row.add_child(_crystal_button)


## Opens the screen: the hero choice heals [param hero_heal] hit points (already
## computed from the hero's maximum), the crystal choice repairs [param crystal_heal].
## The screen must be in the tree.
func open(hero_heal: float, crystal_heal: float) -> void:
	_hero_button.text = "Soigner le héros\n+%d PV" % roundi(hero_heal)
	_crystal_button.text = "Réparer le cristal\n+%d PV" % roundi(crystal_heal)
	visible = true


func _make_choice(color: Color) -> Button:
	var button: Button = ItemCard.make_button("", CHOICE_SIZE)
	button.add_theme_color_override(&"font_color", color)
	button.add_theme_color_override(&"font_hover_color", color.lightened(0.3))
	ItemCard.apply_frame(button, color)
	return button


func _on_choice_pressed(hero: bool) -> void:
	visible = false
	if hero:
		hero_chosen.emit()
	else:
		crystal_chosen.emit()
