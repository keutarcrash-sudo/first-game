## Small panel, top right under the specialization line: the hero's real stats
## (damage, fire rate, speed, pickup range, then the lines of the chosen
## specialization, then the item lines (étape 5a) shown only when they differ from
## the base). Every value is read from the same getters the game uses, so
## cards are included. A value that just went up is shown in green with "▲" for
## [constant RAISED_SECONDS] (for a cost or a damage taken, "went up" means "got
## better": the compared value is the saving). One block: a fixed-width column anchored
## to the right edge (names and values side by side, a long name is cut with "…"
## rather than widening it) on a dark translucent backing that reads over the floor.
## Display only: it never changes game state.
class_name StatsPanel
extends Control

## Width of the whole block, backing included (screen px).
const WIDTH := 280.0
const TOP := 36.0  # Under the specialization line of the HUD (top 4 px, 20 px font).
const PADDING := 8.0
const BACK_COLOR := Color(0.03, 0.02, 0.08, 0.72)
const BACK_BORDER_COLOR := Color(0.55, 0.9, 1.0, 0.35)
const BACK_CORNER_RADIUS := 6
const NAME_VALUE_GAP := 10
const RIGHT_MARGIN := 40.0
const ROW_FONT_SIZE := 17
const ROW_SEPARATION := 0
const RAISED_SECONDS := 4.0
const RAISED_EPSILON := 0.0001
const RAISED_MARK := "▲ "
const NAME_COLOR := Color(0.9, 0.95, 1.0)
const VALUE_COLOR := Color(1.0, 0.9, 0.35)
const RAISED_COLOR := Color(0.4, 1.0, 0.5)

var _hero: Hero
var _modifiers: PlayerModifiers
var _economy: EconomyStats
var _stats: HeroStats
var _towers: TowerStats
var _reserve: TowerReserve  # Real next prices once bound ([method bind_reserve]).
var _box: VBoxContainer
var _previous: Dictionary = {}  # { row id: value at the last refresh }
var _raised_left: Dictionary = {}  # { row id: seconds left showing the green arrow }


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -(WIDTH + RIGHT_MARGIN)
	offset_right = -RIGHT_MARGIN
	offset_top = TOP
	offset_bottom = TOP
	# The backing hugs the rows: full width of this column, as tall as its content.
	var back := PanelContainer.new()
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var style := StyleBoxFlat.new()
	style.bg_color = BACK_COLOR
	style.border_color = BACK_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(BACK_CORNER_RADIUS)
	style.set_content_margin_all(PADDING)
	back.add_theme_stylebox_override(&"panel", style)
	add_child(back)
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override(&"separation", ROW_SEPARATION)
	back.add_child(_box)
	set_process(false)


## Gives the panel what it reads and keeps it up to date on
## [signal PlayerModifiers.changed]. [param stats] gives the base walking speed,
## [param economy] the base pickup radius and gold per kill, [param towers] the base
## tower prices. Call once, after the [CrystalHud] is ready.
func setup(hero: Hero, modifiers: PlayerModifiers, economy: EconomyStats, stats: HeroStats, towers: TowerStats) -> void:
	_towers = towers
	_hero = hero
	_modifiers = modifiers
	_economy = economy
	_stats = stats
	modifiers.changed.connect(refresh)
	hero.health().changed.connect(refresh.unbind(2))
	refresh()


## Rereads every value, marks the ones that increased, and redraws the rows.
## Also call it once the hero is equipped (the specialization lines appear then).
func refresh() -> void:
	if _modifiers == null or _box == null:
		return
	var rows: Array[Dictionary] = _collect_rows()
	for row: Dictionary in rows:
		var id: String = row["id"]
		var value: float = row["value"]
		if _previous.has(id) and value > float(_previous[id]) + RAISED_EPSILON:
			_raised_left[id] = RAISED_SECONDS
		_previous[id] = value
	set_process(not _raised_left.is_empty())
	_redraw(rows)


func _process(delta: float) -> void:
	var expired := false
	for id: String in _raised_left.keys():
		var left: float = float(_raised_left[id]) - delta
		if left <= 0.0:
			_raised_left.erase(id)
			expired = true
		else:
			_raised_left[id] = left
	if expired:
		refresh()


## Shows the real next purchase prices of [param reserve] in the tower price line
## and rereads them on every [signal TowerReserve.changed].
func bind_reserve(reserve: TowerReserve) -> void:
	_reserve = reserve
	reserve.changed.connect(refresh)
	refresh()


