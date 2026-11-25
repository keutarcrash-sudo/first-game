## The player's towers (towers T1): buying, gift towers, upgrades and the
## placed / in-reserve state. Pure logic: it never touches gold or nodes. The
## caller reads a price, asks for the purchase, then spends the price itself.
## Prices: (base cost + price_step x paid towers of that kind) x cost_factor,
## rounded; upgrades: upgrade_costs[level - 1] x cost_factor, rounded.
class_name TowerReserve
extends RefCounted

## Emitted after any change: purchase, gift, upgrade, placement or return.
signal changed

var _stats: TowerStats
var _records: Array[TowerRecord] = []
## Kind -> number of towers of that kind bought with gold.
var _paid_counts: Dictionary = {}
var _next_id: int = 1


## [param stats] gives base prices, the price step, upgrade costs and branches.
func _init(stats: TowerStats) -> void:
	_stats = stats


## Gold price of the next paid tower of [param kind], after multiplying by
## [param cost_factor] (product of the discounts, 1.0 for none).
func price_of_next(kind: TowerStats.Kind, cost_factor: float) -> int:
	var paid: int = _paid_counts.get(kind, 0)
	return roundi((_stats.cost_of(kind) + _stats.price_step * paid) * cost_factor)


## Buys a tower of [param kind] into the reserve if [param gold_available]
## covers [method price_of_next]; returns it, or [code]null[/code] if not. The
## caller spends the price it read before calling.
func buy(kind: TowerStats.Kind, gold_available: int, cost_factor: float) -> TowerRecord:
	if gold_available < price_of_next(kind, cost_factor):
		return null
	_paid_counts[kind] = int(_paid_counts.get(kind, 0)) + 1
	return _add(kind, false)


## Adds a gift tower of [param kind]; it does not raise later prices.
func add_free(kind: TowerStats.Kind) -> TowerRecord:
	return _add(kind, true)


## Kind with the fewest owned towers (paid and free); CANNON on a tie.
func least_owned_kind() -> TowerStats.Kind:
	var best: TowerStats.Kind = TowerStats.Kind.CANNON
	var best_count: int = _count_of(best)
	for kind: TowerStats.Kind in TowerStats.Kind.values():
		var count: int = _count_of(kind)
		if count < best_count:
			best = kind
			best_count = count
	return best


## Gold price of the next upgrade of [param record], or -1 at the top level.
func upgrade_cost(record: TowerRecord, cost_factor: float) -> int:
	if record.level >= TowerRecord.MAX_LEVEL:
		return -1
	return roundi(_stats.upgrade_costs[record.level - 1] * cost_factor)


## Upgrades [param record] one level and returns the price to spend, or -1 if
## refused (top level, not enough gold, unknown record, bad branch). Level 1 -> 2
## needs a branch of the record's kind; level 2 -> 3 keeps the branch, so
## [param branch] must be [code]&""[/code] or the current branch.
func try_upgrade(record: TowerRecord, branch: StringName, gold_available: int, cost_factor: float) -> int:
	if not _records.has(record):
		return -1
	var cost: int = upgrade_cost(record, cost_factor)
	if cost < 0 or gold_available < cost:
		return -1
	if record.level == 1:
		if not _stats.branch_ids(record.kind).has(branch):
			return -1
		record.branch = branch
	elif branch != &"" and branch != record.branch:
		return -1
	record.level += 1
	changed.emit()
	return cost


## Every owned tower, placed or not, in purchase order.
func records() -> Array[TowerRecord]:
	return _records.duplicate()


## Owned towers waiting in the reserve (not placed).
func available() -> Array[TowerRecord]:
	var waiting: Array[TowerRecord] = []
	for record: TowerRecord in _records:
		if not record.placed:
			waiting.append(record)
	return waiting


## Marks [param record] as standing on the map.
func mark_placed(record: TowerRecord) -> void:
	if record.placed:
		return
	record.placed = true
	changed.emit()


## Puts [param record] back in the reserve; it keeps its level and branch.
func mark_returned(record: TowerRecord) -> void:
	if not record.placed:
		return
	record.placed = false
	changed.emit()


## Puts every placed tower back in the reserve (end of wave).
func return_all() -> void:
	var any: bool = false
	for record: TowerRecord in _records:
		if record.placed:
			record.placed = false
			any = true
	if any:
		changed.emit()


func _add(kind: TowerStats.Kind, is_free: bool) -> TowerRecord:
	var record := TowerRecord.new()
	record.id = _next_id
	_next_id += 1
	record.kind = kind
	record.is_free = is_free
	_records.append(record)
	changed.emit()
	return record


func _count_of(kind: TowerStats.Kind) -> int:
	var count: int = 0
	for record: TowerRecord in _records:
		if record.kind == kind:
			count += 1
	return count
