## The Archer's bow (story 008, design/game-brief.md « Après le MVP », Archer):
## piercing arrows, long range, critical hits that mark the target. Pure rules,
## no scene tree: values come from the specialization's "weapon" object plus the
## Archer cards in [PlayerModifiers], read at use time so a card acts at once.
class_name ArcherWeapon
extends RefCounted

var _weapon: Dictionary
var _modifiers: PlayerModifiers
var _rng: RandomNumberGenerator


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


## Rolls one hit: [code]true[/code] when it is critical.
func roll_crit() -> bool:
	return _rng.randf() < crit_chance()
