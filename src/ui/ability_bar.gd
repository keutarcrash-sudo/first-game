## The four ability boxes (étape 3a): key, ability name, and during a cooldown a
## dark veil with the seconds left (rounded up). A box without ability shows "—".
## Display only: reads an [AbilityCaster], never changes it.
class_name AbilityBar
extends Control

const SLOTS: Array[StringName] = [&"primary", &"a", &"e", &"r"]
const KEY_LABELS := {&"primary": "Clic droit", &"a": "A", &"e": "E", &"r": "R"}
const BOX_SIZE := Vector2(150.0, 56.0)
const BOX_SPACING := 12.0
const BOTTOM_MARGIN := 120.0  # Just above the tower buttons.
const KEY_FONT_SIZE := 14
const NAME_FONT_SIZE := 16
const COOLDOWN_FONT_SIZE := 26
const BOX_COLOR := Color(0.12, 0.14, 0.2, 0.85)
const BORDER_COLOR := Color(0.4, 0.45, 0.6)
const VEIL_COLOR := Color(0.0, 0.0, 0.0, 0.65)
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const EMPTY_COLOR := Color(0.5, 0.5, 0.55)
const KEY_COLOR := Color(1.0, 0.9, 0.35)

var _caster: AbilityCaster


## Binds the bar to [param caster] and keeps it up to date.
func setup(caster: AbilityCaster) -> void:
	_caster = caster
	caster.cooldowns_changed.connect(queue_redraw)
	var total_width: float = BOX_SIZE.x * SLOTS.size() + BOX_SPACING * (SLOTS.size() - 1)
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -total_width * 0.5
	offset_right = total_width * 0.5
	offset_top = -(BOTTOM_MARGIN + BOX_SIZE.y)
	offset_bottom = -BOTTOM_MARGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(_delta: float) -> void:
	# Smooth veil while a cooldown runs.
	if _caster == null:
		return
	for slot: StringName in SLOTS:
		if _caster.cooldown_left(slot) > 0.0:
			queue_redraw()
			return


func _draw() -> void:
	if _caster == null:
		return
	var font: Font = ThemeDB.fallback_font
	for i: int in SLOTS.size():
		var slot: StringName = SLOTS[i]
		var box := Rect2(Vector2(i * (BOX_SIZE.x + BOX_SPACING), 0.0), BOX_SIZE)
		draw_rect(box, BOX_COLOR)
		draw_rect(box, BORDER_COLOR, false, 2.0)
		var def: AbilityDef = _caster.ability(slot)
		draw_string(font, box.position + Vector2(6.0, 16.0), KEY_LABELS[slot], HORIZONTAL_ALIGNMENT_LEFT, BOX_SIZE.x - 12.0, KEY_FONT_SIZE, KEY_COLOR if def != null else EMPTY_COLOR)
		if def == null:
			draw_string(font, box.position + Vector2(0.0, 42.0), "—", HORIZONTAL_ALIGNMENT_CENTER, BOX_SIZE.x, NAME_FONT_SIZE, EMPTY_COLOR)
			continue
		draw_string(font, box.position + Vector2(0.0, 44.0), def.display_name, HORIZONTAL_ALIGNMENT_CENTER, BOX_SIZE.x, NAME_FONT_SIZE, TEXT_COLOR)
		var left: float = _caster.cooldown_left(slot)
		if left > 0.0:
			draw_rect(box, VEIL_COLOR)
			draw_string(font, box.position + Vector2(0.0, 38.0), str(ceili(left)), HORIZONTAL_ALIGNMENT_CENTER, BOX_SIZE.x, COOLDOWN_FONT_SIZE, TEXT_COLOR)
