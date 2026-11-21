## Logic check for AbilityBarStyle. Run with:
## godot --headless -s res://tests/unit/ui/ability_bar_style_check.gd
## Prints "ABILITY_BAR_STYLE OK" or "ABILITY_BAR_STYLE FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/ability_bar.json"


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("ABILITY_BAR_STYLE OK")
	else:
		print("ABILITY_BAR_STYLE FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var style: AbilityBarStyle = AbilityBarStyle.load_from_file(PATH)
	if style == null:
		return "real file loads"
	if style.color_of(&"a") != Color("#19e3ff"):
		return "color_of a is cyan"
	if not is_equal_approx(style.bottom_band_height(), 120.0 + 72.0 + 6.0 + 18.0 * 1.2 + 8.0):
		return "bottom_band_height formula"
	if not is_equal_approx(style.breath_scale(0.0), 1.0):
		return "breath_scale(0) is 1"
	if not is_equal_approx(style.breath_scale(0.8), 1.05):
		return "breath_scale(half period) is 1.05"
	if not is_equal_approx(style.breath_scale(1.6), 1.0):
		return "breath_scale(period) is 1"
	if not is_equal_approx(style.pop_scale(0.0), 1.25):
		return "pop_scale(0) is 1.25"
	if not is_equal_approx(style.pop_scale(0.25), 1.0):
		return "pop_scale(duration) is 1"
	if not is_equal_approx(style.pop_scale(-1.0), 1.0):
		return "pop_scale(negative) is 1"
	if not is_equal_approx(style.pop_flash(0.0), 1.0):
		return "pop_flash(0) is 1"
	if not is_equal_approx(style.pop_flash(0.25), 0.0):
		return "pop_flash(duration) is 0"
	if not is_equal_approx(AbilityBarStyle.cooldown_fraction(3.0, 6.0), 0.5):
		return "cooldown_fraction half"
	if not is_equal_approx(AbilityBarStyle.cooldown_fraction(7.0, 6.0), 1.0):
		return "cooldown_fraction clamped to 1"
	if not is_equal_approx(AbilityBarStyle.cooldown_fraction(1.0, 0.0), 0.0):
		return "cooldown_fraction total 0 is 0"
	return _run_invalid()


## Each broken copy of the real file must be refused (null).
func _run_invalid() -> String:
	var base: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not base is Dictionary:
		return "real file parses"
	var missing: Dictionary = (base as Dictionary).duplicate(true)
	(missing["role_colors"] as Dictionary).erase("e")
	if AbilityBarStyle.from_data(missing, "missing_role") != null:
		return "missing role refused"
	var bad_color: Dictionary = (base as Dictionary).duplicate(true)
	(bad_color["role_colors"] as Dictionary)["a"] = "not-a-color"
	if AbilityBarStyle.from_data(bad_color, "bad_color") != null:
		return "invalid color refused"
	var bad_disc: Dictionary = (base as Dictionary).duplicate(true)
	bad_disc["disc_diameter"] = 0.0
	if AbilityBarStyle.from_data(bad_disc, "bad_disc") != null:
		return "disc_diameter <= 0 refused"
	var bad_period: Dictionary = (base as Dictionary).duplicate(true)
	(bad_period["breath"] as Dictionary)["period"] = 0.0
	if AbilityBarStyle.from_data(bad_period, "bad_period") != null:
		return "breath.period <= 0 refused"
	return ""
