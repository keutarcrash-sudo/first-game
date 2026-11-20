## Logic check for ItemPool (étape 5a, spec §7.4), with an ItemCatalog built in memory. Run with:
## godot --headless -s res://tests/unit/items/item_pool_check.gd
## Prints "ITEM_POOL OK" or "ITEM_POOL FAIL: <name>" then quits (exit 1 on failure).
extends SceneTree

const RARITIES_PATH := "res://assets/data/card_rarities.json"
const PROCS_PATH := "res://assets/data/procs.json"
const SPECS_PATH := "res://assets/data/specializations.json"
const ABILITIES_PATH := "res://assets/data/abilities.json"
const DRAW_COUNT := 4
const REPEATS := 200
const SEED := 12345

var _rarities: CardRarities
var _rules: ProcRules
var _specs: SpecializationCatalog
var _abilities: AbilityCatalog


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("ITEM_POOL OK")
	else:
		print("ITEM_POOL FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _item(id: String, rarity: String = "common", requires_spec: String = "") -> Dictionary:
	return {"id": id, "category": "attack", "rarity": rarity, "display_name": id, "description": "d", "glyph": "X", "requires_spec": requires_spec, "effects": [{"type": "tower_range_bonus", "value": 0.1}]}


func _catalog(items: Array) -> ItemCatalog:
	var data: Dictionary = {"prices": {"common": 60, "uncommon": 100, "rare": 150, "epic": 220, "legendary": 300},
		"shop": {"slots": 4, "crystal_repair_cost": 40, "crystal_repair_hp": 20},
		"treasure": {"slots": 3, "fallback_gold": 100}, "rest": {"hero_heal_fraction": 0.3, "crystal_heal": 20},
		"items": items}
	return ItemCatalog.from_data(data, "memory", _rarities, _specs, _rules, _abilities)


func _pool(catalog: ItemCatalog, modifiers: PlayerModifiers, spec_id: String) -> ItemPool:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return ItemPool.new(catalog, modifiers, rng, spec_id, _rarities)


func _ids(items: Array[ItemDef]) -> PackedStringArray:
	var ids := PackedStringArray()
	for item: ItemDef in items:
		ids.append(item.id)
	return ids


## Returns the name of the first failing check, or "" if all pass.
func _run() -> String:
	_rarities = CardRarities.load_from_file(RARITIES_PATH)
	_rules = ProcRules.load_from_file(PROCS_PATH)
	if _rarities == null or _rules == null:
		return "load_dependencies"
	_specs = SpecializationCatalog.load_from_file(SPECS_PATH, _rules)
	if _specs == null:
		return "load_specs"
	_abilities = AbilityCatalog.load_from_file(ABILITIES_PATH, _specs)
	if _abilities == null:
		return "load_abilities"
	var catalog: ItemCatalog = _catalog([_item("a"), _item("b", "uncommon"), _item("c", "rare"),
		_item("d", "epic"), _item("e", "legendary"), _item("f"), _item("archer_only", "common", "archer")])
	if catalog == null:
		return "build_catalog"

	# draw(4, 1) gives 4 distinct items.
	var modifiers := PlayerModifiers.new(_rules)
	var pool: ItemPool = _pool(catalog, modifiers, "maitre_feu")
	var first: Array[ItemDef] = pool.draw(DRAW_COUNT, 1)
	if first.size() != DRAW_COUNT:
		return "draw_gives_four"
	var seen: Dictionary = {}
	for item: ItemDef in first:
		if seen.has(item.id):
			return "draw_distinct"
		seen[item.id] = true

	# An owned item never shows up; an archer item never shows up for another spec.
	modifiers.take_item(catalog.get_item("a"))
	for i: int in REPEATS:
		var ids: PackedStringArray = _ids(pool.draw(DRAW_COUNT, 1 + i % 20))
		if ids.size() != DRAW_COUNT:
			return "draw_size_after_take"
		if ids.has("a"):
			return "owned_item_never_drawn"
		if ids.has("archer_only"):
			return "other_spec_item_never_drawn"

	# The archer item is offered to the archer (only item left in its catalog).
	var archer_catalog: ItemCatalog = _catalog([_item("archer_only", "common", "archer")])
	if archer_catalog == null:
		return "build_archer_catalog"
	var archer_draw: PackedStringArray = _ids(_pool(archer_catalog, PlayerModifiers.new(_rules), "archer").draw(DRAW_COUNT, 1))
	if archer_draw != PackedStringArray(["archer_only"]):
		return "archer_item_for_archer"

	# Two items left: draw(4, 1) gives those two; none left: empty.
	var small: ItemCatalog = _catalog([_item("x"), _item("y", "rare"), _item("z", "epic")])
	if small == null:
		return "build_small_catalog"
	var small_mods := PlayerModifiers.new(_rules)
	var small_pool: ItemPool = _pool(small, small_mods, "maitre_eau")
	small_mods.take_item(small.get_item("x"))
	var two: PackedStringArray = _ids(small_pool.draw(DRAW_COUNT, 1))
	if two.size() != 2 or not two.has("y") or not two.has("z"):
		return "fewer_items_when_few_left"
	small_mods.take_item(small.get_item("y"))
	small_mods.take_item(small.get_item("z"))
	if not small_pool.draw(DRAW_COUNT, 1).is_empty():
		return "empty_when_none_left"
	return ""
