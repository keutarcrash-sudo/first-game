## Defeat screen (story 007, design/game-brief.md MVP feature 7): wave reached,
## points earned this game and in total, the permanent upgrade tree, a refusal
## message and the « Rejouer » button. Works while the tree is paused, sits above
## every other layer and stops clicks from reaching the game. Owns no state: it
## emits [signal node_clicked] / [signal replay_pressed] and the caller decides,
## then calls [method refresh] or [method show_refusal].
## Story 009: the branch named [constant SCROLL_BRANCH] may hold up to 8 independent
## nodes, so its column is a vertical [ScrollContainer] (mouse wheel) as tall as the
## other columns; the other branches keep their fixed layout.
## Story 008: four columns (Cristal, Départ, Arsenal, Spécialisations) fit
## 1280×720; the tree's placeholders are drawn greyed and take no click.
class_name DeathScreen
extends CanvasLayer

## Emitted when the player clicks the upgrade [param upgrade_id], whatever its state.
signal node_clicked(upgrade_id: String)
## Emitted when the player clicks « Rejouer ».
signal replay_pressed

const SCREEN_LAYER := 20  # Above the HUD (1) and the card choice screen (10).
const DIM_COLOR := Color(0.0, 0.0, 0.05, 0.9)
const COLUMN_SEPARATION := 14
const TITLE_FONT_SIZE := 52
const INFO_FONT_SIZE := 24
const BRANCH_FONT_SIZE := 22
const NODE_NAME_FONT_SIZE := 20
const NODE_TEXT_FONT_SIZE := 15
const MESSAGE_FONT_SIZE := 22
const REPLAY_FONT_SIZE := 26
const TITLE_COLOR := Color(1.0, 0.4, 0.35)
const TEXT_COLOR := Color(0.9, 0.95, 1.0)
const POINTS_COLOR := Color(1.0, 0.9, 0.35)
const BRANCH_COLOR := Color(0.55, 0.9, 1.0)
const MESSAGE_COLOR := Color(1.0, 0.45, 0.4)
const NODE_SIZE := Vector2(276.0, 140.0)  # 4 columns: 4 × 276 + 3 × 24 = 1176 px, inside 1280.
const NODE_PADDING := 10.0
const NODE_TEXT_SPACING := 4
const NODE_BORDER_WIDTH := 3
const NODE_CORNER_RADIUS := 6
const NODE_HOVER_LIGHTEN := 0.12
const COLUMN_SPACING := 24.0
const ROW_SPACING := 44.0
const BRANCH_TITLE_HEIGHT := 34.0
const SCROLL_BRANCH := "Spécialisations"  # The branch laid out in a scrolling column, nodes stacked in file order.
const SCROLLBAR_WIDTH := 16.0  # Extra width of that column for the scroll bar: 1176 + 16 = 1192 px, inside 1280.
const SCROLL_ROW_SPACING := 14.0
const MIN_VISIBLE_ROWS := 2  # The scrolling column is at least as tall as two rows, even if the other branches are shorter.
const LINK_WIDTH := 4.0
const LINK_ON_COLOR := Color(0.45, 0.95, 0.55)
const LINK_OFF_COLOR := Color(0.3, 0.32, 0.4)
const MESSAGE_MIN_HEIGHT := 30.0
const REPLAY_SIZE := Vector2(240.0, 54.0)
# Per node state: fill, border, name colour, status line colour.
const OWNED_COLORS := [Color(0.12, 0.3, 0.18), Color(0.45, 0.95, 0.55), Color(0.85, 1.0, 0.88), Color(0.45, 0.95, 0.55)]
const AVAILABLE_COLORS := [Color(0.16, 0.17, 0.26), Color(1.0, 0.9, 0.35), Color(1.0, 0.9, 0.35), Color(1.0, 0.9, 0.35)]
const LOCKED_COLORS := [Color(0.1, 0.1, 0.13), Color(0.3, 0.32, 0.4), Color(0.5, 0.52, 0.58), Color(0.5, 0.52, 0.58)]
const TOO_EXPENSIVE_COLORS := [Color(0.14, 0.14, 0.2), Color(0.55, 0.45, 0.4), Color(0.85, 0.88, 0.95), Color(1.0, 0.45, 0.4)]

