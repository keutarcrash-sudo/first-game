## The two display fonts of the neon look (SIL OFL 1.1, see assets/fonts/OFL.txt):
## Bangers for titles, wave, gold and onomatopoeia; Bungee for numbers.
## Each font is loaded once and shared.
class_name NeonFonts
extends RefCounted

const TITLE_PATH := "res://assets/fonts/Bangers-Regular.ttf"
const NUMBERS_PATH := "res://assets/fonts/Bungee-Regular.ttf"
## Outline thickness in pixels of the black text outline.
const OUTLINE_SIZE := 6

static var _title: FontFile
static var _numbers: FontFile
static var _tried: Dictionary = {}  # Path -> true once a load was attempted (a failure is not retried).


## Bangers, for titles and short shouted text.
static func title() -> Font:
	if _title == null:
		_title = _load(TITLE_PATH)
	return _title


## Bungee, for numbers (cooldowns).
static func numbers() -> Font:
	if _numbers == null:
		_numbers = _load(NUMBERS_PATH)
	return _numbers


## Loads [param path] once; on failure reports it (once) and returns [code]null[/code].
static func _load(path: String) -> FontFile:
	if _tried.has(path):
		return null
	_tried[path] = true
	var font := load(path) as FontFile
	if font == null:
		push_error("NeonFonts: cannot load font '%s'." % path)
	return font


## Gives [param label] the font [param font] and a black outline of [constant OUTLINE_SIZE].
static func style_label(label: Label, font: Font) -> void:
	label.add_theme_font_override(&"font", font)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_constant_override(&"outline_size", OUTLINE_SIZE)
