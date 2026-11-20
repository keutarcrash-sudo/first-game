## Logic check for WorldMapGenerator / WorldMap (étape 5a, spec §6.2, §8bis). Run with:
## godot --headless -s res://tests/unit/world/world_map_check.gd
## Prints "WORLD_MAP OK" or "WORLD_MAP FAIL: <name>" then quits (exit 1 on failure).
## The rules are re-checked here independently of WorldMapGenerator.is_valid.
extends SceneTree

const MAP_PATH := "res://assets/data/world_map.json"
const SEEDS := 500
const COLUMNS := 7
const MIN_NODES := 2
const MAX_NODES := 3
const MIN_SHOPS := 2
const MAX_SAME := 2


func _init() -> void:
	var failed: String = _run()
	if failed.is_empty():
		print("WORLD_MAP OK")
	else:
		print("WORLD_MAP FAIL: %s" % failed)
	quit(0 if failed.is_empty() else 1)


func _run() -> String:
	var generator: WorldMapGenerator = WorldMapGenerator.load_from_file(MAP_PATH)
	if generator == null:
		return "the shipped world_map.json loads"
	var fallback: WorldMap = generator.fallback()
	if not generator.is_valid(fallback):
		return "fallback passes is_valid"
	var fallback_rule: String = _broken_rule(fallback)
	if not fallback_rule.is_empty():
		return "fallback follows the rules (%s)" % fallback_rule

	var first: WorldMap = null
	var differs := false
	for seed_value: int in range(1, SEEDS + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map: WorldMap = generator.generate(rng)
		var rule: String = _broken_rule(map)
		if not rule.is_empty():
			return "seed %d: %s" % [seed_value, rule]
		if not generator.is_valid(map):
			return "seed %d: is_valid accepts the generated map" % seed_value
		var again := RandomNumberGenerator.new()
		again.seed = seed_value
		if not _same(map, generator.generate(again)):
			return "seed %d: same seed gives the same map" % seed_value
		if first == null:
			first = map
		elif not _same(first, map):
			differs = true
	if not differs:
		return "different seeds give different maps"

	# is_valid rejects broken maps (each built from the valid fallback).
	var twin: WorldMap = generator.fallback()
	(twin.columns[0][1] as Dictionary)["type"] = WorldMap.SHOP  # Two shops hanging from the start.
	if generator.is_valid(twin):
		return "is_valid rejects siblings of the same type"
	var crossing: WorldMap = generator.fallback()
	(crossing.columns[0][0] as Dictionary)["links"] = PackedInt32Array([1])
	(crossing.columns[0][1] as Dictionary)["links"] = PackedInt32Array([0])
	if generator.is_valid(crossing):
		return "is_valid rejects crossing links"
	var few_shops: WorldMap = generator.fallback()
	(few_shops.columns[6][0] as Dictionary)["type"] = WorldMap.TREASURE  # Upper path R, R, T, T, S, R, T: one shop.
	(few_shops.columns[0][0] as Dictionary)["type"] = WorldMap.REST
	(few_shops.columns[2][0] as Dictionary)["type"] = WorldMap.TREASURE
	if generator.is_valid(few_shops):
		return "is_valid rejects a path with too few shops"
	var run: WorldMap = generator.fallback()
	(run.columns[4][1] as Dictionary)["type"] = WorldMap.SHOP  # S, S, S on columns 3-5 (lower lane).
	if generator.is_valid(run):
		return "is_valid rejects three identical places in a row"

	if WorldMapGenerator.from_data({ "columns": 7, "min_nodes": 2, "max_nodes": 4,
			"weights": { "shop": 40, "treasure": 30, "rest": 30 },
			"min_shops_per_path": 2, "max_same_in_a_row": 2, "max_tries": 50 }, "test") != null:
		return "max_nodes above the type count is refused"
	if WorldMapGenerator.from_data({ "columns": 7, "min_nodes": 2, "max_nodes": 3,
			"weights": { "shop": 40, "treasure": 30 },
			"min_shops_per_path": 2, "max_same_in_a_row": 2, "max_tries": 50 }, "test") != null:
		return "missing weight is refused"
	return ""


## The first broken rule of [param map] as a short text, or "" if it follows them all.
func _broken_rule(map: WorldMap) -> String:
	if map == null or map.columns.size() != COLUMNS:
		return "7 columns"
	for c: int in COLUMNS:
		var count: int = map.size_of(c)
		if count < MIN_NODES or count > MAX_NODES:
			return "column %d has 2 or 3 places" % c
		for index: int in count:
			var links: PackedInt32Array = map.links_of(c, index)
			if c == COLUMNS - 1:
				if not links.is_empty():
					return "last column leads only to the flag"
			elif links.size() < 1 or links.size() > 2:
				return "column %d place %d has 1 or 2 links" % [c, index]
			for target: int in links:
				if target < 0 or c == COLUMNS - 1 or target >= map.size_of(c + 1):
					return "column %d place %d links inside the next column" % [c, index]
	# Start: every place of column 0 hangs from it.
	var start_types: Dictionary = {}
	for index: int in map.size_of(0):
		if start_types.has(map.type_of(0, index)):
			return "column 0 places have different types"
		start_types[map.type_of(0, index)] = true
	for c: int in COLUMNS - 1:
		var incoming: PackedInt32Array = PackedInt32Array()
		incoming.resize(map.size_of(c + 1))
		incoming.fill(0)
		for a: int in map.size_of(c):
			var links_a: PackedInt32Array = map.links_of(c, a)
			var types: Dictionary = {}
			for target: int in links_a:
				incoming[target] += 1
				if types.has(map.type_of(c + 1, target)):
					return "column %d: siblings of place %d have different types" % [c + 1, a]
				types[map.type_of(c + 1, target)] = true
			for b: int in range(a + 1, map.size_of(c)):
				for la: int in links_a:
					for lb: int in map.links_of(c, b):
						if la > lb:
							return "column %d: links do not cross" % c
		for target: int in incoming.size():
			if incoming[target] < 1:
				return "column %d place %d has an incoming link" % [c + 1, target]
	var paths: Array[PackedInt32Array] = []
	for index: int in map.size_of(0):
		_walk(map, PackedInt32Array([index]), paths)
	if paths.is_empty():
		return "at least one path"
	for path: PackedInt32Array in paths:
		var shops: int = 0
		var run: int = 0
		var previous: StringName = &""
		for c: int in path.size():
			var type: StringName = map.type_of(c, path[c])
			shops += 1 if type == WorldMap.SHOP else 0
			run = run + 1 if type == previous else 1
			previous = type
			if run > MAX_SAME:
				return "no 3 identical places in a row on path %s" % path
		if shops < MIN_SHOPS:
			return "at least 2 shops on path %s" % path
	if map.paths().size() != paths.size():
		return "WorldMap.paths lists every path"
	return ""


func _walk(map: WorldMap, path: PackedInt32Array, out: Array[PackedInt32Array]) -> void:
	var c: int = path.size() - 1
	if c == COLUMNS - 1:
		out.append(path)
		return
	for next: int in map.links_of(c, path[c]):
		var longer: PackedInt32Array = path.duplicate()
		longer.append(next)
		_walk(map, longer, out)


func _same(a: WorldMap, b: WorldMap) -> bool:
	if a.columns.size() != b.columns.size():
		return false
	for c: int in a.columns.size():
		if a.size_of(c) != b.size_of(c):
			return false
		for index: int in a.size_of(c):
			if a.type_of(c, index) != b.type_of(c, index) or a.links_of(c, index) != b.links_of(c, index):
				return false
	return true
