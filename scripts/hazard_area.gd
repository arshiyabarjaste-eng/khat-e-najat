## hazard_area.gd
## -----------------------------------------------------------------------------
## Script for the hazard_area.tscn scene template. Like GoalArea, hazards are
## created procedurally by PhysicsController at runtime. This script is a
## placeholder for future extension (e.g. animated spike traps, lava effects).
## -----------------------------------------------------------------------------
extends Area2D
class_name HazardArea

signal hazard_triggered_by(body: Node2D)

@export var label: String = "خطر"
@export var hazard_color: Color = Color(0.65, 0.27, 0.22, 0.85)

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	hazard_triggered_by.emit(body)
