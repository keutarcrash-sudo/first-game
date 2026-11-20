## Every passive item of the game and the shop, treasure and rest numbers, loaded
## from assets/data/items.json (étape 5a, spec §7-§8bis). Pure data, no scene tree.
class_name ItemCatalog
extends RefCounted

## Item categories the file may use.
const CATEGORIES: Array[StringName] = [&"attack", &"survival", &"utility"]

## Number of items a shop offers.
var shop_slots := 0
## Gold price of a crystal repair in a shop.
var crystal_repair_cost := 0
## Crystal hit points a shop repair restores.
var crystal_repair_hp := 0.0
## Number of items a treasure offers.
var treasure_slots := 0
## Gold given when a treasure has no item left to offer.
var treasure_fallback_gold := 0
## Share of the hero's maximum hit points a rest restores.
var rest_hero_heal_fraction := 0.0
## Crystal hit points a rest restores.
var rest_crystal_heal := 0.0

var _items: Array[ItemDef] = []
var _prices: Dictionary = {}  # { rarity id: int }


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String, rarities: CardRarities, specs: SpecializationCatalog, rules: ProcRules, abilities: AbilityCatalog) -> ItemCatalog:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("ItemCatalog: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	return from_data(JSON.parse_string(text), path, rarities, specs, rules, abilities)


## Validates already-parsed JSON [param data] ([param source] names the file in errors).
## Returns [code]null[/code] and prints an error on the first problem.
static func from_data(data: Variant, source: String, rarities: CardRarities, specs: SpecializationCatalog, rules: ProcRules, abilities: AbilityCatalog) -> ItemCatalog:
	if not data is Dictionary or not (data as Dictionary).get("items") is Array:
		push_error("ItemCatalog: '%s' must be a JSON object with an 'items' list." % source)
		return null
	var catalog := ItemCatalog.new()
	var prices: Variant = data.get("prices")
	if not prices is Dictionary:
		push_error("ItemCatalog: key 'prices' in '%s' must be an object." % source)
		return null
	for rarity: StringName in CardRarities.IDS:
		var price: Variant = (prices as Dictionary).get(String(rarity))
		if not _is_number(price) or price <= 0:
			push_error("ItemCatalog: key 'prices.%s' in '%s' must be a number above 0 (got %s)." % [rarity, source, price])
			return null
		catalog._prices[rarity] = int(price)
	var ints: Array = [
		["shop", "slots", "shop_slots"],
		["shop", "crystal_repair_cost", "crystal_repair_cost"],
		["treasure", "slots", "treasure_slots"],
		["treasure", "fallback_gold", "treasure_fallback_gold"],
	]
	for entry: Array in ints:
		var value: Variant = _number_at(data, entry[0], entry[1], source)
		if value == null:
			return null
		catalog.set(entry[2], int(value))
	var floats: Array = [
		["shop", "crystal_repair_hp", "crystal_repair_hp"],
		["rest", "hero_heal_fraction", "rest_hero_heal_fraction"],
		["rest", "crystal_heal", "rest_crystal_heal"],
	]
	for entry: Array in floats:
		var value: Variant = _number_at(data, entry[0], entry[1], source)
		if value == null:
			return null
		catalog.set(entry[2], float(value))
	var seen: Dictionary = {}
	for i: int in data["items"].size():
		var item: ItemDef = _parse_item(data["items"][i], i, source, rarities, specs, rules, abilities)
		if item == null:
			return null
		if seen.has(item.id):
			push_error("ItemCatalog: key 'items[%d].id' in '%s' is a duplicate ('%s')." % [i, source, item.id])
			return null
		seen[item.id] = true
		catalog._items.append(item)
	return catalog


## Every item, in file order.
func all() -> Array[ItemDef]:
	return _items


## The item with [param id], or [code]null[/code] when unknown.
func get_item(id: String) -> ItemDef:
	for item: ItemDef in _items:
		if item.id == id:
			return item
	return null


## Gold price of [param item], set by its rarity.
func price_of(item: ItemDef) -> int:
	return int(_prices.get(item.rarity, 0))


static func _is_number(value: Variant) -> bool:
	return value is float or value is int


## Reads the number [param section].[param key], which must be above 0.
## Returns [code]null[/code] after printing an error.
static func _number_at(data: Dictionary, section: String, key: String, source: String) -> Variant:
	var block: Variant = data.get(section)
	if not block is Dictionary:
		push_error("ItemCatalog: key '%s' in '%s' must be an object." % [section, source])
		return null
	var value: Variant = (block as Dictionary).get(key)
	if not _is_number(value) or value <= 0:
		push_error("ItemCatalog: key '%s.%s' in '%s' must be a number above 0 (got %s)." % [section, key, source, value])
		return null
	return value


static func _parse_item(raw: Variant, index: int, source: String, rarities: CardRarities, specs: SpecializationCatalog, rules: ProcRules, abilities: AbilityCatalog) -> ItemDef:
	if not raw is Dictionary:
		push_error("ItemCatalog: 'items[%d]' in '%s' must be an object." % [index, source])
		return null
	var item := ItemDef.new()
	for key: String in ["id", "display_name", "description", "glyph"]:
		if not raw.get(key) is String or (raw[key] as String).strip_edges().is_empty():
			push_error("ItemCatalog: key 'items[%d].%s' in '%s' must be a non-empty string." % [index, key, source])
			return null
	item.id = raw["id"]
	item.display_name = raw["display_name"]
	item.description = raw["description"]
	item.glyph = raw["glyph"]
	var category: Variant = raw.get("category")
	if not category is String or not CATEGORIES.has(StringName(category)):
		push_error("ItemCatalog: key 'items[%d].category' in '%s' must be one of %s (got %s)." % [index, source, CATEGORIES, category])
		return null
	item.category = StringName(category)
	var rarity: Variant = raw.get("rarity")
	if not rarity is String or not rarities.has_rarity(StringName(rarity)):
		push_error("ItemCatalog: key 'items[%d].rarity' in '%s' must be a rarity id of card_rarities.json (got %s)." % [index, source, rarity])
		return null
	item.rarity = StringName(rarity)
	var spec_id: Variant = raw.get("requires_spec", "")
	if not spec_id is String or (not (spec_id as String).is_empty() and not specs.has_spec(spec_id)):
		push_error("ItemCatalog: key 'items[%d].requires_spec' in '%s' must be the id of a specialization in specializations.json (got %s)." % [index, source, spec_id])
		return null
	item.requires_spec = spec_id
	if not raw.get("effects") is Array or (raw["effects"] as Array).is_empty():
		push_error("ItemCatalog: key 'items[%d].effects' in '%s' must be a non-empty list." % [index, source])
		return null
	for j: int in raw["effects"].size():
		var effect: Variant = raw["effects"][j]
		if not CardCatalog._is_effect_valid(effect, "items[%d].effects[%d]" % [index, j], source, rules, abilities):
			return null
		item.effects.append(effect)
	return item
