## Hardware mouse cursor of the game: the crosshair in COMBAT while the tree runs, the
## arrow everywhere else (other phases, and the defeat screen, where the tree is paused).
## Over a living enemy the crosshair turns to its hover look. The images come from
## [CursorArt] and are turned into textures once. Always processed, so it still sees
## the pause; it puts the arrow back when it leaves the tree (a replay starts clean).
class_name CursorController
extends Node

## Look shown on CURSOR_ARROW.
enum Look { NONE, ARROW, CROSSHAIR, CROSSHAIR_HOVER }

var _state: GameState
var _enemies: Node2D
var _crosshair: ImageTexture
var _crosshair_hover: ImageTexture
var _arrow: ImageTexture
var _crosshair_hotspot: Vector2 = Vector2.ZERO
var _arrow_hotspot: Vector2 = Vector2.ZERO
var _hover_check_interval: float = 0.1
var _hover_elapsed: float = 0.0
var _hovering: bool = false
var _ready_to_apply: bool = false
var _shown: Look = Look.NONE  # What CURSOR_ARROW currently shows.


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Builds the three textures and starts following [param state]'s phase and the
## enemies under [param enemies] (their centre and body radius) for the hover look.
func setup(art: CursorArt, state: GameState, enemies: Node2D) -> void:
	_state = state
	_enemies = enemies
	_crosshair = ImageTexture.create_from_image(art.crosshair(false))
	_crosshair_hover = ImageTexture.create_from_image(art.crosshair(true))
	_arrow = ImageTexture.create_from_image(art.arrow())
	_crosshair_hotspot = art.crosshair_hotspot()
	_arrow_hotspot = art.arrow_hotspot()
	_hover_check_interval = art.hover_check_interval
	# Buttons keep the arrow instead of falling back to the system hand.
	Input.set_custom_mouse_cursor(_arrow, Input.CURSOR_POINTING_HAND, _arrow_hotspot)
	_ready_to_apply = true
	_apply(false)


func _process(delta: float) -> void:
	if not _ready_to_apply:
		return
	_hover_elapsed += delta
	if _hover_elapsed >= _hover_check_interval:
		_hover_elapsed = 0.0
		_hovering = _in_combat() and _mouse_over_enemy()
	_apply(_hovering)


func _exit_tree() -> void:
	if _ready_to_apply:
		Input.set_custom_mouse_cursor(_arrow, Input.CURSOR_ARROW, _arrow_hotspot)
		_shown = Look.NONE


## True while the crosshair is due: COMBAT phase and the tree not paused (defeat).
func _in_combat() -> bool:
	return _state.phase == GameState.Phase.COMBAT and not get_tree().paused


func _mouse_over_enemy() -> bool:
	var mouse: Vector2 = _enemies.get_global_mouse_position()
	for child: Node in _enemies.get_children():
		var enemy := child as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var reach: float = enemy.radius()
		if mouse.distance_squared_to(enemy.global_position) <= reach * reach:
			return true
	return false


## Sets CURSOR_ARROW only when the wanted look differs from the one shown.
func _apply(hover: bool) -> void:
	var wanted: Look = Look.ARROW
	if _in_combat():
		wanted = Look.CROSSHAIR_HOVER if hover else Look.CROSSHAIR
	if wanted == _shown:
		return
	_shown = wanted
	match wanted:
		Look.CROSSHAIR:
			Input.set_custom_mouse_cursor(_crosshair, Input.CURSOR_ARROW, _crosshair_hotspot)
		Look.CROSSHAIR_HOVER:
			Input.set_custom_mouse_cursor(_crosshair_hover, Input.CURSOR_ARROW, _crosshair_hotspot)
		_:
			Input.set_custom_mouse_cursor(_arrow, Input.CURSOR_ARROW, _arrow_hotspot)
