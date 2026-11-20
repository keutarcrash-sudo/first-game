## World map screen (étape 5a, spec §6.1): read left to right, the start, the
## columns of places and the « VAGUE FINALE » flag; lines between linked places;
## a neon icon per place type (shop, treasure, rest, drawn in code); the current
## place marked; the travelled path highlighted; places no longer reachable
## dimmed; a one-line tooltip on hover; the next wave's preview in a corner and
## « Monde X » as title. In choosing mode the reachable places blink and a click
## on one enters it ([signal place_chosen]); in consultation mode a « C'est parti ! »
## button closes it ([signal closed]). Owns no game state: it reads the [WorldRun].
class_name WorldMapScreen
extends CanvasLayer

## Emitted in choosing mode when the player clicks a reachable place of the next
## column ([param index] in that column). The screen hides itself first.
signal place_chosen(index: int)
## Emitted in consultation mode when the player clicks « C'est parti ! ». The screen hides itself first.
signal closed

const PLACE_RADIUS := 26.0
const START_RADIUS := 14.0
const MAP_SIDE_MARGIN := 120.0
const MAP_TOP := 110.0
const MAP_BOTTOM := 150.0
const RING_WIDTH := 3.0
const GLOW_WIDTH := 10.0
const GLOW_GAP := 5.0
const GLOW_ALPHA := 0.3
const CURRENT_RING_GAP := 9.0
const PATH_RING_GAP := 4.0
const HOVER_GROWTH := 1.15
const LINK_WIDTH := 3.0
const PATH_WIDTH := 6.0
const ARC_POINTS := 48
const BLINK_SPEED := 6.0  # Radians per second of the reachable places' pulse.
const DIM_FACTOR := 0.7  # How much darker a place no longer reachable is.
const ICON_RATIO := 0.5  # Icon half-size as a share of the place radius.
const ICON_WIDTH := 2.5
const FLAG_HEIGHT := 60.0
const FLAG_WIDTH := 34.0
const LABEL_FONT_SIZE := 22
const LABEL_WIDTH := 220.0
const LABEL_GAP := 30.0  # From the shape's centre down to the label's baseline.
const LABEL_OUTLINE := 6
const PREVIEW_FONT_SIZE := 24
const HINT_FONT_SIZE := 26
const FOOTER_MARGIN := 40.0
const FOOTER_HEIGHT := 70.0
const PREVIEW_WIDTH := 760.0
const GO_BUTTON_SIZE := Vector2(300.0, 60.0)
const FILL_COLOR := Color("#1c1340")
const LINK_COLOR := Color(0.55, 0.9, 1.0, 0.55)
const PATH_COLOR := Color(1.0, 0.9, 0.35)
const CURRENT_COLOR := Color(1.0, 1.0, 1.0)
const START_COLOR := Color(0.55, 0.9, 1.0)
const FLAG_COLOR := Color(1.0, 0.3, 0.75)
const SHOP_COLOR := Color(1.0, 0.85, 0.2)
const TREASURE_COLOR := Color(1.0, 0.35, 0.85)
const REST_COLOR := Color(0.3, 1.0, 0.55)
const PREVIEW_COLOR := Color(0.55, 0.9, 1.0)
const HINT_COLOR := Color(1.0, 0.9, 0.35)

var _run: WorldRun
var _choosing := false
var _reachable: PackedInt32Array = PackedInt32Array()
var _open_places: Dictionary = {}  # Vector2i(column, index) -> true: places still reachable ahead.
var _hovered := Vector2i(-1, -1)
var _buttons: Array[Button] = []
var _button_places: Array[Vector2i] = []
var _canvas: Control
var _title_label: Label
var _preview_label: Label
var _hint_label: Label
var _go_button: Button


func _init() -> void:
	layer = ItemCard.SCREEN_LAYER
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Works while the game is paused.


