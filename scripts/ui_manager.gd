## ui_manager.gd
## -----------------------------------------------------------------------------
## Helper for gameplay UI: manages buttons, brief text, line budget bar,
## and overlays (win/lose dialogs). Loaded as a child of the gameplay scene's
## UI layer. Communicates with LevelManager via signals.
## -----------------------------------------------------------------------------
extends CanvasLayer
class_name UIManager

# --- Nodes (assigned in gameplay.tscn via @export) --------------------------
@onready var brief_label: Label = %BriefLabel
@onready var level_title_label: Label = %LevelTitleLabel
@onready var line_progress: ProgressBar = %LineProgress
@onready var line_label: Label = %LineLabel
@onready var start_button: Button = %StartButton
@onready var clear_button: Button = %ClearButton
@onready var retry_button: Button = %RetryButton
@onready var undo_button: Button = %UndoButton
@onready var back_button: Button = %BackButton
@onready var hint_button: Button = %HintButton
@onready var timer_label: Label = %TimerLabel
@onready var win_panel: Control = %WinPanel
@onready var lose_panel: Control = %LosePanel
@onready var hint_panel: Control = %HintPanel

@onready var win_stars: Array = [
        %WinStar1, %WinStar2, %WinStar3
]
@onready var win_coins_label: Label = %WinCoinsLabel
@onready var win_next_button: Button = %WinNextButton
@onready var win_retry_button: Button = %WinRetryButton
@onready var win_back_button: Button = %WinBackButton

@onready var lose_retry_button: Button = %LoseRetryButton
@onready var lose_back_button: Button = %LoseBackButton
@onready var lose_reason_label: Label = %LoseReasonLabel

@onready var hint_text_label: Label = %HintTextLabel
@onready var hint_close_button: Button = %HintCloseButton


# --- Lifecycle ---------------------------------------------------------------

func _ready() -> void:
        # Hide panels initially.
        if win_panel: win_panel.visible = false
        if lose_panel: lose_panel.visible = false
        if hint_panel: hint_panel.visible = false
        if timer_label: timer_label.visible = false

        # Hook button signals. The actual handlers are in gameplay.gd,
        # but we expose them via grouped signals for clarity.
        if start_button and not start_button.pressed.is_connected(_on_start_pressed):
                start_button.pressed.connect(_on_start_pressed)
        if clear_button and not clear_button.pressed.is_connected(_on_clear_pressed):
                clear_button.pressed.connect(_on_clear_pressed)
        if retry_button and not retry_button.pressed.is_connected(_on_retry_pressed):
                retry_button.pressed.connect(_on_retry_pressed)
        if undo_button and not undo_button.pressed.is_connected(_on_undo_pressed):
                undo_button.pressed.connect(_on_undo_pressed)
        if back_button and not back_button.pressed.is_connected(_on_back_pressed):
                back_button.pressed.connect(_on_back_pressed)
        if hint_button and not hint_button.pressed.is_connected(_on_hint_pressed):
                hint_button.pressed.connect(_on_hint_pressed)

        if win_next_button and not win_next_button.pressed.is_connected(_on_win_next):
                win_next_button.pressed.connect(_on_win_next)
        if win_retry_button and not win_retry_button.pressed.is_connected(_on_win_retry):
                win_retry_button.pressed.connect(_on_win_retry)
        if win_back_button and not win_back_button.pressed.is_connected(_on_win_back):
                win_back_button.pressed.connect(_on_win_back)

        if lose_retry_button and not lose_retry_button.pressed.is_connected(_on_lose_retry):
                lose_retry_button.pressed.connect(_on_lose_retry)
        if lose_back_button and not lose_back_button.pressed.is_connected(_on_lose_back):
                lose_back_button.pressed.connect(_on_lose_back)

        if hint_close_button and not hint_close_button.pressed.is_connected(_on_hint_close):
                hint_close_button.pressed.connect(_on_hint_close)


# --- Public API --------------------------------------------------------------

## Configures the UI for the loaded level.
func setup_for_level(level: LevelData) -> void:
        if level == null:
                return
        if level_title_label:
                level_title_label.text = "مرحله %d - %s" % [level.level_number, level.title]
        if brief_label:
                brief_label.text = level.brief
        if line_progress:
                line_progress.min_value = 0.0
                line_progress.max_value = level.max_line_length
                line_progress.value = 0.0
                line_progress.show_percentage = false
        if line_label:
                line_label.text = "خط: ۰ / %d" % int(level.max_line_length)
        if timer_label:
                if level.time_limit > 0.0:
                        timer_label.visible = true
                        timer_label.text = "زمان: %.1f" % level.time_limit
                else:
                        timer_label.visible = false
        # Hide action panels during draw phase.
        if win_panel: win_panel.visible = false
        if lose_panel: lose_panel.visible = false
        if hint_panel: hint_panel.visible = false
        # Enable buttons.
        _set_buttons_enabled(true)


