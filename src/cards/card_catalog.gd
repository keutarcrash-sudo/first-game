## Every card of the game, loaded from assets/data/cards.json (story 006).
## Pure data: adding a card with an existing effect type is a data change only.
## To add an effect type, add it to [constant EFFECT_NUMBER_KEYS] and handle it
## in [method PlayerModifiers.take].
class_name CardCatalog
extends RefCounted

## Effect types known to the code, with the numeric keys each one needs (all above 0).
const EFFECT_NUMBER_KEYS := {
	"cannon_fire_rate_bonus": ["value"],
	"damage_bonus": ["value"],
	"frost_slow_factor_mult": ["value", "min_factor"],
	"frost_range_bonus": ["value"],
	"heal_crystal": ["value"],
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
}

## How many cards a choice screen offers.
var offered_per_choice := 3
## All cards, in file order.
var cards: Array[CardDef] = []


## Reads and validates the JSON file at [param path]. Combo ids used by
## [code]unlock_combo[/code] must exist in [param rules], and specialization ids
## used by [code]requires_spec[/code] in [param specs]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String, rules: ProcRules, specs: SpecializationCatalog) -> CardCatalog:
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
		var card: CardDef = _parse_card(data["cards"][i], i, path, rules, specs)
		if card == null:
			return null
		if seen.has(card.id):
			push_error("CardCatalog: key 'cards[%d].id' in '%s' is a duplicate ('%s')." % [i, path, card.id])
			return null
		seen[card.id] = true
		catalog.cards.append(card)
	return catalog


## True when a card with id [param card_id] exists.
func has_card(card_id: String) -> bool:
	for card: CardDef in cards:
		if card.id == card_id:
			return true
	return false


static func _parse_card(raw: Variant, index: int, path: String, rules: ProcRules, specs: SpecializationCatalog) -> CardDef:
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
		if not _is_effect_valid(effect, "cards[%d].effects[%d]" % [index, j], path, rules):
			return null
		card.effects.append(effect)
	return card


static func _is_effect_valid(effect: Variant, where: String, path: String, rules: ProcRules) -> bool:
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
	return true
