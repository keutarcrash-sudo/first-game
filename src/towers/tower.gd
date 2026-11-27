## A placed tower (story 004, towers T2a): a coloured halo on the ground, the tower
## image on top of it, and a faint ring showing its range. What it does comes from its
## [TowerBehaviour], created from its [TowerDef] in [method setup] and ticked every
## physics frame; the range ring follows [method TowerBehaviour.range_now]. The image is
## a [DirectionalSprite] child, drawn after (so over) the halo, which turns gold once
## the tower has evolved (towers T2b).
class_name Tower
extends Node2D

const RING_COLOR := Color(1.0, 1.0, 1.0, 0.18)
const RING_WIDTH := 2.0
const RING_POINTS := 48
const HALO_FILL_ALPHA := 0.25
const HALO_EDGE_ALPHA := 0.7
const HALO_EDGE_WIDTH := 3.0
## Halo colour of an evolved tower (towers T2b).
const EVOLVED_HALO_COLOR := Color(1.0, 0.82, 0.2)

## Body radius in pixels (placement footprint and halo size).
var radius: float
## Range in pixels.
var attack_range: float
var _halo_color: Color
var _record: TowerRecord
var _drawn_evolved: bool = false
var _sprite: DirectionalSprite
var _behaviour: TowerBehaviour


## Sets the tower type [param def], its [param record] (shared, never copied: level and
## branch are read live) and the shared [param ctx], and creates its behaviour. Call
## before adding the tower to the tree.
func setup(def: TowerDef, record: TowerRecord, ctx: TowerBehaviour.TowerContext) -> void:
	radius = def.radius
	_halo_color = def.color
	_record = record
	_drawn_evolved = record.evolved
	_behaviour = TowerBehaviour.create(def.behaviour)
	if _behaviour == null:
		set_physics_process(false)
		return
	_behaviour.setup(self, def, record, ctx)
	attack_range = _behaviour.range_now()


## Gives the tower its image: [param sheet] drawn [param height_px] tall.
func set_visual(sheet: SpriteSheet, height_px: float) -> void:
	if _sprite == null:
		_sprite = DirectionalSprite.new()
		add_child(_sprite)
	_sprite.setup(sheet, height_px, true)
	_sprite.play(&"idle")


## What this tower does, or [code]null[/code] for an unknown behaviour.
func behaviour() -> TowerBehaviour:
	return _behaviour


## Turns the tower image toward [param angle] (radians, as [method Vector2.angle]).
func set_facing(angle: float) -> void:
	if _sprite != null:
		_sprite.set_facing(angle)


func _physics_process(delta: float) -> void:
	if _behaviour == null:
		return
	if _record != null and _record.evolved != _drawn_evolved:
		_drawn_evolved = _record.evolved
		queue_redraw()  # Golden halo once evolved (towers T2b).
	var current_range: float = _behaviour.range_now()
	if not is_equal_approx(current_range, attack_range):
		attack_range = current_range
		queue_redraw()  # The range ring follows (items, étape 5a).
	_behaviour.physics_tick(delta)


func _draw() -> void:
	var halo: Color = EVOLVED_HALO_COLOR if _drawn_evolved else _halo_color
	var fill := Color(halo, HALO_FILL_ALPHA)
	var edge := Color(halo, HALO_EDGE_ALPHA)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, RING_POINTS, edge, HALO_EDGE_WIDTH, true)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, RING_POINTS, RING_COLOR, RING_WIDTH)
	if _behaviour != null:
		_behaviour.draw(self)
