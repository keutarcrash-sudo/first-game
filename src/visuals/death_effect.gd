## A dead enemy's death animation, played where it fell, then freed.
## Purely graphical: it takes no part in the game (not an Enemy, no collision).
class_name DeathEffect
extends Node2D


## Drawn body-centred like the enemies it replaces. Draws [param sheet]'s [code]death[/code] animation at [param height_px], facing
## [param facing] (radians, as [method Vector2.angle]). Call before adding the
## node to the tree, and only with a sheet that has a [code]death[/code] animation
## (see [method SpriteSheet.has_animation]). Frees itself at the end.
func setup(sheet: SpriteSheet, height_px: float, facing: float) -> void:
	var sprite := DirectionalSprite.new()
	add_child(sprite)
	sprite.setup(sheet, height_px, true)
	sprite.set_facing(facing)
	sprite.animation_finished.connect(func(_anim_name: StringName) -> void: queue_free())
	sprite.play(&"death")
