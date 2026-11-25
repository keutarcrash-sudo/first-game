## Logic check for ChainLimiter (towers T1, Task 3). Run with:
## godot --headless -s res://tests/unit/towers/chain_limiter_check.gd
## Prints "CHAIN_LIMITER OK" or "CHAIN_LIMITER FAIL: <reason>" then quits.
extends SceneTree

const PATH := "res://assets/data/towers.json"


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("CHAIN_LIMITER OK")
	else:
		print("CHAIN_LIMITER FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var stats: TowerStats = TowerStats.load_from_file(PATH)
	if stats == null:
		return "towers.json loads"
	if stats.chain_max_per_frame != 12:
		return "towers.json chain.max_per_frame is 12 (got %d)" % stats.chain_max_per_frame
	var limiter := ChainLimiter.new(stats.chain_max_per_frame)
	for i: int in 12:
		if not limiter.try_consume(5):
			return "effect %d of frame 5 allowed" % (i + 1)
	if limiter.try_consume(5):
		return "13th effect of frame 5 refused"
	if not limiter.try_consume(6):
		return "frame 6 starts the count over"
	for i: int in 11:
		if not limiter.try_consume(6):
			return "effect %d of frame 6 allowed" % (i + 2)
	if limiter.try_consume(6):
		return "13th effect of frame 6 refused"
	var none := ChainLimiter.new(0)
	if none.try_consume(1):
		return "a cap of 0 allows nothing"
	return ""
