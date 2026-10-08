## level_object.gd
## -----------------------------------------------------------------------------
## Script for the level_object.tscn scene template. Provides a small base
## API for objects instantiated from level data: store metadata, expose
## type/label/color, and a reset hook for retry.
## -----------------------------------------------------------------------------
extends StaticBody2D
class_name LevelObject

@export var object_type: String = "wall"
@export var label: String = ""
@export var tint: Color = Color(0.42, 0.36, 0.30, 1.0)

var _initial_transform: Transform2D = Transform2D.IDENTITY


func _ready() -> void:
	_initial_transform = global_transform


func reset() -> void:
	global_transform = _initial_transform
