## Line icons of the 12 abilities and the lock, drawn with thick round-ended strokes
## on any [CanvasItem] during its draw. Shapes are laid out in a 48 x 48 box (as in the
## approved mockup) and scaled to [code]size[/code]. An unknown id draws a "?".
class_name AbilityIcons
extends RefCounted

## Draws the icon of [param ability_id] centred on [param center], [param size] pixels
## wide, in [param color] with strokes [param width] pixels thick.
static func draw_icon(canvas: CanvasItem, ability_id: String, center: Vector2, size: float, color: Color, width: float) -> void:
	var pen := _Pen.new(canvas, center, size, color, width)
	match ability_id:
		"fleche_perforante":
			pen.poly([8, 40, 40, 8])
			pen.poly([28, 8, 40, 8, 40, 20])
			pen.poly([8, 40, 14, 38, 10, 34], true)
		"roulade":
			pen.arc(24, 24, 13, 0.0, TAU)
			pen.poly([33, 19, 37, 24, 41, 19])
		"pluie_de_fleches":
			for x: float in [12.0, 24.0, 36.0]:
				pen.poly([x, 6 if x == 24.0 else 8, x, 24])
				pen.poly([x - 4, 30, x, 40, x + 4, 30])
		"oeil_du_chasseur":
			pen.curve(6, 24, 24, 6, 42, 24)
			pen.curve(6, 24, 24, 42, 42, 24)
			pen.arc(24, 24, 6, 0.0, TAU)
			pen.dot(24, 24, 2.5)
			pen.poly([24, 3, 24, 9])
			pen.poly([24, 39, 24, 45])
		"boule_de_feu":
			pen.arc(24, 30, 10, 0.0, TAU)
			pen.poly([15, 25, 13, 10, 20, 17, 24, 4, 28, 17, 35, 10, 33, 25])
		"bond_enflamme":
			pen.curve(8, 36, 22, 2, 38, 30)
			pen.poly([31, 29, 38, 31, 40, 24])
			pen.poly([10, 44, 8, 38, 12, 40, 15, 33, 18, 40, 22, 37, 20, 44], true)
		"mur_de_feu":
			pen.poly([4, 42, 44, 42])
			for x: float in [6.0, 18.0, 30.0]:
				pen.poly([x, 42, x - 1, 32, x + 3, 35, x + 6, 22, x + 9, 33, x + 12, 29, x + 12, 42])
		"meteore":
			pen.arc(19, 29, 9, 0.0, TAU)
			pen.poly([26, 21, 38, 8])
			pen.poly([29, 26, 42, 17])
			pen.poly([21, 19, 30, 6])
			pen.poly([4, 44, 34, 44])
		"vague":
			pen.curve(8, 34, 16, 14, 30, 15)
			pen.arc(30, 22, 7, deg_to_rad(-90.0), deg_to_rad(140.0))
			pen.sine(40, 3, 4, 44, 2)
		"glissade":
			pen.drop(33, 12, 30, 8)
			pen.poly([6, 18, 20, 18])
			pen.poly([4, 28, 18, 28])
			pen.poly([8, 38, 22, 38])
		"flaque":
			pen.drop(24, 4, 18, 6)
			pen.ellipse(24, 36, 18, 7)
			pen.ellipse(24, 36, 8, 3)
		"raz_de_maree":
			pen.curve(4, 34, 8, 2, 32, 5)
			pen.arc(32, 13, 8, deg_to_rad(-90.0), deg_to_rad(140.0))
			pen.sine(37, 3, 2, 46, 3)
			pen.sine(44, 2, 2, 46, 3)
		_:
			_question(pen)


## Draws the lock (same parameters as [method draw_icon]).
static func draw_lock(canvas: CanvasItem, center: Vector2, size: float, color: Color, width: float) -> void:
	var pen := _Pen.new(canvas, center, size, color, width)
	pen.poly([13, 22, 35, 22, 35, 39, 13, 39], true)
	pen.poly([17, 22, 17, 16])
	pen.poly([31, 22, 31, 16])
	pen.arc(24, 16, 7, PI, TAU)
	pen.dot(24, 30, 2.5)


static func _question(pen: _Pen) -> void:
	pen.arc(24, 17, 8, PI, TAU + deg_to_rad(70.0))
	pen.poly([26.7, 24.5, 24, 30])
	pen.dot(24, 38, 2.5)


