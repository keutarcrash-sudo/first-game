## Every card of the game, loaded from assets/data/cards.json (story 006).
## Pure data: adding a card with an existing effect type is a data change only.
## To add an effect type, add it to [constant EFFECT_NUMBER_KEYS] and handle it
## in [method PlayerModifiers._apply_effect].
class_name CardCatalog
extends RefCounted

## Effect types known to the code, with the numeric keys each one needs (all above 0).
const EFFECT_NUMBER_KEYS := {
	"cannon_fire_rate_bonus": ["value"],
	"damage_bonus": ["value"],
	"frost_slow_factor_mult": ["value", "min_factor"],
	"frost_range_bonus": ["value"],
	"heal_crystal": ["value"],
	"hero_heal": ["value"],
	"hero_max_hp_bonus": ["value"],
	"hero_regen": ["value"],
	"hero_heal_on_kill": ["value"],
	"gold_per_kill_bonus": ["value"],
	"cannon_burn": ["duration", "damage_per_second"],
	"unlock_combo": [],
	"pierce_bonus": ["value"],
	"crit_chance_bonus": ["value"],
	"crit_multiplier_bonus": ["value"],
	"mark_duration_bonus": ["value"],
	"weapon_fire_rate_bonus": ["value"],
	"burn_dps_bonus": ["value"],
	"burn_duration_bonus": ["value"],
	"wet_duration_bonus": ["value"],
	"freeze_duration_bonus": ["value"],
	"frozen_vulnerability_bonus": ["value"],
	"hero_damage_bonus": ["value"],
	"move_speed_bonus": ["value"],
	"pickup_radius_mult": ["value"],
	"gold_lifetime_bonus": ["value"],
	"cards_offered_bonus": ["value"],
	"ability_cooldown_mult": ["value"],
	"ability_value_mult": ["value"],
	"ability_value_bonus": ["value"],
	"tower_range_bonus": ["value"],
	"hero_heal_per_wave": ["value"],
	"crystal_damage_reduction": ["value"],
	"tower_cost_mult": ["value"],
	"upgrade_cost_mult": ["value"],
	"free_tower": [],
	"tier3_fire_rate_bonus": ["value"],
	"gold_per_kill_mult": ["value"],
	# Flags: only stored in PlayerModifiers here; their gameplay reads them elsewhere.
	"burst_on_crit": ["chance"],
	"ghost_arrows": [],
	"burning_vulnerability": ["value"],
	"burn_spread_on_death": ["radius"],
	"wet_slow": ["factor"],
	"shatter_on_frozen_death": ["damage", "radius", "freeze"],
	"second_chance": ["hp_fraction"],
}
## Effect types that name an ability with an [code]ability_id[/code] string.
const ABILITY_EFFECTS: Array[String] = ["ability_cooldown_mult", "ability_value_mult", "ability_value_bonus"]
## Effect types that also name one numeric value of that ability with a [code]key[/code] string.
const ABILITY_VALUE_EFFECTS: Array[String] = ["ability_value_mult", "ability_value_bonus"]

## How many cards a choice screen offers.
var offered_per_choice := 3
## All cards, in file order.
var cards: Array[CardDef] = []


## Reads and validates the JSON file at [param path]. Combo ids used by
## [code]unlock_combo[/code] must exist in [param rules], and specialization ids
## used by [code]requires_spec[/code] in [param specs]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String, rules: ProcRules, specs: SpecializationCatalog, rarities: CardRarities, abilities: AbilityCatalog) -> CardCatalog:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("CardCatalog: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.get("cards") is Array:
		push_error("CardCatalog: '%s' must be a JSON object with a 'cards' list." % path)
		return null
	var catalog := CardCatalog.new()
	var offered: Variant = data.get("offered_per_choice", 3)
	if not (offered is float or offered is int) or offered < 1:
		push_error("CardCatalog: key 'offered_per_choice' in '%s' must be a number of at least 1 (got %s)." % [path, offered])
		return null
	catalog.offered_per_choice = int(offered)
	var seen: Dictionary = {}
	for i: int in data["cards"].size():
		var card: CardDef = _parse_card(data["cards"][i], i, path, rules, specs, rarities, abilities)
		if card == null:
			return null
		if seen.has(card.id):
			push_error("CardCatalog: key 'cards[%d].id' in '%s' is a duplicate ('%s')." % [i, path, card.id])
			return null
		seen[card.id] = true
		catalog.cards.append(card)
	for i: int in catalog.cards.size():
		var required: String = catalog.cards[i].requires_card
		if not required.is_empty() and not seen.has(required):
			push_error("CardCatalog: key 'cards[%d].requires_card' in '%s' must be the id of a card in the file (got '%s')." % [i, path, required])
			return null
	return catalog


## True when a card with id [param card_id] exists.
func has_card(card_id: String) -> bool:
	for card: CardDef in cards:
		if card.id == card_id:
			return true
	return false


