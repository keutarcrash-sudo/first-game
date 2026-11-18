## Draws the crystal's path on the field: a line, a dot at the start and a
## larger ring at the arrival. Shown in BUILD and, fainter, in COMBAT.
## Display only: it never changes game state.
class_name PathView
extends Node2D

const OUTLINE_COLOR: Color = Color.BLACK
const OUTLINE_WIDTH: float = 18.0
const ROAD_COLOR: Color = Color("#2a1a5e")
const ROAD_WIDTH: float = 12.0
const LINE_COLOR: Color = Color("#19e3ff")
const LINE_WIDTH: float = 3.0
const DASH_LENGTH: float = 10.0
const START_RADIUS: float = 10.0
const END_RADIUS: float = 18.0
const END_RING_WIDTH: float = 5.0
const COMBAT_ALPHA: float = 0.5
const BUILD_ALPHA: float = 1.0

var _path: CrystalPath
var _state: GameState


## Listens to the phase so the path is fainter during COMBAT.
func setup(state: GameState) -> void:
	_state = state
	state.phase_changed.connect(_on_phase_changed.unbind(1))
	_apply_alpha()


## Shows the path of the coming wave (replaces the previous one).
func show_path(path: CrystalPath) -> void:
	_path = path
	queue_redraw()


func _on_phase_changed() -> void:
	_apply_alpha()


func _apply_alpha() -> void:
	# Other phases (card or spec choice) keep the current alpha.
	if _state.phase == GameState.Phase.COMBAT:
		modulate.a = COMBAT_ALPHA
	elif _state.phase == GameState.Phase.BUILD:
		modulate.a = BUILD_ALPHA


func _draw() -> void:
	if _path == null or _path.points.size() < 2:
		return
	draw_polyline(_path.points, OUTLINE_COLOR, OUTLINE_WIDTH, true)
	draw_polyline(_path.points, ROAD_COLOR, ROAD_WIDTH, true)
	for i: int in _path.points.size() - 1:
		draw_dashed_line(_path.points[i], _path.points[i + 1], LINE_COLOR, LINE_WIDTH, DASH_LENGTH, true, true)
	draw_circle(_path.points[0], START_RADIUS, LINE_COLOR)
	draw_arc(_path.end_point(), END_RADIUS, 0.0, TAU, 32, LINE_COLOR, END_RING_WIDTH, true)