## Draws strokes given in box coordinates, scaled and centred on the canvas.
class _Pen:
	## Side of the box the shapes are written in.
	const BOX := 48.0
	const ARC_POINTS := 24
	const CURVE_POINTS := 12

	var canvas: CanvasItem
	var center: Vector2
	var scale: float
	var color: Color
	var width: float

	func _init(on: CanvasItem, at: Vector2, size: float, ink: Color, stroke_width: float) -> void:
		canvas = on
		center = at
		scale = size / BOX
		color = ink
		width = stroke_width

	## Box point (x, y) on the canvas.
	func pt(x: float, y: float) -> Vector2:
		return center + (Vector2(x, y) - Vector2(BOX, BOX) * 0.5) * scale

	## Polyline through flat box coordinates [x0, y0, x1, y1, ...], optionally closed.
	func poly(coords: Array, closed: bool = false) -> void:
		var points := PackedVector2Array()
		for i: int in range(0, coords.size() - 1, 2):
			points.append(pt(float(coords[i]), float(coords[i + 1])))
		if closed and points.size() > 2:
			points.append(points[0])
		stroke(points)

	## Arc of a box circle from [param from_angle] to [param to_angle] (radians, clockwise on screen).
	func arc(cx: float, cy: float, radius: float, from_angle: float, to_angle: float) -> void:
		var points := PackedVector2Array()
		for i: int in ARC_POINTS + 1:
			var a: float = lerpf(from_angle, to_angle, float(i) / ARC_POINTS)
			points.append(pt(cx + cos(a) * radius, cy + sin(a) * radius))
		stroke(points)

	## Quadratic curve from (x0, y0) to (x2, y2) pulled toward (x1, y1).
	func curve(x0: float, y0: float, x1: float, y1: float, x2: float, y2: float) -> void:
		var points := PackedVector2Array()
		for i: int in CURVE_POINTS + 1:
			var t: float = float(i) / CURVE_POINTS
			var a: Vector2 = Vector2(x0, y0).lerp(Vector2(x1, y1), t)
			var b: Vector2 = Vector2(x1, y1).lerp(Vector2(x2, y2), t)
			var p: Vector2 = a.lerp(b, t)
			points.append(pt(p.x, p.y))
		stroke(points)

	## Horizontal wave at height [param y], [param amplitude] high, [param waves] periods from x0 to x1.
	func sine(y: float, amplitude: float, x0: float, x1: float, waves: int) -> void:
		var points := PackedVector2Array()
		var count: int = ARC_POINTS * waves
		for i: int in count + 1:
			var t: float = float(i) / count
			points.append(pt(lerpf(x0, x1, t), y + sin(t * TAU * waves) * amplitude))
		stroke(points)

	func ellipse(cx: float, cy: float, rx: float, ry: float) -> void:
		var points := PackedVector2Array()
		for i: int in ARC_POINTS + 1:
			var a: float = TAU * float(i) / ARC_POINTS
			points.append(pt(cx + cos(a) * rx, cy + sin(a) * ry))
		stroke(points)

	## Water drop: tip at (x, tip_y), round bottom of [param radius] centred at (x, bottom_y).
	func drop(x: float, tip_y: float, bottom_y: float, radius: float) -> void:
		var reach: float = maxf(bottom_y - tip_y, radius + 1.0)
		var side: float = PI * 0.5 - asin(radius / reach)  # Angle from straight up to a tangent point.
		var points := PackedVector2Array()
		points.append(pt(x, tip_y))
		for i: int in ARC_POINTS + 1:
			var a: float = lerpf(-PI * 0.5 + side, -PI * 0.5 + TAU - side, float(i) / ARC_POINTS)
			points.append(pt(x + cos(a) * radius, bottom_y + sin(a) * radius))
		points.append(pt(x, tip_y))
		stroke(points)

	## Filled dot of box radius [param radius].
	func dot(cx: float, cy: float, radius: float) -> void:
		canvas.draw_circle(pt(cx, cy), radius * scale, color)

	## Thick polyline with round joints and ends.
	func stroke(points: PackedVector2Array) -> void:
		if points.size() < 2:
			return
		canvas.draw_polyline(points, color, width, true)
		for p: Vector2 in points:
			canvas.draw_circle(p, width * 0.5, color)
