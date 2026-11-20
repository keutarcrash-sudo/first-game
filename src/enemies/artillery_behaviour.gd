## Artillery behaviour (étape 4, spec §6.2), owned by an [Enemy] of behaviour "artillery".
## Walks toward the crystal until [code]stand_off[/code] pixels away, then keeps that
## distance (moving along the crystal-to-enemy line, inside the field). While in range
## it fires every [code]fire_interval[/code] seconds: a fixed [TelegraphZone] aimed where
## the crystal will be when it completes, plus a random offset within [code]aim_spread[/code].
## The impact hurts the crystal if its centre is inside the circle and the hero if its body overlaps it.
class_name ArtilleryBehaviour
extends RefCounted

const BAM_WORD := "BAM !"
const BAM_COLOR := Color(1.0, 0.45, 0.2)
const RANGE_EPSILON := 1.0  # Pixels of tolerance on the stand-off distance to count as "in range".

var _stand_off: float
var _fire_interval: float
var _telegraph: float
var _radius: float
var _aim_spread: float
var _crystal_damage: float
var _hero_damage: float
var _crystal: Crystal
var _hero: Hero
var _impact: ImpactFeedback
var _hazards_parent: Node
var _state: GameState
var _field_rect: Rect2
var _rng: RandomNumberGenerator
var _cooldown: float


## [param type] is a validated artillery entry of [EnemyTypes]. [param field_rect] bounds the
## movement (no area = unbounded); [param rng] draws the aim offset.
func _init(type: Dictionary, crystal: Crystal, hero: Hero, impact: ImpactFeedback, hazards_parent: Node, state: GameState, field_rect: Rect2, rng: RandomNumberGenerator) -> void:
	_stand_off = type["stand_off"]
	_fire_interval = type["fire_interval"]
	_telegraph = type["telegraph"]
	_radius = type["radius"]
	_aim_spread = type["aim_spread"]
	_crystal_damage = type["crystal_damage"]
	_hero_damage = type["hero_damage"]
	_crystal = crystal
	_hero = hero
	_impact = impact
	_hazards_parent = hazards_parent
	_state = state
	_field_rect = field_rect
	_rng = rng
	_cooldown = _fire_interval


## Where an enemy at [param from] should stand after moving at most [param max_step] pixels
## toward the ring of radius stand_off around [param target] (backing off if too close).
func next_position(from: Vector2, target: Vector2, max_step: float, body_radius: float) -> Vector2:
	var away: Vector2 = from - target
	var direction: Vector2 = Vector2.RIGHT if away.length_squared() < 0.000001 else away.normalized()
	var wanted: Vector2 = target + direction * _stand_off
	return clamp_to_field(from.move_toward(wanted, max_step), body_radius)


## [param point] pulled back inside the field (shrunk by [param body_radius]); unchanged without a field.
func clamp_to_field(point: Vector2, body_radius: float) -> Vector2:
	if not _field_rect.has_area():
		return point
	var inner: Rect2 = _field_rect.grow(-body_radius)
	if not inner.has_area():
		return point
	return Vector2(clampf(point.x, inner.position.x, inner.end.x), clampf(point.y, inner.position.y, inner.end.y))


## Counts the fire timer down while [param from] is in range of the crystal and fires when it runs out.
func tick_fire(from: Vector2, delta: float) -> void:
	if from.distance_to(_crystal.global_position) > _stand_off + RANGE_EPSILON:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown += _fire_interval
	_fire()


## Lights an announced shot. The impact is resolved by a static function that only holds what
## it needs (never this object or the shooter): the shot always lands, even if the artillery died meanwhile.
func _fire() -> void:
	var offset: Vector2 = Vector2.from_angle(_rng.randf() * TAU) * _aim_spread * sqrt(_rng.randf())
	var zone := TelegraphZone.new()
	zone.setup(_radius, _telegraph, _state)
	zone.impacted.connect(Callable(ArtilleryBehaviour, &"_resolve_impact").bind(_crystal, _hero, _impact, _hazards_parent, _radius, _crystal_damage, _hero_damage))
	_hazards_parent.add_child(zone)
	zone.global_position = _crystal.predicted_position(_telegraph) + offset


static func _resolve_impact(center: Vector2, crystal_node: Object, hero_node: Object, impact_node: Object, hazards_node: Object, radius: float, crystal_damage: float, hero_damage: float) -> void:
	# Loosely typed: a node freed since the shot was fired must not break the call.
	if is_instance_valid(crystal_node):
		var crystal := crystal_node as Crystal
		if TelegraphZone.hits_point(center, radius, crystal.global_position):
			crystal.take_damage(crystal_damage)
	if is_instance_valid(hero_node):
		var hero := hero_node as Hero
		if TelegraphZone.hits_body(center, radius, hero.global_position, hero.body_radius()):
			hero.hurt(hero_damage)
	if is_instance_valid(hazards_node):
		var hazards_parent := hazards_node as Node
		if hazards_parent.get_parent() != null:
			PopBurst.spawn(hazards_parent.get_parent(), center, BAM_WORD, BAM_COLOR, radius)
	if is_instance_valid(impact_node):
		(impact_node as ImpactFeedback).shake(&"small")
