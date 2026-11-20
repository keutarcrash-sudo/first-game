## Kamikaze behaviour (étape 4, spec §6.1), owned by an [Enemy] of behaviour "kamikaze".
## On contact with the crystal the enemy stops and a [TelegraphZone] (the fuse) follows
## it; when the zone completes: crystal damage, hero damage if the hero's body is in
## the circle, onomatopoeia and shake, then the enemy frees itself WITHOUT dying (no gold).
## Killed during the fuse, the enemy calls [method cancel]: no explosion.
class_name KamikazeBehaviour
extends RefCounted

const BOOM_WORD := "KABOUM !"
const BOOM_COLOR := Color(1.0, 0.3, 0.2)
const BLINK_HALF_PERIOD := 0.1  # Seconds between two red/normal flips while the fuse burns.

var _fuse: float
var _radius: float
var _crystal_damage: float
var _hero_damage: float
var _crystal: Crystal
var _hero: Hero
var _impact: ImpactFeedback
var _hazards_parent: Node
var _state: GameState
var _enemy: Enemy
var _zone: TelegraphZone
var _fusing := false


## [param type] is a validated kamikaze entry of [EnemyTypes]; zones are added to [param hazards_parent].
func _init(type: Dictionary, crystal: Crystal, hero: Hero, impact: ImpactFeedback, hazards_parent: Node, state: GameState) -> void:
	_fuse = type["fuse"]
	_radius = type["radius"]
	_crystal_damage = type["crystal_damage"]
	_hero_damage = type["hero_damage"]
	_crystal = crystal
	_hero = hero
	_impact = impact
	_hazards_parent = hazards_parent
	_state = state


## True from the contact until the explosion or [method cancel]: the enemy no longer walks.
func is_fusing() -> bool:
	return _fusing


## True on the "red" half of the blink while fusing (visual only).
func is_blink_red() -> bool:
	return _fusing and fmod(Time.get_ticks_msec() / 1000.0 / BLINK_HALF_PERIOD, 2.0) < 1.0


## Lights the fuse on [param enemy] (its zone follows it). Does nothing if already lit.
func begin_fuse(enemy: Enemy) -> void:
	if _fusing:
		return
	_fusing = true
	_enemy = enemy
	_zone = TelegraphZone.new()
	_zone.setup(_radius, _fuse, _state, enemy)
	_zone.impacted.connect(_on_impacted)
	_hazards_parent.add_child(_zone)
	_zone.global_position = enemy.global_position


## Puts the fuse out without exploding (the enemy was killed).
func cancel() -> void:
	_fusing = false
	if _zone != null and is_instance_valid(_zone):
		_zone.cancel()
	_zone = null


func _on_impacted(center: Vector2) -> void:
	_fusing = false
	_zone = null
	var hero_hit: bool = is_instance_valid(_hero) and TelegraphZone.hits_body(center, _radius, _hero.global_position, _hero.body_radius())
	if is_instance_valid(_crystal):
		_crystal.take_damage(_crystal_damage)
	if hero_hit:
		_hero.hurt(_hero_damage)
	if is_instance_valid(_hazards_parent) and _hazards_parent.get_parent() != null:
		PopBurst.spawn(_hazards_parent.get_parent(), center, BOOM_WORD, BOOM_COLOR, _radius)
	if is_instance_valid(_impact):
		_impact.shake(&"big" if hero_hit else &"small")
	if is_instance_valid(_enemy) and not _enemy.is_queued_for_deletion():
		_enemy.queue_free()  # Not through died: no gold.
