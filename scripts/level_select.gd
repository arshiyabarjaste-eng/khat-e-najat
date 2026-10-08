## level_select.gd
## -----------------------------------------------------------------------------
## Shows a grid of 15 levels, organized by chapter. Locked levels cannot be
## entered. Shows star count and chapter color.
## -----------------------------------------------------------------------------
extends Control
class_name LevelSelect

@onready var back_button: Button = %BackButton
@onready var coins_label: Label = %CoinsLabel

# Per-chapter view. We default to showing all 15 levels in one grid grouped
# by chapter (with chapter dividers). For simplicity, we use 3 sub-grids.
@onready var chapter1_container: VBoxContainer = %Chapter1Container
@onready var chapter2_container: VBoxContainer = %Chapter2Container
@onready var chapter3_container: VBoxContainer = %Chapter3Container


func _ready() -> void:
        if back_button and not back_button.pressed.is_connected(_on_back):
                back_button.pressed.connect(_on_back)

        _update_coins_label()
        _populate_levels()


func _populate_levels() -> void:
        # Clear existing children of each chapter's Grid (index 1, after the Header).
        for ch in [_get_chapter_grid(1), _get_chapter_grid(2), _get_chapter_grid(3)]:
                if ch == null:
                        continue
                for c in ch.get_children():
                        c.queue_free()

        for i in range(1, 16):
                var container := _get_chapter_grid(GameManager.get_chapter_for_level(i) + 1)
                if container == null:
                        continue
                var btn := _make_level_button(i)
                container.add_child(btn)


## Returns the GridContainer (child index 1) for the given chapter (1..3).
func _get_chapter_grid(chapter: int) -> GridContainer:
        var container: VBoxContainer
        match chapter:
                1: container = chapter1_container
                2: container = chapter2_container
                _: container = chapter3_container
        if container == null:
                return null
        # Grid is the second child (after the Header panel).
        if container.get_child_count() < 2:
                return null
        return container.get_child(1) as GridContainer


func _make_level_button(level_num: int) -> Button:
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(110, 110)
        btn.text = _to_persian(level_num)
        btn.add_theme_font_size_override("font_size", 28)

        var unlocked := GameManager.is_level_unlocked(level_num)
        btn.disabled = not unlocked
        if not unlocked:
                btn.text = "🔒  " + _to_persian(level_num)
                btn.modulate = Color(0.6, 0.6, 0.6, 1.0)

        # Show stars below the number, via tooltip.
        var id := "level_%02d" % level_num
        var stars := SaveManager.get_level_stars(id)
        btn.tooltip_text = "ستاره‌ها: %s از ۳" % _to_persian(stars)

        btn.add_theme_color_override("font_color", Color.WHITE)
        btn.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7, 1.0))

        btn.pressed.connect(_on_level_pressed.bind(level_num))
        return btn


func _on_level_pressed(level_num: int) -> void:
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.BUTTON)
        if not GameManager.is_level_unlocked(level_num):
                return
        GameManager.start_level(level_num)


func _on_back() -> void:
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.BUTTON)
        GameManager.current_state = GameManager.GameState.MAIN_MENU
        get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _update_coins_label() -> void:
        if coins_label:
                coins_label.text = "سکه: %s" % _to_persian(GameManager.coins)


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