func _ready() -> void:
	set_process(false)  # Only the choosing mode animates (blinking places).
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP  # Clicks never reach the game below.
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = ItemCard.DIM_COLOR
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.offset_left = MAP_SIDE_MARGIN
	_canvas.offset_right = -MAP_SIDE_MARGIN
	_canvas.offset_top = MAP_TOP
	_canvas.offset_bottom = -MAP_BOTTOM
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Only the place buttons take clicks.
	root.add_child(_canvas)
	_canvas.draw.connect(_draw_map)
	_canvas.resized.connect(_place_buttons)
	_title_label = _make_label(ItemCard.TITLE_FONT_SIZE, ItemCard.TEXT_COLOR)
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title_label.offset_top = FOOTER_MARGIN
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_title_label)
	_preview_label = _make_label(PREVIEW_FONT_SIZE, PREVIEW_COLOR)
	_preview_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_preview_label.offset_left = FOOTER_MARGIN
	_preview_label.offset_right = FOOTER_MARGIN + PREVIEW_WIDTH
	_preview_label.offset_top = -(FOOTER_MARGIN + FOOTER_HEIGHT)
	_preview_label.offset_bottom = -FOOTER_MARGIN
	_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_preview_label)
	_hint_label = _make_label(HINT_FONT_SIZE, HINT_COLOR)
	_hint_label.text = "Choisis ton prochain lieu"
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint_label.offset_left = -(FOOTER_MARGIN + LABEL_WIDTH * 2.0)
	_hint_label.offset_right = -FOOTER_MARGIN
	_hint_label.offset_top = -(FOOTER_MARGIN + FOOTER_HEIGHT)
	_hint_label.offset_bottom = -FOOTER_MARGIN
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(_hint_label)
	_go_button = ItemCard.make_button("C'est parti !", GO_BUTTON_SIZE)
	_go_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_go_button.offset_left = -(FOOTER_MARGIN + GO_BUTTON_SIZE.x)
	_go_button.offset_right = -FOOTER_MARGIN
	_go_button.offset_top = -(FOOTER_MARGIN + GO_BUTTON_SIZE.y)
	_go_button.offset_bottom = -FOOTER_MARGIN
	var font: Font = NeonFonts.title()
	if font != null:
		_go_button.add_theme_font_override(&"font", font)
	ItemCard.apply_frame(_go_button, PREVIEW_COLOR)
	_go_button.pressed.connect(_on_go_pressed)
	root.add_child(_go_button)


func _process(_delta: float) -> void:
	_canvas.queue_redraw()  # The reachable places blink.


## Shows the map of [param run] with [param preview_text] (the next wave's number
## and enemies) in the bottom-left corner. [param choosing] [code]true[/code]: the
## reachable places blink and a click on one emits [signal place_chosen];
## [code]false[/code]: consultation, closed by « C'est parti ! » ([signal closed]).
## The screen must be in the tree.
func open(run: WorldRun, preview_text: String, choosing: bool) -> void:
	_run = run
	_choosing = choosing
	_reachable = run.reachable() if choosing else PackedInt32Array()
	_open_places = _places_ahead(run)
	_hovered = Vector2i(-1, -1)
	_title_label.text = "Monde %d" % run.world
	_preview_label.text = "Prochaine vague — %s" % preview_text
	_hint_label.visible = choosing
	_go_button.visible = not choosing
	_rebuild_buttons()
	visible = true
	set_process(choosing)
	_canvas.queue_redraw()


## Every place of the columns ahead that can still be reached from the player's place.
static func _places_ahead(run: WorldRun) -> Dictionary:
	var result: Dictionary = {}
	if run.map == null:
		return result
	var frontier: PackedInt32Array = run.reachable()
	var column: int = run.column + 1
	while column < run.map.columns.size() and not frontier.is_empty():
		var next: PackedInt32Array = PackedInt32Array()
		for index: int in frontier:
			result[Vector2i(column, index)] = true
			for link: int in run.map.links_of(column, index):
				if not next.has(link):
					next.append(link)
		frontier = next
		column += 1
	return result


func _rebuild_buttons() -> void:
	for button: Button in _buttons:
		button.queue_free()
	_buttons.clear()
	_button_places.clear()
	if _run.map == null:
		return
	for column: int in _run.map.columns.size():
		for index: int in _run.map.size_of(column):
			var place := Vector2i(column, index)
			var button := Button.new()
			button.flat = true
			button.focus_mode = Control.FOCUS_NONE
			button.custom_minimum_size = Vector2(PLACE_RADIUS, PLACE_RADIUS) * 2.0
			button.tooltip_text = _tooltip(_run.map.type_of(column, index))
			if _is_choosable(place):
				button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.pressed.connect(_on_place_pressed.bind(place))
			button.mouse_entered.connect(_on_place_hovered.bind(place, true))
			button.mouse_exited.connect(_on_place_hovered.bind(place, false))
			_canvas.add_child(button)
			_buttons.append(button)
			_button_places.append(place)
	_place_buttons()


