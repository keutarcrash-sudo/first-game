## Draws the cards offered between waves (story 006): distinct cards picked at
## random among those the player can still take. Pure logic, no scene tree.
class_name CardPool
extends RefCounted

var _catalog: CardCatalog
var _modifiers: PlayerModifiers
var _rng: RandomNumberGenerator


## Gives the pool the cards, the player's modifiers (to know what is still available) and the random generator.
func _init(catalog: CardCatalog, modifiers: PlayerModifiers, rng: RandomNumberGenerator) -> void:
	_catalog = catalog
	_modifiers = modifiers
	_rng = rng


## Returns up to [member CardCatalog.offered_per_choice] different available
## cards. Fewer when fewer are left, empty when none is.
func draw() -> Array[CardDef]:
	var available: Array[CardDef] = []
	for card: CardDef in _catalog.cards:
		if _modifiers.can_take(card):
			available.append(card)
	var offer: Array[CardDef] = []
	for i: int in mini(_catalog.offered_per_choice, available.size()):
		var pick: int = _rng.randi_range(0, available.size() - 1)
		offer.append(available[pick])
		available.remove_at(pick)
	return offer
