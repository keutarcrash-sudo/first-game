## Treasure screen (étape 5a, spec §7.2): free items side by side, the player must
## take one (no way to leave, like the card choice). Owns no game state: it only
## emits [signal item_chosen]. When no item is left, the caller gives the
## fallback gold ([member ItemCatalog.treasure_fallback_gold]) instead of opening it.
class_name TreasureScreen
extends CanvasLayer

## Emitted when the player clicks an item. The screen hides itself first.
signal item_chosen(item: ItemDef)

var _rarities: CardRarities
var _row: HBoxContainer


func _init() -> void:
	layer = ItemCard.SCREEN_LAYER
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Works while the game is paused.


func _ready() -> void:
	var column: VBoxContainer = ItemCard.build_overlay(self, "Trésor : choisis un objet")
	_row = ItemCard.make_row()
	column.add_child(_row)


## Gives the screen the rarities (frame colours and labels). Call once before
## [method open].
func setup(rarities: CardRarities) -> void:
	_rarities = rarities


## Shows [param items] (one clickable card each) and waits for a click. The screen
## must be in the tree; [param items] should not be empty.
func open(items: Array[ItemDef]) -> void:
	ItemCard.clear(_row)
	for item: ItemDef in items:
		var card: Button = ItemCard.build(item, _rarities)
		card.pressed.connect(_on_item_pressed.bind(item))
		_row.add_child(card)
	visible = true


func _on_item_pressed(item: ItemDef) -> void:
	visible = false
	item_chosen.emit(item)
