## line_drawer.gd
## -----------------------------------------------------------------------------
## Captures user touch/mouse input and produces smoothed line segments.
## Each "stroke" is a contiguous series of points collected between
## input-down and input-up. Multiple strokes are allowed (subject to
## max_line_segments in the level).
##
## Visual rendering is via a Line2D child node. Physics conversion is
## performed by the parent PhysicsController (call `build_physics_segments`).
##
## Designed to be embedded under the gameplay scene's "World" node.
## -----------------------------------------------------------------------------
extends Node2D
class_name LineDrawer

signal stroke_started()
signal stroke_added(points: PackedVector2Array, length: float)
signal stroke_undone()
signal lines_cleared()
signal length_changed(total_length: float)

# Visual line appearance
@export var line_color: Color = Color(0.16, 0.20, 0.50, 1.0)  # لاجوردی
@export var line_width: float = 8.0
@export var line_joint_mode: Line2D.LineJointMode = Line2D.LINE_JOINT_ROUND
@export var line_begin_cap: Line2D.LineCapMode = Line2D.LINE_CAP_ROUND
@export var line_end_cap: Line2D.LineCapMode = Line2D.LINE_CAP_ROUND

# Smoothing
@export var min_point_distance: float = 14.0   # px between consecutive samples
@export var simplify_tolerance: float = 6.0   # Douglas-Peucker tolerance

# Limits (set by LevelManager based on LevelData)
@export var max_total_length: float = 1200.0
@export var max_strokes: int = 0   # 0 = unlimited

# UI exclusion rectangle (in screen coords) — drawing is blocked here.
var ui_exclusion_rects: Array[Rect2] = []

# State
var _strokes: Array[PackedVector2Array] = []   # array of strokes
var _stroke_lengths: Array[float] = []         # length per stroke
var _total_length: float = 0.0
var _is_drawing: bool = false
var _current_stroke: PackedVector2Array = PackedVector2Array()

# Visuals
var _line_renderers: Array[Line2D] = []
var _preview_line: Line2D = null


func _ready() -> void:
	# Build a preview line (used while drawing).
	_preview_line = Line2D.new()
	_preview_line.name = "PreviewLine"
	_preview_line.width = line_width
	_preview_line.default_color = line_color
	_preview_line.joint_mode = line_joint_mode
	_preview_line.begin_cap_mode = line_begin_cap
	_preview_line.end_cap_mode = line_end_cap
	_preview_line.z_index = 10
	_preview_line.visible = false
	add_child(_preview_line)


func _exit_tree() -> void:
	# Clean up all dynamically created Line2D renderers.
	for lr in _line_renderers:
		if is_instance_valid(lr):
			lr.queue_free()
	_line_renderers.clear()


# --- Input handling ----------------------------------------------------------

