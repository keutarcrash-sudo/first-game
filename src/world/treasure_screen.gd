## Treasure screen (étape 5a, spec §7.2): free items side by side, the player must
## take one (no way to leave, like the card choice). Owns no game state: it only
## emits [signal item_chosen]. When no item is left, the caller gives the
## fallback gold ([member ItemCatalog.treasure_fallback_gold]) instead of opening it.
class_name TreasureScreen
extends CanvasLayer

## Shown on the card of a « Plans » offer (towers T2a): its category line and glyph.
const PLAN_CATEGORY := &"PLAN"
const PLAN_GLYPH := "P"

## Emitted when the player clicks an item. The screen hides itself first.
signal item_chosen(item: ItemDef)
## Emitted when the player clicks the « Plans » card (towers T2a). The screen hides itself first.
signal plan_chosen(plan: CardDef)

var _rarities: CardRarities
var _row: HBoxContainer


func _init() -> void:
	layer = ItemCard.SCREEN_LAYER
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Works while the game is paused.


func _ready() -> void:
	var column: VBoxContainer = ItemCard.build_overlay(self, "Trésor : choisis ta récompense")
	_row = ItemCard.make_row()
	column.add_child(_row)


## Gives the screen the rarities (frame colours and labels). Call once before
## [method open].
func setup(rarities: CardRarities) -> void:
	_rarities = rarities


## Shows [param items] (one clickable card each), then [param plan] if not null
## (a « Plans » card drawn like an item card, framed in its rarity colour), and
## waits for a click. The screen must be in the tree; there should be at least one card.
func open(items: Array[ItemDef], plan: CardDef = null) -> void:
	ItemCard.clear(_row)
	for item: ItemDef in items:
		var card: Button = ItemCard.build(item, _rarities)
		card.pressed.connect(_on_item_pressed.bind(item))
		_row.add_child(card)
	if plan != null:
		var plan_card: Button = ItemCard.build(_plan_look(plan), _rarities)
		plan_card.pressed.connect(_on_plan_pressed.bind(plan))
		_row.add_child(plan_card)
	visible = true


## A display-only item carrying the name, description and rarity of [param plan]
## (never taken as an item: it stays out of the item bar and of the shop).
func _plan_look(plan: CardDef) -> ItemDef:
	var look := ItemDef.new()
	look.id = plan.id
	look.display_name = plan.display_name
	look.description = plan.description
	look.rarity = plan.rarity
	look.category = PLAN_CATEGORY
	look.glyph = PLAN_GLYPH
	return look


func _on_item_pressed(item: ItemDef) -> void:
	visible = false
	item_chosen.emit(item)


func _on_plan_pressed(plan: CardDef) -> void:
	visible = false
	plan_chosen.emit(plan)
