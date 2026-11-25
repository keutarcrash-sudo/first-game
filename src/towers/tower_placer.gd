## Tower placement (story 004, design/game-brief.md MVP feature 4; towers T1):
## during the BUILD phase a left click on a placed tower emits [signal tower_clicked]
## (upgrade panel); otherwise a left click in the arena places the selection at the
## cursor when the spot is valid: a tower of the [TowerReserve] for free
## ([method select_record]), or a new tower bought on the spot
## ([method select_purchase], price [method TowerReserve.price_of_next]). Also draws a small
## preview of the tower (and its range) under the cursor, only while the cursor is
## over the arena (BUILD fits the arena clear of the HUD, so the cursor over the HUD
## or past the arena shows no stray red ring). Placed towers are
## children of the towers node; at the end of a wave they go back to the reserve
## ([method return_all_towers]).
class_name TowerPlacer
extends Node2D

## Emitted when a valid placement is refused because the gold is insufficient.
signal not_enough_gold
## Emitted when a left click in BUILD lands on a placed tower; [param screen_position]
## is the click in viewport (HUD) coordinates.
signal tower_clicked(record: TowerRecord, screen_position: Vector2)
## Emitted when the selection changes ([method select_record], [method select_purchase],
## a placement, a pick-up or the end of a wave).
signal selection_changed
## Emitted when a click on the field only dismisses the open upgrade panel
## ([method set_panel_open]); nothing is placed or bought.
signal panel_dismiss_requested

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
var _reserve: TowerReserve
var _records: Dictionary = {}  # id -> TowerRecord of the placed towers (read by TowerEffects).
var _tower_nodes: Dictionary = {}  # id -> Tower node of the placed towers.
var _selected_record: TowerRecord  # Reserve tower placed by the next click; null = buy _kind.
var _panel_open: bool = false  # A field click then only dismisses the upgrade panel.


## Gives the placer its tuning values, the game state (gold and phase), the arena,
## the crystal to keep clear, and the nodes holding the towers, the enemies and the
## bullets, the combo rules handed to cannon shots, the card modifiers handed to every tower (shared, never copied), the target designator handed to every cannon, and the player's [param reserve] (purchases and the records of the placed towers). Call once, before the first frame.
func setup(stats: TowerStats, state: GameState, field_rect: Rect2, crystal: Crystal, towers: Node2D, enemies: Node2D, bullets: Node2D, rules: ProcRules, modifiers: PlayerModifiers, designator: TargetDesignator, reserve: TowerReserve) -> void:
	_reserve = reserve
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


## Removes every placed tower from the map and puts it back in the reserve with its
## level and branch (end of wave). The selection moves to a waiting tower of the
## selected kind, or buying that kind when none waits.
func return_all_towers() -> void:
	for child: Node in _towers.get_children():
		_towers.remove_child(child)
		child.queue_free()
	_records.clear()
	_tower_nodes.clear()
	_reserve.return_all()
	_select_next_waiting(_kind)  # The next build starts with a free reserve tower when one waits.


## Removes the placed tower of [param record] from the map and puts it back in the
## reserve; it keeps its level and branch. Ignored if the tower is not placed.
func pick_up(record: TowerRecord) -> void:
	if not _records.has(record.id):
		return
	var tower: Node = _tower_nodes[record.id]
	_towers.remove_child(tower)  # Out of the spot checks at once, not at the end of the frame.
	tower.queue_free()
	_records.erase(record.id)
	_tower_nodes.erase(record.id)
	_reserve.mark_returned(record)


## The records of the placed towers, id -> [TowerRecord] (read by [TowerEffects]).
## They are the reserve's records: levels and branches carry over.
func records_by_id() -> Dictionary:
	return _records


## Makes the next valid click place [param record], a tower waiting in the reserve,
## for free. Ignored if the record is already placed.
func select_record(record: TowerRecord) -> void:
	if record.placed:
		return
	_selected_record = record
	_kind = record.kind
	_apply_preview_sheet()
	selection_changed.emit()


