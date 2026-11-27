## Logic check for EvolutionRules, TowerReserve.evolve, the evolution blocks of
## TowerStats / TowerDef and the requires_tower cards (towers T2b, Task 1). Run with:
## godot --headless -s res://tests/unit/towers/evolution_rules_check.gd
## Prints "EVOLUTION_RULES OK" or "EVOLUTION_RULES FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/towers.json"
const RARITIES_PATH := "res://assets/data/card_rarities.json"
const RICH := 100000


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("EVOLUTION_RULES OK")
	else:
		print("EVOLUTION_RULES FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var stats: TowerStats = TowerStats.load_from_file(PATH)
	if stats == null:
		return "real file loads"
	var cannon: TowerDef = stats.def_of(&"cannon")
	if cannon.evolution_name(&"incendiaire") != "Volcan" or cannon.requirement_item(&"incendiaire") != "poudre_noire":
		return "Volcan block read"
	if stats.def_of(&"frost").requirement_card(&"eclats") != "zero_absolu":
		return "Avalanche needs the card zero_absolu"
	if cannon.branch_value(&"incendiaire", "evolution") != null:
		return "evolution block is not a branch value"
	if int(cannon.value("pierce_total", &"perforant", 3)) != 3 or int(cannon.value("pierce_total", &"perforant", 3, true)) != 999:
		return "value: evolution layer only when evolved"
	if not is_equal_approx(float(cannon.value("damage", &"perforant", 3, true)), 10.0):
		return "value: evolved falls back to the base value"
	var items := {"poudre_noire": {"name": "Poudre noire", "spec": "", "spec_name": ""}, "lunette": {"name": "Lunette", "spec": "archer", "spec_name": "Archer"}, "bottes": {"name": "Bottes de vent"}, "bouclier_cristal": {"name": "Bouclier de cristal"}, "gachette": {"name": "Gâchette légère"}, "plans_ingenieur": {"name": "Plans d'ingénieur"}}
	var cards := {"gel_mordant": {"name": "Gel mordant"}, "zero_absolu": {"name": "Zéro absolu", "spec": "maitre_eau", "spec_name": "Maître de l'eau"}, "condensateur": {"name": "Condensateur"}, "reservoir_sous_pression": {"name": "Réservoir sous pression"}, "combustion": {"name": "Combustion", "spec": "maitre_feu"}, "artillerie_lourde": {"name": "Artillerie lourde"}}
	if not stats.resolve_evolutions(items, cards, "test"):
		return "resolve_evolutions accepts known ids"
	if EvolutionRules.requirement_label(cannon, &"incendiaire") != "objet Poudre noire":
		return "requirement_label of an item"
	if cannon.requirement_spec(&"perforant") != &"archer":
		return "Lunette reserved to the archer"
	var no_card: Dictionary = cards.duplicate()
	no_card.erase("gel_mordant")
	if TowerStats.load_from_file(PATH).resolve_evolutions(items, no_card, "test"):
		return "resolve_evolutions refuses an unknown card"
	var failed: String = _run_status(stats)
	if failed.is_empty():
		failed = _run_invalid()
	if failed.is_empty():
		failed = _run_card_pool(stats)
	return failed


func _run_status(stats: TowerStats) -> String:
	var owned: Dictionary = {}
	var has_item := func(id: String) -> bool: return owned.has(id)
	var has_card := func(id: String) -> bool: return owned.has(id)
	var reserve := TowerReserve.new(stats)
	var cannon: TowerDef = stats.def_of(&"cannon")
	var record: TowerRecord = reserve.add_free(&"cannon")
	if EvolutionRules.status(record, cannon, has_item, has_card, &"", &"archer") != EvolutionRules.NO_BRANCH:
		return "level 1 is no_branch"
	if reserve.try_upgrade(record, &"incendiaire", RICH, 1.0) < 0:
		return "upgrade to 2"
	if EvolutionRules.status(record, cannon, has_item, has_card, &"", &"archer") != EvolutionRules.NEEDS_LEVEL:
		return "level 2 needs_level"
	if reserve.evolve(record) or record.evolved:
		return "evolve of a level 2 refused"
	if reserve.try_upgrade(record, &"", RICH, 1.0) < 0:
		return "upgrade to 3"
	if EvolutionRules.status(record, cannon, has_item, has_card, &"", &"archer") != EvolutionRules.MISSING:
		return "level 3 without the item is missing"
	owned["poudre_noire"] = true
	if EvolutionRules.status(record, cannon, has_item, has_card, &"", &"archer") != EvolutionRules.READY:
		return "level 3 with the item is ready"
	var changes: Array[int] = [0]
	reserve.changed.connect(func() -> void: changes[0] += 1)
	if not reserve.evolve(record) or not record.evolved or changes[0] != 1:
		return "evolve applies and emits changed"
	if EvolutionRules.status(record, cannon, has_item, has_card, &"", &"archer") != EvolutionRules.EVOLVED:
		return "evolved status"
	if reserve.evolve(record):
		return "second evolve refused"
	reserve.mark_placed(record)
	reserve.mark_returned(record)
	reserve.return_all()
	if not record.evolved or record.level != 3 or record.branch != &"incendiaire":
		return "evolution kept in the reserve"
	var frost: TowerDef = stats.def_of(&"frost")
	var shards: TowerRecord = reserve.add_free(&"frost")
	reserve.try_upgrade(shards, &"eclats", RICH, 1.0)
	reserve.try_upgrade(shards, &"", RICH, 1.0)
	owned["zero_absolu"] = true
	if EvolutionRules.status(shards, frost, has_item, has_card, &"maitre_eau", &"archer") != EvolutionRules.OTHER_HERO:
		return "evolution reserved to maitre_eau is other_hero for an archer"
	if EvolutionRules.status(shards, frost, has_item, has_card, &"maitre_eau", &"maitre_eau") != EvolutionRules.READY:
		return "evolution reserved to maitre_eau is ready for its hero"
	if reserve.evolve(TowerRecord.new()):
		return "evolve of an unknown record refused"
	return ""


func _run_invalid() -> String:
	var base: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var no_name: Dictionary = (base as Dictionary).duplicate(true)
	_evolution_of(no_name, "cannon", "incendiaire").erase("name")
	if TowerStats.from_data(no_name, "no_name") != null:
		return "evolution without name refused"
	var no_value: Dictionary = (base as Dictionary).duplicate(true)
	_evolution_of(no_value, "mortar", "grappe").erase("shells")
	if TowerStats.from_data(no_value, "no_value") != null:
		return "evolution without a required value refused"
	var both: Dictionary = (base as Dictionary).duplicate(true)
	_evolution_of(both, "tesla", "arc")["requires_card"] = "condensateur"
	if TowerStats.from_data(both, "both") != null:
		return "evolution with an item and a card refused"
	var missing: Dictionary = (base as Dictionary).duplicate(true)
	((((missing["towers"] as Dictionary)["amplifier"] as Dictionary)["branches"] as Dictionary)["cadence"] as Dictionary).erase("evolution")
	if TowerStats.from_data(missing, "missing") != null:
		return "branch without its evolution refused"
	return ""


## A requires_tower card is only drawn once its tower is unlocked.
func _run_card_pool(stats: TowerStats) -> String:
	var rarities: CardRarities = CardRarities.load_from_file(RARITIES_PATH)
	if rarities == null:
		return "load rarities"
	var key := CardDef.new()
	key.id = "condensateur"
	key.rarity = &"rare"
	key.max_stacks = 1
	key.requires_tower = "tesla"
	key.effects.append({"type": "evolution_key"})
	var catalog := CardCatalog.new()
	catalog.cards.append(key)
	var mods := PlayerModifiers.new(null)
	var starting: Array[StringName] = [&"cannon", &"frost"]
	mods.set_starting_towers(starting)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pool := CardPool.new(catalog, mods, rng, PackedStringArray(), 0, "", rarities, func(_id: String) -> bool: return true)
	if pool.can_draw(5):
		return "requires_tower card excluded while the tower is locked"
	mods.unlock_tower(&"tesla")
	if pool.draw(5) != [key]:
		return "requires_tower card drawn once the tower is unlocked"
	var raw := {"id": "k", "display_name": "K", "description": "k", "rarity": "rare", "requires_tower": "laser", "effects": [{"type": "evolution_key"}]}
	if CardCatalog._parse_card(raw, 0, "test", null, null, rarities, null, stats) != null:
		return "catalog refuses an unknown requires_tower"
	raw["requires_tower"] = "tesla"
	var parsed: CardDef = CardCatalog._parse_card(raw, 0, "test", null, null, rarities, null, stats)
	if parsed == null or parsed.requires_tower != "tesla":
		return "catalog reads requires_tower"
	return ""


func _evolution_of(data: Dictionary, tower_id: String, branch: String) -> Dictionary:
	return ((((data["towers"] as Dictionary)[tower_id] as Dictionary)["branches"] as Dictionary)[branch] as Dictionary)["evolution"]