func _place_buttons() -> void:
	if _run == null or _run.map == null:
		return
	for i: int in _buttons.size():
		var place: Vector2i = _button_places[i]
		_buttons[i].size = Vector2(PLACE_RADIUS, PLACE_RADIUS) * 2.0
		_buttons[i].position = _place_position(place.x, place.y) - Vector2(PLACE_RADIUS, PLACE_RADIUS)


## Centre of place [param index] of column [param column], in the canvas.
func _place_position(column: int, index: int) -> Vector2:
	var step: float = _canvas.size.x / float(_run.map.columns.size() + 1)
	var count: int = _run.map.size_of(column)
	return Vector2(step * float(column + 1), _canvas.size.y * float(index + 1) / float(count + 1))


func _start_position() -> Vector2:
	return Vector2(0.0, _canvas.size.y * 0.5)


func _flag_position() -> Vector2:
	return Vector2(_canvas.size.x, _canvas.size.y * 0.5)


func _is_passed(column: int, index: int) -> bool:
	return column < _run.visited.size() and _run.visited[column] == index


func _is_dimmed(column: int, index: int) -> bool:
	return not _is_passed(column, index) and not _open_places.has(Vector2i(column, index))


func _is_choosable(place: Vector2i) -> bool:
	return _choosing and place.x == _run.column + 1 and _reachable.has(place.y)


func _draw_map() -> void:
	if _run == null or _run.map == null or not visible:
		return
	var map: WorldMap = _run.map
	var last: int = map.columns.size() - 1
	for index: int in map.size_of(0):
		_draw_link(_start_position(), _place_position(0, index), _is_passed(0, index), _is_dimmed(0, index))
	for column: int in last:
		for index: int in map.size_of(column):
			for link: int in map.links_of(column, index):
				var travelled: bool = _is_passed(column, index) and _is_passed(column + 1, link)
				var dimmed: bool = _is_dimmed(column, index) or _is_dimmed(column + 1, link)
				_draw_link(_place_position(column, index), _place_position(column + 1, link), travelled, dimmed)
	for index: int in map.size_of(last):
		_draw_link(_place_position(last, index), _flag_position(), false, _is_dimmed(last, index))
	_draw_start()
	_draw_flag()
	for column: int in map.columns.size():
		for index: int in map.size_of(column):
			_draw_place(column, index)


func _draw_link(from: Vector2, to: Vector2, travelled: bool, dimmed: bool) -> void:
	if travelled:
		_canvas.draw_line(from, to, PATH_COLOR, PATH_WIDTH, true)
		return
	var color: Color = LINK_COLOR.darkened(DIM_FACTOR) if dimmed else LINK_COLOR
	_canvas.draw_line(from, to, color, LINK_WIDTH, true)


func _draw_start() -> void:
	var center: Vector2 = _start_position()
	var color: Color = PATH_COLOR if _run.column >= 0 else START_COLOR
	_canvas.draw_circle(center, START_RADIUS, color)
	if _run.column < 0:
		_canvas.draw_arc(center, START_RADIUS + CURRENT_RING_GAP, 0.0, TAU, ARC_POINTS, CURRENT_COLOR, RING_WIDTH, true)
	_draw_label("Départ", center + Vector2(0.0, START_RADIUS + LABEL_GAP), START_COLOR)


func _draw_flag() -> void:
	var foot: Vector2 = _flag_position() + Vector2(0.0, FLAG_HEIGHT * 0.5)
	var top: Vector2 = foot - Vector2(0.0, FLAG_HEIGHT)
	_canvas.draw_line(foot, top, FLAG_COLOR, RING_WIDTH, true)
	var cloth := PackedVector2Array([top, top + Vector2(FLAG_WIDTH, FLAG_HEIGHT * 0.2), top + Vector2(0.0, FLAG_HEIGHT * 0.4)])
	_canvas.draw_colored_polygon(cloth, FLAG_COLOR)
	_draw_label("VAGUE FINALE", foot + Vector2(0.0, LABEL_GAP), FLAG_COLOR)


