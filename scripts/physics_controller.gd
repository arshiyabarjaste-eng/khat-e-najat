## physics_controller.gd
## -----------------------------------------------------------------------------
## Owns the simulation: builds physics bodies from drawn lines, manages
## win/lose detection (via Area2D triggers), and resets state on retry.
##
## Each drawn line segment becomes a StaticBody2D with a SegmentShape2D.
## We use StaticBody2D (not RigidBody2D) so the drawn line is immovable,
## which gives predictable physics interactions and stable simulation.
## -----------------------------------------------------------------------------
extends Node2D
class_name PhysicsController

signal simulation_started()
signal simulation_stopped()
signal player_reached_goal()
signal player_entered_hazard()
signal time_expired()
signal player_left_bounds()

# Currently active physics bodies created from drawn lines.
var _line_bodies: Array[StaticBody2D] = []
# Player body (the rescue target).
var _player_body: RigidBody2D = null
# Goal area trigger.
var _goal_area: Area2D = null
# Hazard areas.
var _hazard_areas: Array[Area2D] = []
# Static walls/platforms/ground from level data.
var _static_bodies: Array[StaticBody2D] = []
# Visual sprites for objects.
var _visual_nodes: Array[Node2D] = []

# Simulation state.
var _sim_running: bool = false
var _player_initial_transform: Transform2D = Transform2D.IDENTITY
var _player_initial_velocity: Vector2 = Vector2.ZERO
var _player_initial_angular: float = 0.0
var _time_remaining: float = 0.0
var _has_time_limit: bool = false
var _world_node: Node2D = null


# --- Lifecycle ---------------------------------------------------------------

func _ready() -> void:
        set_physics_process(false)


func _physics_process(delta: float) -> void:
        if not _sim_running:
                return
        if _has_time_limit:
                _time_remaining -= delta
                if _time_remaining <= 0.0:
                        _time_remaining = 0.0
                        time_expired.emit()
                        stop_simulation()


# --- Setup -------------------------------------------------------------------

## Sets up the entire level scene from a LevelData resource.
## Cleans up any previous setup first.
func setup_level(level: LevelData, world_node: Node2D) -> void:
        teardown()
        _world_node = world_node
        # Apply gravity via the default physics area. We also set gravity_scale
        # on the player body as a fallback in case the server call fails.
        var default_area := PhysicsServer2D.area_get_default_area()
        if default_area.is_valid():
                PhysicsServer2D.area_set_param(default_area,
                        PhysicsServer2D.AREA_PARAM_GRAVITY, level.gravity)
        # Optional time limit.
        if level.time_limit > 0.0:
                _has_time_limit = true
                _time_remaining = level.time_limit
        else:
                _has_time_limit = false

        # Build static bodies for walls, platforms, ground.
        for obj in level.objects:
                _instantiate_object(obj, level)

        # Cache player's initial transform for reset.
        if _player_body != null:
                _player_initial_transform = _player_body.global_transform
                _player_initial_velocity = _player_body.linear_velocity
                _player_initial_angular = _player_body.angular_velocity


## Instantiates a single object from the level data dictionary.
func _instantiate_object(obj: Dictionary, level: LevelData) -> void:
        var obj_type: String = String(obj.get("type", ""))
        var pos: Vector2 = obj.get("position", Vector2.ZERO)
        var size: Vector2 = obj.get("size", Vector2(40, 40))
        var rot: float = float(obj.get("rotation", 0.0))
        var color: Color = obj.get("color", Color(0.5, 0.5, 0.5, 1.0))
        var label: String = String(obj.get("label", ""))

        match obj_type:
                "wall", "ground", "platform":
                        _make_static_rect(pos, size, rot, color, label, _world_node)
                "hazard":
                        _make_hazard(pos, size, rot, color, label)
                "goal":
                        _make_goal(pos, size, color, label)
                "ball", "cat", "crate", "player":
                        _make_player(obj, pos, size, color)
                _:
                        # Unknown — treat as static rect for safety.
                        _make_static_rect(pos, size, rot, color, label, _world_node)


