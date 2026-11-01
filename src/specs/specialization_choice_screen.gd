## Specialization choice screen (story 008, design/game-brief.md « Après le MVP »):
## opens at the start of every game, before anything else, dims the arena and
## shows the unlocked specializations side by side. The player clicks one with
## the mouse; buttons take no keyboard focus, so Space does nothing here. Owns no
## game state: it only emits [signal specialization_chosen].
class_name SpecializationChoiceScreen
extends CanvasLayer

## Emitted when the player clicks a specialization. The screen hides itself first.
signal specialization_chosen(spec: SpecializationDef)

const SCREEN_LAYER := 10  # Same layer as the card choice screen; both never show at once.
const DIM_COLOR := Color(0.0, 0.0, 0.05, 0.85)
const TITLE_FONT_SIZE := 38
const NAME_FONT_SIZE := 30
const TEXT_FONT_SIZE := 20
const STATS_FONT_SIZE := 17
const NOTE_FONT_SIZE := 20
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const NAME_COLOR := Color(1.0, 0.9, 0.35)
const STATS_COLOR := Color(0.55, 0.9, 1.0)
const NOTE_COLOR := Color(0.6, 0.63, 0.72)
const PANEL_SIZE := Vector2(320.0, 320.0)
const PANEL_PADDING := 16.0
const PANEL_SPACING := 28
const SCREEN_SIDE_MARGIN := 40.0  # Minimum free space left and right of the row.
const TEXT_SPACING := 14
const COLUMN_SPACING := 32

var _row: HBoxContainer


func _init() -> void:
	layer = SCREEN_LAYER
	visible = false


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP  # Clicks never reach the arena below.
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = DIM_COLOR
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", COLUMN_SPACING)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	var title: Label = _make_label("Choisis ta spécialisation", TITLE_FONT_SIZE, TEXT_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override(&"separation", PANEL_SPACING)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_row)
	var note: Label = _make_label("D'autres spécialisations se débloqueront dans l'arbre", NOTE_FONT_SIZE, NOTE_COLOR)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)


## Shows [param specs] (one clickable panel each, even when there is only one)
## and waits for a click. Panels narrow when needed so the row fits the screen.
func show_specs(specs: Array[SpecializationDef]) -> void:
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var free_width: float = get_viewport().get_visible_rect().size.x - 2.0 * SCREEN_SIDE_MARGIN - PANEL_SPACING * (specs.size() - 1)
	var panel_width: float = minf(PANEL_SIZE.x, free_width / specs.size())
	for spec: SpecializationDef in specs:
		_row.add_child(_make_panel(spec, panel_width))
	visible = true


func _make_panel(spec: SpecializationDef, width: float) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE  # Space starts waves: a focused panel must not react to it.
	button.custom_minimum_size = Vector2(width, PANEL_SIZE.y)
	button.pressed.connect(_on_panel_pressed.bind(spec))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = PANEL_PADDING
	box.offset_top = PANEL_PADDING
	box.offset_right = -PANEL_PADDING
	box.offset_bottom = -PANEL_PADDING
	box.add_theme_constant_override(&"separation", TEXT_SPACING)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var name_label: Label = _make_label(spec.display_name, NAME_FONT_SIZE, NAME_COLOR)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var description: Label = _make_label(spec.description, TEXT_FONT_SIZE, TEXT_COLOR)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description)
	var stats: Label = _make_label(spec.stats_line, STATS_FONT_SIZE, STATS_COLOR)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(stats)
	return button


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _on_panel_pressed(spec: SpecializationDef) -> void:
	visible = false
	specialization_chosen.emit(spec)
