## main_menu.gd
## -----------------------------------------------------------------------------
## Root script for the main menu scene. Shows logo, level progress summary,
## and routes to gameplay / level select / settings.
## -----------------------------------------------------------------------------
extends Control
class_name MainMenu

@onready var start_button: Button = %StartButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var settings_button: Button = %SettingsButton
@onready var coins_label: Label = %CoinsLabel
@onready var progress_label: Label = %ProgressLabel
@onready var title_label: Label = %TitleLabel
@onready var slogan_label: Label = %SloganLabel

func _ready() -> void:
	if start_button and not start_button.pressed.is_connected(_on_start):
		start_button.pressed.connect(_on_start)
	if level_select_button and not level_select_button.pressed.is_connected(_on_level_select):
		level_select_button.pressed.connect(_on_level_select)
	if settings_button and not settings_button.pressed.is_connected(_on_settings):
		settings_button.pressed.connect(_on_settings)

	# Apply current state and update display.
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	_update_display()

	# Start ambient music if enabled.
	if AudioManager:
		AudioManager.play_music()


func _update_display() -> void:
	if coins_label:
		coins_label.text = "سکه: %s" % _to_persian(GameManager.coins)
	# Compute overall progress: levels with at least 1 star.
	var completed := 0
	for i in range(1, GameManager.TOTAL_LEVELS + 1):
		var id := "level_%02d" % i
		if SaveManager.get_level_stars(id) >= 1:
			completed += 1
	if progress_label:
		progress_label.text = "پیشرفت: %s / %s" % [_to_persian(completed), _to_persian(GameManager.TOTAL_LEVELS)]


# --- Button handlers ---------------------------------------------------------

func _on_start() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	# Find the first not-yet-completed level.
	var level_num := 1
	for i in range(1, GameManager.TOTAL_LEVELS + 1):
		var id := "level_%02d" % i
		if SaveManager.get_level_stars(id) < 1:
			level_num = i
			break
		if i == GameManager.TOTAL_LEVELS:
			level_num = i  # All done — start from the last.
	GameManager.start_level(level_num)


func _on_level_select() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	GameManager.current_state = GameManager.GameState.LEVEL_SELECT
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _on_settings() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	GameManager.current_state = GameManager.GameState.SETTINGS
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


# --- Helpers -----------------------------------------------------------------

const PERSIAN_DIGITS := ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]

func _to_persian(n: int) -> String:
	var s := str(n)
	var out := ""
	for ch in s:
		if ch >= "0" and ch <= "9":
			out += PERSIAN_DIGITS[int(ch)]
		else:
			out += ch
	return out
