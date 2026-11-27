## One card as described in assets/data/cards.json (story 006). Plain data,
## built and validated by [CardCatalog].
class_name CardDef
extends RefCounted

## Unique id.
var id: String
## Name shown on the card.
var display_name: String
## Readable description of what the card does.
var description: String
## What the card works with; empty when not relevant.
var combines_with: String
## True when the card is only offered once the skill tree unlocks it (story 007).
var locked_by_default := false
## Id of the specialization this card belongs to (story 008): the card is only
## offered when that specialization is the one chosen. Empty for every specialization.
var requires_spec := ""
## Rarity id, one of [constant CardRarities.IDS].
var rarity: StringName = &"common"
## Id of an ability (abilities.json) that must be unlocked for the card to be offered; empty for none.
var requires_ability := ""
## Id of a card that must have been taken at least once for this card to be offered; empty for none.
var requires_card := ""
## Maximum number of times the card can be taken; -1 means unlimited.
var max_stacks := -1
## First wave (the one about to be played) on which the card can be offered (towers T2a: plans from wave 2).
var min_wave := 1
## Effects applied each time the card is taken: dictionaries with a "type" key
## (see [PlayerModifiers]) and the values of that type.
var effects: Array[Dictionary] = []


## Id of the tower an [code]unlock_tower[/code] effect of the card unlocks (a
## « Plans » card, towers T2a); [code]&""[/code] when the card unlocks none.
func unlocked_tower() -> StringName:
	for effect: Dictionary in effects:
		if String(effect.get("type", "")) == "unlock_tower":
			return StringName(String(effect.get("tower_id", "")))
	return &""
