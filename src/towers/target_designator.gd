## Target designation (étape 2): during COMBAT a left click on an enemy
## designates it; cannons in range shoot it first. Draws a pulsing ring around
## the designated enemy. Leaving COMBAT clears the designation.
class_name TargetDesignator
extends Node2D

const RING_COLOR := Color(1.0, 0.35, 0.15)
const RING_WIDTH := 4.0
const RING_POINTS := 48
const RING_GAP := 10.0
const PULSE_AMPLITUDE := 3.0
const PULSE_SPEED := 8.0

var _state: GameState
var _enemies: Node2D
var _stats: TowerStats
var _target: Enemy


## Gives the designator the game state (phase), the node holding the enemies and the tuning values. Call once, before the first frame.
func setup(state: GameState, enemies: Node2D, stats: TowerStats) -> void:
	_state = state
	_enemies = enemies
	_stats = stats
	state.phase_changed.connect(_on_phase_changed)


## The designated enemy, or null when none or when it is gone (freed or being freed).
func target() -> Enemy:
	if _target == null or not is_instance_valid(_target) or _target.is_queued_for_deletion():
		return null
	return _target


## Forgets the designated enemy.
func clear() -> void:
	_target = null
	queue_redraw()


func _process(_delta: float) -> void:
	# The ring pulses with time, so it is redrawn every frame while a target exists.
	if _target == null:
		return
	if target() == null:
		clear()  # The designated enemy died: erase the ring.
		return
	queue_redraw()


func _draw() -> void:
	var designated: Enemy = target()
	if designated == null:
		return
	var time: float = Time.get_ticks_msec() / 1000.0
	var ring_radius: float = designated.radius() + RING_GAP + PULSE_AMPLITUDE * sin(time * PULSE_SPEED)
	draw_arc(to_local(designated.global_position), ring_radius, 0.0, TAU, RING_POINTS, RING_COLOR, RING_WIDTH)


## Clicks consumed by the HUD buttons never reach this function.
func _unhandled_input(event: InputEvent) -> void:
	if _state.phase != GameState.Phase.COMBAT:
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var clicked: Enemy = _enemy_at(get_global_mouse_position())
	if clicked == null:
		return
	_target = clicked
	get_viewport().set_input_as_handled()


## The valid enemy whose centre is nearest to [param point], provided the click lands within its radius plus the click margin.
func _enemy_at(point: Vector2) -> Enemy:
	var best: Enemy = null
	var best_sq: float = INF
	for i: int in _enemies.get_child_count():
		var enemy := _enemies.get_child(i) as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var distance_sq: float = point.distance_squared_to(enemy.global_position)
		var reach: float = enemy.radius() + _stats.designation_click_margin
		if distance_sq <= reach * reach and distance_sq < best_sq:
			best_sq = distance_sq
			best = enemy
	return best


func _on_phase_changed(phase: GameState.Phase) -> void:
	if phase != GameState.Phase.COMBAT:
		clear()
