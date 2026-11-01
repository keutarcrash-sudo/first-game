## Draws the cards offered between waves (story 006): distinct cards picked at
## random among those the player can still take. Cards locked by default are
## only drawn once the skill tree unlocks them (story 007). Cards of a
## specialization are only drawn when it is the chosen one (story 008). Pure logic, no scene tree.
class_name CardPool
extends RefCounted

var _catalog: CardCatalog
var _modifiers: PlayerModifiers
var _rng: RandomNumberGenerator
var _unlocked_ids: PackedStringArray
var _offered_bonus: int
var _spec_id: String


## Gives the pool the cards, the player's modifiers (to know what is still
## available), the random generator, the ids of the locked-by-default cards the
## skill tree unlocked, the extra cards offered per choice and the id of the
## specialization chosen for this game.
func _init(catalog: CardCatalog, modifiers: PlayerModifiers, rng: RandomNumberGenerator, unlocked_ids: PackedStringArray, offered_bonus: int, spec_id: String) -> void:
	_catalog = catalog
	_modifiers = modifiers
	_rng = rng
	_unlocked_ids = unlocked_ids
	_offered_bonus = offered_bonus
	_spec_id = spec_id


## Returns up to [member CardCatalog.offered_per_choice] + the skill tree bonus
## different available cards. Fewer when fewer are left, empty when none is.
func draw() -> Array[CardDef]:
	var available: Array[CardDef] = []
	for card: CardDef in _catalog.cards:
		var unlocked: bool = not card.locked_by_default or _unlocked_ids.has(card.id)
		var for_this_spec: bool = card.requires_spec.is_empty() or card.requires_spec == _spec_id
		if unlocked and for_this_spec and _modifiers.can_take(card):
			available.append(card)
	var offer: Array[CardDef] = []
	for i: int in mini(_catalog.offered_per_choice + _offered_bonus, available.size()):
		var pick: int = _rng.randi_range(0, available.size() - 1)
		offer.append(available[pick])
		available.remove_at(pick)
	return offer
