## Draws passive items for a shop or a treasure (étape 5a, spec §7.4): never an
## item already owned, never an item of another specialization, never the same
## item twice in one draw. The rarity of each slot is rolled first, by the card
## rarity weights of the wave (as [CardPool] does), among the rarities that still
## have an item.
class_name ItemPool
extends RefCounted

var _catalog: ItemCatalog
var _modifiers: PlayerModifiers
var _rng: RandomNumberGenerator
var _spec_id: String
var _rarities: CardRarities


## [param catalog] lists every item, [param modifiers] knows the items owned,
## [param rng] drives the draws, [param spec_id] is the specialization chosen for
## this game and [param rarities] gives the rarity weights.
func _init(catalog: ItemCatalog, modifiers: PlayerModifiers, rng: RandomNumberGenerator, spec_id: String, rarities: CardRarities) -> void:
	_catalog = catalog
	_modifiers = modifiers
	_rng = rng
	_spec_id = spec_id
	_rarities = rarities


## Draws up to [param count] distinct items for wave [param wave]: for each slot a
## rarity is rolled by weight among the rarities that still have an item, then an
## item of it. Fewer items when fewer are available, empty when none is.
func draw(count: int, wave: int) -> Array[ItemDef]:
	var available: Array[ItemDef] = _available()
	var offer: Array[ItemDef] = []
	for i: int in mini(count, available.size()):
		var rarity: StringName = _roll_rarity(available, wave)
		var candidates: Array[ItemDef] = []
		for item: ItemDef in available:
			if item.rarity == rarity:
				candidates.append(item)
		var pick: ItemDef = candidates[_rng.randi_range(0, candidates.size() - 1)]
		offer.append(pick)
		available.erase(pick)
	return offer


## The items the player can still get.
func _available() -> Array[ItemDef]:
	var available: Array[ItemDef] = []
	var known: Array[StringName] = _rarities.order()
	for item: ItemDef in _catalog.all():
		if not known.has(item.rarity):
			continue
		if not item.requires_spec.is_empty() and item.requires_spec != _spec_id:
			continue
		if _modifiers.owns_item(item.id):
			continue
		available.append(item)
	return available


## A rarity picked by weight among those of [param available] (same draw as
## [method CardPool._roll_rarity]).
func _roll_rarity(available: Array[ItemDef], wave: int) -> StringName:
	var present: Array[StringName] = []
	var total := 0.0
	for rarity: StringName in _rarities.order():
		for item: ItemDef in available:
			if item.rarity == rarity:
				present.append(rarity)
				total += _rarities.weight(rarity, wave)
				break
	var roll: float = _rng.randf() * total
	for rarity: StringName in present:
		roll -= _rarities.weight(rarity, wave)
		if roll < 0.0:
			return rarity
	return present[present.size() - 1]
