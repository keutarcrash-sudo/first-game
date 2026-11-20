## Logic check for ItemCatalog and the real assets/data/items.json. Run with:
## godot --headless -s res://tests/unit/items/item_catalog_check.gd
## Prints "ITEM_CATALOG OK" or "ITEM_CATALOG FAIL: <name>" then quits (exit 1 on failure).
extends SceneTree

const ITEMS_PATH := "res://assets/data/items.json"
const RARITIES_PATH := "res://assets/data/card_rarities.json"
const PROCS_PATH := "res://assets/data/procs.json"
const SPECS_PATH := "res://assets/data/specializations.json"
const ABILITIES_PATH := "res://assets/data/abilities.json"


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("ITEM_CATALOG OK")
	else:
		print("ITEM_CATALOG FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _item(id: String, rarity: String = "common", effect_type: String = "tower_range_bonus") -> Dictionary:
	return {"id": id, "category": "attack", "rarity": rarity, "display_name": id, "description": "d", "glyph": "X", "requires_spec": "", "effects": [{"type": effect_type, "value": 0.1}]}


## Returns the name of the first failing check, or "" if all pass.
func _run() -> String:
	var rarities: CardRarities = CardRarities.load_from_file(RARITIES_PATH)
	var rules: ProcRules = ProcRules.load_from_file(PROCS_PATH)
	if rarities == null or rules == null:
		return "load_dependencies"
	var specs: SpecializationCatalog = SpecializationCatalog.load_from_file(SPECS_PATH, rules)
	if specs == null:
		return "load_specs"
	var abilities: AbilityCatalog = AbilityCatalog.load_from_file(ABILITIES_PATH, specs)
	if abilities == null:
		return "load_abilities"
	var catalog: ItemCatalog = ItemCatalog.load_from_file(ITEMS_PATH, rarities, specs, rules, abilities)
	if catalog == null:
		return "load_items"
	if catalog.all().size() != 12:
		return "twelve_items"
	var expected: Dictionary = {&"common": 60, &"uncommon": 100, &"rare": 150, &"epic": 220, &"legendary": 300}
	var seen_rarity: Dictionary = {}
	for item: ItemDef in catalog.all():
		if catalog.price_of(item) != expected[item.rarity]:
			return "price_of_%s" % item.id
		seen_rarity[item.rarity] = true
	if seen_rarity.size() != 5:
		return "all_five_rarities_used"
	var lunette: ItemDef = catalog.get_item("lunette")
	if lunette == null or lunette.requires_spec != "archer":
		return "lunette_requires_archer"
	if catalog.get_item("inconnu") != null:
		return "get_item_unknown"
	if catalog.shop_slots != 4 or catalog.crystal_repair_cost != 40 or not is_equal_approx(catalog.crystal_repair_hp, 20.0):
		return "shop_numbers"
	if catalog.treasure_slots != 3 or catalog.treasure_fallback_gold != 100:
		return "treasure_numbers"
	if not is_equal_approx(catalog.rest_hero_heal_fraction, 0.3) or not is_equal_approx(catalog.rest_crystal_heal, 20.0):
		return "rest_numbers"
	# from_data accepts a valid in-memory dictionary, rejects the invalid ones (null + push_error).
	var base: Dictionary = {"prices": {"common": 60, "uncommon": 100, "rare": 150, "epic": 220, "legendary": 300},
		"shop": {"slots": 4, "crystal_repair_cost": 40, "crystal_repair_hp": 20},
		"treasure": {"slots": 3, "fallback_gold": 100}, "rest": {"hero_heal_fraction": 0.3, "crystal_heal": 20}}
	var valid: Dictionary = base.duplicate(true)
	valid["items"] = [_item("a"), _item("b", "epic")]
	if ItemCatalog.from_data(valid, "memory", rarities, specs, rules, abilities) == null:
		return "from_data_valid"
	var cases: Dictionary = {
		"bad_rarity": [_item("a", "mythic")],
		"bad_effect": [_item("a", "common", "no_such_effect")],
		"duplicate_id": [_item("a"), _item("a")],
	}
	var unknown_cat: Dictionary = _item("a")
	unknown_cat["category"] = "magic"
	cases["bad_category"] = [unknown_cat]
	var unknown_spec: Dictionary = _item("a")
	unknown_spec["requires_spec"] = "no_such_spec"
	cases["bad_spec"] = [unknown_spec]
	for case_name: String in cases:
		var data: Dictionary = base.duplicate(true)
		data["items"] = cases[case_name]
		if ItemCatalog.from_data(data, "memory", rarities, specs, rules, abilities) != null:
			return "rejects_%s" % case_name
	return ""
