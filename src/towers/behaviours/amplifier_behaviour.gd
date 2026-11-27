## Amplifier behaviour (towers T2a, spec §5.4 and §8bis): it does not shoot; the other
## towers within its range get its bonuses ([method boost]), the strongest amplifier per
## bonus type counting ([AmplifierRules], read by the [TowerPlacer] in
## [member TowerBehaviour.TowerContext.amp_at]). Base: +[code]damage_bonus[/code] damage.
## Cadence (level 2+): +[code]rate_bonus[/code] fire rate (interval / (1 + bonus)).
## Catalyseur (level 2+): the states the towers around set last +[code]state_bonus[/code].
## Branch and level are read live. Drawn as a pulsing ring with small links to the
## boosted towers (not to other amplifiers: an amplifier is never amplified).
class_name AmplifierBehaviour
extends TowerBehaviour

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
	return {"damage": _number("damage_bonus"), "rate": _number("rate_bonus"), "state": _number("state_bonus")}


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


## Value [param key] for this tower's branch and level ([method TowerDef.value]), 0 when
## neither has it. Required keys are validated by [TowerStats].
func _number(key: String) -> float:
	var value: Variant = _def.value(key, _record.branch, _record.level)
	return 0.0 if value == null else float(value)
