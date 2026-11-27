## Logic check for NexusRules (towers T2b, Task 4): the light states a Nexus shares with the
## towers it boosts, values read from towers.json. Run with:
## godot --headless -s res://tests/unit/towers/nexus_rules_check.gd
## Prints "NEXUS_RULES OK" or "NEXUS_RULES FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/towers.json"


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("NEXUS_RULES OK")
	else:
		print("NEXUS_RULES FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var stats: TowerStats = TowerStats.load_from_file(PATH)
	if stats == null:
		return "towers.json loads"
	var amp: TowerDef = stats.def_of(&"amplifier")
	var values: Dictionary = {}
	for key: String in NexusRules.KEYS:
		values[key] = amp.value(key, &"catalyseur", 3, true)
		if values[key] == null:
			return "Nexus value %s in towers.json" % key
	if not is_equal_approx(float(amp.value("rate_mult", &"cadence", 3, true)), 2.0):
		return "Surrégime rate_mult 2"

	var burn: Array[Dictionary] = NexusRules.shared_states([_tower(&"cannon", &"incendiaire", 2, false, 1)], values)
	if burn.size() != 1 or burn[0]["state"] != &"burn":
		return "Incendiaire cannon shares a burn (got %s)" % [burn]
	if not is_equal_approx(float(burn[0]["dps"]), 4.0) or not is_equal_approx(float(burn[0]["duration"]), 2.0):
		return "the shared burn is 4/s for 2 s"

	var frost: Array[Dictionary] = NexusRules.shared_states([_tower(&"frost", &"eclats", 3, false, 1)], values)
	if frost.size() != 1 or frost[0]["state"] != &"slow":
		return "frost shares only a slow, never a freeze (got %s)" % [frost]
	if not is_equal_approx(float(frost[0]["factor"]), 0.7) or not is_equal_approx(float(frost[0]["duration"]), 1.0):
		return "the shared slow is 0.7 for 1 s"

	var blizzard: Array[Dictionary] = NexusRules.shared_states([_tower(&"frost", &"blizzard", 3, false, 1)], values)
	if blizzard.size() != 2 or blizzard[1]["state"] != &"wet" or not is_equal_approx(float(blizzard[1]["duration"]), 2.0):
		return "Blizzard level 3 also shares wet 2 s (got %s)" % [blizzard]
	for state: Dictionary in blizzard:
		if state["state"] == &"freeze":
			return "never a freeze"

	var arc: Array[Dictionary] = NexusRules.shared_states([_tower(&"tesla", &"arc", 2, false, 1)], values)
	if arc.size() != 1 or arc[0]["state"] != &"stun" or not is_equal_approx(float(arc[0]["duration"]), 0.2):
		return "Tesla Arc shares a stun 0.2 s (got %s)" % [arc]
	var tremor: Array[Dictionary] = NexusRules.shared_states([_tower(&"mortar", &"sismique", 3, true, 1)], values)
	if tremor.size() != 1 or tremor[0]["state"] != &"stun":
		return "Tremblement shares a stun"

	if not NexusRules.shared_states([_tower(&"mortar", &"sismique", 3, false, 1)], values).is_empty():
		return "a non-evolved Sismique mortar shares nothing"
	if not NexusRules.shared_states([] as Array[Dictionary], values).is_empty():
		return "no boosted tower: nothing"

	var both: Array[Dictionary] = [_tower(&"frost", &"eclats", 2, false, 7), _tower(&"cannon", &"incendiaire", 3, false, 8)]
	var for_frost: Array[Dictionary] = NexusRules.shared_states(both, values, 7)
	if for_frost.size() != 1 or for_frost[0]["state"] != &"burn":
		return "a tower does not receive its own states (got %s)" % [for_frost]
	var two_burners: Array[Dictionary] = [_tower(&"cannon", &"incendiaire", 3, false, 1), _tower(&"flamethrower", &"napalm", 2, false, 2)]
	if NexusRules.shared_states(two_burners, values).size() != 1:
		return "a state is shared once however many towers set it"
	return ""


func _tower(id: StringName, branch: StringName, level: int, evolved: bool, record: int) -> Dictionary:
	return {"id": id, "branch": branch, "level": level, "evolved": evolved, "record": record}
