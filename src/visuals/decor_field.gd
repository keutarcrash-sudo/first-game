## Neon decor (rocks, trees, crystals) scattered once per game over the field.
## Purely visual: nothing collides. Pieces within the path clearance of the
## wave path are hidden by [method show_path] so the path stays readable.
class_name DecorField
extends Node2D

## Placement attempts per requested piece before giving up (the field may be too small).
const _TRIES_PER_PIECE := 30

var _stats: DecorStats
var _pieces: Array[Node2D] = []


## Places the pieces once. [param crystal_start] is kept clear, [param rng]
## makes the layout reproducible. Each sheet folder is loaded a single time.
## Pieces whose sheet fails to load are not placed (the error names the file).
func setup(stats: DecorStats, field_rect: Rect2, crystal_start: Vector2, rng: RandomNumberGenerator) -> void:
	_stats = stats
	var sheets: Array[SpriteSheet] = []
	for dir: String in stats.piece_sheets:
		sheets.append(SpriteSheet.load_from_dir(dir))
	var area: Rect2 = field_rect.grow(-stats.edge_margin)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return
	var spots: Array[Vector2] = []
	var kinds: Array[int] = []
	var tries: int = stats.count * _TRIES_PER_PIECE
	while spots.size() < stats.count and tries > 0:
		tries -= 1
		var pos := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		var kind: int = rng.randi_range(0, sheets.size() - 1)
		if sheets[kind] == null or pos.distance_to(crystal_start) < stats.crystal_clearance:
			continue
		var free: bool = true
		for other: Vector2 in spots:
			if pos.distance_to(other) < stats.min_spacing:
				free = false
				break
		if free:
			spots.append(pos)
			kinds.append(kind)
	# Lower pieces are drawn last so they overlap the ones behind them.
	var order: Array[int] = []
	order.assign(range(spots.size()))
	order.sort_custom(func(a: int, b: int) -> bool: return spots[a].y < spots[b].y)
	for i: int in order:
		var sprite := DirectionalSprite.new()
		sprite.position = spots[i]
		add_child(sprite)
		sprite.setup(sheets[kinds[i]], stats.piece_heights[kinds[i]])
		sprite.play(&"idle")
		_pieces.append(sprite)


## Shows every piece, then hides those closer than the path clearance to any
## segment of [param path].
func show_path(path: CrystalPath) -> void:
	if _stats == null:
		return
	var points: PackedVector2Array = path.points
	for piece: Node2D in _pieces:
		var hidden: bool = false
		for i: int in range(1, points.size()):
			var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(piece.position, points[i - 1], points[i])
			if piece.position.distance_to(nearest) < _stats.path_clearance:
				hidden = true
				break
		piece.visible = not hidden
