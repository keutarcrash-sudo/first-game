## What a placed [Tower] does (towers T2a): shooting, a frost aura… One small
## subclass per behaviour id of towers.json ([constant TowerStats.BEHAVIOUR_KEYS]),
## created by [method create]. The [Tower] node keeps the shared parts (halo, range
## ring, image) and calls [method physics_tick] every physics frame and
## [method draw] from its own [method CanvasItem._draw].
class_name TowerBehaviour
extends RefCounted

## What every behaviour may read, built once by the [TowerPlacer] and shared by all
## towers (never copied).
class TowerContext:
	extends RefCounted

	## Tuning values of the towers (shared blocks such as [code]freeze[/code]).
	var stats: TowerStats
	## Node holding the enemies.
	var enemies: Node2D
	## Node the shots are added to.
	var bullets: Node2D
	## Arena the shots must stay in.
	var arena_rect: Rect2
	## Combo rules handed to the shots.
	var rules: ProcRules
	## Card and item modifiers, read at use time.
	var modifiers: PlayerModifiers
	## Designator whose target is shot first when in range.
	var designator: TargetDesignator
	## Cap of the chain effects per frame ([TowerEffects]); may be null.
	var chain_limiter: ChainLimiter
	## Node of the damage numbers; may be null (the enemies show their own hits).
	var damage_numbers: Node
	## Called with a world position, returns the amplifier bonuses there
	## (Dictionary [code]damage[/code], [code]rate[/code], [code]state[/code]).
	## Neutral until the amplifier exists.
	var amp_at: Callable

	func _init() -> void:
		amp_at = neutral_amp

	## Bonuses of no amplifier: all zero.
	func neutral_amp(_at: Vector2) -> Dictionary:
		return {"damage": 0.0, "rate": 0.0, "state": 0.0}


## The behaviour of id [param behaviour], or [code]null[/code] (after an error) if unknown.
static func create(behaviour: StringName) -> TowerBehaviour:
	match behaviour:
		&"shooter":
			return ShooterBehaviour.new()
		&"frost_aura":
			return FrostAuraBehaviour.new()
	push_error("TowerBehaviour: unknown behaviour '%s'." % behaviour)
	return null


## Gives the behaviour its [param tower] node (may be null for a range preview), its
## type [param def], its [param record] (shared, never copied: level and branch are read
## live) and the shared [param ctx]. Call once, before the first tick.
func setup(_tower: Tower, _def: TowerDef, _record: TowerRecord, _ctx: TowerContext) -> void:
	pass


## One physics frame of work.
func physics_tick(_delta: float) -> void:
	pass


## Extra drawing on [param canvas] (the tower node), after the halo and the range ring.
func draw(_canvas: CanvasItem) -> void:
	pass


## Range in pixels right now, card, item and branch bonuses included.
func range_now() -> float:
	return 0.0
