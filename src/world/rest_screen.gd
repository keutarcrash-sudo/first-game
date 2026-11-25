## Rest screen (étape 5a, spec §7.3): two choices, only one possible — heal the
## hero or repair the crystal. Shows the real amounts given by the caller. Owns
## no game state: it only emits [signal hero_chosen] or [signal crystal_chosen].
## A choice whose target is already full is greyed out (« PV au max »); when both
## are, « Retour à la carte » emits [signal back_requested] instead.
class_name RestScreen
extends CanvasLayer

## Emitted when the player picks the hero heal. The screen hides itself first.
signal hero_chosen
## Emitted when the player picks the crystal repair. The screen hides itself first.
signal crystal_chosen
## Emitted by « Retour à la carte » (offered only when hero and crystal are both
## full). The screen hides itself first.
signal back_requested

const CHOICE_SIZE := Vector2(300.0, 160.0)
const BACK_BUTTON_SIZE := Vector2(320.0, 56.0)
const FULL_TEXT := "PV au max"

var _hero_button: Button
var _crystal_button: Button
var _back_button: Button


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
	var actions: HBoxContainer = ItemCard.make_row()
	column.add_child(actions)
	_back_button = ItemCard.make_button("Retour à la carte", BACK_BUTTON_SIZE)
	_back_button.pressed.connect(_on_back_pressed)
	actions.add_child(_back_button)


## Opens the screen: the hero choice heals [param hero_heal] hit points (already
## computed from the hero's maximum), the crystal choice repairs [param crystal_heal].
## [param hero_full] / [param crystal_full]: that target is at its maximum, its
## choice is disabled; both full shows « Retour à la carte ». The screen must be in the tree.
func open(hero_heal: float, crystal_heal: float, hero_full: bool, crystal_full: bool) -> void:
	_hero_button.text = "Soigner le héros\n%s" % (FULL_TEXT if hero_full else "+%d PV" % roundi(hero_heal))
	_hero_button.disabled = hero_full
	_crystal_button.text = "Réparer le cristal\n%s" % (FULL_TEXT if crystal_full else "+%d PV" % roundi(crystal_heal))
	_crystal_button.disabled = crystal_full
	_back_button.visible = hero_full and crystal_full
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


func _on_back_pressed() -> void:
	visible = false
	back_requested.emit()
