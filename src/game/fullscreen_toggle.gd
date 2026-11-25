## Full screen handling (not an autoload; one instance, child of the main scene).
## F11 ([code]toggle_fullscreen[/code]) switches between full screen and a window.
## The game starts in full screen from project.godot ([code]window/size/mode[/code]);
## a browser refuses that until the player acts, so on the web the first click or
## key press asks for full screen again (on desktop the window already is, so it
## does nothing). Keeps working while the tree is paused (defeat screen).
## Note: DisplayServer.window_get_mode / window_set_mode and WINDOW_MODE_* are
## long-standing Godot 4 API, not covered by docs/engine-reference/godot/.
class_name FullscreenToggle
extends Node

var _gesture_handled := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## [code]true[/code] when the window covers the screen (either full screen mode).
static func is_fullscreen() -> bool:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## Switches to the non-exclusive full screen (alt-tab keeps working) or back to a window.
static func toggle() -> void:
	if is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# _input, not _unhandled_input: the first gesture must be seen even when a HUD
# button consumes the click. Nothing is marked handled, the game still gets it.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_fullscreen") and not event.is_echo():
		_gesture_handled = true  # The player chose the mode: no automatic request after this.
		toggle()
		return
	if _gesture_handled or not OS.has_feature("web"):
		return
	var click := event as InputEventMouseButton
	var key := event as InputEventKey
	if (click != null and click.pressed) or (key != null and key.pressed):
		_gesture_handled = true
		if not is_fullscreen():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