func _make_static_rect(pos: Vector2, size: Vector2, rot_deg: float,
                color: Color, label: String, parent: Node) -> void:
        var body := StaticBody2D.new()
        body.position = pos
        body.rotation_degrees = rot_deg
        body.collision_layer = 0b00001   # world layer
        body.collision_mask = 0b11111    # collide with everything
        var shape := RectangleShape2D.new()
        shape.size = size
        var col := CollisionShape2D.new()
        col.shape = shape
        body.add_child(col)
        # Visual.
        var vis := ColorRect.new()
        vis.color = color
        vis.size = size
        # ColorRect's pivot isn't centered by default — anchor to top-left
        # of the rectangle's local space.
        vis.position = Vector2(-size.x / 2.0, -size.y / 2.0)
        vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
        body.add_child(vis)
        if not label.is_empty():
                var lbl := Label.new()
                lbl.text = label
                lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                lbl.position = Vector2(-size.x / 2.0, -8.0)
                lbl.add_theme_font_size_override("font_size", 14)
                body.add_child(lbl)
        parent.add_child(body)
        _static_bodies.append(body)


func _make_hazard(pos: Vector2, size: Vector2, rot_deg: float,
                color: Color, label: String) -> void:
        var area := Area2D.new()
        area.position = pos
        area.rotation_degrees = rot_deg
        area.collision_layer = 0b00100   # hazard layer
        area.collision_mask = 0b00010    # detect player
        area.monitoring = true
        area.monitorable = false
        var shape := RectangleShape2D.new()
        shape.size = size
        var col := CollisionShape2D.new()
        col.shape = shape
        area.add_child(col)
        # Visual.
        var vis := ColorRect.new()
        vis.color = color
        vis.size = size
        vis.position = Vector2(-size.x / 2.0, -size.y / 2.0)
        vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
        area.add_child(vis)
        if not label.is_empty():
                var lbl := Label.new()
                lbl.text = label
                lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                lbl.position = Vector2(-size.x / 2.0, -8.0)
                area.add_child(lbl)
        area.body_entered.connect(_on_hazard_body_entered)
        _world_node.add_child(area)
        _hazard_areas.append(area)


func _make_goal(pos: Vector2, size: Vector2, color: Color, label: String) -> void:
        var area := Area2D.new()
        area.position = pos + size / 2.0
        area.collision_layer = 0b01000   # goal layer
        area.collision_mask = 0b00010    # detect player
        area.monitoring = true
        area.monitorable = false
        var shape := RectangleShape2D.new()
        shape.size = size
        var col := CollisionShape2D.new()
        col.shape = shape
        area.add_child(col)
        # Visual.
        var vis := ColorRect.new()
        vis.color = color
        vis.size = size
        vis.position = Vector2(-size.x / 2.0, -size.y / 2.0)
        vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
        area.add_child(vis)
        if not label.is_empty():
                var lbl := Label.new()
                lbl.text = label
                lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                lbl.position = Vector2(-size.x / 2.0, -8.0)
                area.add_child(lbl)
        area.body_entered.connect(_on_goal_body_entered)
        _world_node.add_child(area)
        _goal_area = area


func _make_player(obj: Dictionary, pos: Vector2, size: Vector2, color: Color) -> void:
        # If we already have a player (multiple in level), warn and skip.
        if _player_body != null:
                push_warning("[PhysicsController] Multiple player objects in level; only the first will be tracked.")
                return
        var radius := float(obj.get("radius", min(size.x, size.y) / 2.0))
        var is_circle := radius > 0.0
        var body := RigidBody2D.new()
        # Position is the top-left of the rect for our convention; convert to center.
        body.position = pos + size / 2.0
        body.gravity_scale = 1.0
        body.linear_damp = 0.1
        body.angular_damp = 0.5
        body.contact_monitor = true
        body.max_contacts_reported = 4
        body.collision_layer = 0b00010   # player layer
        body.collision_mask = 0b11101    # collide with world + drawn lines + hazard + goal (not player)
        var col := CollisionShape2D.new()
        if is_circle:
                var s := CircleShape2D.new()
                s.radius = radius
                col.shape = s
        else:
                var s := RectangleShape2D.new()
                s.size = size
                col.shape = s
        body.add_child(col)
        # Visual.
        var vis := ColorRect.new()
        vis.color = color
        vis.size = size
        vis.position = Vector2(-size.x / 2.0, -size.y / 2.0)
        vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
        body.add_child(vis)
        _world_node.add_child(body)
        _player_body = body
        # Hook up "out of bounds" detection via body_exited_scene (we approximate
        # by checking global position each physics tick).
        _player_initial_transform = body.global_transform


