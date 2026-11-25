## What the player has gained from cards during this game (story 006): stacks
## per card and the resulting modifiers. Pure logic, no scene tree. Towers, the
## hero and the wave cycle share one instance and read it at use time, so a card
## acts at once on towers that are already placed.
class_name PlayerModifiers
extends RefCounted

## Emitted after a card is taken.
signal changed
## Emitted after a passive item is taken (before [signal changed]).
signal items_changed
## Emitted when a card asks the crystal to recover [param amount] hit points.
signal heal_requested(amount: float)
## Emitted when a card asks the hero to recover [param amount] hit points.
signal hero_heal_requested(amount: float)

## Cooldown reductions never go below this share of the base cooldown (-75 % at most).
const MIN_COOLDOWN_FACTOR := 0.25
## Effect types that are only flags (read through [method has_flag] and [method flag_value]).
const FLAG_EFFECTS: Array[String] = ["burst_on_crit", "ghost_arrows", "burning_vulnerability", "burn_spread_on_death", "wet_slow", "shatter_on_frozen_death", "second_chance"]

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
var _frozen_vulnerability_bonus := 0.0
var _tier3_fire_rate_bonus := 0.0  # « Surcharge » (filled by Task 5 of towers T1).
var _hero_damage_bonus := 0.0
var _move_speed_bonus := 0.0
var _pickup_bonus := 0.0  # Sum of (multiplier - 1) over the cards taken.
var _gold_lifetime_bonus := 0.0
var _cards_offered_bonus := 0
var _cooldown_reduction: Dictionary = {}  # { ability id: summed reduction, 0.3 = -30 % }
var _value_mult_bonus: Dictionary = {}  # { "ability id/key": summed (multiplier - 1) }
var _value_bonus: Dictionary = {}  # { "ability id/key": summed flat bonus }
var _flags: Dictionary = {}  # { flag: { key: summed value } }
var _hero_max_hp_bonus := 0.0
var _hero_regen := 0.0
var _hero_heal_on_kill := 0.0
var _took_legendary := false
var _items: Array[ItemDef] = []
var _item_ids: Dictionary = {}
var _tower_range_bonus := 0.0
var _hero_heal_per_wave := 0.0
var _crystal_reduction := 0.0
var _tower_cost_mult := 1.0
var _gold_kill_mult := 1.0


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
	if card.rarity == &"legendary":
		_took_legendary = true
	for effect: Dictionary in card.effects:
		_apply_effect(effect)
	changed.emit()


## Takes the passive item [param item] and applies its effects. Ignored if already owned.
func take_item(item: ItemDef) -> void:
	if owns_item(item.id):
		return
	_item_ids[item.id] = true
	_items.append(item)
	for effect: Dictionary in item.effects:
		_apply_effect(effect)
	items_changed.emit()
	changed.emit()


## True once the item [param id] has been taken.
func owns_item(id: String) -> bool:
	return _item_ids.has(id)


## The items taken, in the order taken.
func owned_items() -> Array[ItemDef]:
	return _items


## Factor applied to the range of towers (1 + sum of the item bonuses).
func tower_range_factor() -> float:
	return 1.0 + _tower_range_bonus


## Price of a tower with base price [param base] after item discounts, rounded.
func tower_cost(base: int) -> int:
	return roundi(base * _tower_cost_mult)


## Factor applied to damage the crystal takes: 1 minus the item reductions, never below 0.1.
func crystal_damage_factor() -> float:
	return maxf(1.0 - _crystal_reduction, 0.1)


## Gold for one kill given the base amount [param base], after item multipliers, rounded.
func gold_per_kill(base: int) -> int:
	return roundi(base * _gold_kill_mult)


## Hero hit points recovered at the start of each wave.
func hero_heal_per_wave() -> float:
	return _hero_heal_per_wave


## Factor applied to the cannon's fire interval (1.0 = unchanged, below 1 = faster).
func cannon_interval_factor() -> float:
	return 1.0 / (1.0 + _fire_rate_bonus)


## Factor applied to the cannons' shot damage, before combo multipliers (general bonus only).
func damage_multiplier() -> float:
	return 1.0 + _damage_bonus


## Factor applied to the hero's shots and abilities, before combo multipliers: the
## general bonus times the hero-only bonus.
func hero_damage_multiplier() -> float:
	return (1.0 + _damage_bonus) * (1.0 + _hero_damage_bonus)


## Total extra maximum hit points the hero got from cards.
func hero_max_hp_bonus() -> float:
	return _hero_max_hp_bonus


## Hero hit points regenerated per second.
func hero_regen() -> float:
	return _hero_regen


## Hero hit points recovered for each enemy killed.
func hero_heal_on_kill() -> float:
	return _hero_heal_on_kill


## Factor applied to the hero's walking speed.
func move_speed_factor() -> float:
	return 1.0 + _move_speed_bonus


## Factor applied to the gold pickup radius (bonuses of several cards add up).
func pickup_radius_factor() -> float:
	return 1.0 + _pickup_bonus


