## Arena for story 001: dark background, visible arena bounds and the hero.
## Loads the tuning data once and hands it to the hero.
extends Node2D

const STATS_PATH := "res://assets/data/hero_stats.json"
const FLOOR_COLOR := Color(0.09, 0.09, 0.13)
const BORDER_COLOR := Color(0.4, 0.45, 0.6)
const BORDER_WIDTH := 4.0

var _arena_rect: Rect2

@onready var _hero: Hero = $Hero
@onready var _bullets: Node2D = $Bullets


func _ready() -> void:
	var stats: HeroStats = HeroStats.load_from_file(STATS_PATH)
	if stats == null:
		_hero.queue_free()
		return
	_arena_rect = Rect2((get_viewport_rect().size - stats.arena_size) / 2.0, stats.arena_size)
	_hero.setup(stats, _arena_rect, _bullets)
	_hero.global_position = _arena_rect.get_center()
	queue_redraw()


func _draw() -> void:
	draw_rect(_arena_rect, FLOOR_COLOR)
	draw_rect(_arena_rect, BORDER_COLOR, false, BORDER_WIDTH)
