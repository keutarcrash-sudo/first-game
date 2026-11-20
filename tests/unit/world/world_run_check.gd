## Logic check for WorldRun and the "world" block of waves.json (étape 5a, spec §5). Run with:
## godot --headless -s res://tests/unit/world/world_run_check.gd
## Prints "WORLD_RUN OK" or "WORLD_RUN FAIL: <name>" then quits (exit 1 on failure).
extends SceneTree

const WAVES_PATH := "res://assets/data/waves.json"
const WAVES_PER_WORLD := 8
const FINAL_COUNT_MULT := 1.5


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("WORLD_RUN OK")
	else:
		print("WORLD_RUN FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var curve: WaveCurve = WaveCurve.load_from_file(WAVES_PATH)
	if curve == null:
		return "the shipped waves.json loads"
	if curve.waves_per_world != WAVES_PER_WORLD or not is_equal_approx(curve.final_count_mult, FINAL_COUNT_MULT):
		return "waves.json world block is 8 waves, x1.5 final wave"

	var run := WorldRun.new(WAVES_PER_WORLD)
	if run.world != 1 or run.column != -1:
		return "a run starts in world 1 at the start"
	if run.world_of(1) != 1 or run.world_of(8) != 1 or run.world_of(9) != 2 or run.world_of(16) != 2 or run.world_of(17) != 3:
		return "world_of"
	if run.wave_in_world(1) != 1 or run.wave_in_world(8) != 8 or run.wave_in_world(9) != 1 or run.wave_in_world(16) != 8:
		return "wave_in_world"
	if not run.is_final_wave(8) or not run.is_final_wave(16) or run.is_final_wave(7) or run.is_final_wave(9):
		return "is_final_wave"
	if not run.reachable().is_empty() or run.move_to(0):
		return "nothing reachable before a map is set"

	# Two lanes: 0 -> 0 and 1 -> 1, then the flag.
	var map := WorldMap.new()
	var first: Array[Dictionary] = [
		WorldMap.make_place(WorldMap.SHOP, PackedInt32Array([0])),
		WorldMap.make_place(WorldMap.TREASURE, PackedInt32Array([1])),
	]
	var last: Array[Dictionary] = [
		WorldMap.make_place(WorldMap.REST, PackedInt32Array()),
		WorldMap.make_place(WorldMap.SHOP, PackedInt32Array()),
	]
	map.columns.append(first)
	map.columns.append(last)
	run.start_world(map)
	if run.reachable() != PackedInt32Array([0, 1]):
		return "from the start, all of column 0 is reachable"
	if run.move_to(2) or run.column != -1:
		return "a place outside column 0 is refused"
	if not run.move_to(0) or run.column != 0 or run.node != 0:
		return "moving into column 0"
	if run.move_to(1) or run.column != 0:
		return "a place not linked to the current one is refused"
	if not run.move_to(0) or run.column != 1 or run.visited != PackedInt32Array([0, 0]):
		return "moving along a link"
	if not run.reachable().is_empty() or run.move_to(0):
		return "nothing after the last column"
	run.world += 1
	run.start_world(map)
	if run.column != -1 or run.node != -1 or not run.visited.is_empty() or run.world != 2:
		return "start_world puts the player back at the start"
	if run.reachable().size() != 2:
		return "start_world makes column 0 reachable again"
	return ""