var _tree: SkillTree
var _progress: SaveProgress
var _points_earned := 0
var _wave_label: Label
var _points_label: Label
var _message_label: Label
var _tree_area: Control
var _node_buttons: Dictionary = {}  # upgrade id -> Button
var _column_x: Array[float] = []  # Left edge of each branch column, in the tree area.
var _scroll_content: Control  # Holds the nodes of the SCROLL_BRANCH column; null if the tree has no such branch.


func _init() -> void:
	layer = SCREEN_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS  # The game is paused while this screen is open.
	visible = false


## Builds the screen and one node per upgrade of [param tree]. Each branch gets
## a column (in order of first appearance, upgrades first, then placeholders) and
## each node a row one below its deepest requirement; the layout assumes one node
## per branch and row. A placeholder sits one row below the last node of its
## branch. Call once, after the screen is in the scene tree.
func setup(tree: SkillTree) -> void:
	_tree = tree
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP  # Clicks never reach the arena below.
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = DIM_COLOR
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	column.add_child(_make_label("Défaite", TITLE_FONT_SIZE, TITLE_COLOR, true))
	_wave_label = _make_label("", INFO_FONT_SIZE, TEXT_COLOR, true)
	column.add_child(_wave_label)
	_points_label = _make_label("", INFO_FONT_SIZE, POINTS_COLOR, true)
	column.add_child(_points_label)
	_tree_area = Control.new()
	_tree_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tree_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tree_area.draw.connect(_draw_links.bind(_tree_area))
	column.add_child(_tree_area)
	_build_nodes()
	_message_label = _make_label("", MESSAGE_FONT_SIZE, MESSAGE_COLOR, true)
	_message_label.custom_minimum_size.y = MESSAGE_MIN_HEIGHT  # The layout does not jump when a message appears.
	column.add_child(_message_label)
	var replay := Button.new()
	replay.text = "Rejouer"
	replay.focus_mode = Control.FOCUS_NONE
	replay.custom_minimum_size = REPLAY_SIZE
	replay.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	replay.add_theme_font_size_override(&"font_size", REPLAY_FONT_SIZE)
	replay.pressed.connect(replay_pressed.emit)
	column.add_child(replay)


