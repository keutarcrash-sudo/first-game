## Death effects of the tower branches (towers T1, design §6 and §8bis):
## - Incendiaire level 3: an enemy that dies burning from the shells of that cannon explodes,
##   hurting and burning (with that cannon's burn) the enemies around it;
## - Éclats level 2: an enemy that dies frozen by that frost tower shatters and hurts the
##   enemies around it; level 3: the shards also freeze them ([method Enemy.freeze_from],
##   which respects the freeze cooldown).
## Chains are allowed (a blast that kills an enemy burning or frozen from the same branch
## sets it off in turn) and capped per frame by a [ChainLimiter]; the effects past the cap
## are dropped. The cap counts process frames ([method Engine.get_process_frames]).
## Like [CardEffects], the effects are deferred out of the death signal.
class_name TowerEffects
extends Node

const INCENDIAIRE := &"incendiaire"
const ECLATS := &"eclats"
const VISUAL_RADIUS_RATIO := 0.5  # The burst is drawn at half the effect radius: a small one.
const EXPLOSION_WORD := "BOUM !"
const EXPLOSION_COLOR := Color(1.0, 0.55, 0.15)
const SHARD_WORD := "CRAC !"
const SHARD_COLOR := Color(0.75, 0.95, 1.0)

var _enemies: Node2D
var _stats: TowerStats
var _modifiers: PlayerModifiers
var _records: Callable
var _limiter: ChainLimiter


## Watches every enemy added under [param enemies_parent]. [param stats] gives the branch values
## and the chain cap, [param modifiers] the cards (« Munitions incendiaires », damage, « Gel profond »), and
## [param records] is called with no argument at each death and returns the towers' records
## (a Dictionary id -> [TowerRecord]). Call once.
func setup(enemies_parent: Node2D, stats: TowerStats, modifiers: PlayerModifiers, records: Callable) -> void:
	_enemies = enemies_parent
	_stats = stats
	_modifiers = modifiers
	_records = records
	_limiter = ChainLimiter.new(stats.chain_max_per_frame)
	enemies_parent.child_entered_tree.connect(_on_enemy_added)
	for child: Node in enemies_parent.get_children():
		_on_enemy_added(child)


func _on_enemy_added(node: Node) -> void:
	var enemy := node as Enemy
	if enemy != null:
		# An enemy enters the tree once (it is never re-parented), so it is connected once.
		enemy.died_with_state.connect(_on_enemy_died.bind(enemy))


## The chain-effect cap shared with the towers ([method TowerPlacer.set_chain_limiter]).
func limiter() -> ChainLimiter:
	return _limiter


## The record of tower [param id] when it has [param branch] (a branch id belongs to one
## tower type) and at least [param level]; null otherwise.
func _record_with(id: int, branch: StringName, level: int) -> TowerRecord:
	if id < 0 or not _records.is_valid():
		return null
	var records: Dictionary = _records.call()
	var record := records.get(id) as TowerRecord
	if record == null or record.branch != branch or record.level < level or _stats.def_of(record.kind) == null:
		return null
	return record


# The dying enemy is still valid here (its deletion is only queued): its last burner and freezer are read now.
func _on_enemy_died(at: Vector2, was_burning: bool, was_frozen: bool, enemy: Enemy) -> void:
	if was_burning:
		var cannon: TowerRecord = _record_with(enemy.last_burner_id(), INCENDIAIRE, TowerRecord.MAX_LEVEL)
		if cannon != null:
			_explode.call_deferred(at, cannon.id, cannon.kind)
	if was_frozen:
		var frost: TowerRecord = _record_with(enemy.last_freezer_id(), ECLATS, 2)
		if frost != null:
			_shatter.call_deferred(at, frost.id, frost.kind, frost.level >= TowerRecord.MAX_LEVEL)


func _explode(at: Vector2, cannon_id: int, kind: StringName) -> void:
	if not _limiter.try_consume(Engine.get_process_frames()):
		return
	var radius: float = _value(kind, INCENDIAIRE, "l3_explosion_radius")
	var damage: float = _value(kind, INCENDIAIRE, "l3_explosion_damage") * _modifiers.damage_multiplier()
	var duration: float = _value(kind, INCENDIAIRE, "burn_duration")
	if _modifiers.burn_duration() > 0.0:
		duration *= _value(kind, INCENDIAIRE, "card_duration_mult")
	var dps: float = _value(kind, INCENDIAIRE, "burn_dps")
	_show(at, EXPLOSION_WORD, EXPLOSION_COLOR, radius)
	for enemy: Enemy in _living_enemies_near(at, radius):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue  # Killed earlier in this same loop.
		# Hit first, then burn: only an enemy already burning from this branch explodes when killed here.
		enemy.take_damage(damage, false, &"area")
		if not enemy.is_queued_for_deletion():
			enemy.apply_burn(duration, dps, cannon_id)


func _shatter(at: Vector2, frost_id: int, kind: StringName, freezes: bool) -> void:
	if not _limiter.try_consume(Engine.get_process_frames()):
		return
	var radius: float = _value(kind, ECLATS, "shard_radius")
	var damage: float = _value(kind, ECLATS, "shard_damage") * _modifiers.damage_multiplier()
	var freeze: float = _value(kind, ECLATS, "l3_shard_freeze") + _modifiers.freeze_duration_bonus()
	_show(at, SHARD_WORD, SHARD_COLOR, radius)
	for enemy: Enemy in _living_enemies_near(at, radius):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		enemy.take_damage(damage, false, &"area")
		if freezes and not enemy.is_queued_for_deletion():
			enemy.freeze_from(freeze, _stats.freeze_cooldown, frost_id)


## Enemies still alive within [param radius] of [param at] (a snapshot: killing one cannot disturb the loop).
func _living_enemies_near(at: Vector2, radius: float) -> Array[Enemy]:
	var found: Array[Enemy] = []
	if not is_instance_valid(_enemies):
		return found
	var radius_sq: float = radius * radius
	for child: Node in _enemies.get_children():
		var enemy := child as Enemy
		if enemy != null and not enemy.is_queued_for_deletion() and enemy.global_position.distance_squared_to(at) <= radius_sq:
			found.append(enemy)
	return found


func _show(at: Vector2, word: String, color: Color, radius: float) -> void:
	if is_instance_valid(_enemies):
		PopBurst.spawn(_enemies.get_parent(), at, word, color, radius * VISUAL_RADIUS_RATIO)


## Number [param key] of branch [param branch] of a tower of [param kind] (required and validated by [constant TowerStats.BRANCH_KEYS]).
func _value(kind: StringName, branch: StringName, key: String) -> float:
	return float(_stats.branch_value(kind, branch, key))
