## Camera of the field. COMBAT: follows the hero at zoom 1. BUILD: zooms out so
## the whole field fits, centred on it. Other phases (card or spec choice)
## leave it unchanged. COMBAT limits match the field (bottom lowered by the band);
## BUILD lifts them so the field stays centred.
## The bottom HUD band (ability bar and tower buttons, height given in [method setup])
## hides the bottom of the screen: BUILD fits the field above it, COMBAT lets the
## field's bottom edge rise above it and shifts the view down when the crystal
## would fall under it (the hero always stays on screen; [CrystalPointer] is the fallback).
## Note: Camera2D is not covered by docs/engine-reference/godot/; the properties
## used (zoom, limit_*, offset, make_current) are long-standing Godot 4 API.
class_name GameCamera
extends Camera2D

## Limits large enough to never bind (BUILD view may be wider than the field).
const NO_LIMIT: int = 10000000
## Half-height of the crystal's body (screen pixels at zoom 1) kept above the band.
const CRYSTAL_HALF_HEIGHT: float = 50.0
## Smallest distance (screen pixels) between the hero and the top of the screen
## when the view shifts down for the crystal.
const HERO_TOP_MARGIN: float = 80.0
## How fast the crystal shift catches up with its target (1/s, exponential).
const SHIFT_SPEED: float = 8.0

var _hero: Node2D
var _crystal: Node2D
var _field_rect: Rect2
var _state: GameState
var _bottom_band: float = 0.0
var _shift: float = 0.0  # Extra downward shift (world px) for the crystal, smoothed.


## Sets limits from [param field_rect], makes this camera current and listens to the phase.
## [param bottom_band] is the height in screen pixels of the HUD band at the
## bottom of the screen ([method AbilityBar.bottom_band_height]).
func setup(hero: Node2D, crystal: Node2D, field_rect: Rect2, state: GameState, bottom_band: float) -> void:
	_hero = hero
	_crystal = crystal
	_field_rect = field_rect
	_state = state
	_bottom_band = maxf(bottom_band, 0.0)
	state.phase_changed.connect(_on_phase_changed.unbind(1))
	make_current()
	_apply_phase()


## Shifts the view by [param shake] pixels on top of the followed position
## (screen shake). [code]Vector2.ZERO[/code] ends the shake.
func set_shake_offset(shake: Vector2) -> void:
	offset = shake


func _physics_process(delta: float) -> void:
	if _state != null and _state.phase == GameState.Phase.COMBAT:
		_follow_hero(1.0 - exp(-SHIFT_SPEED * delta))


func _on_phase_changed() -> void:
	_apply_phase()


func _apply_phase() -> void:
	if _state.phase == GameState.Phase.COMBAT:
		zoom = Vector2.ONE
		_set_limits(
			floori(_field_rect.position.x), floori(_field_rect.position.y),
			ceili(_field_rect.end.x), ceili(_field_rect.end.y + _bottom_band))
		_follow_hero(1.0)  # Snap: no sweep when the combat starts.
	elif _state.phase == GameState.Phase.BUILD:
		var view: Vector2 = get_viewport_rect().size
		var usable_height: float = maxf(view.y - _bottom_band, 1.0)
		var fit: float = minf(view.x / _field_rect.size.x, usable_height / _field_rect.size.y)
		zoom = Vector2(fit, fit)
		_set_limits(-NO_LIMIT, -NO_LIMIT, NO_LIMIT, NO_LIMIT)
		# The field's centre sits in the middle of the area above the band.
		global_position = _field_rect.get_center() + Vector2(0.0, _bottom_band * 0.5 / fit)


func _set_limits(left: int, top: int, right: int, bottom: int) -> void:
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom


## Centres on the hero, plus the crystal shift moved by [param weight] (0..1)
## towards its target. Uses position, not offset (offset is the screen shake).
func _follow_hero(weight: float) -> void:
	if not is_instance_valid(_hero):
		return
	var half_height: float = get_viewport_rect().size.y * 0.5 / zoom.y
	var band: float = _bottom_band / zoom.y
	var hero_pos: Vector2 = _hero.global_position
	# Centre the limits will actually show, so the shift is measured from it.
	var base_y: float = hero_pos.y
	if float(limit_bottom - limit_top) >= half_height * 2.0:
		base_y = clampf(base_y, limit_top + half_height, limit_bottom - half_height)
	var target: float = 0.0
	if is_instance_valid(_crystal):
		# Centre needed for the crystal's bottom to stay above the band.
		var needed_y: float = _crystal.global_position.y + CRYSTAL_HALF_HEIGHT / zoom.y + band - half_height
		# Lowest centre that keeps the hero HERO_TOP_MARGIN below the top: the hero wins.
		var hero_max_y: float = hero_pos.y + half_height - HERO_TOP_MARGIN / zoom.y
		target = maxf(minf(needed_y, hero_max_y) - base_y, 0.0)
	_shift = lerpf(_shift, target, clampf(weight, 0.0, 1.0))
	global_position = Vector2(hero_pos.x, base_y + _shift)
