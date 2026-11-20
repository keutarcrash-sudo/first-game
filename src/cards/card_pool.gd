## Draws the cards offered between waves (story 006): distinct cards picked at
## random among those the player can still take, the rarity being rolled first
## for each slot (spec « Cartes et lisibilité » §5.1, §5.3, §8bis). Cards locked
## by default are only drawn once the skill tree unlocks them (story 007). Cards
## of a specialization are only drawn when it is the chosen one (story 008).
## Pure logic, no scene tree. Buying a reroll is up to the caller.
class_name CardPool
extends RefCounted

var _catalog: CardCatalog
var _modifiers: PlayerModifiers
var _rng: RandomNumberGenerator
var _unlocked_ids: PackedStringArray
var _offered_bonus: int
var _spec_id: String
var _rarities: CardRarities
var _is_ability_unlocked: Callable
var _rerolls_done := 0


## Gives the pool the cards, the player's modifiers (to know what is still
## available), the random generator, the ids of the locked-by-default cards the
## skill tree unlocked, the extra cards offered per choice, the id of the
## specialization chosen for this game, the rarities (weights, reroll prices) and
## [param is_ability_unlocked], a [code]func(ability_id: String) -> bool[/code]
## telling whether an ability can be cast yet.
func _init(catalog: CardCatalog, modifiers: PlayerModifiers, rng: RandomNumberGenerator, unlocked_ids: PackedStringArray, offered_bonus: int, spec_id: String, rarities: CardRarities, is_ability_unlocked: Callable) -> void:
	_catalog = catalog
	_modifiers = modifiers
	_rng = rng
	_unlocked_ids = unlocked_ids
	_offered_bonus = offered_bonus
	_spec_id = spec_id
	_rarities = rarities
	_is_ability_unlocked = is_ability_unlocked


## Number of cards of a full offer: the catalog's base + the skill tree bonus + the cards bonus.
func offer_size() -> int:
	return _catalog.offered_per_choice + _offered_bonus + _modifiers.cards_offered_bonus()


## Starts a new choice screen: the reroll price goes back to its base.
func begin_choice() -> void:
	_rerolls_done = 0


## Price in gold of the next reroll on this choice screen.
func reroll_cost() -> int:
	return _rarities.reroll_cost(_rerolls_done)


## True when at least one card can still be drawn (a reroll is then possible).
func can_draw() -> bool:
	return not _available().is_empty()


## Draws a full offer for wave [param wave]: for each slot a rarity is rolled by
## weight among the rarities that still have a card, then a card of it. Fewer
## cards when fewer are available, empty when none is.
func draw(wave: int) -> Array[CardDef]:
	var available: Array[CardDef] = _available()
	var offer: Array[CardDef] = []
	for i: int in mini(offer_size(), available.size()):
		var rarity: StringName = _roll_rarity(available, wave)
		var candidates: Array[CardDef] = []
		for card: CardDef in available:
			if card.rarity == rarity:
				candidates.append(card)
		var pick: CardDef = candidates[_rng.randi_range(0, candidates.size() - 1)]
		offer.append(pick)
		available.erase(pick)
	return offer


## Replaces the whole offer with a new draw and raises the next reroll price.
## Does not take any gold: the caller spends [method reroll_cost] first.
func reroll(wave: int) -> Array[CardDef]:
	_rerolls_done += 1
	return draw(wave)


## The cards the player can take now (spec §5.1).
func _available() -> Array[CardDef]:
	var available: Array[CardDef] = []
	var no_more_legendary: bool = _modifiers.took_legendary()
	for card: CardDef in _catalog.cards:
		if card.locked_by_default and not _unlocked_ids.has(card.id):
			continue
		if not card.requires_spec.is_empty() and card.requires_spec != _spec_id:
			continue
		if not _modifiers.can_take(card):
			continue
		if not card.requires_ability.is_empty() and not _is_ability_unlocked.call(card.requires_ability):
			continue
		if not card.requires_card.is_empty() and _modifiers.stacks_of(card.requires_card) < 1:
			continue
		if no_more_legendary and card.rarity == &"legendary":
			continue
		available.append(card)
	return available


## A rarity picked by weight among those of [param available].
func _roll_rarity(available: Array[CardDef], wave: int) -> StringName:
	var present: Array[StringName] = []
	var total := 0.0
	for rarity: StringName in _rarities.order():
		for card: CardDef in available:
			if card.rarity == rarity:
				present.append(rarity)
				total += _rarities.weight(rarity, wave)
				break
	var roll: float = _rng.randf() * total
	for rarity: StringName in present:
		roll -= _rarities.weight(rarity, wave)
		if roll < 0.0:
			return rarity
	return present[present.size() - 1]
