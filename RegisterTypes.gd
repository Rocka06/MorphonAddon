extends Node

func _ready() -> void:
	MorphonSerializer.register_script_by_path("Animal", "res://Animal.gd")
	MorphonSerializer.register_script_by_path("Dog", "res://Dog.gd")
