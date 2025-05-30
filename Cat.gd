class_name Cat extends Animal

@export var color : Color

func speak():
	print("meow")
	print(color)

func _serialize() -> Dictionary:
	return {"color": color}
	
func _deserialize(data : Dictionary):
	color = data["color"]
