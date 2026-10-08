## level_manager.gd
## -----------------------------------------------------------------------------
## Glue layer between LevelData (data) and PhysicsController/LineDrawer (engine).
## Knows the current level number, sets up the scene, drives the state machine,
## and reports win/lose to the gameplay UI.
## -----------------------------------------------------------------------------
extends Node
class_name LevelManager

signal level_loaded(level: LevelData)
signal level_won(stars: int, coins_earned: int, line_used: float)
signal level_lost(reason: String)
signal attempt_counted(count: int)
signal line_budget_changed(used: float, max_val: float)
signal sim_state_changed(running: bool)

# Public state.
var current_level: LevelData = null
var current_level_number: int = 1
var attempts: int = 0
var line_used_on_win: float = 0.0
var sim_running: bool = false:
        set(v):
                if v != sim_running:
                        sim_running = v
                        sim_state_changed.emit(v)

# Internal references (set externally by gameplay.gd).
var physics: PhysicsController = null
var line_drawer: LineDrawer = null
var world_node: Node2D = null

# World bounds for OOB check (in world coords).
var world_bounds := Rect2(0, 0, 720, 1280)


func _ready() -> void:
        # NOTE: Signal connections are made lazily inside load_level() because
        # physics and line_drawer are assigned by gameplay.gd._ready() which
        # runs AFTER this node's _ready() (children _ready first, parent last).
        _connect_signals()


func _connect_signals() -> void:
        if physics != null:
                if not physics.player_reached_goal.is_connected(_on_player_reached_goal):
                        physics.player_reached_goal.connect(_on_player_reached_goal)
                if not physics.player_entered_hazard.is_connected(_on_player_in_hazard):
                        physics.player_entered_hazard.connect(_on_player_in_hazard)
                if not physics.time_expired.is_connected(_on_time_expired):
                        physics.time_expired.connect(_on_time_expired)
        if line_drawer != null:
                if not line_drawer.length_changed.is_connected(_on_line_length_changed):
                        line_drawer.length_changed.connect(_on_line_length_changed)


# --- Public API --------------------------------------------------------------

## Loads the level by number and sets up the scene.
func load_level(level_num: int) -> void:
        # Re-attempt signal connection (in case physics/line_drawer were assigned after _ready()).
        _connect_signals()
        current_level_number = level_num
        current_level = LevelData.load_by_number(level_num)
        if current_level == null:
                push_error("[LevelManager] Failed to load level %d" % level_num)
                return
        # Validate.
        var errs := current_level.validate()
        if not errs.is_empty():
                push_warning("[LevelManager] Level %d validation: %s" % [level_num, str(errs)])
        # Configure LineDrawer limits.
        if line_drawer != null:
                line_drawer.max_total_length = current_level.max_line_length
                line_drawer.max_strokes = current_level.max_line_segments
        # Setup physics world.
        if physics != null and world_node != null:
                physics.setup_level(current_level, world_node)
        attempts = 0
        sim_running = false
        level_loaded.emit(current_level)


## Called when the user presses "Start" (شروع).
func start_simulation() -> void:
        if sim_running:
                return
        if physics == null or line_drawer == null:
                return
        # Build line physics from current strokes.
        var strokes := line_drawer.get_strokes()
        physics.build_line_physics(strokes)
        attempts += 1
        attempt_counted.emit(attempts)
        sim_running = true
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.START_SIM)
        physics.start_simulation()


## Called when user presses "Retry" (تلاش مجدد) or after a lose.
func retry_level() -> void:
        # Reset simulation flag first so _on_sim_state_changed allows drawing again.
        sim_running = false
        # Clear drawn lines (visual + internal state).
        if line_drawer:
                line_drawer.clear_all()
        # Re-setup the level: this calls teardown() internally, which frees all
        # dynamic physics bodies and rebuilds the scene from the level data.
        # This is the cleanest way to reset everything to initial state.
        if current_level != null and world_node != null and physics != null:
                physics.setup_level(current_level, world_node)


## Called when user presses "Clear" (پاک‌کردن خط).
func clear_lines() -> void:
        if line_drawer:
                line_drawer.clear_all()


## Called when user presses "Undo" (لغو آخرین خط).
func undo_last_line() -> void:
        if line_drawer:
                line_drawer.undo_last_stroke()


## Should be called by gameplay.gd every frame to check OOB.
func check_out_of_bounds() -> void:
        if sim_running and physics != null:
                if physics.check_player_out_of_bounds(world_bounds):
                        _on_player_out_of_bounds()


## Returns the line-used ratio (0..1) for star calculations.
func get_line_ratio() -> float:
        if current_level == null or current_level.max_line_length <= 0.0:
                return 0.0
        return line_drawer.get_total_length() / current_level.max_line_length


## Returns the number of stars earned (0, 1, 2, or 3) based on win conditions.
func compute_stars() -> int:
        if current_level == null:
                return 0
        var ratio := get_line_ratio()
        # 1 star is awarded just for completion (handled by caller).
        if ratio <= current_level.star3_line_threshold:
                return 3
        if ratio <= current_level.star2_line_threshold:
                return 2
        return 1


# --- Signal handlers (forwarded from PhysicsController) ----------------------

func _on_player_reached_goal() -> void:
        if not sim_running or current_level == null:
                return
        line_used_on_win = line_drawer.get_total_length() if line_drawer else 0.0
        var stars := compute_stars()
        var coins_earned := 0
        if GameManager:
                coins_earned = GameManager.record_level_result(current_level.level_id, stars, line_used_on_win, attempts)
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.WIN)
        sim_running = false
        level_won.emit(stars, coins_earned, line_used_on_win)


func _on_player_in_hazard() -> void:
        if not sim_running:
                return
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.LOSE)
        sim_running = false
        level_lost.emit("هدف به خطر افتاد!")


func _on_time_expired() -> void:
        if not sim_running:
                return
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.LOSE)
        sim_running = false
        level_lost.emit("زمان تمام شد!")


func _on_player_out_of_bounds() -> void:
        if not sim_running:
                return
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.LOSE)
        sim_running = false
        level_lost.emit("هدف از صحنه خارج شد!")


func _on_line_length_changed(total: float) -> void:
        if current_level != null:
                line_budget_changed.emit(total, current_level.max_line_length)
