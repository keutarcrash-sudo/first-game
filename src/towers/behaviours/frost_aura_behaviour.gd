## Frost aura behaviour, the frost tower (story 004, moved from the T1 FrostTower): every
## physics frame, asks each enemy within range to be slowed to [code]slow_factor[/code].
## It never remembers which enemies it slowed: the enemy drops the slow by itself as soon
## as no tower refreshes it (see [method Enemy.apply_slow]). Slow and range are read from
## the card modifiers every frame (story 006), so cards act on placed towers.
## Story 009: with the Maître de l'eau (freeze enabled in the modifiers), each wet
## enemy in range is also offered to [method Enemy.try_freeze].
## Towers T1: each enemy in range is also asked for the tower freeze ([method Enemy.apply_chill],
## « Gel profond » lengthens it), tagged with this tower's [TowerRecord] id, read every frame so
## an upgrade acts at once. Blizzard (level 2+): range x [code]range_mult[/code] and a shorter
## dwell; at level 3 an enemy this tower freezes is also wet for [code]l3_wet_duration[/code]
## seconds. Éclats acts at the enemy's death ([TowerEffects]).
## Towers T2b, Cœur de l'hiver (evolved Blizzard): every [code]pulse_interval[/code] seconds
## (as soon as an enemy is in range once it is due), every enemy in range is frozen for
## [code]pulse_freeze[/code] x (1 + state) seconds through [method Enemy.force_freeze], which
## ignores the refreeze cooldown; a shock ring spreads over the zone. Avalanche: [TowerEffects].
class_name FrostAuraBehaviour
extends TowerBehaviour

const BLIZZARD := &"blizzard"
const PULSE_RING_COLOR := Color(0.8, 0.95, 1.0, 0.9)
const PULSE_RING_WIDTH := 4.0
const PULSE_RING_SECONDS := 0.4  # The shock ring grows from the tower to the range edge in this time.
const PULSE_RING_POINTS := 48

var _tower: Tower
var _def: TowerDef
var _record: TowerRecord
var _ctx: TowerBehaviour.TowerContext
var _base_slow_factor: float
var _wetted: Dictionary = {}  # Instance ids of the enemies frozen by this tower and already wet for it (Blizzard 3).
var _still_frozen: Dictionary = {}  # Same, built during the current frame, then swapped with _wetted.
var _pulse_left := 0.0  # Seconds before the next Cœur de l'hiver pulse is due.
var _ring_left := 0.0  # Seconds the shock ring of the last pulse is still drawn.


## See [method TowerBehaviour.setup].
func setup(tower: Tower, def: TowerDef, record: TowerRecord, ctx: TowerBehaviour.TowerContext) -> void:
	_tower = tower
	_def = def
	_record = record
	_ctx = ctx
	_base_slow_factor = float(def.values["slow_factor"])


## Range with the card and item bonuses and the Blizzard bonus.
func range_now() -> float:
	var modifiers: PlayerModifiers = _ctx.modifiers
	var factor: float = modifiers.frost_range_factor() * modifiers.tower_range_factor()
	if _is_blizzard():
		factor *= _blizzard_number("range_mult")
	return _def.range * factor


## Slows, chills and (Maître de l'eau, Blizzard 3) freezes or wets the enemies in range.
func physics_tick(delta: float) -> void:
	var modifiers: PlayerModifiers = _ctx.modifiers
	var stats: TowerStats = _ctx.stats
	var blizzard: bool = _is_blizzard()
	var wet_on_freeze: bool = blizzard and _record.level >= TowerRecord.MAX_LEVEL
	var slow_factor: float = modifiers.frost_slow_factor(_base_slow_factor)
	var water_duration: float = modifiers.freeze_duration()
	var water_cooldown: float = modifiers.freeze_cooldown()
	var dwell: float = _blizzard_number("dwell") if blizzard else stats.freeze_dwell
	# Catalyseur: the freeze and the Blizzard wet this tower sets last longer (not the dwell or the cooldown).
	var amp: Dictionary = _ctx.amp_at.call(_tower.global_position, _record.id)
	var state_factor: float = 1.0 + float(amp["state"])
	var chill_duration: float = (stats.freeze_duration + modifiers.freeze_duration_bonus()) * state_factor
	var range_sq: float = _tower.attack_range * _tower.attack_range
	var enemies: Node2D = _ctx.enemies
	var heart: bool = _is_heart_of_winter()
	var pulse_freeze: float = _evolution_number("pulse_freeze") * state_factor if heart else 0.0
	_pulse_left = maxf(_pulse_left - delta, 0.0)
	var pulsed := false
	_still_frozen.clear()
	for i: int in enemies.get_child_count():
		var enemy := enemies.get_child(i) as Enemy
		if enemy == null or _tower.global_position.distance_squared_to(enemy.global_position) > range_sq:
			continue
		if heart and _pulse_left <= 0.0:
			enemy.force_freeze(pulse_freeze, _record.id)  # Whatever the refreeze cooldown (spec §7bis); keeps this tower as freezer.
			pulsed = true
		enemy.apply_slow(slow_factor)
		enemy.apply_chill(dwell, chill_duration, stats.freeze_cooldown, _record.id)
		if water_duration > 0.0:
			enemy.try_freeze(water_duration, water_cooldown, _record.id)
		if wet_on_freeze and enemy.has_state(&"frozen") and enemy.last_freezer_id() == _record.id:
			var key: int = enemy.get_instance_id()
			_still_frozen[key] = true
			if not _wetted.has(key):  # Once per freeze, when it is first seen.
				enemy.apply_wet(_blizzard_number("l3_wet_duration") * state_factor)
	var previous: Dictionary = _wetted
	_wetted = _still_frozen
	_still_frozen = previous
	if pulsed:
		_pulse_left = _evolution_number("pulse_interval")
		_ring_left = PULSE_RING_SECONDS
	if _ring_left > 0.0:
		_ring_left = maxf(_ring_left - delta, 0.0)
		_tower.queue_redraw()


## The shock ring of the last Cœur de l'hiver pulse, growing to the range edge, while it is visible.
func draw(canvas: CanvasItem) -> void:
	if _ring_left <= 0.0:
		return
	var progress: float = 1.0 - _ring_left / PULSE_RING_SECONDS
	var color := Color(PULSE_RING_COLOR, PULSE_RING_COLOR.a * (1.0 - progress))
	canvas.draw_arc(Vector2.ZERO, _tower.attack_range * progress, 0.0, TAU, PULSE_RING_POINTS, color, PULSE_RING_WIDTH, true)


func _is_blizzard() -> bool:
	return _record.level >= 2 and _record.branch == BLIZZARD


## Number [param key] of the Blizzard branch (required and validated by [constant TowerStats.BRANCH_KEYS]).
func _blizzard_number(key: String) -> float:
	return float(_def.branch_value(BLIZZARD, key))


## True for a Cœur de l'hiver: an evolved level 3 Blizzard frost tower (towers T2b).
func _is_heart_of_winter() -> bool:
	return _record.evolved and _record.level >= TowerRecord.MAX_LEVEL and _record.branch == BLIZZARD


## Number [param key] of the Blizzard evolution (required and validated by [constant TowerStats.EVOLUTION_KEYS]).
func _evolution_number(key: String) -> float:
	return float(_def.value(key, BLIZZARD, _record.level, true))