## Updates the line-length progress display.
func update_line_progress(used: float, max_val: float) -> void:
        if line_progress:
                line_progress.value = used
        if line_label:
                # Use Persian digits for friendliness.
                line_label.text = "خط: %s / %s" % [_to_persian(int(used)), _to_persian(int(max_val))]


## Updates the timer display.
func update_timer(remaining: float) -> void:
        if timer_label and remaining >= 0.0:
                timer_label.text = "زمان: %s" % _to_persian_float(remaining, 1)


## Disables action buttons during simulation.
func set_simulation_mode(running: bool) -> void:
        if start_button: start_button.disabled = running
        if clear_button: clear_button.disabled = running
        if undo_button: undo_button.disabled = running
        if hint_button: hint_button.disabled = running


## Shows the win panel with stars + coins.
func show_win(stars: int, coins_earned: int) -> void:
        if win_panel == null:
                return
        win_panel.visible = true
        for i in range(3):
                if i < win_stars.size() and win_stars[i] != null:
                        win_stars[i].modulate = Color.WHITE if i < stars else Color(0.3, 0.3, 0.3, 1.0)
        if win_coins_label:
                win_coins_label.text = "+ %s سکه" % _to_persian(coins_earned)
        # Disable "Next" button if no more levels.
        if win_next_button:
                var current_num := _parse_level_number(GameManager.current_level_id)
                var next_num := GameManager.get_next_level_number(current_num)
                win_next_button.disabled = (next_num == 0)


## Shows the lose panel with reason.
func show_lose(reason: String) -> void:
        if lose_panel == null:
                return
        lose_panel.visible = true
        if lose_reason_label:
                lose_reason_label.text = reason


## Shows the hint text.
func show_hint(text: String) -> void:
        if hint_panel == null:
                return
        if hint_text_label:
                hint_text_label.text = text
        hint_panel.visible = true


func hide_hint() -> void:
        if hint_panel:
                hint_panel.visible = false


## Returns the screen-space rectangles of all UI panels/buttons that should
## block line drawing. Called by gameplay.gd to pass to LineDrawer.
func get_ui_exclusion_rects() -> Array[Rect2]:
        var out: Array[Rect2] = []
        # The top bar (title + brief) and bottom bar (buttons).
        var nodes: Array = [level_title_label, brief_label, start_button, clear_button,
                retry_button, undo_button, back_button, hint_button, timer_label]
        for node in nodes:
                if node == null:
                        continue
                if not (node is Control):
                        continue
                var ctrl: Control = node
                var rect: Rect2 = ctrl.get_global_rect()
                out.append(rect.grow(8))
        return out


# --- Signal handlers (forward to gameplay.gd via owner) ---------------------

func _on_start_pressed() -> void:
        if owner != null and owner.has_method("_on_ui_start"):
                owner._on_ui_start()

func _on_clear_pressed() -> void:
        if owner != null and owner.has_method("_on_ui_clear"):
                owner._on_ui_clear()

func _on_retry_pressed() -> void:
        if owner != null and owner.has_method("_on_ui_retry"):
                owner._on_ui_retry()

func _on_undo_pressed() -> void:
        if owner != null and owner.has_method("_on_ui_undo"):
                owner._on_ui_undo()

func _on_back_pressed() -> void:
        if owner != null and owner.has_method("_on_ui_back"):
                owner._on_ui_back()

func _on_hint_pressed() -> void:
        if owner != null and owner.has_method("_on_ui_hint"):
                owner._on_ui_hint()

func _on_win_next() -> void:
        if owner != null and owner.has_method("_on_ui_win_next"):
                owner._on_ui_win_next()

func _on_win_retry() -> void:
        if owner != null and owner.has_method("_on_ui_retry"):
                owner._on_ui_retry()

func _on_win_back() -> void:
        if owner != null and owner.has_method("_on_ui_back"):
                owner._on_ui_back()

func _on_lose_retry() -> void:
        if owner != null and owner.has_method("_on_ui_retry"):
                owner._on_ui_retry()

func _on_lose_back() -> void:
        if owner != null and owner.has_method("_on_ui_back"):
                owner._on_ui_back()

func _on_hint_close() -> void:
        hide_hint()


# --- Helpers ----------------------------------------------------------------

func _set_buttons_enabled(enabled: bool) -> void:
        if start_button: start_button.disabled = not enabled
        if clear_button: clear_button.disabled = not enabled
        if retry_button: retry_button.disabled = not enabled
        if undo_button: undo_button.disabled = not enabled


func _parse_level_number(level_id: String) -> int:
        # "level_03" -> 3
        if level_id.begins_with("level_"):
                return int(level_id.substr(6))
        return 0


# Persian digit conversion (RTL display)
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


func _to_persian_float(f: float, decimals: int = 1) -> String:
        var s := ("%%.%df" % decimals) % f
        var out := ""
        for ch in s:
                if ch >= "0" and ch <= "9":
                        out += PERSIAN_DIGITS[int(ch)]
                else:
                        out += ch
        return out
