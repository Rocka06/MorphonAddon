extends Node

func _init():
	MorphonSerializer.register_script_by_path("Animal","res://Animal.gd")
	MorphonSerializer.register_script_by_path("Car","res://CSharpTest/Car.cs")
	MorphonSerializer.register_script_by_path("Cat","res://Cat.gd")
	MorphonSerializer.register_script_by_path("Dog","res://Dog.gd")
	MorphonSerializer.register_script_by_path("SpriteFramesSerialized","res://sprite_frames_serialized.gd")
	MorphonSerializer.register_script_by_path("Vehicle","res://CSharpTest/Vehicle.cs")