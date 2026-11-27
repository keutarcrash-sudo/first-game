## Upgrade panel of a placed tower (towers T1), opened in BUILD by a click on the
## tower, next to it: its level, its branch, the next upgrade and its price, two
## branch buttons at level 1, a "Niveau 3" button at level 2, and "Reprendre". At
## level 3 (towers T2b): « ÉVOLUER ! » when the evolution's item or card is owned,
## else « Évolue avec : … » or « Évolution réservée à … » greyed out; once evolved,
## the evolution's name in gold.
## The upgrade buttons are greyed out while the gold is short. Display only: it
## emits requests and the game ([code]main.gd[/code]) applies them. Escape closes it.
class_name TowerUpgradePanel
extends PanelContainer

## Emitted when the player asks to upgrade [param record]; [param branch] is the
## chosen branch at level 1, [code]&""[/code] at level 2.
signal upgrade_requested(record: TowerRecord, branch: StringName)
## Emitted when the player clicks « ÉVOLUER ! » for [param record] (towers T2b).
signal evolve_requested(record: TowerRecord)
## Emitted when the player clicks "Reprendre".
signal pick_up_requested(record: TowerRecord)
## Emitted when the panel closes, whatever the reason.
signal closed

const TITLE_FONT_SIZE := 22
const TEXT_FONT_SIZE := 18
const BUTTON_FONT_SIZE := 18
const BUTTON_SIZE := Vector2(150.0, 36.0)
const SPACING := 6
const PADDING := 12
## Gap between the clicked point and the panel corner.
const CURSOR_OFFSET := Vector2(24.0, -24.0)
const SCREEN_MARGIN := 8.0
const FRAME_COLOR := Color(0.45, 0.85, 1.0)
const BG_COLOR := Color(0.06, 0.06, 0.12, 0.94)
const TITLE_COLOR := Color(1.0, 0.9, 0.35)
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const SHORT_COLOR := Color(1.0, 0.3, 0.3)
const DISABLED_COLOR := Color(0.5, 0.5, 0.55)
const EVOLVED_COLOR := Color(1.0, 0.82, 0.2)
const FRAME_WIDTH := 3
const FRAME_RADIUS := 8

var _stats: TowerStats
var _reserve: TowerReserve
var _modifiers: PlayerModifiers
var _state: GameState
var _record: TowerRecord
var _hero_spec: StringName = &""
var _column: VBoxContainer
var _refresh_queued: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # A click on the panel never reaches the field.
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.border_color = FRAME_COLOR
	style.set_border_width_all(FRAME_WIDTH)
	style.set_corner_radius_all(FRAME_RADIUS)
	style.set_content_margin_all(PADDING)
	add_theme_stylebox_override(&"panel", style)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override(&"separation", SPACING)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)


## Gives the panel what it reads: branch names, upgrade prices (after the
## discounts of [param modifiers]) and the gold of [param state]. It refreshes
## itself while open when the gold, the reserve or the modifiers change. Call once.
func setup(stats: TowerStats, reserve: TowerReserve, modifiers: PlayerModifiers, state: GameState) -> void:
	_stats = stats
	_reserve = reserve
	_modifiers = modifiers
	_state = state
	state.gold_changed.connect(_refresh_if_open.unbind(1))
	reserve.changed.connect(_refresh_if_open)
	modifiers.changed.connect(_refresh_if_open)


## Sets the specialization id of the hero of this run, to tell an evolution reserved
## to another hero (towers T2b). Call once the hero is chosen.
func set_hero_spec(spec_id: StringName) -> void:
	_hero_spec = spec_id
	_refresh_if_open()


## Evolution status of [param record] for the player's items and cards and this
## run's hero ([method EvolutionRules.status]).
func evolution_status(record: TowerRecord) -> StringName:
	var def: TowerDef = _stats.def_of(record.kind)
	var spec: StringName = &"" if def == null else def.requirement_spec(record.branch)
	return EvolutionRules.status(record, def, _modifiers.owns_item, _has_card, spec, _hero_spec)


## Shows the panel of [param record] next to [param screen_position] (viewport coordinates).
func open(record: TowerRecord, screen_position: Vector2) -> void:
	_record = record
	_rebuild()
	visible = true
	reset_size()
	var screen: Vector2 = get_viewport_rect().size
	var spot: Vector2 = screen_position + CURSOR_OFFSET - Vector2(0.0, size.y)
	spot.x = clampf(spot.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, screen.x - size.x - SCREEN_MARGIN))
	spot.y = clampf(spot.y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, screen.y - size.y - SCREEN_MARGIN))
	position = spot


## Hides the panel and emits [signal closed]; nothing happens if it is already closed.
func close() -> void:
	if not visible:
		return
	visible = false
	_record = null
	closed.emit()


## The record shown, or [code]null[/code] when closed.
func shown_record() -> TowerRecord:
	return _record


