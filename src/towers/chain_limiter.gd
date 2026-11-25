## Caps the chained tower effects (Incendiaire level 3 explosions, Éclats shards) to a
## number per frame (towers T1, [member TowerStats.chain_max_per_frame]), so a chain
## through a large crowd never freezes the game: the effects past the cap are dropped.
class_name ChainLimiter
extends RefCounted

var _max_per_frame: int
var _frame := -1
var _used := 0


## [param max_per_frame]: effects allowed in one frame (at least 0).
func _init(max_per_frame: int) -> void:
	_max_per_frame = maxi(max_per_frame, 0)


## Uses one effect of frame [param frame]. Returns [code]false[/code] once the frame's
## cap is reached; a different frame starts the count over.
func try_consume(frame: int) -> bool:
	if frame != _frame:
		_frame = frame
		_used = 0
	if _used >= _max_per_frame:
		return false
	_used += 1
	return true