func _build_nodes() -> void:
	var branches: Array[String] = []
	var rows: Dictionary = {}  # upgrade id -> row; requirements come earlier in the file
	var branch_rows: Dictionary = {}  # branch -> rows used, so a placeholder goes below its branch's nodes
	var row_count := MIN_VISIBLE_ROWS  # Rows of the fixed branches only: the scrolling column never makes the screen taller.
	for upgrade: SkillTree.Upgrade in _tree.upgrades:
		if not branches.has(upgrade.branch):
			branches.append(upgrade.branch)
		var row: int = branch_rows.get(upgrade.branch, 0)  # Scrolling branch: stacked in file order.
		if upgrade.branch != SCROLL_BRANCH:
			row = 0
			for required: String in upgrade.requires:
				row = maxi(row, rows[required] + 1)
		rows[upgrade.id] = row
		branch_rows[upgrade.branch] = maxi(branch_rows.get(upgrade.branch, 0), row + 1)
		if upgrade.branch != SCROLL_BRANCH:
			row_count = maxi(row_count, row + 1)
	var placeholder_rows: Array[int] = []
	for placeholder: SkillTree.Placeholder in _tree.placeholders:
		if not branches.has(placeholder.branch):
			branches.append(placeholder.branch)
		var row: int = branch_rows.get(placeholder.branch, 0)
		branch_rows[placeholder.branch] = row + 1
		placeholder_rows.append(row)
		if placeholder.branch != SCROLL_BRANCH:
			row_count = maxi(row_count, row + 1)
	var area_height: float = BRANCH_TITLE_HEIGHT + row_count * NODE_SIZE.y + (row_count - 1) * ROW_SPACING
	_column_x.clear()
	var x := 0.0
	for branch: String in branches:
		_column_x.append(x)
		x += NODE_SIZE.x + COLUMN_SPACING + (SCROLLBAR_WIDTH if branch == SCROLL_BRANCH else 0.0)
	_tree_area.custom_minimum_size = Vector2(x - COLUMN_SPACING, area_height)
	for i: int in branches.size():
		var title: Label = _make_label(branches[i], BRANCH_FONT_SIZE, BRANCH_COLOR, true)
		title.position = Vector2(_column_x[i], 0.0)
		title.size = Vector2(NODE_SIZE.x, BRANCH_TITLE_HEIGHT)
		_tree_area.add_child(title)
		if branches[i] == SCROLL_BRANCH:
			title.size.x += SCROLLBAR_WIDTH
			var scroll := ScrollContainer.new()
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			scroll.position = Vector2(_column_x[i], BRANCH_TITLE_HEIGHT)
			scroll.size = Vector2(NODE_SIZE.x + SCROLLBAR_WIDTH, area_height - BRANCH_TITLE_HEIGHT)
			_scroll_content = Control.new()
			_scroll_content.mouse_filter = Control.MOUSE_FILTER_IGNORE  # The wheel reaches the scroll container.
			var count: int = branch_rows[SCROLL_BRANCH]
			_scroll_content.custom_minimum_size = Vector2(NODE_SIZE.x, count * NODE_SIZE.y + (count - 1) * SCROLL_ROW_SPACING)
			_scroll_content.draw.connect(_draw_links.bind(_scroll_content))
			scroll.add_child(_scroll_content)
			_tree_area.add_child(scroll)
	for upgrade: SkillTree.Upgrade in _tree.upgrades:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.position = _node_position(branches.find(upgrade.branch), rows[upgrade.id], upgrade.branch)
		button.size = NODE_SIZE
		button.pressed.connect(node_clicked.emit.bind(upgrade.id))
		_add_node_texts(button, upgrade.display_name, upgrade.description)
		_canvas_of(upgrade.branch).add_child(button)
		_node_buttons[upgrade.id] = button
	for i: int in _tree.placeholders.size():
		var placeholder: SkillTree.Placeholder = _tree.placeholders[i]
		# A Panel, not a Button: it cannot be clicked and is never styled as buyable.
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.position = _node_position(branches.find(placeholder.branch), placeholder_rows[i], placeholder.branch)
		panel.size = NODE_SIZE
		var style := StyleBoxFlat.new()
		style.bg_color = LOCKED_COLORS[0]
		style.border_color = LOCKED_COLORS[1]
		style.set_border_width_all(NODE_BORDER_WIDTH)
		style.set_corner_radius_all(NODE_CORNER_RADIUS)
		panel.add_theme_stylebox_override(&"panel", style)
		var labels: Array[Node] = _add_node_texts(panel, placeholder.display_name, placeholder.description).get_children()
		for label: Node in labels:
			(label as Label).add_theme_color_override(&"font_color", LOCKED_COLORS[2])
		_canvas_of(placeholder.branch).add_child(panel)


## The control a node of [param branch] is added to: the scrolling content or the tree area.
func _canvas_of(branch: String) -> Control:
	return _scroll_content if branch == SCROLL_BRANCH else _tree_area


## Position of a node inside [method _canvas_of]: scrolling nodes are stacked from the top of the content.
func _node_position(column: int, row: int, branch: String) -> Vector2:
	if branch == SCROLL_BRANCH:
		return Vector2(0.0, row * (NODE_SIZE.y + SCROLL_ROW_SPACING))
	return Vector2(_column_x[column], BRANCH_TITLE_HEIGHT + row * (NODE_SIZE.y + ROW_SPACING))


