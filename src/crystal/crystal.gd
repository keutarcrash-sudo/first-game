## The crystal to defend (story 002, design/game-brief.md MVP feature 2).
## Holds the hit points; enemies call [method take_damage] when they touch it.
class_name Crystal
extends Node2D

const COLOR := Color(0.4, 0.95, 0.85)
const OUTLINE_COLOR := Color(0.85, 1.0, 0.97)
const OUTLINE_WIDTH := 3.0

## Emitted after every change of hit points.
signal health_changed(current_hp: float, max_hp: float)
## Emitted once, when hit points reach zero.
signal destroyed

## Crystal radius, in pixels.
var radius: float
## Current hit points.
var current_hp: float
## Hit points at full health.
var max_hp: float


## Sets hit points and size from [param stats]; [param max_hp_bonus] (skill
## tree, story 007) adds to the base max hit points. Starts at full health.
## Call once, before the first physics frame.
func setup(stats: DefenceStats, max_hp_bonus: float) -> void:
	radius = stats.crystal_radius
	max_hp = stats.crystal_max_hp + max_hp_bonus
	current_hp = max_hp
	queue_redraw()


## Removes [param amount] hit points. Ignored once the crystal is destroyed.
func take_damage(amount: float) -> void:
	if current_hp <= 0.0:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		destroyed.emit()


## Gives back [param amount] hit points, never above [member max_hp]. Ignored once the crystal is destroyed.
func heal(amount: float) -> void:
	if current_hp <= 0.0:
		return
	current_hp = minf(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)


func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -radius), Vector2(radius * 0.8, 0.0),
		Vector2(0.0, radius), Vector2(-radius * 0.8, 0.0),
	])
	draw_colored_polygon(points, COLOR)
	points.append(points[0])
	draw_polyline(points, OUTLINE_COLOR, OUTLINE_WIDTH)
