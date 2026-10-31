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
## Maximum number of times the card can be taken; -1 means unlimited.
var max_stacks := -1
## Effects applied each time the card is taken: dictionaries with a "type" key
## (see [PlayerModifiers]) and the values of that type.
var effects: Array[Dictionary] = []
