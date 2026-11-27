## Logic check for BurnRules (strongest burn kept, Napalm stacking). Run with:
## godot --headless -s res://tests/unit/enemies/burn_rules_check.gd
## Prints "BURN_RULES OK" or "BURN_RULES FAIL: <reason>" then quits (exit 1 on failure).
extends SceneTree


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("BURN_RULES OK")
	else:
		print("BURN_RULES FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var merges: Array = [
		[5.0, 1.0, 8.0, 4.0, Vector2(8.0, 4.0)],
		[10.0, 3.0, 6.0, 2.0, Vector2(10.0, 3.0)],
		[6.0, 1.0, 6.0, 4.0, Vector2(6.0, 4.0)],
	]
	for c: Array in merges:
		var got: Vector2 = BurnRules.merge(c[0], c[1], c[2], c[3])
		if not got.is_equal_approx(c[4]):
			return "merge(%s, %s, %s, %s) = %s, expected %s" % [c[0], c[1], c[2], c[3], got, c[4]]
	if not is_equal_approx(BurnRules.stacked_dps(10.0, 3.0, 2.0), 20.0):
		return "stacked_dps(10, 3, 2) is capped at 20"
	if not is_equal_approx(BurnRules.stacked_dps(10.0, 1.0, 2.0), 10.0):
		return "stacked_dps(10, 1, 2) is 10"
	return ""
