## Death effects of the legendary cards (design: docs/superpowers/specs/2026-11-20-cartes-et-lisibilite-design.md §5.4, §8bis).
## Brasier éternel: an enemy that dies burning sets fire to the enemies around it.
## Zéro absolu: an enemy that dies frozen explodes (damage and freeze around it).
## Chained deaths are deferred one frame and never touch an enemy that is freed or queued for deletion.
class_name CardEffects
extends Node

var _enemies: Node
var _modifiers: PlayerModifiers


## Watches every enemy added under [param enemies_parent] and reads the cards in [param modifiers] at each death. Call once.
func setup(enemies_parent: Node, modifiers: PlayerModifiers) -> void:
	_enemies = enemies_parent
	_modifiers = modifiers
	enemies_parent.child_entered_tree.connect(_on_enemy_added)
	for child: Node in enemies_parent.get_children():
		_on_enemy_added(child)


func _on_enemy_added(node: Node) -> void:
	var enemy := node as Enemy
	if enemy != null and not enemy.died_with_state.is_connected(_on_enemy_died):
		enemy.died_with_state.connect(_on_enemy_died.bind(enemy))


# The dying enemy is still valid here (its deletion is only queued): its burn is read now, the rest is deferred.
func _on_enemy_died(at: Vector2, was_burning: bool, was_frozen: bool, enemy: Enemy) -> void:
	if was_burning and _modifiers.has_flag(&"burn_spread_on_death"):
		_spread_burn.call_deferred(at, _modifiers.flag_value(&"burn_spread_on_death", "radius"), enemy.burn_full_duration(), enemy.burn_damage_per_second())
	if was_frozen and _modifiers.has_flag(&"shatter_on_frozen_death"):
		_shatter.call_deferred(at, _modifiers.flag_value(&"shatter_on_frozen_death", "radius"), _modifiers.flag_value(&"shatter_on_frozen_death", "damage"), _modifiers.flag_value(&"shatter_on_frozen_death", "freeze"))


## Enemies still alive within [param radius] of [param at] (a snapshot: killing one cannot disturb the loop).
func _living_enemies_near(at: Vector2, radius: float) -> Array[Enemy]:
	var found: Array[Enemy] = []
	if not is_instance_valid(_enemies):
		return found
	for child: Node in _enemies.get_children():
		var enemy := child as Enemy
		if enemy != null and not enemy.is_queued_for_deletion() and enemy.global_position.distance_to(at) <= radius:
			found.append(enemy)
	return found


func _spread_burn(at: Vector2, radius: float, duration: float, damage_per_second: float) -> void:
	for enemy: Enemy in _living_enemies_near(at, radius):
		enemy.apply_burn(duration, damage_per_second)


func _shatter(at: Vector2, radius: float, damage: float, freeze: float) -> void:
	for enemy: Enemy in _living_enemies_near(at, radius):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue  # Killed by an earlier blast of this same loop.
		enemy.take_damage(damage)
		if not enemy.is_queued_for_deletion():
			enemy.force_freeze(freeze)
