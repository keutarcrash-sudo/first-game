## Logic check for TowerReserve, TowerRecord, TowerDef and the towers T1 / T2a blocks of
## TowerStats. Run with:
## godot --headless -s res://tests/unit/towers/tower_reserve_check.gd
## Prints "TOWER_RESERVE OK" or "TOWER_RESERVE FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/towers.json"
const CANNON := &"cannon"
const FROST := &"frost"
const RICH := 100000


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("TOWER_RESERVE OK")
	else:
		print("TOWER_RESERVE FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var stats: TowerStats = TowerStats.load_from_file(PATH)
	if stats == null:
		return "real file loads"
	if stats.price_step != 25 or stats.upgrade_costs != [80, 150] as Array[int]:
		return "reserve block read"
	if stats.chain_max_per_frame != 12 or not is_equal_approx(stats.frozen_vulnerability, 0.25):
		return "chain / freeze blocks read"
	if stats.branch_ids(CANNON) != [&"incendiaire", &"perforant"] as Array[StringName]:
		return "cannon branch ids"
	if stats.branch_value(FROST, &"eclats", "label") != "Éclats":
		return "branch_value label"
	if stats.starting_unlocked != [CANNON, FROST] as Array[StringName]:
		return "starting_unlocked is cannon and frost"
	var cannon_def: TowerDef = stats.def_of(CANNON)
	if cannon_def == null or cannon_def.behaviour != &"shooter" or stats.def_of(FROST).behaviour != &"frost_aura":
		return "behaviours of cannon and frost"
	if cannon_def.base_cost != 50 or not is_equal_approx(cannon_def.range, 250.0) or not is_equal_approx(float(cannon_def.values["damage"]), 10.0):
		return "cannon values read"
	if not is_equal_approx(float(stats.def_of(FROST).values["slow_factor"]), 0.45):
		return "frost slow_factor read"
	if not is_equal_approx(float(cannon_def.value("burn_dps", &"incendiaire", 2)), 8.0):
		return "value reads the branch at level 2"
	if int(cannon_def.value("pierce_total", &"perforant", 3)) != 3:
		return "value reads the level 2 key at level 3 without l3_"
	if not is_equal_approx(float(cannon_def.value("damage", &"perforant", 3)), 10.0):
		return "value falls back to the base value"
	if not is_equal_approx(float(cannon_def.value("range", &"", 1)), 250.0):
		return "value reads the base range"
	if stats.def_of(&"laser") != null:
		return "unknown tower is null"
	var failed: String = _run_prices(stats)
	if failed.is_empty():
		failed = _run_upgrades(stats)
	if failed.is_empty():
		failed = _run_placement(stats)
	if failed.is_empty():
		failed = _run_invalid()
	return failed


func _run_prices(stats: TowerStats) -> String:
	var both: Array[StringName] = [CANNON, FROST]
	var cannon_only: Array[StringName] = [CANNON]
	var reserve := TowerReserve.new(stats)
	if reserve.least_owned_kind(both) != CANNON:
		return "least_owned_kind is CANNON on an empty tie"
	for expected: int in [50, 75, 100]:
		if reserve.price_of_next(CANNON, 1.0) != expected:
			return "cannon price %d" % expected
		if reserve.buy(CANNON, RICH, 1.0) == null:
			return "buy cannon at %d" % expected
	if reserve.price_of_next(FROST, 1.0) != 50:
		return "frost price independent of cannons"
	if reserve.least_owned_kind(both) != FROST:
		return "least_owned_kind is FROST when cannons outnumber it"
	if reserve.least_owned_kind(cannon_only) != CANNON:
		return "least_owned_kind ignores the locked towers"
	var none: Array[StringName] = []
	if reserve.least_owned_kind(none) != &"":
		return "least_owned_kind is empty when nothing is unlocked"
	if reserve.buy(&"laser", RICH, 1.0) != null or reserve.add_free(&"laser") != null:
		return "unknown kind refused"
	var discounted := TowerReserve.new(stats)
	for expected: int in [40, 60, 80]:
		if discounted.price_of_next(CANNON, 0.8) != expected:
			return "discounted cannon price %d" % expected
		discounted.buy(CANNON, RICH, 0.8)
	var gifts := TowerReserve.new(stats)
	var gift: TowerRecord = gifts.add_free(FROST)
	if gift == null or not gift.is_free or gifts.price_of_next(FROST, 1.0) != 50:
		return "add_free does not raise the price"
	if gifts.least_owned_kind(both) != CANNON:
		return "least_owned_kind picks the kind with fewer towers"
	gifts.add_free(CANNON)
	if gifts.least_owned_kind(both) != CANNON:
		return "least_owned_kind is CANNON on a tie"
	var poor := TowerReserve.new(stats)
	if poor.buy(CANNON, 49, 1.0) != null or not poor.records().is_empty():
		return "buy with too little gold returns null"
	return ""


func _run_upgrades(stats: TowerStats) -> String:
	var reserve := TowerReserve.new(stats)
	var cannon: TowerRecord = reserve.buy(CANNON, RICH, 1.0)
	if reserve.try_upgrade(cannon, &"", RICH, 1.0) != -1 or cannon.level != 1:
		return "level 1 upgrade without branch refused"
	if reserve.try_upgrade(cannon, &"blizzard", RICH, 1.0) != -1 or cannon.branch != &"":
		return "branch of another kind refused"
	if reserve.try_upgrade(cannon, &"incendiaire", 79, 1.0) != -1 or cannon.level != 1:
		return "upgrade without enough gold refused"
	if reserve.try_upgrade(cannon, &"incendiaire", RICH, 1.0) != 80 or cannon.level != 2:
		return "incendiaire upgrade costs 80 and reaches level 2"
	if reserve.try_upgrade(cannon, &"", RICH, 1.0) != 150 or cannon.level != 3:
		return "level 3 upgrade costs 150"
	if cannon.branch != &"incendiaire":
		return "level 3 keeps the branch"
	if reserve.upgrade_cost(cannon, 1.0) != -1 or reserve.try_upgrade(cannon, &"", RICH, 1.0) != -1:
		return "level 3 cannot upgrade"
	var cheap: TowerRecord = reserve.buy(CANNON, RICH, 1.0)
	if reserve.upgrade_cost(cheap, 0.6) != 48:
		return "upgrade with cost_factor 0.6 costs 48"
	return ""


func _run_placement(stats: TowerStats) -> String:
	var reserve := TowerReserve.new(stats)
	var cannon: TowerRecord = reserve.buy(CANNON, RICH, 1.0)
	var frost: TowerRecord = reserve.buy(FROST, RICH, 1.0)
	reserve.try_upgrade(frost, &"eclats", RICH, 1.0)
	reserve.mark_placed(cannon)
	reserve.mark_placed(frost)
	if reserve.available().size() != 0 or reserve.records().size() != 2:
		return "mark_placed removes from available"
	if reserve.price_of_next(CANNON, 1.0) != 75:
		return "placing does not change the price"
	reserve.return_all()
	if reserve.available().size() != 2:
		return "return_all puts every tower back"
	if frost.level != 2 or frost.branch != &"eclats":
		return "returned tower keeps level and branch"
	reserve.mark_placed(frost)
	reserve.mark_returned(frost)
	if not reserve.available().has(frost) or frost.level != 2:
		return "mark_returned puts the tower back unchanged"
	return ""


## Each broken copy of the real file must be refused (null).
func _run_invalid() -> String:
	var base: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not base is Dictionary:
		return "real file parses"
	var no_step: Dictionary = (base as Dictionary).duplicate(true)
	(no_step["reserve"] as Dictionary).erase("price_step")
	if TowerStats.from_data(no_step, "no_step") != null:
		return "missing reserve.price_step refused"
	var no_label: Dictionary = (base as Dictionary).duplicate(true)
	(_branches_of(no_label, "frost")["blizzard"] as Dictionary).erase("label")
	if TowerStats.from_data(no_label, "no_label") != null:
		return "branch without label refused"
	var no_key: Dictionary = (base as Dictionary).duplicate(true)
	(_branches_of(no_key, "cannon")["incendiaire"] as Dictionary).erase("l3_explosion_damage")
	if TowerStats.from_data(no_key, "no_key") != null:
		return "branch without a required key refused"
	var no_branch: Dictionary = (base as Dictionary).duplicate(true)
	_branches_of(no_branch, "frost").erase("eclats")
	if TowerStats.from_data(no_branch, "no_branch") != null:
		return "missing required branch refused"
	var bad_behaviour: Dictionary = (base as Dictionary).duplicate(true)
	var laser: Dictionary = _tower_of(bad_behaviour, "cannon")
	laser["behaviour"] = "laser"
	if TowerStats.from_data(bad_behaviour, "bad_behaviour") != null:
		return "unknown behaviour refused"
	var no_value: Dictionary = (base as Dictionary).duplicate(true)
	_tower_of(no_value, "cannon").erase("fire_interval")
	if TowerStats.from_data(no_value, "no_value") != null:
		return "missing behaviour value refused"
	var bad_unlock: Dictionary = (base as Dictionary).duplicate(true)
	bad_unlock["starting_unlocked"] = ["cannon", "laser"]
	if TowerStats.from_data(bad_unlock, "bad_unlock") != null:
		return "unknown starting tower refused"
	var dup_branch: Dictionary = (base as Dictionary).duplicate(true)
	_branches_of(dup_branch, "frost")["incendiaire"] = (_branches_of(dup_branch, "cannon")["incendiaire"] as Dictionary).duplicate(true)
	if TowerStats.from_data(dup_branch, "dup_branch") != null:
		return "branch id shared by two towers refused"
	return ""


func _tower_of(data: Dictionary, tower_id: String) -> Dictionary:
	return (data["towers"] as Dictionary)[tower_id] as Dictionary


func _branches_of(data: Dictionary, tower_id: String) -> Dictionary:
	return _tower_of(data, tower_id)["branches"] as Dictionary
