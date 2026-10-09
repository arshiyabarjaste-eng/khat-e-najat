## GameManager.gd
## -----------------------------------------------------------------------------
## Singleton (Autoload). Tracks global game state, current level, coins,
## and transitions between main scenes. Persists across scene changes.
## -----------------------------------------------------------------------------
extends Node
# GameManager — registered as autoload singleton in project.godot.
# Do NOT add `class_name` here; it conflicts with the autoload name in Godot 4.x.

# --- Signals ----------------------------------------------------------------
signal coins_changed(new_amount: int)
signal level_unlocked(level_id: String)
signal state_changed(new_state: GameState)

# --- Enums -------------------------------------------------------------------
enum GameState {
        BOOT,
        MAIN_MENU,
        LEVEL_SELECT,
        GAMEPLAY_DRAW,   # Player is drawing lines (pre-simulation)
        GAMEPLAY_SIM,    # Physics simulation is running
        WIN,
        LOSE,
        SETTINGS,
}

# --- Public State ------------------------------------------------------------
var current_state: GameState = GameState.BOOT:
        set(v):
                if v != current_state:
                        current_state = v
                        state_changed.emit(v)

var coins: int = 0:
        set(v):
                coins = max(0, v)
                coins_changed.emit(coins)

var current_level_id: String = ""
var current_chapter: int = 0
var last_level_result := {
        "stars": 0,
        "coins_earned": 0,
        "line_used": 0.0,
        "attempts": 0,
        "won": false,
}

# Constants
const TOTAL_LEVELS: int = 15
const LEVELS_PER_CHAPTER: int = 5
const COIN_REWARD_BASE: int = 50
const COIN_REWARD_PER_STAR: int = 25

# Chapter metadata (used by level_select UI)
const CHAPTERS: Array = [
        {
                "id": 1,
                "title": "کوچه‌های محله",
                "subtitle": "خانه‌های ایرانی، حوض و گلدان",
                "color": Color(0.20, 0.50, 0.45, 1.0),  # فیروزه‌ای
        },
        {
                "id": 2,
                "title": "شهر شلوغ",
                "subtitle": "خیابان، موتور و مغازه",
                "color": Color(0.45, 0.30, 0.20, 1.0),  # آجری
        },
        {
                "id": 3,
                "title": "باغ و روستا",
                "subtitle": "درخت، جوی آب و دیوار کاه‌گلی",
                "color": Color(0.35, 0.55, 0.25, 1.0),  # سبز طبیعی
        },
]


# --- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
        # Bind SaveManager signals
        if SaveManager:
                if not SaveManager.data_loaded.is_connected(_on_save_loaded):
                        SaveManager.data_loaded.connect(_on_save_loaded)
        # Initial load is performed by SaveManager._ready() (autoload order).
        current_state = GameState.MAIN_MENU


func _on_save_loaded(data: Dictionary) -> void:
        coins = int(data.get("coins", 0))


# --- Public API --------------------------------------------------------------

## Returns the chapter index (0-based) for a 1-based level number.
func get_chapter_for_level(level_num: int) -> int:
        return clampi(int((level_num - 1) / LEVELS_PER_CHAPTER), 0, CHAPTERS.size() - 1)


## Returns true if the level (1-based number) is unlocked.
func is_level_unlocked(level_num: int) -> bool:
        if level_num <= 1:
                return true  # First level is always unlocked
        var prev_key := "level_%02d" % (level_num - 1)
        var prev_stars := SaveManager.get_level_stars(prev_key)
        # A level is unlocked if the previous one has at least 1 star.
        return prev_stars >= 1


## Records a level's completion. Updates best stars, awards coins.
## Returns the actual coins awarded (delta) so the UI can show "+50" etc.
func record_level_result(level_id: String, stars: int, line_used: float, attempts: int) -> int:
        var prev_best := SaveManager.get_level_stars(level_id)
        var new_best := maxi(prev_best, stars)
        SaveManager.set_level_stars(level_id, new_best)
        SaveManager.set_level_meta(level_id, {
                "best_stars": new_best,
                "best_line_used": line_used,
                "attempts": attempts + SaveManager.get_level_attempts(level_id),
        })

        # Coin reward: base + per-star bonus, only the delta from prev_best.
        var coin_delta := COIN_REWARD_BASE + COIN_REWARD_PER_STAR * (stars - prev_best)
        coin_delta = maxi(coin_delta, 0)
        coins += coin_delta
        SaveManager.set_coins(coins)
        SaveManager.save_async()
        return coin_delta


## Convenience helper: loads the gameplay scene and asks LevelManager to load a level.
func start_level(level_num: int) -> void:
        current_level_id = "level_%02d" % level_num
        current_chapter = get_chapter_for_level(level_num) + 1
        last_level_result = {
                "stars": 0,
                "coins_earned": 0,
                "line_used": 0.0,
                "attempts": 0,
                "won": false,
        }
        current_state = GameState.GAMEPLAY_DRAW
        get_tree().change_scene_to_file("res://scenes/gameplay.tscn")


## Reset everything (used by settings → "بازگردانی پیشرفت").
func reset_progress() -> void:
        coins = 0
        current_level_id = ""
        current_chapter = 0
        last_level_result = {
                "stars": 0,
                "coins_earned": 0,
                "line_used": 0.0,
                "attempts": 0,
                "won": false,
        }
        SaveManager.reset_all()
        current_state = GameState.MAIN_MENU


## Returns next level number (1-based) or 0 if no more levels.
func get_next_level_number(current_num: int) -> int:
        var next := current_num + 1
        if next > TOTAL_LEVELS:
                return 0
        return next
