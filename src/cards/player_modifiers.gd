## What the player has gained from cards during this game (story 006): stacks
## per card and the resulting modifiers. Pure logic, no scene tree. Towers, the
## hero and the wave cycle share one instance and read it at use time, so a card
## acts at once on towers that are already placed.
class_name PlayerModifiers
extends RefCounted

## Emitted after a card is taken.
signal changed
## Emitted when a card asks the crystal to recover [param amount] hit points.
signal heal_requested(amount: float)

var _rules: ProcRules
var _stacks: Dictionary = {}
var _taken: Array[CardDef] = []
var _fire_rate_bonus := 0.0
var _damage_bonus := 0.0
var _slow_mult := 1.0
var _slow_floor := 0.0
var _range_bonus := 0.0
var _gold_bonus := 0
var _burn_duration := 0.0
var _burn_dps := 0.0
var _pierce_bonus := 0
var _crit_chance_bonus := 0.0
var _crit_mult_bonus := 0.0
var _mark_duration_bonus := 0.0
var _weapon_rate_bonus := 0.0
var _burn_dps_bonus := 0.0
var _burn_duration_bonus := 0.0
var _wet_duration_bonus := 0.0
var _freeze_duration_bonus := 0.0
var _freeze_base_duration := 0.0
var _freeze_cooldown := 0.0


## [param rules] receives the combos unlocked by cards.
func _init(rules: ProcRules) -> void:
	_rules = rules


## How many times the card [param card_id] has been taken.
func stacks_of(card_id: String) -> int:
	return _stacks.get(card_id, 0)


## True while [param card] has not reached its maximum number of stacks.
func can_take(card: CardDef) -> bool:
	return card.max_stacks < 0 or stacks_of(card.id) < card.max_stacks


## Takes [param card] once and applies its effects. Ignored if [method can_take] is false.
func take(card: CardDef) -> void:
	if not can_take(card):
		return
	if not _stacks.has(card.id):
		_taken.append(card)
	_stacks[card.id] = stacks_of(card.id) + 1
	for effect: Dictionary in card.effects:
		match String(effect["type"]):
			"cannon_fire_rate_bonus":
				_fire_rate_bonus += float(effect["value"])
			"damage_bonus":
				_damage_bonus += float(effect["value"])
			"frost_slow_factor_mult":
				_slow_mult *= float(effect["value"])
				_slow_floor = float(effect["min_factor"])
			"frost_range_bonus":
				_range_bonus += float(effect["value"])
			"heal_crystal":
				heal_requested.emit(float(effect["value"]))
			"gold_per_kill_bonus":
				_gold_bonus += int(effect["value"])
			"cannon_burn":
				_burn_duration = float(effect["duration"])
				_burn_dps = float(effect["damage_per_second"])
			"unlock_combo":
				_rules.activate(String(effect["combo_id"]))
			"pierce_bonus":
				_pierce_bonus += roundi(effect["value"])
			"crit_chance_bonus":
				_crit_chance_bonus += float(effect["value"])
			"crit_multiplier_bonus":
				_crit_mult_bonus += float(effect["value"])
			"mark_duration_bonus":
				_mark_duration_bonus += float(effect["value"])
			"weapon_fire_rate_bonus":
				_weapon_rate_bonus += float(effect["value"])
			"burn_dps_bonus":
				_burn_dps_bonus += float(effect["value"])
			"burn_duration_bonus":
				_burn_duration_bonus += float(effect["value"])
			"wet_duration_bonus":
				_wet_duration_bonus += float(effect["value"])
			"freeze_duration_bonus":
				_freeze_duration_bonus += float(effect["value"])
	changed.emit()


## Factor applied to the cannon's fire interval (1.0 = unchanged, below 1 = faster).
func cannon_interval_factor() -> float:
	return 1.0 / (1.0 + _fire_rate_bonus)


## Factor applied to hero and cannon shot damage, before combo multipliers.
func damage_multiplier() -> float:
	return 1.0 + _damage_bonus


## The frost slow factor to use given the tower's base [param base] (lower = slower), never below the card floor.
func frost_slow_factor(base: float) -> float:
	return minf(base, maxf(base * _slow_mult, _slow_floor))


## Factor applied to the frost tower's range.
func frost_range_factor() -> float:
	return 1.0 + _range_bonus


## Extra gold per enemy killed.
func gold_per_kill_bonus() -> int:
	return _gold_bonus


## Burn duration in seconds given to cannon shots; 0 when no card makes them burn.
func burn_duration() -> float:
	return _burn_duration


## Burn damage per second.
func burn_damage_per_second() -> float:
	return _burn_dps


## Extra enemies an Archer arrow passes through.
func pierce_bonus() -> int:
	return _pierce_bonus


## Added to the Archer's critical hit chance (0.1 = +10 %).
func crit_chance_bonus() -> float:
	return _crit_chance_bonus


## Added to the Archer's critical hit damage multiplier.
func crit_multiplier_bonus() -> float:
	return _crit_mult_bonus


## Extra seconds an enemy stays marked.
func mark_duration_bonus() -> float:
	return _mark_duration_bonus


## Factor applied to the chosen specialization's weapon fire rate (story 009); the cannon is not affected.
func weapon_fire_rate_factor() -> float:
	return 1.0 + _weapon_rate_bonus


## Extra burn damage per second on the specialization weapon's burn.
func burn_dps_bonus() -> float:
	return _burn_dps_bonus


## Extra seconds of burning on the specialization weapon's burn.
func burn_duration_bonus() -> float:
	return _burn_duration_bonus


## Extra seconds an enemy stays wet.
func wet_duration_bonus() -> float:
	return _wet_duration_bonus


## Switches on the « trempé + glace = gelé » conversion (story 009): frost towers
## freeze wet enemies for [param duration] seconds, then the enemy cannot be
## frozen again for [param cooldown] seconds. Called once, when the chosen
## specialization has freeze data.
func enable_freeze(duration: float, cooldown: float) -> void:
	_freeze_base_duration = duration
	_freeze_cooldown = cooldown


## Seconds a freeze lasts, card bonus included; 0 while the conversion is off.
func freeze_duration() -> float:
	if _freeze_base_duration <= 0.0:
		return 0.0
	return _freeze_base_duration + _freeze_duration_bonus


## Seconds after a freeze during which the enemy cannot be frozen again.
func freeze_cooldown() -> float:
	return _freeze_cooldown


## One entry per card taken, in the order taken, such as "Canon rapide ×2".
func owned_labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for card: CardDef in _taken:
		var count: int = stacks_of(card.id)
		labels.append(card.display_name if count == 1 else "%s ×%d" % [card.display_name, count])
	return labels
