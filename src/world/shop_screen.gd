## Shop screen (étape 5a, spec §7.1): the items on sale side by side (each at the
## price of its rarity), a crystal repair button and « Partir ». An item too dear
## and an impossible repair (not enough gold, or crystal full) are greyed. A
## bought item leaves the stall. Owns no game state: it emits signals and the
## caller spends the gold, then calls [method refresh].
class_name ShopScreen
extends CanvasLayer

## Emitted when the player clicks an affordable item. The item has already left
## the stall; the caller takes the gold and the item, then calls [method refresh].
signal item_bought(item: ItemDef)
## Emitted when the player clicks the crystal repair. The screen stays open; the
## caller takes the gold, repairs, then calls [method refresh].
signal repair_requested
## Emitted when the player clicks « Partir ». The screen hides itself first.
signal left

const ACTION_BUTTON_SIZE := Vector2(320.0, 56.0)

var _items: Array[ItemDef] = []
var _catalog: ItemCatalog
var _rarities: CardRarities
var _gold := 0
var _crystal_full := false
var _gold_label: Label
var _row: HBoxContainer
var _repair_button: Button


func _init() -> void:
	layer = ItemCard.SCREEN_LAYER
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Works while the game is paused.


func _ready() -> void:
	var column: VBoxContainer = ItemCard.build_overlay(self, "Magasin")
	_gold_label = ItemCard.make_label("", ItemCard.PRICE_FONT_SIZE, ItemCard.PRICE_COLOR)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(_gold_label)
	_row = ItemCard.make_row()
	column.add_child(_row)
	var actions: HBoxContainer = ItemCard.make_row()
	column.add_child(actions)
	_repair_button = ItemCard.make_button("", ACTION_BUTTON_SIZE)
	_repair_button.pressed.connect(func() -> void: repair_requested.emit())
	actions.add_child(_repair_button)
	var leave_button: Button = ItemCard.make_button("Partir", ACTION_BUTTON_SIZE)
	leave_button.pressed.connect(_on_leave_pressed)
	actions.add_child(leave_button)


## Gives the screen the rarities (frame colours and labels). Call once before
## [method open].
func setup(rarities: CardRarities) -> void:
	_rarities = rarities


## Opens the shop with [param items] on sale (drawn once on entry, spec §8bis),
## prices and repair numbers from [param catalog], the player's [param gold] and
## whether the crystal is at full health ([param crystal_full]). The screen must
## be in the tree.
func open(items: Array[ItemDef], catalog: ItemCatalog, gold: int, crystal_full: bool) -> void:
	_items.assign(items)
	_catalog = catalog
	refresh(gold, crystal_full)
	visible = true


## Redraws the stall and the repair button for [param gold] and [param crystal_full]
## (after a purchase or a repair).
func refresh(gold: int, crystal_full: bool) -> void:
	_gold = gold
	_crystal_full = crystal_full
	_gold_label.text = "Or : %d" % gold
	_rebuild_stall()
	var cost: int = _catalog.crystal_repair_cost
	var can_pay: bool = gold >= cost
	_repair_button.text = "Réparer le cristal : +%d PV (%d or)" % [roundi(_catalog.crystal_repair_hp), cost]
	_repair_button.disabled = not can_pay or crystal_full
	_repair_button.add_theme_color_override(&"font_disabled_color", ItemCard.UNAFFORDABLE_COLOR if not can_pay else ItemCard.DISABLED_COLOR)


func _rebuild_stall() -> void:
	ItemCard.clear(_row)
	for item: ItemDef in _items:
		var price: int = _catalog.price_of(item)
		var card: Button = ItemCard.build(item, _rarities, price, price <= _gold)
		card.pressed.connect(_on_item_pressed.bind(item))
		_row.add_child(card)


func _on_item_pressed(item: ItemDef) -> void:
	if _catalog.price_of(item) > _gold or not _items.has(item):
		return
	_items.erase(item)
	_rebuild_stall()
	item_bought.emit(item)


func _on_leave_pressed() -> void:
	visible = false
	left.emit()
