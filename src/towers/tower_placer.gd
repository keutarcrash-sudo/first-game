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
var _modifiers: PlayerModifiers
var _ctx: TowerBehaviour.TowerContext
var _kind: StringName = &""
var _sheets: Dictionary = {}  # Tower id (StringName) -> SpriteSheet; a missing id has no image.
var _preview: DirectionalSprite
var _preview_behaviour: TowerBehaviour  # Gives the preview ring its range (no tower node).
var _sheet_errors_reported: Dictionary = {}  # Tower ids whose missing sheet was reported.
var _reserve: TowerReserve
var _records: Dictionary = {}  # id -> TowerRecord of the placed towers (read by TowerEffects).
var _tower_nodes: Dictionary = {}  # id -> Tower node of the placed towers.
var _amplifier_count: int = 0  # Placed towers whose behaviour is an amplifier (none: _amp_at returns neutral at once).
var _selected_record: TowerRecord  # Reserve tower placed by the next click; null = buy _kind.
var _panel_open: bool = false  # A field click then only dismisses the upgrade panel.


## Gives the placer its tuning values, the game state (gold and phase), the arena,
## the crystal to keep clear, and the nodes holding the towers, the enemies and the
## bullets, the combo rules handed to the shots, the card modifiers handed to every tower (shared, never copied), the target designator handed to every tower, and the player's [param reserve] (purchases and the records of the placed towers). These make the [TowerBehaviour.TowerContext] shared by all towers. The first unlocked tower is selected for purchase. Call once, before the first frame.
func setup(stats: TowerStats, state: GameState, field_rect: Rect2, crystal: Crystal, towers: Node2D, enemies: Node2D, bullets: Node2D, rules: ProcRules, modifiers: PlayerModifiers, designator: TargetDesignator, reserve: TowerReserve) -> void:
	_reserve = reserve
	_modifiers = modifiers
	_stats = stats
	_state = state
	_field_rect = field_rect
	_crystal = crystal
	_towers = towers
	_ctx = TowerBehaviour.TowerContext.new()
	_ctx.stats = stats
	_ctx.enemies = enemies
	_ctx.bullets = bullets
	_ctx.arena_rect = field_rect
	_ctx.rules = rules
	_ctx.modifiers = modifiers
	_ctx.designator = designator
	_ctx.state = state
	_ctx.amp_at = _amp_at
	var unlocked: Array[StringName] = modifiers.unlocked_towers()
	_kind = unlocked[0] if not unlocked.is_empty() else stats.defs()[0].id
	_refresh_preview_behaviour()
	state.phase_changed.connect(_on_phase_changed)
	_on_phase_changed(state.phase)


## Gives every tower the chain-effect cap of the [TowerEffects] ([member TowerBehaviour.TowerContext.chain_limiter]).
func set_chain_limiter(limiter: ChainLimiter) -> void:
	_ctx.chain_limiter = limiter


## Gives every tower the ground layer (the hazards node, under the characters) for the mortar
## announcements and craters ([member TowerBehaviour.TowerContext.ground]).
func set_ground(ground: Node2D) -> void:
	_ctx.ground = ground


## Gives every tower the floating damage numbers node ([member TowerBehaviour.TowerContext.damage_numbers]); may be null.
func set_damage_numbers(numbers: Node) -> void:
	_ctx.damage_numbers = numbers


## Gives the placer the tower images, tower id (StringName) -> [SpriteSheet], used for the
## preview and for every placed tower, drawn [member TowerDef.height_px] tall. A tower
## without a sheet is reported once and shown without an image. Call once, before the first frame.
func set_visuals(sheets: Dictionary) -> void:
	_sheets = sheets
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
	_amplifier_count = 0
	_reserve.return_all()
	_select_next_waiting(_kind)  # The next build starts with a free reserve tower when one waits.


## Removes the placed tower of [param record] from the map and puts it back in the
## reserve; it keeps its level and branch. Ignored if the tower is not placed.
func pick_up(record: TowerRecord) -> void:
	if not _records.has(record.id):
		return
	var tower: Node = _tower_nodes[record.id]
	if tower is Tower and (tower as Tower).behaviour() is AmplifierBehaviour:
		_amplifier_count -= 1
	_towers.remove_child(tower)  # Out of the spot checks at once, not at the end of the frame.
	tower.queue_free()
	_records.erase(record.id)
	_tower_nodes.erase(record.id)
	_reserve.mark_returned(record)


## The records of the placed towers, id -> [TowerRecord] (read by [TowerEffects]).
## They are the reserve's records: levels and branches carry over.
func records_by_id() -> Dictionary:
	return _records


## The placed [Tower] node of record id [param id], or null when it is not placed (read by
## [TowerEffects] for the Fournaise range, towers T2b).
func tower_of(id: int) -> Tower:
	return _tower_nodes.get(id) as Tower


## Makes the next valid click place [param record], a tower waiting in the reserve,
## for free. Ignored if the record is already placed.
func select_record(record: TowerRecord) -> void:
	if record.placed:
		return
	_selected_record = record
	_kind = record.kind
	_refresh_preview_behaviour()
	_apply_preview_sheet()
	selection_changed.emit()


## Makes the next valid click buy a new tower of [param kind] and place it there.
## The first unlocked tower is selected by default. Ignored for an unknown kind.
func select_purchase(kind: StringName) -> void:
	if _stats.def_of(kind) == null:
		return
	_selected_record = null
	_kind = kind
	_refresh_preview_behaviour()
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
func selected_kind() -> StringName:
	return _kind