func _input(event: InputEvent) -> void:
	# We accept both mouse drag and screen drag/touch.
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_begin_stroke(t.position)
		else:
			_end_stroke()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_continue_stroke(d.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_begin_stroke(mb.position)
			else:
				_end_stroke()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if _is_drawing:
			_continue_stroke((event as InputEventMouseMotion).position)
			get_viewport().set_input_as_handled()


# --- Stroke management -------------------------------------------------------

func _begin_stroke(screen_pos: Vector2) -> void:
	if GameManager.current_state != GameManager.GameState.GAMEPLAY_DRAW:
		return
	if _is_drawing:
		return
	# Check UI exclusion.
	if _is_in_exclusion(screen_pos):
		return
	# Check stroke count limit (0 = unlimited).
	if max_strokes > 0 and _strokes.size() >= max_strokes:
		return
	# Check length budget.
	if _total_length >= max_total_length:
		return

	_is_drawing = true
	_current_stroke = PackedVector2Array()
	# Convert to local (this Node2D's transform).
	var local_pos := to_local(screen_pos)
	_current_stroke.append(local_pos)
	_preview_line.clear_points()
	_preview_line.add_point(local_pos)
	_preview_line.visible = true
	stroke_started.emit()


func _continue_stroke(screen_pos: Vector2) -> void:
	if not _is_drawing:
		return
	var local_pos := to_local(screen_pos)
	# Throttle by min distance.
	var last := _current_stroke[_current_stroke.size() - 1]
	if local_pos.distance_to(last) < min_point_distance:
		return
	# Check budget for this segment.
	var seg_len := local_pos.distance_to(last)
	if _total_length + seg_len > max_total_length:
		# Clamp: end the stroke here.
		_end_stroke()
		return
	_current_stroke.append(local_pos)
	_preview_line.add_point(local_pos)
	_total_length += seg_len
	length_changed.emit(_total_length)


func _end_stroke() -> void:
	if not _is_drawing:
		return
	_is_drawing = false
	_preview_line.visible = false
	_preview_line.clear_points()

	# Need at least 2 points to form a line.
	if _current_stroke.size() < 2:
		_current_stroke = PackedVector2Array()
		return

	# Simplify the stroke (Douglas-Peucker).
	var simplified := _simplify(_current_stroke, simplify_tolerance)
	if simplified.size() < 2:
		simplified = _current_stroke

	# Recompute actual length of simplified polyline.
	var actual_length := _polyline_length(simplified)
	# Adjust _total_length: subtract raw stroke length, add simplified length.
	var raw_length := _polyline_length(_current_stroke)
	_total_length = _total_length - raw_length + actual_length

	_strokes.append(simplified)
	_stroke_lengths.append(actual_length)

	# Render this finalized stroke.
	_render_stroke(simplified)

	length_changed.emit(_total_length)
	stroke_added.emit(simplified, actual_length)
	_current_stroke = PackedVector2Array()


# --- Undo / Clear ------------------------------------------------------------

func undo_last_stroke() -> bool:
	if _strokes.is_empty():
		return false
	_strokes.pop_back()
	var removed_len := _stroke_lengths.pop_back()
	_total_length = max(0.0, _total_length - removed_len)
	# Re-render: remove last renderer.
	if not _line_renderers.is_empty():
		var lr := _line_renderers.pop_back()
		if is_instance_valid(lr):
			lr.queue_free()
	length_changed.emit(_total_length)
	stroke_undone.emit()
	return true


func clear_all() -> void:
	_strokes.clear()
	_stroke_lengths.clear()
	_total_length = 0.0
	for lr in _line_renderers:
		if is_instance_valid(lr):
			lr.queue_free()
	_line_renderers.clear()
	length_changed.emit(0.0)
	lines_cleared.emit()


func get_strokes() -> Array[PackedVector2Array]:
	return _strokes.duplicate()


func get_total_length() -> float:
	return _total_length


# --- Helpers -----------------------------------------------------------------

func _render_stroke(points: PackedVector2Array) -> void:
	var lr := Line2D.new()
	lr.width = line_width
	lr.default_color = line_color
	lr.joint_mode = line_joint_mode
	lr.begin_cap_mode = line_begin_cap
	lr.end_cap_mode = line_end_cap
	lr.z_index = 5
	for p in points:
		lr.add_point(p)
	add_child(lr)
	_line_renderers.append(lr)


func _is_in_exclusion(screen_pos: Vector2) -> bool:
	for r in ui_exclusion_rects:
		if r.has_point(screen_pos):
			return true
	return false


## Add a screen-space rect (e.g. UI panel bounds) where drawing is blocked.
func add_exclusion_rect(rect: Rect2) -> void:
	ui_exclusion_rects.append(rect)


## Douglas-Peucker simplification. Returns a simplified PackedVector2Array.
func _simplify(points: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if points.size() <= 2:
		return points
	# Iterative implementation to avoid recursion stack issues.
	var keep := PackedByteArray()
	keep.resize(points.size())
	keep.fill(0)
	keep[0] = 1
	keep[points.size() - 1] = 1

	var stack: Array = [[0, points.size() - 1]]
	while not stack.is_empty():
		var pair = stack.pop_back()
		var start: int = pair[0]
		var end: int = pair[1]
		if end - start <= 1:
			continue
		var max_dist: float = 0.0
		var max_idx: int = -1
		var p_start: Vector2 = points[start]
		var p_end: Vector2 = points[end]
		for i in range(start + 1, end):
			var d := _perp_distance(points[i], p_start, p_end)
			if d > max_dist:
				max_dist = d
				max_idx = i
		if max_idx != -1 and max_dist > epsilon:
			keep[max_idx] = 1
			stack.append([start, max_idx])
			stack.append([max_idx, end])

	var out := PackedVector2Array()
	for i in range(points.size()):
		if keep[i] == 1:
			out.append(points[i])
	return out


func _perp_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t := (p - a).dot(ab) / len_sq
	t = clampf(t, 0.0, 1.0)
	var proj := a + ab * t
	return p.distance_to(proj)


func _polyline_length(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i in range(1, points.size()):
		total += points[i].distance_to(points[i - 1])
	return total


## Returns strokes as a list of segment pairs (start, end).
## Used by PhysicsController to build collision segments.
func get_all_segments() -> Array:
	var out: Array = []
	for stroke in _strokes:
		var pts: PackedVector2Array = stroke
		for i in range(1, pts.size()):
			out.append([pts[i - 1], pts[i]])
	return out
