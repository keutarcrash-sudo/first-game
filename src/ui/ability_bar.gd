## The four ability discs ("badges pop"): per slot, back to front, an offset shadow,
## a glow, the role-coloured disc with a black outline, the ability icon, the dark
## cooldown clock with the seconds left, a tilted yellow key tag and the name below.
## Locked: grey disc, lock and grey name. Ready: slow breathing. A cooldown that ends
## during COMBAT pops with a white flash. Display only: reads an [AbilityCaster].
class_name AbilityBar
extends Control

const SLOTS: Array[StringName] = [&"primary", &"a", &"e", &"r"]
## Icon side as a share of the disc diameter (46 / 84 in the mockup).
const ICON_RATIO := 0.55
## Icon stroke as a share of the icon side.
const ICON_STROKE_RATIO := 0.085
const ARC_POINTS := 48
const GLOW_RINGS := 3
const GLOW_RING_STEP := 4.0  # Pixels between two glow rings.
const CLOCK_COLOR := Color(0.04, 0.016, 0.12, 0.82)
const FLASH_ALPHA := 0.85
const INK_COLOR := Color(0.96, 0.96, 1.0)
const LOCKED_INK_COLOR := Color("#6d6690")
const KEY_TAG_COLOR := Color("#ffe14d")
const KEY_TAG_ANGLE := 8.0  # Degrees, clockwise.
const KEY_TAG_PADDING := Vector2(7.0, 2.0)
const KEY_TAG_BORDER := 3.0
const KEY_TAG_SHADOW := Vector2(3.0, 3.0)
## Share of the key tag height that rises above the top of the disc (< 0.5, see plan).
const KEY_TAG_RISE := 0.4
## Smallest font size a long name may shrink to.
const MIN_NAME_FONT_SIZE := 10

var _caster: AbilityCaster
var _style: AbilityBarStyle
var _time := 0.0  # Seconds since setup, drives the breathing.
var _last_left: Dictionary = {}  # { slot: cooldown left seen on the previous frame }
var _pop_start: Dictionary = {}  # { slot: _time when its cooldown ended in COMBAT }


## Binds the bar to [param caster], drawn with [param style], and keeps it up to date.
func setup(caster: AbilityCaster, style: AbilityBarStyle) -> void:
	_caster = caster
	_style = style
	caster.cooldowns_changed.connect(queue_redraw)
	for slot: StringName in SLOTS:
		_last_left[slot] = caster.cooldown_left(slot)
	var total_width: float = style.disc_diameter * SLOTS.size() + style.spacing * (SLOTS.size() - 1)
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -total_width * 0.5
	offset_right = total_width * 0.5
	offset_bottom = -style.bottom_margin
	offset_top = -(style.bottom_band_height() - style.band_margin)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


## Height in screen pixels of the bottom HUD band in COMBAT (this bar and a small
## margin): what lies below it on screen is hidden. The one source of this value;
## [GameCamera] keeps the crystal above it.
static func bottom_band_height(style: AbilityBarStyle) -> float:
	return style.bottom_band_height()


func _process(delta: float) -> void:
	if _caster == null or _style == null:
		return
	_time += delta
	var in_combat: bool = _caster.is_in_combat()
	var animated := false
	for slot: StringName in SLOTS:
		var left: float = _caster.cooldown_left(slot)
		var before: float = float(_last_left.get(slot, 0.0))
		_last_left[slot] = left
		# Pop only when a running cooldown reaches 0 in COMBAT: an unlock, a new
		# specialization or a phase change never pops.
		if in_combat and before > 0.0 and left <= 0.0 and _caster.is_unlocked(slot):
			_pop_start[slot] = _time
		elif _pop_start.has(slot) and _time - float(_pop_start[slot]) >= _style.pop_duration:
			_pop_start.erase(slot)  # Pop over.
		if _caster.ability(slot) != null and _caster.is_unlocked(slot):
			animated = true  # Breathing, clock or pop: all move every frame.
	if animated:
		queue_redraw()


func _draw() -> void:
	if _caster == null or _style == null:
		return
	var title_font: Font = _font_or_fallback(NeonFonts.title())
	var number_font: Font = _font_or_fallback(NeonFonts.numbers())
	var radius: float = _style.disc_diameter * 0.5
	for i: int in SLOTS.size():
		var slot: StringName = SLOTS[i]
		var center := Vector2(radius + i * (_style.disc_diameter + _style.spacing), radius)
		var def: AbilityDef = _caster.ability(slot)
		var unlocked: bool = def != null and _caster.is_unlocked(slot)
		draw_set_transform(center, 0.0, Vector2.ONE * _disc_scale(slot, unlocked))
		_draw_disc(slot, def, unlocked, radius, number_font)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_key_tag(slot, center, radius, title_font)
		_draw_name(def, unlocked, center, title_font)


## Breathing while ready, pop right after a cooldown ends (no breathing meanwhile), else 1.
func _disc_scale(slot: StringName, unlocked: bool) -> float:
	if not unlocked:
		return 1.0
	if _pop_start.has(slot):
		var since: float = _time - float(_pop_start[slot])
		if since < _style.pop_duration:
			return _style.pop_scale(since)
	if _caster.cooldown_left(slot) > 0.0:
		return 1.0
	return _style.breath_scale(_time)


