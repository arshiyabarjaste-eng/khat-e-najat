## level_data.gd
## -----------------------------------------------------------------------------
## Runtime representation of a single level's configuration.
## Levels are loaded from JSON files under res://data/levels/level_NN.json.
## Adding a new level only requires creating a new .json file — no code changes.
##
## Why JSON instead of .tres?
##   Godot's .tres format struggles with arrays of dictionaries (typed).
##   JSON is simpler, validated in-editor, and trivially editable.
## -----------------------------------------------------------------------------
extends RefCounted
class_name LevelData

# --- Identity ----------------------------------------------------------------
var level_id: String = "level_01"
var level_number: int = 1
var title: String = "مرحله ۱"
var chapter: int = 1
var brief: String = "گربه را به نقطه امن برسان."
var hint: String = "یه خط بکش تا مسیر گربه به سمت امن هدایت بشه."

# --- Physics config ----------------------------------------------------------
var gravity: float = 980.0
var time_limit: float = 0.0  # 0 = no time limit
var max_line_length: float = 1200.0  # in world pixels
var max_line_segments: int = 0  # 0 = unlimited
var allow_undo: bool = true
var allow_clear: bool = true

# --- Objectives (3-star criteria) -------------------------------------------
var star2_line_threshold: float = 0.85  # use <85% of max length → 2 stars minimum
var star3_line_threshold: float = 0.60  # use <60% of max length → 3 stars
var require_special_condition: bool = false
var special_condition_text: String = ""

# --- Scene layout (object placements) ---------------------------------------
## Each entry is a Dictionary with: type, position (Vector2), size (Vector2),
## rotation (deg), color (Color), and any type-specific fields.
var objects: Array = []

# --- Background art ---------------------------------------------------------
var background_color: Color = Color(0.20, 0.50, 0.45, 1.0)  # فیروزه‌ای default
var background_scene_path: String = ""  # optional: res path to a PackedScene
var scene_name: String = ""
var scene_tint: Color = Color(1.0, 1.0, 1.0, 1.0)


# --- Static loader ----------------------------------------------------------

## Loads a LevelData by 1-based level number.
static func load_by_number(num: int) -> LevelData:
	var path := "res://data/levels/level_%02d.json" % num
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		push_error("[LevelData] Cannot find level file: " + path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[LevelData] Cannot open level file: " + path)
		return null
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[LevelData] Invalid JSON in: " + path)
		return null
	var ld := LevelData.new()
	ld._from_dict(parsed)
	return ld


## Populates this LevelData from a Dictionary (parsed JSON).
func _from_dict(d: Dictionary) -> void:
	level_id = String(d.get("level_id", level_id))
	level_number = int(d.get("level_number", level_number))
	title = String(d.get("title", title))
	chapter = int(d.get("chapter", chapter))
	brief = String(d.get("brief", brief))
	hint = String(d.get("hint", hint))
	gravity = float(d.get("gravity", gravity))
	time_limit = float(d.get("time_limit", time_limit))
	max_line_length = float(d.get("max_line_length", max_line_length))
	max_line_segments = int(d.get("max_line_segments", max_line_segments))
	allow_undo = bool(d.get("allow_undo", allow_undo))
	allow_clear = bool(d.get("allow_clear", allow_clear))
	star2_line_threshold = float(d.get("star2_line_threshold", star2_line_threshold))
	star3_line_threshold = float(d.get("star3_line_threshold", star3_line_threshold))
	require_special_condition = bool(d.get("require_special_condition", require_special_condition))
	special_condition_text = String(d.get("special_condition_text", special_condition_text))
	scene_name = String(d.get("scene_name", scene_name))
	background_scene_path = String(d.get("background_scene_path", ""))

	# Color parsing — supports both [r,g,b,a] arrays and hex strings.
	background_color = _parse_color(d.get("background_color", [0.20, 0.50, 0.45, 1.0]))
	scene_tint = _parse_color(d.get("scene_tint", [1.0, 1.0, 1.0, 1.0]))

	# Objects: each is a dict with parsed Vector2/Color.
	objects.clear()
	var raw_objects = d.get("objects", [])
	if typeof(raw_objects) == TYPE_ARRAY:
		for o in raw_objects:
			if typeof(o) != TYPE_DICTIONARY:
				continue
			var oo: Dictionary = {}
			oo["type"] = String(o.get("type", "block"))
			oo["position"] = _parse_vec2(o.get("position", [0, 0]))
			oo["size"] = _parse_vec2(o.get("size", [40, 40]))
			oo["rotation"] = float(o.get("rotation", 0))
			oo["color"] = _parse_color(o.get("color", [0.5, 0.5, 0.5, 1.0]))
			oo["label"] = String(o.get("label", ""))
			oo["velocity"] = _parse_vec2(o.get("velocity", [0, 0]))
			oo["radius"] = float(o.get("radius", 0))
			objects.append(oo)


static func _parse_vec2(v) -> Vector2:
	if v is Vector2:
		return v
	if typeof(v) == TYPE_ARRAY and v.size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return Vector2.ZERO


static func _parse_color(v) -> Color:
	if v is Color:
		return v
	if typeof(v) == TYPE_ARRAY:
		if v.size() >= 4:
			return Color(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
		if v.size() >= 3:
			return Color(float(v[0]), float(v[1]), float(v[2]), 1.0)
	if typeof(v) == TYPE_STRING:
		return Color(v)
	return Color(0.5, 0.5, 0.5, 1.0)


# --- Validation --------------------------------------------------------------

## Validates that required fields are set and that at least one goal exists.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if level_id.is_empty():
		errors.append("level_id is empty")
	if title.is_empty():
		errors.append("title is empty")
	var has_goal := false
	var has_player := false
	for obj in objects:
		match String(obj.get("type", "")):
			"goal":
				has_goal = true
			"player", "ball", "crate", "cat":
				has_player = true
	if not has_goal:
		errors.append("Level has no goal area — cannot be won.")
	if not has_player:
		errors.append("Level has no player/rescue target — cannot be played.")
	return errors


## Returns a deep-copied array of objects so callers can mutate without
## affecting the loaded data (important during simulation).
func get_objects_snapshot() -> Array:
	var out: Array = []
	for o in objects:
		out.append((o as Dictionary).duplicate(true))
	return out
