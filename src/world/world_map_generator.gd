## Builds world maps (étape 5a, spec §6.2 and §8bis) from the tuning values of
## world_map.json. Generation runs in three steps — column sizes, non-crossing
## links, then place types — and the result is checked by [method is_valid];
## a failed draw is redrawn, up to [code]max_tries[/code] draws, after which the
## hand-written [method fallback] map is used so generation always ends.
## Uses only the RandomNumberGenerator it is given: one seed, one map.
class_name WorldMapGenerator
extends RefCounted

const INT_KEYS: Array[String] = ["columns", "min_nodes", "max_nodes", "min_shops_per_path", "max_same_in_a_row", "max_tries"]
## Most links a place can have toward the next column (spec §6.1).
const MAX_LINKS := 2

var _columns: int
var _min_nodes: int
var _max_nodes: int
## Place type (StringName) -> draw weight (float > 0).
var _weights: Dictionary = {}
var _min_shops_per_path: int
var _max_same_in_a_row: int
var _max_tries: int


## Reads and validates the JSON file at [param path]. Returns [code]null[/code]
## and prints an error naming the file and the faulty key if anything is wrong.
static func load_from_file(path: String) -> WorldMapGenerator:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("WorldMapGenerator: cannot read '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return null
	return from_data(JSON.parse_string(text), path)


## Validates already-parsed JSON [param data] ([param source] names the file in errors).
## Returns [code]null[/code] and prints an error on the first problem.
static func from_data(data: Variant, source: String) -> WorldMapGenerator:
	if not data is Dictionary:
		push_error("WorldMapGenerator: '%s' is not a valid JSON object." % source)
		return null
	var values: Dictionary = data
	for key: String in INT_KEYS:
		var value: Variant = values.get(key)
		if not (value is float or value is int) or float(value) != floorf(float(value)):
			push_error("WorldMapGenerator: key '%s' in '%s' must be a whole number." % [key, source])
			return null
	var generator := WorldMapGenerator.new()
	generator._columns = int(values["columns"])
	generator._min_nodes = int(values["min_nodes"])
	generator._max_nodes = int(values["max_nodes"])
	generator._min_shops_per_path = int(values["min_shops_per_path"])
	generator._max_same_in_a_row = int(values["max_same_in_a_row"])
	generator._max_tries = int(values["max_tries"])
	if generator._columns < 1:
		push_error("WorldMapGenerator: key 'columns' in '%s' must be at least 1." % source)
		return null
	if generator._min_nodes < 1:
		push_error("WorldMapGenerator: key 'min_nodes' in '%s' must be at least 1." % source)
		return null
	# Column 0 hangs entirely from the start, so its places need distinct types;
	# and each place covers at most MAX_LINKS places of the next column.
	if generator._max_nodes < generator._min_nodes or generator._max_nodes > WorldMap.TYPES.size() \
			or generator._max_nodes > generator._min_nodes * MAX_LINKS:
		push_error("WorldMapGenerator: key 'max_nodes' in '%s' must be between min_nodes and min(%d, min_nodes x %d)." % [source, WorldMap.TYPES.size(), MAX_LINKS])
		return null
	if generator._min_shops_per_path < 0 or generator._min_shops_per_path > generator._columns:
		push_error("WorldMapGenerator: key 'min_shops_per_path' in '%s' must be between 0 and columns." % source)
		return null
	if generator._max_same_in_a_row < 1:
		push_error("WorldMapGenerator: key 'max_same_in_a_row' in '%s' must be at least 1." % source)
		return null
	if generator._max_tries < 1:
		push_error("WorldMapGenerator: key 'max_tries' in '%s' must be at least 1." % source)
		return null
	var weights: Variant = values.get("weights")
	if not weights is Dictionary or (weights as Dictionary).size() != WorldMap.TYPES.size():
		push_error("WorldMapGenerator: key 'weights' in '%s' must be an object with exactly the keys %s." % [source, WorldMap.TYPES])
		return null
	for type: StringName in WorldMap.TYPES:
		var weight: Variant = (weights as Dictionary).get(String(type))
		if not (weight is float or weight is int) or weight <= 0:
			push_error("WorldMapGenerator: key 'weights.%s' in '%s' must be a positive number." % [type, source])
			return null
		generator._weights[type] = float(weight)
	if not generator.is_valid(generator.fallback()):
		push_error("WorldMapGenerator: the values in '%s' reject the built-in fallback map; generation could fail to end." % source)
		return null
	return generator


## Draws a map with [param rng]; redraws while a rule fails, up to max_tries
## draws, then returns [method fallback] (with the shipped values a draw
## succeeds about 3 times in 10, so the fallback is practically never used).
## The result always passes [method is_valid].
func generate(rng: RandomNumberGenerator) -> WorldMap:
	for _attempt: int in _max_tries:
		var map: WorldMap = _draw(rng)
		if is_valid(map):
			return map
	return fallback()


## True when [param map] follows every rule: column count and sizes, 1 to 2
## ascending links per place (none in the last column), every place of columns
## after the first reached, no crossing links, no two places of a column linked
## from the same previous place (or the start) sharing a type, and on every path
## at least min_shops_per_path shops and never more than max_same_in_a_row
## identical types in a row.
func is_valid(map: WorldMap) -> bool:
	if map == null or map.columns.size() != _columns:
		return false
	for column: Variant in map.columns:
		if not column is Array:
			return false
	for c: int in _columns:
		if not _is_column_valid(map, c):
			return false
	if not _has_distinct_types(map, 0, PackedInt32Array(range(map.size_of(0)))):
		return false
	for c: int in _columns - 1:
		var reached: Dictionary = {}
		var previous_last: int = -1
		for index: int in map.size_of(c):
			var links: PackedInt32Array = map.links_of(c, index)
			if links[0] < previous_last:
				return false  # Crossing with the previous place's links.
			previous_last = links[links.size() - 1]
			if not _has_distinct_types(map, c + 1, links):
				return false
			for target: int in links:
				reached[target] = true
		if reached.size() != map.size_of(c + 1):
			return false
	for path: PackedInt32Array in map.paths():
		if not _is_path_valid(map, path):
			return false
	return true


## The fixed map used when every draw failed (spec §8bis). Written by hand for
## the shipped world_map.json (7 columns of 2 places); loading checks it is valid
## for the values in the file.
func fallback() -> WorldMap:
	var s: StringName = WorldMap.SHOP
	var t: StringName = WorldMap.TREASURE
	var r: StringName = WorldMap.REST
	var layout: Array = [
		[[s, [0]], [t, [1]]],
		[[r, [0]], [s, [1]]],
		[[s, [0, 1]], [r, [1]]],
		[[t, [0]], [s, [1]]],
		[[s, [0]], [t, [1]]],
		[[r, [0]], [s, [0, 1]]],
		[[s, []], [r, []]],
	]
	var map := WorldMap.new()
	for column: Array in layout:
		var places: Array[Dictionary] = []
		for entry: Array in column:
			places.append(WorldMap.make_place(entry[0] as StringName, PackedInt32Array(entry[1] as Array)))
		map.columns.append(places)
	return map


## One draw: sizes, links, then types. Types are drawn column by column with
## the weights, skipping a type a sibling already has, a type that would make
## more than max_same_in_a_row identical places in a row on some path, and
## forcing a shop when a path could otherwise no longer reach min_shops_per_path.
## Returns [code]null[/code] when those constraints leave no type for a place
## (the caller draws again); the result is still checked by [method is_valid].
func _draw(rng: RandomNumberGenerator) -> WorldMap:
	var sizes: PackedInt32Array = PackedInt32Array()
	for c: int in _columns:
		sizes.append(rng.randi_range(_min_nodes, _max_nodes))
	var links: Array[Array] = []
	for c: int in _columns:
		if c == _columns - 1:
			var ends: Array[PackedInt32Array] = []
			for _i: int in sizes[c]:
				ends.append(PackedInt32Array())
			links.append(ends)
		else:
			links.append(_draw_links(sizes[c], sizes[c + 1], rng))
	var map := WorldMap.new()
	# Per place of the previous column: longest run of its own type over the
	# paths reaching it, and fewest shops over those paths.
	var previous_runs: PackedInt32Array = PackedInt32Array()
	var previous_shops: PackedInt32Array = PackedInt32Array()
	for c: int in _columns:
		var places: Array[Dictionary] = []
		var runs: PackedInt32Array = PackedInt32Array()
		var shops: PackedInt32Array = PackedInt32Array()
		for index: int in sizes[c]:
			var parents: PackedInt32Array = PackedInt32Array()
			if c > 0:
				for p: int in sizes[c - 1]:
					if (links[c - 1][p] as PackedInt32Array).has(index):
						parents.append(p)
			var forbidden: Array[StringName] = []
			for earlier: int in index:
				if c == 0 or _share_parent(links[c - 1], earlier, index):
					forbidden.append(places[earlier]["type"])
			var fewest_shops: int = 0 if c == 0 else _columns
			for p: int in parents:
				var parent_type: StringName = map.type_of(c - 1, p)
				if previous_runs[p] >= _max_same_in_a_row and not forbidden.has(parent_type):
					forbidden.append(parent_type)
				fewest_shops = mini(fewest_shops, previous_shops[p])
			var type: StringName
			if fewest_shops + (_columns - 1 - c) < _min_shops_per_path:
				if forbidden.has(WorldMap.SHOP):
					return null
				type = WorldMap.SHOP
			else:
				if forbidden.size() >= WorldMap.TYPES.size():
					return null
				type = _draw_type(forbidden, rng)
			var run: int = 1
			for p: int in parents:
				if map.type_of(c - 1, p) == type:
					run = maxi(run, previous_runs[p] + 1)
			runs.append(run)
			shops.append(fewest_shops + (1 if type == WorldMap.SHOP else 0))
			places.append(WorldMap.make_place(type, links[c][index]))
		map.columns.append(places)
		previous_runs = runs
		previous_shops = shops
	return map


## Links from a column of [param count] places to one of [param next_count]:
## each place aims at an interval of 1 or 2 consecutive places, starting at the
## earliest at the end of the previous place's interval (shared place) and at the
## latest just after it, so links never cross and every next place is covered.
## Requires next_count <= count x MAX_LINKS (checked when loading).
func _draw_links(count: int, next_count: int, rng: RandomNumberGenerator) -> Array[PackedInt32Array]:
	var result: Array[PackedInt32Array] = []
	var last_end: int = -1
	for index: int in count:
		var remaining: int = count - 1 - index
		var options: Array[Vector2i] = []
		var first_start: int = maxi(last_end, 0)
		for start: int in range(first_start, last_end + 2):
			for end: int in range(start, start + MAX_LINKS):
				# The places after this one must still be able to cover the rest.
				if end < next_count and next_count - 1 - end <= remaining * MAX_LINKS:
					options.append(Vector2i(start, end))
		var pick: Vector2i = options[rng.randi_range(0, options.size() - 1)]
		result.append(PackedInt32Array(range(pick.x, pick.y + 1)))
		last_end = pick.y
	return result


## True when places [param a] and [param b] of a column are both linked from one
## place of the previous column ([param parent_links] = that column's links).
func _share_parent(parent_links: Array, a: int, b: int) -> bool:
	for targets: PackedInt32Array in parent_links:
		if targets.has(a) and targets.has(b):
			return true
	return false


## A weighted type that is not in [param forbidden].
func _draw_type(forbidden: Array[StringName], rng: RandomNumberGenerator) -> StringName:
	var allowed: Array[StringName] = []
	var total: float = 0.0
	for type: StringName in WorldMap.TYPES:
		if not forbidden.has(type):
			allowed.append(type)
			total += _weights[type]
	var roll: float = rng.randf() * total
	for type: StringName in allowed:
		roll -= _weights[type]
		if roll < 0.0:
			return type
	return allowed[allowed.size() - 1]


func _is_column_valid(map: WorldMap, c: int) -> bool:
	var count: int = map.size_of(c)
	if count < _min_nodes or count > _max_nodes:
		return false
	var next_count: int = map.size_of(c + 1) if c < _columns - 1 else 0
	for index: int in count:
		var place: Variant = (map.columns[c] as Array)[index]
		if not place is Dictionary or not WorldMap.TYPES.has(place.get("type")) \
				or not place.get("links") is PackedInt32Array:
			return false
		var links: PackedInt32Array = place["links"]
		if c == _columns - 1:
			if not links.is_empty():
				return false
			continue
		if links.is_empty() or links.size() > MAX_LINKS:
			return false
		for i: int in links.size():
			if links[i] < 0 or links[i] >= next_count or (i > 0 and links[i] <= links[i - 1]):
				return false
	return true


## True when the places [param indexes] of column [param c] all have different types.
func _has_distinct_types(map: WorldMap, c: int, indexes: PackedInt32Array) -> bool:
	var seen: Dictionary = {}
	for index: int in indexes:
		var type: StringName = map.type_of(c, index)
		if seen.has(type):
			return false
		seen[type] = true
	return true


func _is_path_valid(map: WorldMap, path: PackedInt32Array) -> bool:
	var shops: int = 0
	var run: int = 0
	var previous: StringName = &""
	for c: int in path.size():
		var type: StringName = map.type_of(c, path[c])
		if type == WorldMap.SHOP:
			shops += 1
		run = run + 1 if type == previous else 1
		if run > _max_same_in_a_row:
			return false
		previous = type
	return shops >= _min_shops_per_path