## Layers 1 to 5 around the origin (the transform places and scales the disc).
func _draw_disc(slot: StringName, def: AbilityDef, unlocked: bool, radius: float, number_font: Font) -> void:
	var color: Color = _style.color_of(slot) if unlocked else _style.locked_color
	draw_circle(_style.shadow_offset, radius, Color.BLACK)
	if unlocked:
		for k: int in GLOW_RINGS:
			var alpha: float = _style.glow_alpha * float(GLOW_RINGS - k) / float(GLOW_RINGS + 1)
			draw_circle(Vector2.ZERO, radius + GLOW_RING_STEP * (k + 1), Color(color, alpha * 0.5))
	draw_circle(Vector2.ZERO, radius, color)
	var icon_size: float = _style.disc_diameter * ICON_RATIO
	var stroke: float = icon_size * ICON_STROKE_RATIO
	if def == null:
		pass  # No ability in this slot: plain grey disc.
	elif unlocked:
		AbilityIcons.draw_icon(self, def.id, Vector2.ZERO, icon_size, Color.BLACK, stroke)
	else:
		AbilityIcons.draw_lock(self, Vector2.ZERO, icon_size, LOCKED_INK_COLOR, stroke)
	var inner: float = radius - _style.outline_px
	if unlocked:
		var left: float = _caster.cooldown_left(slot)
		if left > 0.0:
			_draw_clock(AbilityBarStyle.cooldown_fraction(left, _caster.cooldown_total(slot)), inner)
			_draw_centered_text(number_font, str(ceili(left)), Vector2.ZERO, _style.cooldown_font_size, INK_COLOR)
		if _pop_start.has(slot):
			var flash: float = _style.pop_flash(_time - float(_pop_start[slot]))
			if flash > 0.0:
				draw_circle(Vector2.ZERO, inner, Color(1.0, 1.0, 1.0, flash * FLASH_ALPHA))
	draw_arc(Vector2.ZERO, radius - _style.outline_px * 0.5, 0.0, TAU, ARC_POINTS, Color.BLACK, _style.outline_px, true)


## Dark sector covering [param fraction] of the disc, from noon, clockwise.
func _draw_clock(fraction: float, radius: float) -> void:
	if fraction <= 0.0:
		return
	if fraction >= 1.0:
		draw_circle(Vector2.ZERO, radius, CLOCK_COLOR)
		return
	var steps: int = maxi(2, ceili(ARC_POINTS * fraction))
	var points := PackedVector2Array([Vector2.ZERO])
	for i: int in steps + 1:
		# Screen y points down, so a growing angle turns clockwise; -PI/2 is noon.
		var angle: float = -PI * 0.5 + TAU * fraction * float(i) / float(steps)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, CLOCK_COLOR)


## Layer 6: yellow tag with the key, tilted, at the top right of the disc.
func _draw_key_tag(slot: StringName, center: Vector2, radius: float, font: Font) -> void:
	var text: String = str(_style.key_labels.get(slot, ""))
	var font_size: int = _style.key_font_size
	var tag_size := Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, float(font_size)) + KEY_TAG_PADDING * 2.0
	var right_limit: float = center.x + radius + _style.spacing * 0.4
	var tag_center := Vector2(minf(center.x + radius * 0.55, right_limit - tag_size.x * 0.5), center.y - radius + tag_size.y * (0.5 - KEY_TAG_RISE))
	var rect := Rect2(-tag_size * 0.5, tag_size)
	draw_set_transform(tag_center, deg_to_rad(KEY_TAG_ANGLE), Vector2.ONE)
	draw_rect(Rect2(rect.position + KEY_TAG_SHADOW, rect.size), Color.BLACK)
	draw_rect(rect, KEY_TAG_COLOR)
	draw_rect(rect, Color.BLACK, false, KEY_TAG_BORDER)
	_draw_centered_text(font, text, Vector2.ZERO, font_size, Color.BLACK, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Layer 7: the name under the disc, Bangers with a black outline, shrunk to fit its slot.
func _draw_name(def: AbilityDef, unlocked: bool, center: Vector2, font: Font) -> void:
	var text: String = "—" if def == null else def.display_name
	var outline: int = roundi(_style.outline_px)
	var room: float = _style.disc_diameter + _style.spacing - outline
	var font_size: int = _style.name_font_size
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if width > room:
		font_size = maxi(MIN_NAME_FONT_SIZE, floori(font_size * room / width))
	var baseline := Vector2(center.x - room * 0.5, _style.disc_diameter + _style.name_gap + font.get_ascent(font_size))
	var color: Color = INK_COLOR if unlocked else LOCKED_INK_COLOR
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, room, font_size, outline, Color.BLACK)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, room, font_size, color)


## [param text] centred on [param at], with a black outline when [param outline] > 0.
func _draw_centered_text(font: Font, text: String, at: Vector2, font_size: int, color: Color, outline: int = -1) -> void:
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := Vector2(at.x - text_size.x * 0.5, at.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	var outline_size: int = NeonFonts.OUTLINE_SIZE if outline < 0 else outline
	if outline_size > 0:
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _font_or_fallback(font: Font) -> Font:
	return font if font != null else ThemeDB.fallback_font
