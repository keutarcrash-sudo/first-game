## Logic check for DamageNumberModel. Run with:
## godot --headless -s res://tests/unit/ui/damage_numbers_check.gd
## Prints "DAMAGE_NUMBERS OK" or "DAMAGE_NUMBERS FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/damage_numbers.json"
const POS := Vector2(100, 100)


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("DAMAGE_NUMBERS OK")
	else:
		print("DAMAGE_NUMBERS FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _make() -> DamageNumberModel:
	var m: DamageNumberModel = DamageNumberModel.load_from_file(PATH)
	if m != null:
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		m.set_rng(rng)
	return m


func _run() -> String:
	var m: DamageNumberModel = _make()
	if m == null:
		return "real file loads"
	# Immediate sources.
	m.report(1, POS, 14.4, &"hero", false, 0.0)
	var n: Array[Dictionary] = m.numbers()
	if n.size() != 1 or n[0]["text"] != "14" or n[0]["color"] != Color("#ffffff") or n[0]["font_size"] != 22:
		return "hero hit is a white 14, size 22"
	m = _make()
	m.report(1, POS, 30.0, &"hero", true, 0.0)
	n = m.numbers()
	if n.size() != 1 or n[0]["text"] != "30!" or n[0]["color"] != Color("#ffe14d") or n[0]["font_size"] != 32:
		return "crit is a yellow 30!, size 32"
	m = _make()
	m.report(1, POS, 5.0, &"cannon", false, 0.0)
	n = m.numbers()
	if n.size() != 1 or n[0]["color"] != Color("#19e3ff"):
		return "cannon is cyan"
	# Burn grouping.
	m = _make()
	for i: int in 10:
		m.report(2, POS, 0.3, &"burn", false, 0.05 * i)
	if not m.numbers().is_empty():
		return "burn shows nothing before the interval"
	m.advance(0.5)
	n = m.numbers()
	if n.size() != 1 or n[0]["text"] != "3" or n[0]["color"] != Color("#ff9a1f"):
		return "burn group is one orange 3"
	m.advance(0.5 + 0.7 + 0.01)
	if not m.numbers().is_empty():
		return "number expires after lifetime"
	# Under 1 waits.
	m = _make()
	m.report(2, POS, 0.2, &"burn", false, 0.0)
	m.advance(0.6)
	if not m.numbers().is_empty():
		return "sum under 1 waits"
	# Death flush.
	m.report(2, POS, 0.4, &"burn", false, 0.6)
	m.flush(2, POS, 0.7)
	n = m.numbers()
	if n.size() != 1 or n[0]["text"] != "1":
		return "flush shows the pending sum (0.6 -> 1)"
	# Area is white.
	m = _make()
	m.report(3, POS, 4.0, &"area", false, 0.0)
	m.advance(0.5)
	n = m.numbers()
	if n.size() != 1 or n[0]["text"] != "4" or n[0]["color"] != Color("#ffffff"):
		return "area group is white"
	# Expiration.
	m = _make()
	m.report(1, POS, 5.0, &"hero", false, 0.0)
	m.advance(0.7 + 0.01)
	if not m.numbers().is_empty():
		return "expired number removed"
	# Rise and age.
	m = _make()
	m.report(1, POS, 5.0, &"hero", false, 0.0)
	var start_y: float = m.numbers()[0]["position"].y
	m.advance(0.35)
	n = m.numbers()
	if not is_equal_approx(n[0]["age"], 0.35) or not is_equal_approx(n[0]["position"].y, start_y - 17.0):
		return "number rises rise_px * age / lifetime"
	# Cap.
	m = _make()
	for i: int in 70:
		m.report(i, POS, float(i + 1), &"hero", false, 0.0)
	n = m.numbers()
	if n.size() != 60 or n[0]["text"] != "11" or n[59]["text"] != "70":
		return "cap 60 drops the oldest"
	# Disabled.
	m = _make()
	m.enabled = false
	m.report(1, POS, 5.0, &"hero", false, 0.0)
	m.report(1, POS, 5.0, &"burn", false, 0.0)
	m.flush(1, POS, 0.0)
	m.advance(1.0)
	if not m.numbers().is_empty():
		return "disabled creates nothing"
	# Clear.
	m = _make()
	m.report(1, POS, 5.0, &"hero", false, 0.0)
	m.clear()
	if not m.numbers().is_empty():
		return "clear empties"
	# Fade.
	m = _make()
	if not is_equal_approx(m.alpha(0.0), 1.0) or not is_equal_approx(m.alpha(0.7), 0.0):
		return "alpha(0) is 1 and alpha(lifetime) is 0"
	if not is_equal_approx(m.alpha(0.35), 1.0) or not is_equal_approx(m.alpha(0.525), 0.5):
		return "alpha fades over the second half"
	return _run_invalid()


## Each broken copy of the real file must be refused (null).
func _run_invalid() -> String:
	var base: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not base is Dictionary:
		return "real file parses"
	var bad_color: Dictionary = (base as Dictionary).duplicate(true)
	(bad_color["colors"] as Dictionary)["burn"] = "not-a-color"
	if DamageNumberModel.from_data(bad_color, "bad_color") != null:
		return "invalid color refused"
	var bad_life: Dictionary = (base as Dictionary).duplicate(true)
	bad_life["lifetime"] = 0.0
	if DamageNumberModel.from_data(bad_life, "bad_life") != null:
		return "lifetime <= 0 refused"
	var bad_max: Dictionary = (base as Dictionary).duplicate(true)
	bad_max["max_on_screen"] = 0
	if DamageNumberModel.from_data(bad_max, "bad_max") != null:
		return "max_on_screen < 1 refused"
	return ""
