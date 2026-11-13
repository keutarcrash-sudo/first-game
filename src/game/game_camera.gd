## Camera of the field. COMBAT: follows the hero at zoom 1. BUILD: zooms out so
## the whole field fits, centred on it. Other phases (card or spec choice)
## leave it unchanged. Limits match the field exactly.
## Note: Camera2D is not covered by docs/engine-reference/godot/; the properties
## used (zoom, limit_*, make_current) are long-standing Godot 4 API.
class_name GameCamera
extends Camera2D

var _hero: Node2D
var _field_rect: Rect2
var _state: GameState


## Sets limits from [param field_rect], makes this camera current and listens to the phase.
func setup(hero: Node2D, field_rect: Rect2, state: GameState) -> void:
	_hero = hero
	_field_rect = field_rect
	_state = state
	limit_left = floori(field_rect.position.x)
	limit_top = floori(field_rect.position.y)
	limit_right = ceili(field_rect.end.x)
	limit_bottom = ceili(field_rect.end.y)
	state.phase_changed.connect(_on_phase_changed.unbind(1))
	make_current()
	_apply_phase()


func _on_phase_changed() -> void:
	_apply_phase()


func _apply_phase() -> void:
	if _state.phase == GameState.Phase.COMBAT:
		zoom = Vector2.ONE
		global_position = _hero.global_position
	elif _state.phase == GameState.Phase.BUILD:
		var view: Vector2 = get_viewport_rect().size
		var fit: float = minf(view.x / _field_rect.size.x, view.y / _field_rect.size.y)
		zoom = Vector2(fit, fit)
		global_position = _field_rect.get_center()


func _process(_delta: float) -> void:
	if _state != null and _state.phase == GameState.Phase.COMBAT:
		global_position = _hero.global_position
