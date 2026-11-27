## Pure rules of the burn (towers T2a, spec §8bis « Brûlures qui se croisent »): how a new
## burn merges with the one already running and how the Napalm level 3 burn stacks.
## No node: [Enemy] calls these from [method Enemy.apply_burn].
class_name BurnRules
extends RefCounted


## Merges a running burn ([param cur_dps] per second, [param cur_left] seconds left) with a
## new one ([param new_dps], [param new_left]): keeps the stronger damage per second and the
## longer time left, each on its own. Returns x = damage per second, y = seconds left.
static func merge(cur_dps: float, cur_left: float, new_dps: float, new_left: float) -> Vector2:
	return Vector2(maxf(cur_dps, new_dps), maxf(cur_left, new_left))


## Damage per second of a stacking burn: [param base_dps] times [param stacks], never more
## than [param max_mult] times [param base_dps] nor less than [param base_dps].
static func stacked_dps(base_dps: float, stacks: float, max_mult: float) -> float:
	return base_dps * clampf(stacks, 1.0, maxf(max_mult, 1.0))