## The image of the towers of [param kind], or [code]null[/code] when it has none.
func sheet_of(kind: StringName) -> SpriteSheet:
	return _sheets.get(kind) as SpriteSheet


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
	var preview_range: float = 0.0 if _preview_behaviour == null else _preview_behaviour.range_now()
	draw_arc(mouse, preview_range, 0.0, TAU, RING_POINTS, color, RING_WIDTH)


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


## Rebuilds the behaviour giving the preview ring its range: the selected reserve tower,
## or a new level 1 tower of the selected kind. The record is shared, so an upgrade of the
## selected tower shows at once; cards and items are read live.
func _refresh_preview_behaviour() -> void:
	var def: TowerDef = _stats.def_of(_kind)
	_preview_behaviour = null if def == null else TowerBehaviour.create(def.behaviour)
	if _preview_behaviour == null:
		return
	var record: TowerRecord = _selected_record
	if record == null:
		record = TowerRecord.new()
		record.kind = _kind
	_preview_behaviour.setup(null, def, record, _ctx)


func _has_sheet() -> bool:
	return sheet_of(_kind) != null


func _apply_preview_sheet() -> void:
	if _preview == null:
		return
	var sheet: SpriteSheet = sheet_of(_kind)
	if sheet == null:
		_report_missing_sheet(_kind)
		_preview.visible = false
		return
	_preview.visible = true
	_preview.setup(sheet, _stats.def_of(_kind).height_px, true)
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


## Reports once per kind that a tower image was not given; the tower is then placed without its visual.
func _report_missing_sheet(kind: StringName) -> void:
	if _sheet_errors_reported.has(kind):
		return
	_sheet_errors_reported[kind] = true
	push_error("TowerPlacer: no sheet for tower '%s' (set_visuals); it is shown without an image." % kind)


## The record of the placed tower whose body contains [param spot], or null.
func _record_at(spot: Vector2) -> TowerRecord:
	for id: int in _tower_nodes:
		var tower: Tower = _tower_nodes[id]
		if spot.distance_squared_to(tower.position) <= tower.radius * tower.radius:
			return _records[id]
	return null


## After a reserve tower is placed, selects the next one of [param kind] still
## waiting, or falls back to buying that kind.
func _select_next_waiting(kind: StringName) -> void:
	_selected_record = null
	for waiting: TowerRecord in _reserve.available():
		if waiting.kind == kind:
			_selected_record = waiting
			break
	_refresh_preview_behaviour()
	selection_changed.emit()


func _place(record: TowerRecord, spot: Vector2) -> void:
	var def: TowerDef = _stats.def_of(record.kind)
	if def == null:
		push_error("TowerPlacer: unknown tower '%s'; not placed." % record.kind)
		return
	_records[record.id] = record
	var tower := Tower.new()
	tower.setup(def, record, _ctx)
	var sheet: SpriteSheet = sheet_of(record.kind)
	if sheet != null:
		tower.set_visual(sheet, def.height_px)
	else:
		_report_missing_sheet(record.kind)
	tower.position = spot
	_towers.add_child(tower)
	_tower_nodes[record.id] = tower
	if tower.behaviour() is AmplifierBehaviour:
		_amplifier_count += 1


## The amplifier bonuses at the placed tower of record id [param id] (itself left out), or
## none when it is not placed (read by [TowerEffects]).
func amp_of_tower(id: int) -> Dictionary:
	var tower: Tower = _tower_nodes.get(id) as Tower
	if tower == null:
		return AmplifierRules.neutral()
	return _amp_at(tower.global_position, id)


## The amplifier bonuses at [param at] ([member TowerBehaviour.TowerContext.amp_at]): the
## strongest per type ([AmplifierRules]) of the placed amplifiers whose range covers it,
## the amplifier of record id [param self_id] left out. Towers T2b: when a Nexus covers it,
## also [code]"shared"[/code], the light states of the other towers boosted by the Nexus
## amplifiers covering it ([method NexusRules.shared_states]; the tower of [param self_id]
## gives none of its own).
func _amp_at(at: Vector2, self_id: int) -> Dictionary:
	if _amplifier_count <= 0:
		return AmplifierRules.neutral()
	var boosts: Array[Dictionary] = []
	var nexuses: Array[Tower] = []
	for id: int in _tower_nodes:
		if id == self_id:
			continue
		var tower: Tower = _tower_nodes[id]
		var amplifier := tower.behaviour() as AmplifierBehaviour
		if amplifier == null:
			continue
		if tower.global_position.distance_squared_to(at) <= tower.attack_range * tower.attack_range:
			boosts.append(amplifier.boost())
			if amplifier.is_nexus():
				nexuses.append(tower)
	var result: Dictionary = AmplifierRules.combine(boosts)
	if not nexuses.is_empty():
		var shared: Array[Dictionary] = _nexus_shared(nexuses, self_id)
		if not shared.is_empty():
			result["shared"] = shared
	return result


## The states shared with the tower of record id [param self_id] by the Nexus towers
## [param nexuses]: every non-amplifier tower within one of their ranges counts.
func _nexus_shared(nexuses: Array[Tower], self_id: int) -> Array[Dictionary]:
	var boosted: Array[Dictionary] = []
	for id: int in _tower_nodes:
		if id == self_id:
			continue
		var tower: Tower = _tower_nodes[id]
		if tower.behaviour() is AmplifierBehaviour:
			continue
		var record: TowerRecord = _records.get(id) as TowerRecord
		if record == null:
			continue
		for nexus: Tower in nexuses:
			if nexus.global_position.distance_squared_to(tower.global_position) <= nexus.attack_range * nexus.attack_range:
				boosted.append({"id": record.kind, "branch": record.branch, "level": record.level, "evolved": record.evolved, "record": id})
				break
	var values: Dictionary = (nexuses[0].behaviour() as AmplifierBehaviour).nexus_values()
	return NexusRules.shared_states(boosted, values, self_id)
