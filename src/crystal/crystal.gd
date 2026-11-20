## The crystal to defend (story 002, design/game-brief.md MVP feature 2).
## Holds the hit points; enemies call [method take_damage] when they touch it.
class_name Crystal
extends Node2D

const HALO_COLOR := Color(0.1, 0.89, 1.0)
const HALO_FILL_ALPHA := 0.25
const HALO_EDGE_ALPHA := 0.7
const HALO_EDGE_WIDTH := 3.0
## Halo radius is the crystal radius times (1 + amplitude * sin(...)).
const HALO_BASE_SCALE := 1.15
const HALO_PULSE_AMPLITUDE := 0.12
const HALO_PULSE_SPEED := 3.0
const HALO_POINTS := 48

## Emitted after every change of hit points.
signal health_changed(current_hp: float, max_hp: float)
## Emitted once, when hit points reach zero.
signal destroyed

## Emitted once per path, when the crystal reaches the end of it.
signal arrived

## Travelling speed, in pixels per second.
var speed: float

## Crystal radius, in pixels.
var radius: float
## Current hit points.
var current_hp: float
## Hit points at full health.
var max_hp: float

var _path: CrystalPath
var _sprite: DirectionalSprite
var _distance: float = 0.0
var _travelling: bool = false
var _damage_factor: float = 1.0


## Sets hit points and size from [param stats]; [param max_hp_bonus] (skill
## tree, story 007) adds to the base max hit points. Starts at full health.
## Call once, before the first physics frame.
func setup(stats: DefenceStats, max_hp_bonus: float) -> void:
	radius = stats.crystal_radius
	speed = stats.crystal_speed
	max_hp = stats.crystal_max_hp + max_hp_bonus
	current_hp = max_hp
	queue_redraw()


## Gives the crystal its cart image: [param sheet] drawn [param height_px] tall.
## A cyan halo pulses under it.
func set_visual(sheet: SpriteSheet, height_px: float) -> void:
	if _sprite == null:
		_sprite = DirectionalSprite.new()
		add_child(_sprite)
	_sprite.setup(sheet, height_px, true)
	_sprite.play(&"idle")


## Starts walking [param path] from its beginning, at [member speed]. Restarts
## if already travelling. Emits [signal arrived] once at the end; a zero-length
## path arrives on the next physics frame.
func travel(path: CrystalPath) -> void:
	_path = path
	_distance = 0.0
	_travelling = true
	global_position = path.position_at(0.0)


## Where the crystal will be after [param seconds] more seconds of walking its path (stopping
## at the end), or its current position when it is not travelling.
func predicted_position(seconds: float) -> Vector2:
	if not _travelling or _path == null:
		return global_position
	return _path.position_at(minf(_distance + speed * seconds, _path.length()))


## Stops walking without emitting [signal arrived].
func stop() -> void:
	_travelling = false


## True while the crystal is walking along a path.
func is_travelling() -> bool:
	return _travelling


func _process(_delta: float) -> void:
	queue_redraw()  # The halo pulses with time.


func _physics_process(delta: float) -> void:
	if not _travelling or current_hp <= 0.0:
		return
	_distance += speed * delta
	if _distance >= _path.length():
		global_position = _path.end_point()
		_travelling = false
		arrived.emit()
		return
	global_position = _path.position_at(_distance)


## Sets the factor applied to every hit the crystal takes (Bouclier du cristal,
## étape 5a spec §8). 1.0 = full damage, the default.
func set_damage_factor(factor: float) -> void:
	_damage_factor = maxf(factor, 0.0)


## Removes [param amount] × the damage factor hit points. Ignored once the crystal is destroyed.
func take_damage(amount: float) -> void:
	if current_hp <= 0.0:
		return
	current_hp = maxf(current_hp - amount * _damage_factor, 0.0)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		stop()
		destroyed.emit()


## Gives back [param amount] hit points, never above [member max_hp]. Ignored once the crystal is destroyed.
func heal(amount: float) -> void:
	if current_hp <= 0.0:
		return
	current_hp = minf(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)


func _draw() -> void:
	var time: float = Time.get_ticks_msec() / 1000.0
	var halo_radius: float = radius * (HALO_BASE_SCALE + HALO_PULSE_AMPLITUDE * sin(time * HALO_PULSE_SPEED))
	draw_circle(Vector2.ZERO, halo_radius, Color(HALO_COLOR, HALO_FILL_ALPHA))
	draw_arc(Vector2.ZERO, halo_radius, 0.0, TAU, HALO_POINTS, Color(HALO_COLOR, HALO_EDGE_ALPHA), HALO_EDGE_WIDTH, true)
