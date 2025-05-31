extends Node

@export var AnimalList : Array[Animal]
@export var Icon : Texture2D

func _ready() -> void:
	var config := MorphonConfigFile.new()
	
	var referencedDog := Dog.new()
	var clonedDog := Dog.new()
	
	referencedDog.Name = "Doggo"
	clonedDog.Name = "Bruno"
	
	config.set_value("Pets", "AnimalList", AnimalList)
	config.set_value("Player", "Health", 31.2)
	config.set_value("Player", "Icon", Icon)
	config.set_value("Test", "referencedDog", referencedDog)
	config.set_cloned_value("Test", "clonedDog", clonedDog)
	
	referencedDog.Name = "Rewritten"
	clonedDog.Name = "Rewritten"
	
	config.save("user://save.json")
	config.clear()
	
	config.load("user://save.json")
	$Sprite2D.texture = config.get_value("Player", "Icon")
	
	print(config.get_value("Player", "Health"))
	for i in config.get_value("Pets", "AnimalList") as Array[Animal]:
		i.speak()
		print(i.Name)
		print(i.Age)
