## Tower placement (story 004, design/game-brief.md MVP feature 4): during the
## BUILD phase a left click in the arena places the selected tower at the
## cursor when the spot is valid and the gold suffices. Also draws a small
## preview of the tower (and its range) under the cursor. Placed towers are
## children of the towers node and stay for the whole game.
class_name TowerPlacer
extends Node2D

## Emitted when a valid placement is refused because the gold is insufficient.
signal not_enough_gold

const VALID_COLOR := Color(0.4, 1.0, 0.5, 0.35)
const INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.35)
const RING_WIDTH := 2.0
const RING_POINTS := 48

var _stats: TowerStats
var _state: GameState
var _arena_rect: Rect2
var _crystal: Crystal
var _towers: Node2D
var _enemies: Node2D
var _bullets: Node2D
var _rules: ProcRules
var _kind := TowerStats.Kind.CANNON


## Gives the placer its tuning values, the game state (gold and phase), the arena,
## the crystal to keep clear, and the nodes holding the towers, the enemies and the
## bullets, and the combo rules handed to cannon shots. Call once, before the first frame.
func setup(stats: TowerStats, state: GameState, arena_rect: Rect2, crystal: Crystal, towers: Node2D, enemies: Node2D, bullets: Node2D, rules: ProcRules) -> void:
	_rules = rules
	_stats = stats
	_state = state
	_arena_rect = arena_rect
	_crystal = crystal
	_towers = towers
	_enemies = enemies
	_bullets = bullets
	state.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(state.phase)


## Chooses the type of tower the next click places. The cannon is selected by default.
func select_kind(kind: TowerStats.Kind) -> void:
	_kind = kind


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var mouse: Vector2 = get_local_mouse_position()
	var radius: float = _stats.radius_of(_kind)
	var color: Color = VALID_COLOR if _is_spot_valid(mouse, radius) else INVALID_COLOR
	draw_circle(mouse, radius, color)
	draw_arc(mouse, _stats.range_of(_kind), 0.0, TAU, RING_POINTS, color, RING_WIDTH)


## Clicks consumed by the HUD buttons never reach this function.
func _unhandled_input(event: InputEvent) -> void:
	if _state.phase != GameState.Phase.BUILD:
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var position_clicked: Vector2 = get_global_mouse_position()
	# Validity first: an invalid spot must never cost gold.
	if not _is_spot_valid(position_clicked, _stats.radius_of(_kind)):
		return
	if not _state.spend_gold(_stats.cost_of(_kind)):
		not_enough_gold.emit()
		return
	_place(position_clicked)


func _on_phase_changed(phase: GameState.Phase) -> void:
	var building: bool = phase == GameState.Phase.BUILD
	visible = building
	set_process(building)


## A spot is valid when the tower body is fully inside the arena and overlaps neither the crystal nor a placed tower.
func _is_spot_valid(spot: Vector2, radius: float) -> bool:
	if not _arena_rect.grow(-radius).has_point(spot):
		return false
	var crystal_gap: float = _crystal.radius + radius
	if spot.distance_squared_to(_crystal.global_position) < crystal_gap * crystal_gap:
		return false
	for i: int in _towers.get_child_count():
		var tower := _towers.get_child(i) as Tower
		var tower_gap: float = tower.radius + radius
		if spot.distance_squared_to(tower.position) < tower_gap * tower_gap:
			return false
	return true


func _place(spot: Vector2) -> void:
	var tower: Tower
	if _kind == TowerStats.Kind.CANNON:
		var cannon := CannonTower.new()
		cannon.setup(_stats, _enemies, _bullets, _arena_rect, _rules)
		tower = cannon
	else:
		var frost := FrostTower.new()
		frost.setup(_stats, _enemies)
		tower = frost
	tower.position = spot
	_towers.add_child(tower)
