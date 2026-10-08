## SaveManager.gd
## -----------------------------------------------------------------------------
## Singleton (Autoload). Handles persistent storage of progress, settings,
## and per-level metadata. Uses JSON file at user://save.json for portability
## and ease of debugging. The format is forward-compatible (additive).
## -----------------------------------------------------------------------------
extends Node
class_name SaveManager

signal data_loaded(data: Dictionary)
signal data_saved()

const SAVE_PATH := "user://save.json"
const SCHEMA_VERSION := 1

# In-memory cache; written through to disk on save_async().
var _data: Dictionary = {
	"schema_version": SCHEMA_VERSION,
	"coins": 0,
	"levels": {},           # level_id -> {best_stars, best_line_used, attempts}
	"settings": {
		"sound_enabled": true,
		"music_enabled": true,
		"sound_volume": 1.0,
		"music_volume": 0.7,
		"language": "fa",
	},
	"tutorial_shown": false,
}

var _dirty: bool = false
var _save_in_flight: bool = false


# --- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	_load()


func _exit_tree() -> void:
	# Best-effort save on exit.
	if _dirty:
		_save_blocking()


# --- Public API: load / save -------------------------------------------------

func _load() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		# Fresh install — keep defaults.
		print("[SaveManager] No save file found, using defaults.")
		data_loaded.emit(_data)
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[SaveManager] Save file is corrupt; resetting to defaults.")
		_data = _default_data()
		data_loaded.emit(_data)
		return

	# Merge: keep new keys for forward-compat, but overwrite from disk.
	_data = _merge(_default_data(), parsed)
	# Ensure settings exist with all keys.
	if not _data.has("settings"):
		_data["settings"] = _default_data()["settings"]
	# Validate types of critical fields.
	_data["coins"] = int(_data.get("coins", 0))
	if typeof(_data["levels"]) != TYPE_DICTIONARY:
		_data["levels"] = {}
	if typeof(_data["settings"]) != TYPE_DICTIONARY:
		_data["settings"] = _default_data()["settings"]

	data_loaded.emit(_data)


func _default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"coins": 0,
		"levels": {},
		"settings": {
			"sound_enabled": true,
			"music_enabled": true,
			"sound_volume": 1.0,
			"music_volume": 0.7,
			"language": "fa",
		},
		"tutorial_shown": false,
	}


## Deep-merge source into target (source wins). Returns new dict.
func _merge(target: Dictionary, source: Dictionary) -> Dictionary:
	var out: Dictionary = target.duplicate(true)
	for key in source:
		var sval = source[key]
		if typeof(sval) == TYPE_DICTIONARY and typeof(out.get(key)) == TYPE_DICTIONARY:
			out[key] = _merge(out[key], sval)
		else:
			out[key] = sval
	return out


func save_async() -> void:
	if _save_in_flight:
		_dirty = true
		return
	_save_in_flight = true
	# Defer to next idle frame so we don't block the current frame.
	call_deferred("_do_save")


func _do_save() -> void:
	_save_in_flight = false
	if _save_in_flight:  # Was queued again during save — re-loop.
		_dirty = false
		call_deferred("_do_save")
		return
	_save_blocking()
	if _dirty:
		_dirty = false
		call_deferred("_do_save")


func _save_blocking() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Cannot write save file: " + str(FileAccess.get_open_error()))
		return
	var json_text := JSON.stringify(_data, "  ")
	file.store_string(json_text)
	file.close()
	data_saved.emit()


# --- Public API: coins -------------------------------------------------------

func get_coins() -> int:
	return int(_data.get("coins", 0))

func set_coins(value: int) -> void:
	_data["coins"] = max(0, value)
	_dirty = true


# --- Public API: per-level data ----------------------------------------------

func get_level_stars(level_id: String) -> int:
	var levels: Dictionary = _data.get("levels", {})
	var entry: Dictionary = levels.get(level_id, {})
	return int(entry.get("best_stars", 0))

func set_level_stars(level_id: String, stars: int) -> void:
	if not _data.has("levels") or typeof(_data["levels"]) != TYPE_DICTIONARY:
		_data["levels"] = {}
	if not _data["levels"].has(level_id):
		_data["levels"][level_id] = {}
	_data["levels"][level_id]["best_stars"] = maxi(0, stars)
	_dirty = true

func get_level_attempts(level_id: String) -> int:
	var levels: Dictionary = _data.get("levels", {})
	var entry: Dictionary = levels.get(level_id, {})
	return int(entry.get("attempts", 0))

func set_level_meta(level_id: String, meta: Dictionary) -> void:
	if not _data.has("levels") or typeof(_data["levels"]) != TYPE_DICTIONARY:
		_data["levels"] = {}
	_data["levels"][level_id] = meta
	_dirty = true

func get_level_meta(level_id: String) -> Dictionary:
	var levels: Dictionary = _data.get("levels", {})
	return levels.get(level_id, {})


# --- Public API: settings ----------------------------------------------------

func get_setting(key: String, default = null):
	var settings: Dictionary = _data.get("settings", {})
	return settings.get(key, default)

func set_setting(key: String, value) -> void:
	if not _data.has("settings") or typeof(_data["settings"]) != TYPE_DICTIONARY:
		_data["settings"] = {}
	_data["settings"][key] = value
	_dirty = true

func is_sound_enabled() -> bool:
	return bool(get_setting("sound_enabled", true))

func is_music_enabled() -> bool:
	return bool(get_setting("music_enabled", true))

func get_sound_volume() -> float:
	return float(get_setting("sound_volume", 1.0))

func get_music_volume() -> float:
	return float(get_setting("music_volume", 0.7))


# --- Public API: tutorial flag ----------------------------------------------

func is_tutorial_shown() -> bool:
	return bool(_data.get("tutorial_shown", false))

func mark_tutorial_shown() -> void:
	_data["tutorial_shown"] = true
	_dirty = true


# --- Public API: reset -------------------------------------------------------

func reset_all() -> void:
	_data = _default_data()
	_dirty = true
	_save_blocking()