static func _parse_card(raw: Variant, index: int, path: String, rules: ProcRules, specs: SpecializationCatalog, rarities: CardRarities, abilities: AbilityCatalog) -> CardDef:
	if not raw is Dictionary:
		push_error("CardCatalog: 'cards[%d]' in '%s' must be an object." % [index, path])
		return null
	var card := CardDef.new()
	for key: String in ["id", "display_name", "description"]:
		if not raw.get(key) is String or (raw[key] as String).strip_edges().is_empty():
			push_error("CardCatalog: key 'cards[%d].%s' in '%s' must be a non-empty string." % [index, key, path])
			return null
	card.id = raw["id"]
	card.display_name = raw["display_name"]
	card.description = raw["description"]
	var combines: Variant = raw.get("combines_with", "")
	if not combines is String:
		push_error("CardCatalog: key 'cards[%d].combines_with' in '%s' must be a string." % [index, path])
		return null
	card.combines_with = combines
	var locked: Variant = raw.get("locked_by_default", false)
	if not locked is bool:
		push_error("CardCatalog: key 'cards[%d].locked_by_default' in '%s' must be true or false." % [index, path])
		return null
	card.locked_by_default = locked
	var spec_id: Variant = raw.get("requires_spec", "")
	if not spec_id is String or (not (spec_id as String).is_empty() and not specs.has_spec(spec_id)):
		push_error("CardCatalog: key 'cards[%d].requires_spec' in '%s' must be the id of a specialization in specializations.json (got %s)." % [index, path, spec_id])
		return null
	card.requires_spec = spec_id
	var rarity: Variant = raw.get("rarity")
	if not rarity is String or not rarities.has_rarity(StringName(rarity)):
		push_error("CardCatalog: key 'cards[%d].rarity' in '%s' must be a rarity id of card_rarities.json (got %s)." % [index, path, rarity])
		return null
	card.rarity = StringName(rarity)
	var ability_id: Variant = raw.get("requires_ability", "")
	if not ability_id is String or (not (ability_id as String).is_empty() and _find_ability(abilities, ability_id) == null):
		push_error("CardCatalog: key 'cards[%d].requires_ability' in '%s' must be the id of an ability in abilities.json (got %s)." % [index, path, ability_id])
		return null
	card.requires_ability = ability_id
	var card_id: Variant = raw.get("requires_card", "")
	if not card_id is String:
		push_error("CardCatalog: key 'cards[%d].requires_card' in '%s' must be a string." % [index, path])
		return null
	card.requires_card = card_id
	var max_stacks: Variant = raw.get("max_stacks")
	if max_stacks != null:
		if not (max_stacks is float or max_stacks is int) or max_stacks < 1:
			push_error("CardCatalog: key 'cards[%d].max_stacks' in '%s' must be null or a number of at least 1." % [index, path])
			return null
		card.max_stacks = int(max_stacks)
	if not raw.get("effects") is Array or (raw["effects"] as Array).is_empty():
		push_error("CardCatalog: key 'cards[%d].effects' in '%s' must be a non-empty list." % [index, path])
		return null
	for j: int in raw["effects"].size():
		var effect: Variant = raw["effects"][j]
		if not _is_effect_valid(effect, "cards[%d].effects[%d]" % [index, j], path, rules, abilities):
			return null
		card.effects.append(effect)
	return card


static func _is_effect_valid(effect: Variant, where: String, path: String, rules: ProcRules, abilities: AbilityCatalog) -> bool:
	if not effect is Dictionary or not effect.get("type") is String:
		push_error("CardCatalog: key '%s.type' in '%s' must be a string." % [where, path])
		return false
	if not EFFECT_NUMBER_KEYS.has(effect["type"]):
		push_error("CardCatalog: key '%s.type' in '%s' is an unknown effect type ('%s')." % [where, path, effect["type"]])
		return false
	for key: String in EFFECT_NUMBER_KEYS[effect["type"]]:
		var value: Variant = effect.get(key)
		if not (value is float or value is int) or value <= 0:
			push_error("CardCatalog: key '%s.%s' in '%s' must be a number above 0 (got %s)." % [where, key, path, value])
			return false
	if effect["type"] == "unlock_combo":
		if not effect.get("combo_id") is String or not rules.has_combo(effect["combo_id"]):
			push_error("CardCatalog: key '%s.combo_id' in '%s' must be the id of a combo in procs.json (got %s)." % [where, path, effect.get("combo_id")])
			return false
	if ABILITY_EFFECTS.has(effect["type"]):
		var def: AbilityDef = _find_ability(abilities, str(effect.get("ability_id")))
		if def == null:
			push_error("CardCatalog: key '%s.ability_id' in '%s' must be the id of an ability in abilities.json (got %s)." % [where, path, effect.get("ability_id")])
			return false
		if ABILITY_VALUE_EFFECTS.has(effect["type"]) and not def.values.has(str(effect.get("key"))):
			push_error("CardCatalog: key '%s.key' in '%s' must be a value of ability '%s' (got %s)." % [where, path, def.id, effect.get("key")])
			return false
		if effect["type"] == "ability_cooldown_mult" and float(effect["value"]) >= 1.0:
			push_error("CardCatalog: key '%s.value' in '%s' must be below 1 (a cooldown multiplier, got %s)." % [where, path, effect["value"]])
			return false
	return true


static func _find_ability(abilities: AbilityCatalog, ability_id: String) -> AbilityDef:
	for def: AbilityDef in abilities.abilities:
		if def.id == ability_id:
			return def
	return null