# --- Line physics ------------------------------------------------------------

## Builds StaticBody2D segments from drawn strokes (called by gameplay.gd
## when the user presses "Start").
func build_line_physics(strokes: Array) -> void:
        for stroke in strokes:
                var pts: PackedVector2Array = stroke
                for i in range(1, pts.size()):
                        var a: Vector2 = pts[i - 1]
                        var b: Vector2 = pts[i]
                        _add_segment_body(a, b)


func _add_segment_body(a: Vector2, b: Vector2) -> void:
        var body := StaticBody2D.new()
        body.collision_layer = 0b10000   # drawn_line layer
        body.collision_mask = 0b00010    # collide with player
        var shape := SegmentShape2D.new()
        shape.a = a
        shape.b = b
        var col := CollisionShape2D.new()
        col.shape = shape
        body.add_child(col)
        _world_node.add_child(body)
        _line_bodies.append(body)


# --- Simulation control ------------------------------------------------------

func start_simulation() -> void:
        if _sim_running:
                return
        if _player_body == null:
                push_error("[PhysicsController] Cannot start simulation — no player body.")
                return
        _sim_running = true
        set_physics_process(true)
        # Wake up the player body (in case it slept during setup).
        _player_body.apply_central_impulse(Vector2.ZERO)
        _player_body.sleeping = false
        simulation_started.emit()


func stop_simulation() -> void:
        if not _sim_running:
                return
        _sim_running = false
        set_physics_process(false)
        if _player_body != null:
                _player_body.set_deferred("sleeping", true)
        simulation_stopped.emit()


func is_sim_running() -> bool:
        return _sim_running


func get_time_remaining() -> float:
        return _time_remaining


## Resets the player to its initial transform and zeroes out velocities.
func reset_to_initial() -> void:
        stop_simulation()
        if _player_body != null:
                # Use deferred calls to safely modify the body.
                _player_body.set_deferred("linear_velocity", Vector2.ZERO)
                _player_body.set_deferred("angular_velocity", 0.0)
                _player_body.set_deferred("global_transform", _player_initial_transform)
                _player_body.set_deferred("sleeping", false)
                _player_body.set_deferred("freeze", false)
        # Remove all line bodies (they were created from drawn strokes).
        for b in _line_bodies:
                if is_instance_valid(b):
                        b.queue_free()
        _line_bodies.clear()
        # Reset time limit if any.
        if _has_time_limit:
                # Will be reset on next setup_level — but for retry, we reset here.
                # We don't have the original time_limit cached, so caller must re-setup.
                pass


# --- Triggers ----------------------------------------------------------------

func _on_goal_body_entered(body: Node2D) -> void:
        if not _sim_running:
                return
        if body == _player_body:
                player_reached_goal.emit()
                stop_simulation()


func _on_hazard_body_entered(body: Node2D) -> void:
        if not _sim_running:
                return
        if body == _player_body:
                player_entered_hazard.emit()
                stop_simulation()


## Called by gameplay.gd's _process to check out-of-bounds.
func check_player_out_of_bounds(bounds: Rect2) -> bool:
        if _player_body == null:
                return false
        return not bounds.has_point(_player_body.global_position)


# --- Teardown ----------------------------------------------------------------

func teardown() -> void:
        stop_simulation()
        for b in _line_bodies:
                if is_instance_valid(b):
                        b.queue_free()
        _line_bodies.clear()
        for b in _static_bodies:
                if is_instance_valid(b):
                        b.queue_free()
        _static_bodies.clear()
        for a in _hazard_areas:
                if is_instance_valid(a):
                        a.queue_free()
        _hazard_areas.clear()
        if _goal_area != null and is_instance_valid(_goal_area):
                _goal_area.queue_free()
        _goal_area = null
        if _player_body != null and is_instance_valid(_player_body):
                _player_body.queue_free()
        _player_body = null
        _has_time_limit = false
        _time_remaining = 0.0
        if _world_node != null:
                for c in _world_node.get_children():
                        c.queue_free()
        _world_node = null