## The rows to show: { id, label, value (compared), text (shown) }.
func _collect_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var damage: float = _modifiers.hero_damage_multiplier()
	rows.append(_row("damage", "Dégâts", damage, "×%.2f" % damage))
	var archer: ArcherWeapon = _hero.archer_weapon()
	var elemental: ElementalWeapon = _hero.elemental_weapon()
	if archer != null:
		var rate: float = archer.fire_rate()
		rows.append(_row("fire_rate", "Cadence", rate, "%.2f /s" % rate))
	elif elemental != null:
		var rate: float = elemental.fire_rate()
		rows.append(_row("fire_rate", "Cadence", rate, "%.2f /s" % rate))
	var speed: float = _stats.hero_speed * _modifiers.move_speed_factor()
	rows.append(_row("speed", "Vitesse", speed, "%d px/s" % roundi(speed)))
	var pickup: float = _economy.pickup_radius * _modifiers.pickup_radius_factor()
	rows.append(_row("pickup", "Ramassage", pickup, "%d px" % roundi(pickup)))
	var max_hp: float = _hero.health().max_hp
	rows.append(_row("max_hp", "PV max", max_hp, "%d" % roundi(max_hp)))
	var regen: float = _modifiers.hero_regen()
	if regen > 0.0:
		rows.append(_row("regen", "Régénération", regen, "%.1f PV/s" % regen))
	if archer != null:
		var chance: float = archer.crit_chance()
		rows.append(_row("crit_chance", "Critique", chance, "%d %%" % roundi(chance * 100.0)))
		var mult: float = archer.crit_multiplier()
		rows.append(_row("crit_mult", "Dégâts critiques", mult, "×%.2f" % mult))
		var pierce: int = archer.pierce()
		rows.append(_row("pierce", "Ennemis traversés", float(pierce), "%d" % pierce))
	if elemental != null:
		if elemental.burn_duration() > 0.0:
			var dps: float = elemental.burn_damage_per_second()
			rows.append(_row("burn_dps", "Brûlure", dps, "%.1f /s" % dps))
			var burn: float = elemental.burn_duration()
			rows.append(_row("burn_time", "Durée brûlure", burn, "%.1f s" % burn))
		if elemental.wet_duration() > 0.0:
			var wet: float = elemental.wet_duration()
			rows.append(_row("wet_time", "Trempé", wet, "%.1f s" % wet))
		var freeze: float = _modifiers.freeze_duration()
		if freeze > 0.0:
			rows.append(_row("freeze_time", "Gel", freeze, "%.1f s" % freeze))
	_append_item_rows(rows)
	return rows


## Item lines (étape 5a spec §8), each shown only when it differs from the base.
func _append_item_rows(rows: Array[Dictionary]) -> void:
	var tower_range: float = _modifiers.tower_range_factor()
	if not is_equal_approx(tower_range, 1.0):
		rows.append(_row("tower_range", "Portée des tours", tower_range, "+%d %%" % roundi((tower_range - 1.0) * 100.0)))
	var cannon_base: int = _towers.cannon_cost
	var frost_base: int = _towers.frost_cost
	if _reserve != null:
		cannon_base = _reserve.price_of_next(TowerStats.Kind.CANNON, 1.0)
		frost_base = _reserve.price_of_next(TowerStats.Kind.FROST, 1.0)
	var cannon_cost: int = _modifiers.tower_cost(cannon_base)
	var frost_cost: int = _modifiers.tower_cost(frost_base)
	if _reserve != null:
		cannon_cost = _reserve.price_of_next(TowerStats.Kind.CANNON, _modifiers.tower_cost_factor())
		frost_cost = _reserve.price_of_next(TowerStats.Kind.FROST, _modifiers.tower_cost_factor())
	var saved: int = cannon_base - cannon_cost + frost_base - frost_cost
	if saved != 0:
		rows.append(_row("tower_cost", "Coût des tours", float(saved), "%d / %d or" % [cannon_cost, frost_cost]))
	var crystal_factor: float = _modifiers.crystal_damage_factor()
	if not is_equal_approx(crystal_factor, 1.0):
		var reduction: float = 1.0 - crystal_factor
		rows.append(_row("crystal_damage", "Dégâts subis par le cristal", reduction, "-%d %%" % roundi(reduction * 100.0)))
	var gold: int = _modifiers.gold_per_kill(_economy.gold_per_kill + _modifiers.gold_per_kill_bonus())
	if gold != _economy.gold_per_kill:
		rows.append(_row("gold_per_kill", "Or par ennemi", float(gold), "%d" % gold))
	var heal: float = _modifiers.hero_heal_per_wave()
	if heal > 0.0:
		rows.append(_row("heal_per_wave", "Soin par vague", heal, "%d PV" % roundi(heal)))
	if _modifiers.has_flag(&"second_chance"):
		var armed: bool = _hero.health().has_rescue()
		rows.append(_row("second_chance", "Seconde chance", 1.0 if armed else 0.0, "prête" if armed else "utilisée"))


func _row(id: String, label: String, value: float, text: String) -> Dictionary:
	return {"id": id, "label": label, "value": value, "text": text}


func _redraw(rows: Array[Dictionary]) -> void:
	for child: Node in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	for row: Dictionary in rows:
		var raised: bool = _raised_left.has(row["id"])
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override(&"separation", NAME_VALUE_GAP)
		var name_label := _make_label(String(row["label"]), NeonFonts.title(), NAME_COLOR)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Cut, never widen: the column keeps its width whatever the name.
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_child(name_label)
		var value_text: String = String(row["text"])
		if raised:
			value_text = RAISED_MARK + value_text
		var value_label := _make_label(value_text, NeonFonts.numbers(), RAISED_COLOR if raised else VALUE_COLOR)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(value_label)
		_box.add_child(line)


func _make_label(text: String, font: Font, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	label.add_theme_color_override(&"font_color", color)
	NeonFonts.style_label(label, font)
	return label
