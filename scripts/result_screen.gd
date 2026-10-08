## result_screen.gd
## -----------------------------------------------------------------------------
## Standalone result screen. The gameplay scene currently shows win/lose
## as inline overlays (WinPanel/LosePanel). This standalone scene is
## provided as an alternative for future refactoring or for showing
## a richer end-of-chapter summary.
## -----------------------------------------------------------------------------
extends Control
class_name ResultScreen

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var stars_row: HBoxContainer = %StarsRow
@onready var coins_label: Label = %CoinsLabel
@onready var next_button: Button = %NextButton
@onready var retry_button: Button = %RetryButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	if next_button and not next_button.pressed.is_connected(_on_next):
		next_button.pressed.connect(_on_next)
	if retry_button and not retry_button.pressed.is_connected(_on_retry):
		retry_button.pressed.connect(_on_retry)
	if back_button and not back_button.pressed.is_connected(_on_back):
		back_button.pressed.connect(_on_back)
	_display_result(GameManager.last_level_result)


func _display_result(result: Dictionary) -> void:
	var won: bool = bool(result.get("won", false))
	if won:
		title_label.text = "آفرین!"
		subtitle_label.text = "نجاتش دادی"
		var stars := int(result.get("stars", 0))
		for i in range(stars_row.get_child_count()):
			var star = stars_row.get_child(i)
			star.modulate = Color.WHITE if i < stars else Color(0.3, 0.3, 0.3, 1.0)
		coins_label.text = "+ %s سکه" % _to_persian(int(result.get("coins_earned", 0)))
	else:
		title_label.text = "ای وای!"
		subtitle_label.text = String(result.get("reason", "دوباره تلاش کن"))
		for i in range(stars_row.get_child_count()):
			stars_row.get_child(i).modulate = Color(0.3, 0.3, 0.3, 1.0)
		coins_label.text = ""


func _on_next() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	var current_num := _parse_level_number(GameManager.current_level_id)
	var next_num := GameManager.get_next_level_number(current_num)
	if next_num > 0:
		GameManager.start_level(next_num)
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_retry() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	var num := _parse_level_number(GameManager.current_level_id)
	GameManager.start_level(num)


func _on_back() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	GameManager.current_state = GameManager.GameState.LEVEL_SELECT
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _parse_level_number(level_id: String) -> int:
	if level_id.begins_with("level_"):
		return int(level_id.substr(6))
	return 1


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