## Display name of [param branch] of a tower of [param kind] (its [code]label[/code]
## in towers.json, else its id).
static func branch_label(stats: TowerStats, kind: StringName, branch: StringName) -> String:
	var label: Variant = stats.branch_value(kind, branch, "label")
	if label is String:
		return label as String
	return String(branch)


## Display name of a tower of [param kind] (its [code]label[/code] in towers.json, else its id).
static func kind_label(stats: TowerStats, kind: StringName) -> String:
	var def: TowerDef = stats.def_of(kind)
	return String(kind) if def == null else def.label


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Rebuilds at the end of the frame: a change often comes from the press of one of
## the panel's own buttons, which must not be freed while it is still emitting.
func _refresh_if_open() -> void:
	if not visible or _refresh_queued:
		return
	_refresh_queued = true
	_refresh_deferred.call_deferred()


func _refresh_deferred() -> void:
	_refresh_queued = false
	if visible and _record != null:
		_rebuild()
		reset_size()


func _rebuild() -> void:
	for child: Node in _column.get_children():
		_column.remove_child(child)
		child.queue_free()
	var kind_name: String = kind_label(_stats, _record.kind)
	var title: String = "%s — niveau %d" % [kind_name, _record.level]
	if _record.branch != &"":
		title += " · %s" % branch_label(_stats, _record.kind, _record.branch)
	_column.add_child(_make_label(title, TITLE_FONT_SIZE, TITLE_COLOR))
	var cost: int = _reserve.upgrade_cost(_record, _modifiers.upgrade_cost_factor())
	if cost < 0:
		_column.add_child(_make_label("Niveau maximal", TEXT_FONT_SIZE, TEXT_COLOR))
		_add_evolution_rows()
	else:
		var short: bool = _state.gold < cost
		var next_text: String = "Choisir une branche" if _record.level == 1 else "Branche renforcée"
		_column.add_child(_make_label("%s — %d or" % [next_text, cost], TEXT_FONT_SIZE, SHORT_COLOR if short else TEXT_COLOR))
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", SPACING)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_column.add_child(row)
		if _record.level == 1:
			for branch: StringName in _stats.branch_ids(_record.kind):
				row.add_child(_make_upgrade_button(branch_label(_stats, _record.kind, branch), branch, short))
		else:
			row.add_child(_make_upgrade_button("Niveau 3", &"", short))
	var pick_up := _make_button("Reprendre")
	pick_up.pressed.connect(_on_pick_up_pressed)
	_column.add_child(pick_up)


## The evolution part of a level 3 panel (towers T2b §6).
func _add_evolution_rows() -> void:
	var def: TowerDef = _stats.def_of(_record.kind)
	if def == null:
		return
	var branch: StringName = _record.branch
	var status: StringName = evolution_status(_record)
	if status == EvolutionRules.EVOLVED:
		_column.add_child(_make_label("Évolution : %s" % def.evolution_name(branch), TEXT_FONT_SIZE, EVOLVED_COLOR))
	elif status == EvolutionRules.READY:
		_column.add_child(_make_label("Évolution : %s" % def.evolution_name(branch), TEXT_FONT_SIZE, EVOLVED_COLOR))
		var evolve: Button = _make_button("ÉVOLUER !")
		evolve.add_theme_color_override(&"font_color", EVOLVED_COLOR)
		evolve.pressed.connect(_on_evolve_pressed)
		_column.add_child(evolve)
	elif status == EvolutionRules.MISSING:
		_column.add_child(_make_label("Évolue avec : %s" % EvolutionRules.requirement_label(def, branch), TEXT_FONT_SIZE, DISABLED_COLOR))
	elif status == EvolutionRules.OTHER_HERO:
		var hero: String = def.requirement_spec_name(branch)
		if hero.is_empty():
			hero = String(def.requirement_spec(branch))
		_column.add_child(_make_label("Évolution réservée à %s" % hero, TEXT_FONT_SIZE, DISABLED_COLOR))


func _has_card(card_id: String) -> bool:
	return _modifiers.stacks_of(card_id) > 0


func _make_upgrade_button(text: String, branch: StringName, short: bool) -> Button:
	var button: Button = _make_button(text)
	button.disabled = short
	button.pressed.connect(_on_upgrade_pressed.bind(branch))
	return button


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE  # Space starts the wave: a focused button must not react to it.
	button.custom_minimum_size = BUTTON_SIZE
	button.add_theme_font_size_override(&"font_size", BUTTON_FONT_SIZE)
	button.add_theme_font_override(&"font", NeonFonts.title())
	button.add_theme_color_override(&"font_disabled_color", DISABLED_COLOR)
	return button


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	NeonFonts.style_label(label, NeonFonts.title())
	return label


func _on_upgrade_pressed(branch: StringName) -> void:
	if _record != null:
		upgrade_requested.emit(_record, branch)


func _on_evolve_pressed() -> void:
	if _record != null:
		evolve_requested.emit(_record)


func _on_pick_up_pressed() -> void:
	if _record == null:
		return
	var picked: TowerRecord = _record
	close()
	pick_up_requested.emit(picked)
