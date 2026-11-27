## Reserve bar (towers T1): in BUILD, one small icon per owned tower waiting off
## the map, showing its type, its level and the first letter of its branch. A
## click on an icon asks for that tower to be placed by the next click on the
## field ([signal record_chosen], wired to [method TowerPlacer.select_record]).
## Display only: it never changes the reserve. When the towers do not fit its width,
## the last icon becomes a "+N" counter, so the bar never runs off-screen. An evolved
## tower (towers T2b) carries a golden star, and its evolution's name shows on hover.
class_name TowerReserveBar
extends HBoxContainer

## Emitted when the player clicks the icon of [param record].
signal record_chosen(record: TowerRecord)

## Height in screen pixels of the bar (read by [method CrystalHud.build_bottom_band_height]).
const HEIGHT := 40.0
const ICON_SIZE := Vector2(64.0, HEIGHT)
const ICON_SPACING := 8
const FONT_SIZE := 16
const SELECTED_COLOR := Color(1.0, 0.9, 0.35)
const BG_COLOR := Color(0.1, 0.1, 0.16, 0.9)
const BG_HOVER_COLOR := Color(0.16, 0.16, 0.24, 0.95)
const FRAME_WIDTH := 2
const SELECTED_FRAME_WIDTH := 4
const FRAME_RADIUS := 6
const STAR_COLOR := Color(1.0, 0.82, 0.2)
## Outer radius in pixels of the star of an evolved tower, and its inner/outer ratio.
const STAR_RADIUS := 6.0
const STAR_INNER_RATIO := 0.45
## Gap in pixels between the star and the icon's top right corner.
const STAR_MARGIN := 3.0

var _reserve: TowerReserve
var _placer: TowerPlacer
var _stats: TowerStats
var _rebuild_queued: bool = false


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Only the icons take clicks.
	add_theme_constant_override(&"separation", ICON_SPACING)


## Shows the towers waiting in [param reserve] and highlights the one [param placer]
## will place next; rebuilds on every change of either. [param stats] names the
## branches. Call once.
func setup(reserve: TowerReserve, placer: TowerPlacer, stats: TowerStats) -> void:
	_stats = stats
	_reserve = reserve
	_placer = placer
	reserve.changed.connect(_queue_rebuild)
	resized.connect(_queue_rebuild)
	placer.selection_changed.connect(_queue_rebuild)
	_rebuild()


## Short text of an icon: type letter (of [param kind_label]), level, and the first letter of the branch.
static func icon_text(record: TowerRecord, kind_label: String, branch_label: String) -> String:
	var kind_text: String = kind_label
	var text: String = "%s %d" % [kind_text.left(1), record.level]
	if branch_label != "":
		text += " %s" % branch_label.left(1)
	return text


## Rebuilds at the end of the frame: a change often comes from the press of an icon,
## which must not be freed while it is still emitting.
func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_queued = false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var selected: TowerRecord = _placer.selected_record()
	var waiting: Array[TowerRecord] = _reserve.available()
	var fits: int = maxi(1, floori((size.x + ICON_SPACING) / (ICON_SIZE.x + ICON_SPACING)))
	var shown: int = waiting.size() if waiting.size() <= fits else fits - 1
	for i: int in shown:
		add_child(_make_icon(waiting[i], waiting[i] == selected))
	if shown < waiting.size():
		add_child(_make_overflow_label(waiting.size() - shown))


func _make_overflow_label(hidden: int) -> Label:
	var label := Label.new()
	label.text = "+%d" % hidden
	label.custom_minimum_size = ICON_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	label.add_theme_color_override(&"font_color", SELECTED_COLOR)
	NeonFonts.style_label(label, NeonFonts.title())
	return label


func _make_icon(record: TowerRecord, selected: bool) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE  # Space starts the wave: a focused button must not react to it.
	button.custom_minimum_size = ICON_SIZE
	button.text = icon_text(record, TowerUpgradePanel.kind_label(_stats, record.kind), _branch_label(record))
	button.tooltip_text = icon_tooltip(record, _branch_label(record), _evolution_name(record))
	button.add_theme_font_size_override(&"font_size", FONT_SIZE)
	button.add_theme_font_override(&"font", NeonFonts.title())
	var def: TowerDef = _stats.def_of(record.kind)
	var color: Color = Color.WHITE if def == null else def.icon_color
	button.add_theme_color_override(&"font_color", color)
	button.add_theme_color_override(&"font_hover_color", color)
	var frame_color: Color = SELECTED_COLOR if selected else color
	var width: int = SELECTED_FRAME_WIDTH if selected else FRAME_WIDTH
	button.add_theme_stylebox_override(&"normal", _frame(frame_color, BG_COLOR, width))
	button.add_theme_stylebox_override(&"hover", _frame(frame_color, BG_HOVER_COLOR, width))
	button.add_theme_stylebox_override(&"pressed", _frame(SELECTED_COLOR, BG_HOVER_COLOR, SELECTED_FRAME_WIDTH))
	button.pressed.connect(_on_icon_pressed.bind(record))
	if record.evolved:
		button.add_child(_make_star())
	return button


## Hover text of an icon: the level, then the branch and the evolution's name when known.
static func icon_tooltip(record: TowerRecord, branch_label: String, evolution_name: String) -> String:
	var text: String = "Niveau %d" % record.level
	if branch_label != "":
		text += " · %s" % branch_label
	if record.evolved and evolution_name != "":
		text += " · %s" % evolution_name
	return text


## A small golden star drawn in the top right corner of an icon (no font glyph needed).
func _make_star() -> Control:
	var star := Control.new()
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.size = Vector2(STAR_RADIUS, STAR_RADIUS) * 2.0
	star.position = Vector2(ICON_SIZE.x - star.size.x - STAR_MARGIN, STAR_MARGIN)
	var points := PackedVector2Array()
	for i: int in 10:
		var reach: float = STAR_RADIUS if i % 2 == 0 else STAR_RADIUS * STAR_INNER_RATIO
		var angle: float = -PI / 2.0 + i * PI / 5.0
		points.append(Vector2(STAR_RADIUS, STAR_RADIUS) + Vector2.from_angle(angle) * reach)
	star.draw.connect(func() -> void: star.draw_colored_polygon(points, STAR_COLOR))
	return star


func _evolution_name(record: TowerRecord) -> String:
	var def: TowerDef = _stats.def_of(record.kind)
	return "" if def == null else def.evolution_name(record.branch)


func _branch_label(record: TowerRecord) -> String:
	if record.branch == &"":
		return ""
	return TowerUpgradePanel.branch_label(_stats, record.kind, record.branch)


static func _frame(color: Color, background: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = color
	style.set_border_width_all(width)
	style.set_corner_radius_all(FRAME_RADIUS)
	return style


func _on_icon_pressed(record: TowerRecord) -> void:
	record_chosen.emit(record)
