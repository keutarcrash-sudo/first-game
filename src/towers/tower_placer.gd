## Tower placement (story 004, design/game-brief.md MVP feature 4): during the
## BUILD phase a left click in the arena places the selected tower at the
## cursor when the spot is valid and the gold suffices. Also draws a small
## preview of the tower (and its range) under the cursor, only while the cursor is
## over the arena (BUILD fits the arena clear of the HUD, so the cursor over the HUD
## or past the arena shows no stray red ring). Placed towers are
## children of the towers node; towers last one wave ([method clear_towers]).
class_name TowerPlacer
extends Node2D

## Emitted when a valid placement is refused because the gold is insufficient.
signal not_enough_gold

const VALID_COLOR := Color(0.5, 1.0, 0.6, 0.55)
const INVALID_COLOR := Color(1.0, 0.4, 0.4, 0.55)
const RING_WIDTH := 2.0
const RING_POINTS := 48

var _stats: TowerStats
var _state: GameState
var _field_rect: Rect2
var _crystal: Crystal
var _towers: Node2D
var _enemies: Node2D
var _bullets: Node2D
var _rules: ProcRules
var _modifiers: PlayerModifiers
var _designator: TargetDesignator
var _kind := TowerStats.Kind.CANNON
var _cannon_sheet: SpriteSheet
var _frost_sheet: SpriteSheet
var _cannon_height: float
var _frost_height: float
var _preview: DirectionalSprite
var _sheet_error_reported := false


## Gives the placer its tuning values, the game state (gold and phase), the arena,
## the crystal to keep clear, and the nodes holding the towers, the enemies and the
## bullets, the combo rules handed to cannon shots, the card modifiers handed to every tower (shared, never copied), and the target designator handed to every cannon. Call once, before the first frame.
func setup(stats: TowerStats, state: GameState, field_rect: Rect2, crystal: Crystal, towers: Node2D, enemies: Node2D, bullets: Node2D, rules: ProcRules, modifiers: PlayerModifiers, designator: TargetDesignator) -> void:
	_designator = designator
	_modifiers = modifiers
	_rules = rules
	_stats = stats
	_state = state
	_field_rect = field_rect
	_crystal = crystal
	_towers = towers
	_enemies = enemies
	_bullets = bullets
	state.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(state.phase)


## Gives the placer the tower images and their on-screen heights in pixels, used for the preview and for every placed tower. Call once, before the first frame.
func set_visuals(cannon_sheet: SpriteSheet, cannon_height: float, frost_sheet: SpriteSheet, frost_height: float) -> void:
	_cannon_sheet = cannon_sheet
	_frost_sheet = frost_sheet
	_cannon_height = cannon_height
	_frost_height = frost_height
	if _preview == null:
		_preview = DirectionalSprite.new()
		add_child(_preview)
	_apply_preview_sheet()


## Frees every placed tower (towers last one wave).
func clear_towers() -> void:
	for child: Node in _towers.get_children():
		child.queue_free()


## Chooses the type of tower the next click places. The cannon is selected by default.
func select_kind(kind: TowerStats.Kind) -> void:
	_kind = kind
	_apply_preview_sheet()


func _process(_delta: float) -> void:
	queue_redraw()
	if _preview != null:
		var mouse: Vector2 = get_local_mouse_position()
		_preview.position = mouse
		_preview.visible = _has_sheet() and _field_rect.has_point(mouse)


func _draw() -> void:
	var mouse: Vector2 = get_local_mouse_position()
	if not _field_rect.has_point(mouse):
		return  # Over the HUD or past the arena: no ring.
	var radius: float = _stats.radius_of(_kind)
	var color: Color = VALID_COLOR if _is_spot_valid(mouse, radius) else INVALID_COLOR
	if _preview != null:
		_preview.tint = color
	draw_arc(mouse, _range_of(_kind), 0.0, TAU, RING_POINTS, color, RING_WIDTH)


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
	if not _state.spend_gold(_modifiers.tower_cost(_stats.cost_of(_kind))):
		not_enough_gold.emit()
		return
	_place(position_clicked)


## The range a tower of [param kind] would have if placed now, card and item bonuses
## included (the same factors the towers read every frame).
func _range_of(kind: TowerStats.Kind) -> float:
	var factor: float = _modifiers.tower_range_factor()
	if kind == TowerStats.Kind.FROST:
		factor *= _modifiers.frost_range_factor()
	return _stats.range_of(kind) * factor


func _has_sheet() -> bool:
	return (_cannon_sheet if _kind == TowerStats.Kind.CANNON else _frost_sheet) != null


func _apply_preview_sheet() -> void:
	if _preview == null:
		return
	var sheet: SpriteSheet = _cannon_sheet if _kind == TowerStats.Kind.CANNON else _frost_sheet
	if sheet == null:
		_report_missing_sheet()
		_preview.visible = false
		return
	_preview.visible = true
	_preview.setup(sheet, _cannon_height if _kind == TowerStats.Kind.CANNON else _frost_height, true)
	_preview.play(&"idle")


func _on_phase_changed(phase: GameState.Phase) -> void:
	var building: bool = phase == GameState.Phase.BUILD
	visible = building
	set_process(building)


## A spot is valid when the tower body is fully inside the arena and overlaps neither the crystal nor a placed tower.
func _is_spot_valid(spot: Vector2, radius: float) -> bool:
	if not _field_rect.grow(-radius).has_point(spot):
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


## Reports once that a tower image was not given; the tower is then placed without its visual.
func _report_missing_sheet() -> void:
	if _sheet_error_reported:
		return
	_sheet_error_reported = true
	push_error("TowerPlacer: tower sheets were not set (set_visuals); towers are shown without an image.")


func _place(spot: Vector2) -> void:
	var tower: Tower
	if _kind == TowerStats.Kind.CANNON:
		var cannon := CannonTower.new()
		cannon.setup(_stats, _enemies, _bullets, _field_rect, _rules, _modifiers, _designator)
		if _cannon_sheet != null:
			cannon.set_visual(_cannon_sheet, _cannon_height)
		else:
			_report_missing_sheet()
		tower = cannon
	else:
		var frost := FrostTower.new()
		frost.setup(_stats, _enemies, _modifiers)
		if _frost_sheet != null:
			frost.set_visual(_frost_sheet, _frost_height)
		else:
			_report_missing_sheet()
		tower = frost
	tower.position = spot
	_towers.add_child(tower)
