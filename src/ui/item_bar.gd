## Row of the passive items owned (étape 5a, spec §8): one neon [ItemIcon] per
## item, in the order taken; hovering an icon shows its name and effect. The
## Seconde chance icon goes grey once the rescue has been used. Display only:
## reads [PlayerModifiers] and [HeroHealth], never changes them.
class_name ItemBar
extends Control

## Effect type of the one-time rescue item (Seconde chance).
const RESCUE_EFFECT := "second_chance"
const ICON_DIAMETER := 40.0
const ICON_SPACING := 8

var _modifiers: PlayerModifiers
var _row: HBoxContainer
var _rescue_used := false


## Binds the bar to [param modifiers] (items owned) and [param health] (rescue
## used) and keeps it up to date. Place and anchor the bar from the caller.
func setup(modifiers: PlayerModifiers, health: HeroHealth) -> void:
	_modifiers = modifiers
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _row == null:
		_row = HBoxContainer.new()
		_row.add_theme_constant_override(&"separation", ICON_SPACING)
		_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_row)
	modifiers.items_changed.connect(_rebuild)
	health.rescued.connect(_on_rescued)
	_rebuild()


func _rebuild() -> void:
	ItemCard.clear(_row)
	for item: ItemDef in _modifiers.owned_items():
		var icon := ItemIcon.new(item, ICON_DIAMETER)
		var spent: bool = _rescue_used and _is_rescue(item)
		icon.dimmed = spent
		icon.mouse_filter = Control.MOUSE_FILTER_STOP  # Needed for the hover tooltip.
		icon.tooltip_text = "%s\n%s%s" % [item.display_name, item.description, " (utilisée)" if spent else ""]
		_row.add_child(icon)
	custom_minimum_size = _row.get_combined_minimum_size()


func _is_rescue(item: ItemDef) -> bool:
	for effect: Dictionary in item.effects:
		if effect.get("type", "") == RESCUE_EFFECT:
			return true
	return false


func _on_rescued() -> void:
	_rescue_used = true
	_rebuild()
