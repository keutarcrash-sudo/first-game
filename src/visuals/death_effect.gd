## A dead enemy's death animation, played where it fell, then freed.
## Purely graphical: it takes no part in the game (not an Enemy, no collision).
class_name DeathEffect
extends Node2D


## Draws [param sheet]'s [code]death[/code] animation at [param height_px], facing
## [param facing] (radians, as [method Vector2.angle]). Call before adding the
## node to the tree. Frees itself at the end (at once if the sheet has no death animation).
func setup(sheet: SpriteSheet, height_px: float, facing: float) -> void:
	if not sheet.has_animation(&"death"):
		push_error("DeathEffect: the sheet has no 'death' animation.")
		queue_free()
		return
	var sprite := DirectionalSprite.new()
	add_child(sprite)
	sprite.setup(sheet, height_px)
	sprite.set_facing(facing)
	sprite.animation_finished.connect(func(_anim_name: StringName) -> void: queue_free())
	sprite.play(&"death")
