extends Node

@export var AnimalList : Array[Animal]
@export var Icon : Texture2D

func _ready() -> void:
	var config := MorphonConfigFile.new()
	
	config.set_value("Pets", "AnimalList", AnimalList)
	config.set_value("Player", "Health", 31.2)
	config.set_value("Player", "Icon", Icon)
	
	config.save("user://save.json")
	config.clear()
	
	config.load("user://save.json")
	$Sprite2D.texture = config.get_value("Player", "Icon")
	
	print(config.get_value("Player", "Health"))
	for i in config.get_value("Pets", "AnimalList") as Array[Animal]:
		i.speak()
		print(i.Name)
		print(i.Age)
