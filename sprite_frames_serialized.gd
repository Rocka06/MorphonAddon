class_name SpriteFramesSerialized extends SpriteFrames

func _serialize() -> Dictionary:
	return {"animations": get("animations")}
	
func _deserialize(data : Dictionary):
	set("animations", data["animations"])
