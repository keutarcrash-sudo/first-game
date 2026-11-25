## Freeze rules of the frost towers (towers T1, Task 2), held by each [Enemy]: how long
## the enemy has stayed in at least one frost zone, when it may freeze, and the damage
## factor of a frozen enemy. Pure logic, no node: see chill_rules_check.gd.
class_name ChillRules
extends RefCounted

## Slack on the dwell threshold, so summed float frame times reach it on the expected frame.
const DWELL_EPSILON := 0.0001

var _dwell := 0.0  # Seconds spent in at least one frost zone, without leaving them all.


## Adds [param delta] seconds when [param chilled_this_frame] (several zones do not add up),
## or starts over from 0 when the enemy left every zone. Returns [code]true[/code] once the
## time reaches [param dwell_needed]; the count then starts over from 0.
func tick(delta: float, chilled_this_frame: bool, dwell_needed: float) -> bool:
	if not chilled_this_frame:
		_dwell = 0.0
		return false
	_dwell += delta
	if _dwell + DWELL_EPSILON >= dwell_needed:
		_dwell = 0.0
		return true
	return false


## Starts the dwell count over from 0 (while the enemy cannot freeze, time in a zone does not count).
func reset() -> void:
	_dwell = 0.0


## Seconds counted so far in the zones.
func dwell() -> float:
	return _dwell


## True when a new freeze may start: not [param frozen] and no [param cooldown_left] remaining.
func can_freeze(frozen: bool, cooldown_left: float) -> bool:
	return not frozen and cooldown_left <= 0.0


## Damage factor of an enemy: 1 + [param base] + [param bonus] while [param frozen]
## (whatever froze it), 1 otherwise. Multiplied with Combustion by the caller.
static func damage_factor(frozen: bool, base: float, bonus: float) -> float:
	return 1.0 + base + bonus if frozen else 1.0
