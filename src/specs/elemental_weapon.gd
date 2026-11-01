## The weapon of the Maître du feu (« fire_bolts ») and of the Maître de l'eau
## (« water_jets ») — story 009, design/game-brief.md « Après le MVP ». Pure
## rules, no scene tree: values come from the specialization's "weapon" object
## plus the cards in [PlayerModifiers], read at use time so a card acts at once.
## A weapon only has the status keys of its type: the others read 0 and the
## bullet applies nothing for them.
class_name ElementalWeapon
extends RefCounted

var _weapon: Dictionary
var _modifiers: PlayerModifiers


## [param weapon] is a validated "fire_bolts" or "water_jets" object from specializations.json.
func _init(weapon: Dictionary, modifiers: PlayerModifiers) -> void:
	_weapon = weapon
	_modifiers = modifiers


## Shots per second, weapon fire-rate cards included.
func fire_rate() -> float:
	return float(_weapon["fire_rate"]) * _modifiers.weapon_fire_rate_factor()


## Damage of one hit before combo multipliers, card damage bonus included.
func damage() -> float:
	return float(_weapon["damage"]) * _modifiers.damage_multiplier()


## Distance in pixels a shot travels.
func max_range() -> float:
	return float(_weapon["range"])


## How many different enemies one shot hits before it disappears.
func pierce() -> int:
	return roundi(_weapon["pierce"]) + _modifiers.pierce_bonus()


## Seconds an enemy burns after a hit; 0 when this weapon does not ignite.
func burn_duration() -> float:
	if not _weapon.has("burn_duration"):
		return 0.0
	return float(_weapon["burn_duration"]) + _modifiers.burn_duration_bonus()


## Burn damage per second; 0 when this weapon does not ignite.
func burn_damage_per_second() -> float:
	if not _weapon.has("burn_damage_per_second"):
		return 0.0
	return float(_weapon["burn_damage_per_second"]) + _modifiers.burn_dps_bonus()


## Seconds an enemy stays wet after a hit; 0 when this weapon does not soak.
func wet_duration() -> float:
	if not _weapon.has("wet_duration"):
		return 0.0
	return float(_weapon["wet_duration"]) + _modifiers.wet_duration_bonus()
