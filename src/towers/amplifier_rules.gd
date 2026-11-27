## Pure rules of the amplifier bonuses (towers T2a): several amplifiers over one tower do
## not add up, each bonus type takes the strongest of them, separately (a Cadence and a
## Catalyseur both apply). Applying: damage x (1 + [code]damage[/code]), fire interval
## / (1 + [code]rate[/code]), durations of the states a tower sets x (1 + [code]state[/code]).
class_name AmplifierRules
extends RefCounted

## The bonus keys, in this order.
const KEYS: Array[String] = ["damage", "rate", "state"]


## Bonuses of no amplifier: all zero.
static func neutral() -> Dictionary:
	return {"damage": 0.0, "rate": 0.0, "state": 0.0}


## The bonuses over a tower reached by the amplifiers of [param boosts] (each
## [code]{ "damage": float, "rate": float, "state": float }[/code], a missing key counts
## as 0): the maximum per key; zeros for an empty list.
static func combine(boosts: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = neutral()
	for boost: Dictionary in boosts:
		for key: String in KEYS:
			result[key] = maxf(float(result[key]), float(boost.get(key, 0.0)))
	return result