func _draw_place(column: int, index: int) -> void:
	var place := Vector2i(column, index)
	var center: Vector2 = _place_position(column, index)
	var type: StringName = _run.map.type_of(column, index)
	var color: Color = _place_color(type)
	var radius: float = PLACE_RADIUS
	var glow_alpha: float = GLOW_ALPHA
	var dimmed: bool = _is_dimmed(column, index)
	if dimmed:
		color = color.darkened(DIM_FACTOR)
		glow_alpha = 0.0
	if _is_choosable(place):
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * BLINK_SPEED)
		glow_alpha = GLOW_ALPHA + (1.0 - GLOW_ALPHA) * pulse
		color = color.lightened(0.4 * pulse)
		if place == _hovered:
			radius *= HOVER_GROWTH
	if glow_alpha > 0.0:
		_canvas.draw_arc(center, radius + GLOW_GAP, 0.0, TAU, ARC_POINTS, Color(color, glow_alpha), GLOW_WIDTH, true)
	_canvas.draw_circle(center, radius, FILL_COLOR)
	_canvas.draw_arc(center, radius, 0.0, TAU, ARC_POINTS, color, RING_WIDTH, true)
	_draw_icon(type, center, radius * ICON_RATIO, color)
	if _is_passed(column, index):
		_canvas.draw_arc(center, radius + PATH_RING_GAP, 0.0, TAU, ARC_POINTS, PATH_COLOR, RING_WIDTH, true)
	if column == _run.column and index == _run.node:
		_canvas.draw_arc(center, radius + CURRENT_RING_GAP, 0.0, TAU, ARC_POINTS, CURRENT_COLOR, RING_WIDTH, true)
		_draw_label("Tu es ici", center + Vector2(0.0, radius + LABEL_GAP), CURRENT_COLOR)


## Neon shapes: a stall with its roof (shop), a chest with its lid and lock
## (treasure), a crescent moon (rest). [param size] is the icon's half-size.
func _draw_icon(type: StringName, center: Vector2, size: float, color: Color) -> void:
	if type == WorldMap.SHOP:
		_canvas.draw_rect(Rect2(center + Vector2(-size * 0.8, -size * 0.1), Vector2(size * 1.6, size * 1.0)), color, false, ICON_WIDTH, true)
		var roof := PackedVector2Array([center + Vector2(-size * 1.1, -size * 0.1), center + Vector2(0.0, -size * 1.0), center + Vector2(size * 1.1, -size * 0.1)])
		_canvas.draw_polyline(roof, color, ICON_WIDTH, true)
	elif type == WorldMap.TREASURE:
		_canvas.draw_rect(Rect2(center + Vector2(-size, -size * 0.3), Vector2(size * 2.0, size * 1.2)), color, false, ICON_WIDTH, true)
		var lid := PackedVector2Array([center + Vector2(-size, -size * 0.3), center + Vector2(-size * 0.7, -size * 0.9), center + Vector2(size * 0.7, -size * 0.9), center + Vector2(size, -size * 0.3)])
		_canvas.draw_polyline(lid, color, ICON_WIDTH, true)
		_canvas.draw_circle(center + Vector2(0.0, size * 0.15), size * 0.2, color)
	else:
		_canvas.draw_circle(center, size, color)
		_canvas.draw_circle(center + Vector2(size * 0.45, -size * 0.3), size * 0.85, FILL_COLOR)


func _draw_label(text: String, baseline_center: Vector2, color: Color) -> void:
	var font: Font = NeonFonts.title()
	if font == null:
		return
	var origin := Vector2(baseline_center.x - LABEL_WIDTH * 0.5, baseline_center.y)
	_canvas.draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, LABEL_WIDTH, LABEL_FONT_SIZE, LABEL_OUTLINE, Color.BLACK)
	_canvas.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, LABEL_WIDTH, LABEL_FONT_SIZE, color)


static func _place_color(type: StringName) -> Color:
	if type == WorldMap.SHOP:
		return SHOP_COLOR
	if type == WorldMap.TREASURE:
		return TREASURE_COLOR
	return REST_COLOR


## The place's name and what it offers, in one line (spec §6.1).
static func _tooltip(type: StringName) -> String:
	if type == WorldMap.SHOP:
		return "Magasin — des objets à acheter et la réparation du cristal"
	if type == WorldMap.TREASURE:
		return "Trésor — un objet gratuit au choix"
	return "Repos — soigner le héros ou réparer le cristal"


func _make_label(font_size: int, color: Color) -> Label:
	var label: Label = ItemCard.make_label("", font_size, color)
	var font: Font = NeonFonts.title()
	if font != null:
		NeonFonts.style_label(label, font)
	return label


func _on_place_hovered(place: Vector2i, entered: bool) -> void:
	if entered:
		_hovered = place
	elif _hovered == place:
		_hovered = Vector2i(-1, -1)
	_canvas.queue_redraw()


func _on_place_pressed(place: Vector2i) -> void:
	if not _is_choosable(place):
		return
	_choosing = false
	visible = false
	set_process(false)
	place_chosen.emit(place.y)


func _on_go_pressed() -> void:
	visible = false
	set_process(false)
	closed.emit()
