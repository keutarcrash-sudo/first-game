## Amplifier behaviour (towers T2a, spec §5.4 and §8bis): it does not shoot; the other
## towers within its range get its bonuses ([method boost]), the strongest amplifier per
## bonus type counting ([AmplifierRules], read by the [TowerPlacer] in
## [member TowerBehaviour.TowerContext.amp_at]). Base: +[code]damage_bonus[/code] damage.
## Cadence (level 2+): +[code]rate_bonus[/code] fire rate (interval / (1 + bonus)).
## Catalyseur (level 2+): the states the towers around set last +[code]state_bonus[/code].
## Branch and level are read live. Drawn as a pulsing ring with small links to the
## boosted towers (not to other amplifiers: an amplifier is never amplified).
## Towers T2b, Surrégime (evolved Cadence): the rate bonus x [code]rate_mult[/code]. Nexus
## (evolved Catalyseur): the towers it boosts share their light states ([NexusRules], built
## by the [TowerPlacer] from [method nexus_values]).
class_name AmplifierBehaviour
extends TowerBehaviour

const CADENCE := &"cadence"
const CATALYSEUR := &"catalyseur"

const PULSE_SPEED := 3.0  # Radians per second of the ring pulse.
const RING_COLOR := Color(0.85, 0.45, 1.0)
const RING_ALPHA_MIN := 0.15
const RING_ALPHA_MAX := 0.5
const RING_WIDTH := 3.0
const RING_POINTS := 64
const LINK_COLOR := Color(0.9, 0.6, 1.0, 0.45)
const LINK_WIDTH := 2.0

var _tower: Tower
var _def: TowerDef
var _record: TowerRecord
var _ctx: TowerBehaviour.TowerContext
var _time := 0.0


## See [method TowerBehaviour.setup].
func setup(tower: Tower, def: TowerDef, record: TowerRecord, ctx: TowerBehaviour.TowerContext) -> void:
	_tower = tower
	_def = def
	_record = record
	_ctx = ctx


## Range with the card and item bonuses.
func range_now() -> float:
	return _number("range") * _ctx.modifiers.tower_range_factor()


## The bonuses this amplifier gives right now: [code]{ "damage", "rate", "state" }[/code]
## (0 for a bonus its branch and level do not give).
func boost() -> Dictionary:
	var rate: float = _number("rate_bonus")
	if _is_evolved(CADENCE):
		rate *= _number("rate_mult")  # Surrégime.
	return {"damage": _number("damage_bonus"), "rate": rate, "state": _number("state_bonus")}


## True for a Nexus (evolved level 3 Catalyseur, towers T2b).
func is_nexus() -> bool:
	return _is_evolved(CATALYSEUR)


## The Nexus evolution values ([constant NexusRules.KEYS]) when this amplifier is a Nexus,
## else empty.
func nexus_values() -> Dictionary:
	var values: Dictionary = {}
	if not is_nexus():
		return values
	for key: String in NexusRules.KEYS:
		values[key] = _def.value(key, CATALYSEUR, _record.level, true)
	return values


## Advances the pulse; the ring and the links are redrawn every frame.
func physics_tick(delta: float) -> void:
	_time = fmod(_time + delta * PULSE_SPEED, TAU)
	_tower.queue_redraw()


## The pulsing ring at the range and a link to each boosted tower.
func draw(canvas: CanvasItem) -> void:
	var pulse: float = 0.5 + 0.5 * sin(_time)
	var ring := Color(RING_COLOR, lerpf(RING_ALPHA_MIN, RING_ALPHA_MAX, pulse))
	var reach: float = _tower.attack_range
	canvas.draw_arc(Vector2.ZERO, reach * lerpf(0.96, 1.0, pulse), 0.0, TAU, RING_POINTS, ring, RING_WIDTH, true)
	var towers: Node = _tower.get_parent()
	if towers == null:
		return
	for child: Node in towers.get_children():
		var other := child as Tower
		if other == null or other == _tower or other.behaviour() is AmplifierBehaviour:
			continue
		if _tower.global_position.distance_squared_to(other.global_position) > reach * reach:
			continue
		canvas.draw_line(Vector2.ZERO, _tower.to_local(other.global_position), LINK_COLOR, LINK_WIDTH, true)


## True for an evolved level 3 amplifier of [param branch] (towers T2b).
func _is_evolved(branch: StringName) -> bool:
	return _record.evolved and _record.level >= TowerRecord.MAX_LEVEL and _record.branch == branch


## Value [param key] for this tower's branch, level and evolution ([method TowerDef.value]), 0
## when none has it. Required keys are validated by [TowerStats].
func _number(key: String) -> float:
	var value: Variant = _def.value(key, _record.branch, _record.level, _record.evolved)
	return 0.0 if value == null else float(value)
