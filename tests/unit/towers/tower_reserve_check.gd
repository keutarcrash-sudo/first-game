## Logic check for TowerReserve, TowerRecord and the towers T1 blocks of
## TowerStats. Run with:
## godot --headless -s res://tests/unit/towers/tower_reserve_check.gd
## Prints "TOWER_RESERVE OK" or "TOWER_RESERVE FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/towers.json"
const CANNON := TowerStats.Kind.CANNON
const FROST := TowerStats.Kind.FROST
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
	var failed: String = _run_prices(stats)
	if failed.is_empty():
		failed = _run_upgrades(stats)
	if failed.is_empty():
		failed = _run_placement(stats)
	if failed.is_empty():
		failed = _run_invalid()
	return failed


func _run_prices(stats: TowerStats) -> String:
	var reserve := TowerReserve.new(stats)
	if reserve.least_owned_kind() != CANNON:
		return "least_owned_kind is CANNON on an empty tie"
	for expected: int in [50, 75, 100]:
		if reserve.price_of_next(CANNON, 1.0) != expected:
			return "cannon price %d" % expected
		if reserve.buy(CANNON, RICH, 1.0) == null:
			return "buy cannon at %d" % expected
	if reserve.price_of_next(FROST, 1.0) != 50:
		return "frost price independent of cannons"
	if reserve.least_owned_kind() != FROST:
		return "least_owned_kind is FROST when cannons outnumber it"
	var discounted := TowerReserve.new(stats)
	for expected: int in [40, 60, 80]:
		if discounted.price_of_next(CANNON, 0.8) != expected:
			return "discounted cannon price %d" % expected
		discounted.buy(CANNON, RICH, 0.8)
	var gifts := TowerReserve.new(stats)
	var gift: TowerRecord = gifts.add_free(FROST)
	if gift == null or not gift.is_free or gifts.price_of_next(FROST, 1.0) != 50:
		return "add_free does not raise the price"
	if gifts.least_owned_kind() != CANNON:
		return "least_owned_kind picks the kind with fewer towers"
	gifts.add_free(CANNON)
	if gifts.least_owned_kind() != CANNON:
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
	(((no_label["branches"] as Dictionary)["frost"] as Dictionary)["blizzard"] as Dictionary).erase("label")
	if TowerStats.from_data(no_label, "no_label") != null:
		return "branch without label refused"
	return ""
