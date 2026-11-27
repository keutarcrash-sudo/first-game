## Logic check for AmplifierRules (towers T2a, Task 4): the strongest amplifier counts,
## per bonus type, separately. Run with:
## godot --headless -s res://tests/unit/towers/amplifier_rules_check.gd
## Prints "AMPLIFIER_RULES OK" or "AMPLIFIER_RULES FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/towers.json"


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("AMPLIFIER_RULES OK")
	else:
		print("AMPLIFIER_RULES FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var stats: TowerStats = TowerStats.load_from_file(PATH)
	if stats == null:
		return "towers.json loads"
	var amp: TowerDef = stats.def_of(&"amplifier")
	if amp == null:
		return "towers.json has the amplifier"
	var damage: float = float(amp.value("damage_bonus", &"", 1))
	var cadence_2: float = float(amp.value("rate_bonus", &"cadence", 2))
	var cadence_3: float = float(amp.value("rate_bonus", &"cadence", 3))
	var catalyst_2: float = float(amp.value("state_bonus", &"catalyseur", 2))
	if not is_equal_approx(damage, 0.25) or not is_equal_approx(cadence_2, 0.3):
		return "amplifier damage 0.25 and Cadence 0.3"
	if not is_equal_approx(cadence_3, 0.5) or not is_equal_approx(catalyst_2, 0.5):
		return "Cadence level 3 0.5 and Catalyseur 0.5"
	if amp.value("rate_bonus", &"catalyseur", 3) != null:
		return "a Catalyseur gives no cadence"
	var cadences: Array[Dictionary] = [_boost(damage, cadence_2, 0.0), _boost(damage, cadence_3, 0.0)]
	var two_cadences: Dictionary = AmplifierRules.combine(cadences)
	if not is_equal_approx(float(two_cadences["rate"]), 0.5):
		return "two Cadence 0.3 and 0.5 give rate 0.5 (got %s)" % two_cadences["rate"]
	if not is_equal_approx(float(two_cadences["damage"]), 0.25):
		return "two amplifiers give damage 0.25, not added (got %s)" % two_cadences["damage"]
	var both: Array[Dictionary] = [_boost(damage, cadence_2, 0.0), _boost(damage, 0.0, catalyst_2)]
	var mixed: Dictionary = AmplifierRules.combine(both)
	if not is_equal_approx(float(mixed["rate"]), 0.3) or not is_equal_approx(float(mixed["state"]), 0.5):
		return "Cadence 0.3 + Catalyseur 0.5 give rate 0.3 and state 0.5 (got %s)" % mixed
	var three: Array[Dictionary] = [_boost(0.1, 0.0, 0.0), _boost(0.4, 0.0, 0.0), _boost(0.2, 0.0, 0.0)]
	var strongest: Dictionary = AmplifierRules.combine(three)
	if not is_equal_approx(float(strongest["damage"]), 0.4):
		return "damage is the maximum (got %s)" % strongest["damage"]
	var none: Array[Dictionary] = []
	var empty: Dictionary = AmplifierRules.combine(none)
	for key: String in ["damage", "rate", "state"]:
		if not empty.has(key) or not is_zero_approx(float(empty[key])):
			return "no amplifier gives %s 0 (got %s)" % [key, empty]
	return ""


func _boost(damage: float, rate: float, state: float) -> Dictionary:
	return {"damage": damage, "rate": rate, "state": state}
