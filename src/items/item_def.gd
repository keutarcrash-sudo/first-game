## One passive item as described in assets/data/items.json (étape 5a). Plain data,
## built and validated by [ItemCatalog].
class_name ItemDef
extends RefCounted

## Unique id.
var id: String
## Category: attack, survival or utility.
var category: StringName = &"attack"
## Rarity id, one of [constant CardRarities.IDS]; sets the price.
var rarity: StringName = &"common"
## Name shown to the player.
var display_name: String
## Readable description of what the item does.
var description: String
## One or two letters drawn at the centre of the item's icon.
var glyph: String
## Id of the specialization the item belongs to; empty for every specialization.
var requires_spec := ""
## Effects applied when the item is taken (same format as card effects, see [PlayerModifiers]).
var effects: Array[Dictionary] = []
