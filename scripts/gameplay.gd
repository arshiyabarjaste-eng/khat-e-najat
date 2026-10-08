## gameplay.gd
## -----------------------------------------------------------------------------
## Root script for the gameplay scene. Owns:
##   - World (Node2D): contains all level objects + drawn line physics
##   - LineDrawer (Node2D, child of World): captures input, renders preview
##   - PhysicsController (Node2D, child of World): builds physics, runs sim
##   - LevelManager (Node): coordinates level data <-> physics/drawer
##   - UIManager (CanvasLayer): on-screen UI + win/lose dialogs
##
## State machine:
##   BOOT → DRAW (user draws lines) → SIM (physics running) → WIN/LOSE → (retry or next)
## -----------------------------------------------------------------------------
extends Node2D
class_name GameplayScene

# Child references (assigned in gameplay.tscn).
@onready var world: Node2D = $World
@onready var line_drawer: LineDrawer = $World/LineDrawer
@onready var physics: PhysicsController = $World/PhysicsController
@onready var level_manager: LevelManager = $LevelManager
@onready var ui_manager: UIManager = $UIManager
@onready var background: ColorRect = $Background

# Tutorial reference (set by main menu if first-time).
var show_tutorial: bool = false


func _ready() -> void:
	# Wire LevelManager to its dependencies.
	level_manager.physics = physics
	level_manager.line_drawer = line_drawer
	level_manager.world_node = world

	# Connect LevelManager signals.
	level_manager.level_loaded.connect(_on_level_loaded)
	level_manager.level_won.connect(_on_level_won)
	level_manager.level_lost.connect(_on_level_lost)
	level_manager.attempt_counted.connect(_on_attempt)
	level_manager.line_budget_changed.connect(_on_line_budget_changed)
	level_manager.sim_state_changed.connect(_on_sim_state_changed)

	# Connect UI handlers (UIManager forwards button presses to us).
	# UIManager calls `owner._on_ui_*()` directly.

	# Determine which level to load.
	var level_num := 1
	if not GameManager.current_level_id.is_empty():
		level_num = _parse_level_number(GameManager.current_level_id)
	GameManager.current_state = GameManager.GameState.GAMEPLAY_DRAW

	# Load the level.
	level_manager.load_level(level_num)

	# Setup UI exclusion rects so drawing doesn't happen over buttons.
	# Deferred to next idle frame so the UI layout has been computed.
	call_deferred("_setup_exclusion_rects")

	# Hook audio settings.
	if AudioManager:
		AudioManager.play_music()

	# Tutorial (first time only).
	if not SaveManager.is_tutorial_shown():
		show_tutorial = true
		# For brevity, we just mark it shown — full tutorial overlay can be added later.
		SaveManager.mark_tutorial_shown()
		SaveManager.save_async()


func _exit_tree() -> void:
	# Ensure physics is stopped before leaving.
	if level_manager and is_instance_valid(level_manager):
		if level_manager.physics and is_instance_valid(level_manager.physics):
			level_manager.physics.stop_simulation()


# --- Per-frame processing ---------------------------------------------------

func _process(delta: float) -> void:
	# Update timer display if simulation is running.
	if level_manager.sim_running and level_manager.physics:
		ui_manager.update_timer(level_manager.physics.get_time_remaining())
		# Check OOB.
		level_manager.check_out_of_bounds()


func _setup_exclusion_rects() -> void:
	if line_drawer and ui_manager:
		var rects := ui_manager.get_ui_exclusion_rects()
		# Convert screen-space rects to local LineDrawer space.
		# LineDrawer is a child of world (which has identity transform in our setup).
		for r in rects:
			# Since line_drawer.to_local(screen_pos) maps screen->local,
			# the rects must be compared in screen space. We do that in
			# the input handler, so pass them as screen-space.
			line_drawer.add_exclusion_rect(r)


# --- Signal handlers --------------------------------------------------------

func _on_level_loaded(level: LevelData) -> void:
	if background:
		background.color = level.background_color
	ui_manager.setup_for_level(level)


func _on_level_won(stars: int, coins_earned: int, line_used: float) -> void:
	GameManager.current_state = GameManager.GameState.WIN
	GameManager.last_level_result = {
		"stars": stars,
		"coins_earned": coins_earned,
		"line_used": line_used,
		"attempts": level_manager.attempts,
		"won": true,
	}
	ui_manager.show_win(stars, coins_earned)


func _on_level_lost(reason: String) -> void:
	GameManager.current_state = GameManager.GameState.LOSE
	GameManager.last_level_result = {
		"stars": 0,
		"coins_earned": 0,
		"line_used": line_drawer.get_total_length() if line_drawer else 0.0,
		"attempts": level_manager.attempts,
		"won": false,
	}
	ui_manager.show_lose(reason)


func _on_attempt(count: int) -> void:
	# Save attempts counter if user later wins.
	pass


func _on_line_budget_changed(used: float, max_val: float) -> void:
	ui_manager.update_line_progress(used, max_val)


func _on_sim_state_changed(running: bool) -> void:
	ui_manager.set_simulation_mode(running)
	if running:
		GameManager.current_state = GameManager.GameState.GAMEPLAY_SIM
	else:
		# If we're stopping without a win/lose already emitted, allow drawing again.
		if GameManager.current_state != GameManager.GameState.WIN and \
		   GameManager.current_state != GameManager.GameState.LOSE:
			GameManager.current_state = GameManager.GameState.GAMEPLAY_DRAW


# --- UI button handlers (called by UIManager via owner) ----------------------

func _on_ui_start() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	level_manager.start_simulation()


func _on_ui_clear() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	level_manager.clear_lines()


func _on_ui_retry() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	# If a win/lose panel was shown, hide it first.
	ui_manager.win_panel.visible = false
	ui_manager.lose_panel.visible = false
	level_manager.retry_level()
	GameManager.current_state = GameManager.GameState.GAMEPLAY_DRAW


func _on_ui_undo() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	level_manager.undo_last_line()


func _on_ui_back() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	GameManager.current_state = GameManager.GameState.LEVEL_SELECT
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _on_ui_hint() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	if level_manager.current_level != null:
		ui_manager.show_hint(level_manager.current_level.hint)


func _on_ui_win_next() -> void:
	if AudioManager:
		AudioManager.play_sfx(AudioManager.SFX.BUTTON)
	var current_num := level_manager.current_level_number
	var next_num := GameManager.get_next_level_number(current_num)
	if next_num > 0:
		GameManager.start_level(next_num)
	else:
		# No more levels — go back to main menu.
		GameManager.current_state = GameManager.GameState.MAIN_MENU
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# --- Helpers ----------------------------------------------------------------

func _parse_level_number(level_id: String) -> int:
	if level_id.begins_with("level_"):
		return int(level_id.substr(6))
	return 1
