## The Archer's bow (story 008, design/game-brief.md « Après le MVP », Archer):
## piercing arrows, long range, critical hits that mark the target. Pure rules,
## no scene tree: values come from the specialization's "weapon" object plus the
## Archer cards in [PlayerModifiers], read at use time so a card acts at once.
class_name ArcherWeapon
extends RefCounted

var _weapon: Dictionary
var _modifiers: PlayerModifiers
var _rng: RandomNumberGenerator
var _force_next_crit := false
var _always_crit := false


## [param weapon] is a validated "arrows" weapon object from specializations.json;
## [param rng] decides the critical hits.
func _init(weapon: Dictionary, modifiers: PlayerModifiers, rng: RandomNumberGenerator) -> void:
	_weapon = weapon
	_modifiers = modifiers
	_rng = rng


## Arrows per second.
func fire_rate() -> float:
	return float(_weapon["fire_rate"])


## Damage of one arrow hit before critical and combo multipliers, card damage bonus included.
func damage() -> float:
	return float(_weapon["damage"]) * _modifiers.damage_multiplier()


## Distance in pixels an arrow travels.
func max_range() -> float:
	return float(_weapon["range"])


## How many different enemies one arrow hits before it disappears.
func pierce() -> int:
	return roundi(_weapon["pierce"]) + _modifiers.pierce_bonus()


## Chance (0 to 1) that a hit is critical.
func crit_chance() -> float:
	return minf(float(_weapon["crit_chance"]) + _modifiers.crit_chance_bonus(), 1.0)


## Damage multiplier of a critical hit.
func crit_multiplier() -> float:
	return float(_weapon["crit_multiplier"]) + _modifiers.crit_multiplier_bonus()


## Seconds an enemy stays marked after a critical hit.
func mark_duration() -> float:
	return float(_weapon["mark_duration"]) + _modifiers.mark_duration_bonus()


## Makes the next [method roll_crit] return [code]true[/code] (étape 3b, Roulade); that roll consumes it.
func force_next_crit() -> void:
	_force_next_crit = true


## While [param active], every [method roll_crit] returns [code]true[/code] (étape 3b, Œil du chasseur).
func set_always_crit(active: bool) -> void:
	_always_crit = active


## Rolls one hit: [code]true[/code] when it is critical (forced, always-critical, or by chance).
## A forced critical is consumed by the roll.
func roll_crit() -> bool:
	if _force_next_crit:
		_force_next_crit = false
		return true
	if _always_crit:
		return true
	return _rng.randf() < crit_chance()
