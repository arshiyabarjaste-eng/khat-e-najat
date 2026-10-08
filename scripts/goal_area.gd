## goal_area.gd
## -----------------------------------------------------------------------------
## Script for the goal_area.tscn scene template. In the current implementation,
## goal areas are created procedurally by PhysicsController at runtime from
## the level JSON data. This script is provided as a placeholder for future
## extension (e.g. custom animations, sound triggers, or alternative visuals).
## -----------------------------------------------------------------------------
extends Area2D
class_name GoalArea

signal goal_reached_by(body: Node2D)

@export var label: String = "مقصد"
@export var highlight_color: Color = Color(0.35, 0.55, 0.25, 0.8)

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	goal_reached_by.emit(body)
