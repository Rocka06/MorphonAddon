extends Node

func _ready() -> void:
	_scan_and_register_resources()

func _scan_and_register_resources(path := "res://"):
	var dir = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path = path.path_join(file_name)

		if dir.current_is_dir():
			_scan_and_register_resources(full_path)
		elif file_name.ends_with(".gd") or file_name.ends_with(".cs"):
			var script = load(full_path) as Script
			var name = file_name.get_basename()
			if script and script.get_instance_base_type() == "Resource":
				MorphonSerializer.register_script(name, script)
			elif script.has_method("_serialize") and script.has_method("_deserialize"):
				MorphonSerializer.register_script(name, script)

		file_name = dir.get_next()
	dir.list_dir_end()
