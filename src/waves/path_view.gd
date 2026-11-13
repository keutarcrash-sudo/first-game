## Draws the crystal's path on the field: a line, a dot at the start and a
## larger ring at the arrival. Shown in BUILD and, fainter, in COMBAT.
## Display only: it never changes game state.
class_name PathView
extends Node2D

const LINE_COLOR: Color = Color(0.55, 0.9, 1.0, 0.5)
const LINE_WIDTH: float = 6.0
const START_RADIUS: float = 10.0
const END_RADIUS: float = 18.0
const END_RING_WIDTH: float = 5.0
## Line colour already has alpha 0.5, so 0.5 here gives an effective 0.25.
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
	draw_polyline(_path.points, LINE_COLOR, LINE_WIDTH, true)
	draw_circle(_path.points[0], START_RADIUS, LINE_COLOR)
	draw_arc(_path.end_point(), END_RADIUS, 0.0, TAU, 32, LINE_COLOR, END_RING_WIDTH, true)