## Extra seconds gold stays on the ground.
func gold_lifetime_bonus() -> float:
	return _gold_lifetime_bonus


## Extra cards offered at each choice (added to the skill tree bonus).
func cards_offered_bonus() -> int:
	return _cards_offered_bonus


## Factor applied to the cooldown of [param ability_id] (1.0 = unchanged); reductions add up, never below [constant MIN_COOLDOWN_FACTOR].
func ability_cooldown_factor(ability_id: String) -> float:
	return maxf(1.0 - float(_cooldown_reduction.get(ability_id, 0.0)), MIN_COOLDOWN_FACTOR)


## The value [param key] of [param ability_id] given its base [param base]: base × multiplier + bonus.
func ability_value(ability_id: String, key: String, base: float) -> float:
	var full_key := "%s/%s" % [ability_id, key]
	return base * (1.0 + float(_value_mult_bonus.get(full_key, 0.0))) + float(_value_bonus.get(full_key, 0.0))


## True once a card of the flag effect [param flag] has been taken.
func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


## The number [param key] of the flag effect [param flag] (summed over stacks); 0 when the flag is off.
func flag_value(flag: StringName, key: String) -> float:
	return float((_flags.get(flag, {}) as Dictionary).get(key, 0.0))


## True once a legendary card has been taken: no other legendary is offered afterwards.
func took_legendary() -> bool:
	return _took_legendary


func _apply_effect(effect: Dictionary) -> void:
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
		"hero_heal":
			hero_heal_requested.emit(float(effect["value"]))
		"hero_max_hp_bonus":
			_hero_max_hp_bonus += float(effect["value"])
		"hero_regen":
			_hero_regen += float(effect["value"])
		"hero_heal_on_kill":
			_hero_heal_on_kill += float(effect["value"])
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
		"frozen_vulnerability_bonus":
			_frozen_vulnerability_bonus += float(effect["value"])
		"hero_damage_bonus":
			_hero_damage_bonus += float(effect["value"])
		"move_speed_bonus":
			_move_speed_bonus += float(effect["value"])
		"pickup_radius_mult":
			_pickup_bonus += float(effect["value"]) - 1.0
		"gold_lifetime_bonus":
			_gold_lifetime_bonus += float(effect["value"])
		"cards_offered_bonus":
			_cards_offered_bonus += roundi(effect["value"])
		"ability_cooldown_mult":
			var ability_id := String(effect["ability_id"])
			_cooldown_reduction[ability_id] = float(_cooldown_reduction.get(ability_id, 0.0)) + 1.0 - float(effect["value"])
		"ability_value_mult":
			var mult_key := "%s/%s" % [effect["ability_id"], effect["key"]]
			_value_mult_bonus[mult_key] = float(_value_mult_bonus.get(mult_key, 0.0)) + float(effect["value"]) - 1.0
		"ability_value_bonus":
			var bonus_key := "%s/%s" % [effect["ability_id"], effect["key"]]
			_value_bonus[bonus_key] = float(_value_bonus.get(bonus_key, 0.0)) + float(effect["value"])
		"tower_range_bonus":
			_tower_range_bonus += float(effect["value"])
		"hero_heal_per_wave":
			_hero_heal_per_wave += float(effect["value"])
		"crystal_damage_reduction":
			_crystal_reduction += float(effect["value"])
		"tower_cost_mult":
			_tower_cost_mult *= float(effect["value"])
		"gold_per_kill_mult":
			_gold_kill_mult *= float(effect["value"])
		_:
			if FLAG_EFFECTS.has(String(effect["type"])):
				_add_flag(StringName(String(effect["type"])), effect)


func _add_flag(flag: StringName, effect: Dictionary) -> void:
	var values: Dictionary = _flags.get(flag, {})
	for key: String in CardCatalog.EFFECT_NUMBER_KEYS[String(flag)]:
		values[key] = float(values.get(key, 0.0)) + float(effect[key])
	_flags[flag] = values


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


## Extra damage fraction taken by a frozen enemy, on top of the towers' base value
## (« Gel mordant »: 0.25 = +25 % more). 0 without the card.
func frozen_vulnerability_bonus() -> float:
	return _frozen_vulnerability_bonus


## Extra seconds given to every freeze by « Gel profond » alone (the frost towers add it
## to their own freeze; [method freeze_duration] already includes it). 0 without the card.
func freeze_duration_bonus() -> float:
	return _freeze_duration_bonus


## Factor applied to the fire rate of level 3 towers that shoot (the cannon), « Surcharge »:
## 1.2 = 20 % faster. 1 without the card.
func tier3_fire_rate_factor() -> float:
	return 1.0 + _tier3_fire_rate_bonus


## One entry per card taken, in the order taken, such as "Canon rapide ×2".
func owned_labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for card: CardDef in _taken:
		var count: int = stacks_of(card.id)
		labels.append(card.display_name if count == 1 else "%s ×%d" % [card.display_name, count])
	return labels