## Makes the next valid click buy a new tower of [param kind] and place it there.
## The cannon is selected by default.
func select_purchase(kind: TowerStats.Kind) -> void:
	_selected_record = null
	_kind = kind
	_apply_preview_sheet()
	selection_changed.emit()


## Tells the placer whether the upgrade panel is open: while it is, a click on the
## field emits [signal panel_dismiss_requested] instead of placing or buying (a click
## on a placed tower still emits [signal tower_clicked]).
func set_panel_open(open: bool) -> void:
	_panel_open = open


## The reserve tower the next click places, or [code]null[/code] when it buys.
func selected_record() -> TowerRecord:
	return _selected_record


## The kind the next click places (bought or taken from the reserve).
func selected_kind() -> TowerStats.Kind:
	return _kind


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
	# A placed tower first: clicking it opens its panel, never buys or places.
	var clicked: TowerRecord = _record_at(position_clicked)
	if clicked != null:
		get_viewport().set_input_as_handled()
		tower_clicked.emit(clicked, click.position)
		return
	if _panel_open:
		get_viewport().set_input_as_handled()
		panel_dismiss_requested.emit()
		return
	# Validity next: an invalid spot must never cost gold.
	if not _is_spot_valid(position_clicked, _stats.radius_of(_kind)):
		return
	var record: TowerRecord = _selected_record
	if record == null or record.placed:
		var cost_factor: float = _modifiers.tower_cost_factor()
		var price: int = _reserve.price_of_next(_kind, cost_factor)
		record = _reserve.buy(_kind, _state.gold, cost_factor)
		if record == null:
			not_enough_gold.emit()
			return
		_state.spend_gold(price)
	_place(record, position_clicked)
	_reserve.mark_placed(record)
	if record == _selected_record:
		_select_next_waiting(record.kind)


## The range a tower of [param kind] would have if placed now, card and item bonuses
## included (the same factors the towers read every frame).
func _range_of(kind: TowerStats.Kind) -> float:
	var factor: float = _modifiers.tower_range_factor()
	if kind == TowerStats.Kind.FROST:
		factor *= _modifiers.frost_range_factor()
		var record: TowerRecord = _selected_record
		if record != null and record.level >= 2 and record.branch == FrostTower.BLIZZARD:
			factor *= float(_stats.branch_value(TowerStats.Kind.FROST, FrostTower.BLIZZARD, "range_mult"))
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


## The record of the placed tower whose body contains [param spot], or null.
func _record_at(spot: Vector2) -> TowerRecord:
	for id: int in _tower_nodes:
		var tower: Tower = _tower_nodes[id]
		if spot.distance_squared_to(tower.position) <= tower.radius * tower.radius:
			return _records[id]
	return null


## After a reserve tower is placed, selects the next one of [param kind] still
## waiting, or falls back to buying that kind.
func _select_next_waiting(kind: TowerStats.Kind) -> void:
	_selected_record = null
	for waiting: TowerRecord in _reserve.available():
		if waiting.kind == kind:
			_selected_record = waiting
			break
	selection_changed.emit()


func _place(record: TowerRecord, spot: Vector2) -> void:
	_records[record.id] = record
	var tower: Tower
	if record.kind == TowerStats.Kind.CANNON:
		var cannon := CannonTower.new()
		cannon.setup(_stats, _enemies, _bullets, _field_rect, _rules, _modifiers, _designator, record)
		if _cannon_sheet != null:
			cannon.set_visual(_cannon_sheet, _cannon_height)
		else:
			_report_missing_sheet()
		tower = cannon
	else:
		var frost := FrostTower.new()
		frost.setup(_stats, _enemies, _modifiers, record)
		if _frost_sheet != null:
			frost.set_visual(_frost_sheet, _frost_height)
		else:
			_report_missing_sheet()
		tower = frost
	tower.position = spot
	_towers.add_child(tower)
	_tower_nodes[record.id] = tower
