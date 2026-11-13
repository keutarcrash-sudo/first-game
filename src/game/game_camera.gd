## Camera of the field. COMBAT: follows the hero at zoom 1. BUILD: zooms out so
## the whole field fits, centred on it. Other phases (card or spec choice)
## leave it unchanged. COMBAT limits match the field; BUILD lifts them so the field stays centred.
## Note: Camera2D is not covered by docs/engine-reference/godot/; the properties
## used (zoom, limit_*, make_current) are long-standing Godot 4 API.
class_name GameCamera
extends Camera2D

## Limits large enough to never bind (BUILD view may be wider than the field).
const NO_LIMIT: int = 10000000

var _hero: Node2D
var _field_rect: Rect2
var _state: GameState


## Sets limits from [param field_rect], makes this camera current and listens to the phase.
func setup(hero: Node2D, field_rect: Rect2, state: GameState) -> void:
	_hero = hero
	_field_rect = field_rect
	_state = state
	state.phase_changed.connect(_on_phase_changed.unbind(1))
	make_current()
	_apply_phase()


func _on_phase_changed() -> void:
	_apply_phase()


func _apply_phase() -> void:
	if _state.phase == GameState.Phase.COMBAT:
		zoom = Vector2.ONE
		_set_limits(
			floori(_field_rect.position.x), floori(_field_rect.position.y),
			ceili(_field_rect.end.x), ceili(_field_rect.end.y))
		_follow_hero()
	elif _state.phase == GameState.Phase.BUILD:
		var view: Vector2 = get_viewport_rect().size
		var fit: float = minf(view.x / _field_rect.size.x, view.y / _field_rect.size.y)
		zoom = Vector2(fit, fit)
		_set_limits(-NO_LIMIT, -NO_LIMIT, NO_LIMIT, NO_LIMIT)
		global_position = _field_rect.get_center()


func _set_limits(left: int, top: int, right: int, bottom: int) -> void:
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom


func _follow_hero() -> void:
	if is_instance_valid(_hero):
		global_position = _hero.global_position


func _physics_process(_delta: float) -> void:
	if _state != null and _state.phase == GameState.Phase.COMBAT:
		_follow_hero()