## Adds the name, description and (empty) status labels inside [param node]; returns their box.
func _add_node_texts(node: Control, display_name: String, description_text: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = NODE_PADDING
	box.offset_top = NODE_PADDING
	box.offset_right = -NODE_PADDING
	box.offset_bottom = -NODE_PADDING
	box.add_theme_constant_override(&"separation", NODE_TEXT_SPACING)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(box)
	box.add_child(_make_label(display_name, NODE_NAME_FONT_SIZE, TEXT_COLOR, true))
	var description: Label = _make_label(description_text, NODE_TEXT_FONT_SIZE, TEXT_COLOR, false)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description)
	box.add_child(_make_label("", NODE_TEXT_FONT_SIZE, TEXT_COLOR, true))
	return box


## Shows the screen for a game that reached wave [param wave_reached] and earned
## [param points_earned] points (already added to [param progress]).
func open(wave_reached: int, points_earned: int, progress: SaveProgress) -> void:
	_wave_label.text = "Vague atteinte : %d" % wave_reached
	_points_earned = points_earned
	refresh(progress)
	visible = true


## Redraws the totals and every node from [param progress], and clears the refusal message.
func refresh(progress: SaveProgress) -> void:
	_progress = progress
	_points_label.text = "Points gagnés : %d    Total : %d" % [_points_earned, progress.total_points]
	_message_label.text = ""
	for upgrade: SkillTree.Upgrade in _tree.upgrades:
		_style_node(upgrade, _tree.node_state(upgrade.id, progress))
	_tree_area.queue_redraw()
	if _scroll_content != null:
		_scroll_content.queue_redraw()


## Shows the short refusal [param message] under the tree.
func show_refusal(message: String) -> void:
	_message_label.text = message


func _style_node(upgrade: SkillTree.Upgrade, state: SkillTree.NodeState) -> void:
	var colors: Array = AVAILABLE_COLORS
	var status: String = "Coût : %d points" % upgrade.cost
	match state:
		SkillTree.NodeState.OWNED:
			colors = OWNED_COLORS
			status = "Acquis"
		SkillTree.NodeState.LOCKED:
			colors = LOCKED_COLORS
			status = "Verrouillé — coût : %d points" % upgrade.cost
		SkillTree.NodeState.TOO_EXPENSIVE:
			colors = TOO_EXPENSIVE_COLORS
			status = "Coût : %d points (pas assez)" % upgrade.cost
	var button: Button = _node_buttons[upgrade.id]
	var normal := StyleBoxFlat.new()
	normal.bg_color = colors[0]
	normal.border_color = colors[1]
	normal.set_border_width_all(NODE_BORDER_WIDTH)
	normal.set_corner_radius_all(NODE_CORNER_RADIUS)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = (colors[0] as Color).lightened(NODE_HOVER_LIGHTEN)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	var labels: Array[Node] = button.get_child(0).get_children()
	(labels[0] as Label).add_theme_color_override(&"font_color", colors[2])
	(labels[2] as Label).text = status
	(labels[2] as Label).add_theme_color_override(&"font_color", colors[3])


## Draws, on [param canvas] (the tree area or the scrolling content), a line from
## each requirement's bottom edge to the top edge of the node needing it. A link
## between nodes that sit on different canvases is not drawn.
func _draw_links(canvas: Control) -> void:
	for upgrade: SkillTree.Upgrade in _tree.upgrades:
		var target: Button = _node_buttons[upgrade.id]
		if target.get_parent() != canvas:
			continue
		for required: String in upgrade.requires:
			var source: Button = _node_buttons[required]
			if source.get_parent() != canvas:
				continue
			var owned: bool = _progress != null and _progress.owned_ids.has(required)
			canvas.draw_line(
				source.position + Vector2(NODE_SIZE.x / 2.0, NODE_SIZE.y),
				target.position + Vector2(NODE_SIZE.x / 2.0, 0.0),
				LINK_ON_COLOR if owned else LINK_OFF_COLOR, LINK_WIDTH)


func _make_label(text: String, font_size: int, color: Color, centered: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
