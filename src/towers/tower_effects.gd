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
## Towers T2b: an evolved Incendiaire cannon (Volcan) also leaves a [LavaPool] where its
## death blast goes off (no cannon burn); an evolved Éclats frost tower (Avalanche) makes
## its death shard hop [code]shard_hops[/code] times to the nearest enemy not yet hit within
## [code]hop_range[/code]. Each pool and each hop uses one effect of the [ChainLimiter].
class_name TowerEffects
extends Node

const INCENDIAIRE := &"incendiaire"
const ECLATS := &"eclats"
const VISUAL_RADIUS_RATIO := 0.5  # The burst is drawn at half the effect radius: a small one.
const EXPLOSION_WORD := "BOUM !"
const EXPLOSION_COLOR := Color(1.0, 0.55, 0.15)
const SHARD_WORD := "CRAC !"
const SHARD_COLOR := Color(0.75, 0.95, 1.0)
const HOP_COLOR := Color(0.75, 0.95, 1.0, 0.9)  # Ice line of an Avalanche hop.
const HOP_WIDTH := 3.0
const HOP_FADE_SECONDS := 0.3

var _enemies: Node2D
var _stats: TowerStats
var _modifiers: PlayerModifiers
var _records: Callable
var _limiter: ChainLimiter
var _amp_of: Callable  # Record id -> amplifier bonuses at that tower; unset = none.
var _ground: Node2D  # Layer of the lava pools; null = the enemies' parent.
var _state: GameState  # The lava pools vanish when its phase leaves COMBAT; may be null.


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


## Gives the amplifier bonuses: [param amp_of] is called with a tower record id and returns
## the bonuses at that placed tower ([method TowerPlacer.amp_of_tower]). The Éclats level 3
## freeze lasts x (1 + [code]state[/code]) (Catalyseur).
func set_amp_source(amp_of: Callable) -> void:
	_amp_of = amp_of


## Gives the ground layer (the hazards node) the Volcan lava pools are added to, and the
## game [param state] whose phase leaving COMBAT clears them (towers T2b). Either may be null.
func set_ground(ground: Node2D, state: GameState) -> void:
	_ground = ground
	_state = state


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
			_explode.call_deferred(at, cannon.id, cannon.kind, cannon.evolved)
	if was_frozen:
		var frost: TowerRecord = _record_with(enemy.last_freezer_id(), ECLATS, 2)
		if frost != null:
			var max_level: bool = frost.level >= TowerRecord.MAX_LEVEL
			_shatter.call_deferred(at, frost.id, frost.kind, max_level, max_level and frost.evolved)


func _explode(at: Vector2, cannon_id: int, kind: StringName, volcano: bool) -> void:
	if not _limiter.try_consume(Engine.get_process_frames()):
		return
	if volcano:
		_lay_lava(at, kind)
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


func _shatter(at: Vector2, frost_id: int, kind: StringName, freezes: bool, avalanche: bool) -> void:
	if not _limiter.try_consume(Engine.get_process_frames()):
		return
	var radius: float = _value(kind, ECLATS, "shard_radius")
	var damage: float = _value(kind, ECLATS, "shard_damage") * _modifiers.damage_multiplier()
	var freeze: float = _value(kind, ECLATS, "l3_shard_freeze") + _modifiers.freeze_duration_bonus()
	if _amp_of.is_valid():
		freeze *= 1.0 + float((_amp_of.call(frost_id) as Dictionary)["state"])
	_show(at, SHARD_WORD, SHARD_COLOR, radius)
	var hit: Dictionary = {}  # Instance ids of the enemies this shard hit (Avalanche hops skip them).
	for enemy: Enemy in _living_enemies_near(at, radius):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		hit[enemy.get_instance_id()] = true
		_shard_hit(enemy, damage, freezes, freeze, frost_id)
	if avalanche:
		_avalanche(at, kind, damage, freezes, freeze, frost_id, hit)


## One shard hit on [param enemy]: [param damage], then (level 3) the freeze of [param freeze] s.
func _shard_hit(enemy: Enemy, damage: float, freezes: bool, freeze: float, frost_id: int) -> void:
	enemy.take_damage(damage, false, &"area")
	if freezes and not enemy.is_queued_for_deletion():
		enemy.freeze_from(freeze, _stats.freeze_cooldown, frost_id)


## Avalanche (towers T2b): from [param at], the shard hops [code]shard_hops[/code] times to the
## nearest living enemy not in [param hit] within [code]hop_range[/code]; each hop is one
## shard hit, uses one effect of the cap and is drawn as a fading ice line.
func _avalanche(at: Vector2, kind: StringName, damage: float, freezes: bool, freeze: float, frost_id: int, hit: Dictionary) -> void:
	var hops: int = int(_evolution_value(kind, ECLATS, "shard_hops"))
	var hop_range: float = _evolution_value(kind, ECLATS, "hop_range")
	var from: Vector2 = at
	for i: int in hops:
		var next: Enemy = _nearest_unhit(from, hop_range, hit)
		if next == null or not _limiter.try_consume(Engine.get_process_frames()):
			return
		var to: Vector2 = next.global_position
		hit[next.get_instance_id()] = true
		_show_hop(from, to)
		_shard_hit(next, damage, freezes, freeze, frost_id)
		from = to


## Nearest living enemy within [param max_distance] of [param at] whose instance id is not in [param skip]; null if none.
func _nearest_unhit(at: Vector2, max_distance: float, skip: Dictionary) -> Enemy:
	var nearest: Enemy = null
	var nearest_sq: float = max_distance * max_distance
	if not is_instance_valid(_enemies):
		return null
	for child: Node in _enemies.get_children():
		var enemy := child as Enemy
		if enemy == null or enemy.is_queued_for_deletion() or skip.has(enemy.get_instance_id()):
			continue
		var distance_sq: float = enemy.global_position.distance_squared_to(at)
		if distance_sq <= nearest_sq:
			nearest_sq = distance_sq
			nearest = enemy
	return nearest


## Volcan (towers T2b): a [LavaPool] at [param at], if the cap allows one more effect this frame.
func _lay_lava(at: Vector2, kind: StringName) -> void:
	if not is_instance_valid(_enemies) or not _limiter.try_consume(Engine.get_process_frames()):
		return
	var layer: Node = _ground if is_instance_valid(_ground) else _enemies.get_parent()
	var pool := LavaPool.new()
	pool.setup(
		_evolution_value(kind, INCENDIAIRE, "lava_radius"), _evolution_value(kind, INCENDIAIRE, "lava_duration"),
		_evolution_value(kind, INCENDIAIRE, "lava_dps") * _modifiers.damage_multiplier(), _state, _enemies
	)
	layer.add_child(pool)
	pool.global_position = at


## A fading ice line from [param from] to [param to] (world positions), drawn above the ground.
func _show_hop(from: Vector2, to: Vector2) -> void:
	if not is_instance_valid(_enemies):
		return
	var line := Line2D.new()
	line.width = HOP_WIDTH
	line.default_color = HOP_COLOR
	_enemies.get_parent().add_child(line)
	line.points = PackedVector2Array([line.to_local(from), line.to_local(to)])
	var tween: Tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, HOP_FADE_SECONDS)
	tween.tween_callback(line.queue_free)


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


## Number [param key] of the evolution of branch [param branch] of a tower of [param kind]
## (required and validated by [constant TowerStats.EVOLUTION_KEYS]).
func _evolution_value(kind: StringName, branch: StringName, key: String) -> float:
	return float(_stats.def_of(kind).value(key, branch, TowerRecord.MAX_LEVEL, true))
