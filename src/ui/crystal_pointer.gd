## Arrow at the screen edge pointing to the crystal, with its hit points, when
## the crystal is off screen. Draws nothing otherwise. Display only.
class_name CrystalPointer
extends Control

const EDGE_MARGIN := 40.0
const ARROW_SIZE := 18.0
const ARROW_COLOR := Color(0.55, 0.9, 1.0)
const FONT_SIZE := 20
const TEXT_OFFSET := Vector2(-30.0, 28.0)

var _crystal: Crystal


## Starts tracking [param crystal]; full-screen, ignores the mouse.
func setup(crystal: Crystal) -> void:
	_crystal = crystal
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	crystal.health_changed.connect(_on_health_changed.unbind(2))


func _on_health_changed() -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _crystal == null:
		return
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * _crystal.global_position
	var screen: Rect2 = Rect2(Vector2.ZERO, get_viewport_rect().size)
	var inner: Rect2 = screen.grow(-EDGE_MARGIN)
	if inner.has_point(screen_pos):
		return
	var centre: Vector2 = screen.get_center()
	var dir: Vector2 = (screen_pos - centre).normalized()
	var spot: Vector2 = _edge_point(centre, dir, inner)
	var side: Vector2 = dir.orthogonal()
	var tip: Vector2 = spot + dir * ARROW_SIZE
	draw_colored_polygon(PackedVector2Array([tip, spot + side * ARROW_SIZE * 0.6, spot - side * ARROW_SIZE * 0.6]), ARROW_COLOR)
	var text_pos: Vector2 = (spot - dir * ARROW_SIZE * 1.2 + TEXT_OFFSET).clamp(Vector2.ZERO, screen.size - Vector2(80.0, 10.0))
	draw_string(ThemeDB.fallback_font, text_pos, "%d PV" % ceili(_crystal.current_hp), HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, ARROW_COLOR)


## Point where the ray from [param centre] along [param dir] leaves [param inner].
func _edge_point(centre: Vector2, dir: Vector2, inner: Rect2) -> Vector2:
	var half: Vector2 = inner.size * 0.5
	var scale_x: float = half.x / absf(dir.x) if absf(dir.x) > 0.0001 else INF
	var scale_y: float = half.y / absf(dir.y) if absf(dir.y) > 0.0001 else INF
	return centre + dir * minf(scale_x, scale_y)
