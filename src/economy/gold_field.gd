## Gold on the ground (étape 2). Dead enemies drop coins here; a coin is picked
## up (gold added to the [GameState]) when the hero comes within the pickup
## radius, and disappears after its lifetime, blinking during the last seconds.
## Coins are plain data, drawn by this single node.
class_name GoldField
extends Node2D

const COIN_RADIUS := 7.0
const COIN_COLOR := Color(1.0, 0.85, 0.25)
const COIN_OUTLINE_COLOR := Color(1.0, 0.97, 0.7)
const BLINK_PERIOD := 0.25

var _state: GameState
var _hero: Node2D
var _economy: EconomyStats
var _coins: Array[Dictionary] = []  # { position: Vector2, amount: int, age: float }


## Gives the field its dependencies. Call once.
func setup(state: GameState, hero: Node2D, economy: EconomyStats) -> void:
	_state = state
	_hero = hero
	_economy = economy


func _physics_process(delta: float) -> void:
	if _economy == null or _coins.is_empty():
		return
	var hero_valid: bool = is_instance_valid(_hero)
	var hero_position: Vector2 = _hero.global_position if hero_valid else Vector2.ZERO
	var radius_squared: float = _economy.pickup_radius * _economy.pickup_radius
	var kept: Array[Dictionary] = []
	var changed := false
	var blink_start: float = _economy.gold_lifetime - _economy.gold_blink_time
	for coin: Dictionary in _coins:
		coin["age"] += delta
		var age: float = coin["age"]
		if age >= _economy.gold_lifetime:
			changed = true
			continue
		if hero_valid and (coin["position"] as Vector2).distance_squared_to(hero_position) <= radius_squared:
			_state.add_gold(coin["amount"])
			changed = true
			continue
		if age >= blink_start:
			changed = true  # The blink phase may have flipped: redraw.
		kept.append(coin)
	_coins = kept
	if changed:
		queue_redraw()


func _draw() -> void:
	if _economy == null:
		return
	var blink_start: float = _economy.gold_lifetime - _economy.gold_blink_time
	for coin: Dictionary in _coins:
		var age: float = coin["age"]
		if age >= blink_start and int((age - blink_start) / (BLINK_PERIOD * 0.5)) % 2 == 1:
			continue
		var at: Vector2 = coin["position"]
		draw_circle(at, COIN_RADIUS, COIN_COLOR)
		draw_arc(at, COIN_RADIUS, 0.0, TAU, 24, COIN_OUTLINE_COLOR, 1.5)


## Adds a coin worth [param amount] gold at [param at] (global position; this node stays at the origin).
func drop(at: Vector2, amount: int) -> void:
	_coins.append({"position": at, "amount": amount, "age": 0.0})
	queue_redraw()


## Removes every coin without giving gold.
func clear() -> void:
	if _coins.is_empty():
		return
	_coins.clear()
	queue_redraw()


## Number of coins on the ground.
func count() -> int:
	return _coins.size()
