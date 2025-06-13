@tool
extends EditorPlugin

var button

func _enter_tree() -> void:
	add_tool_menu_item("Generate Morphon Registerer Script", Callable(self, "_on_button_pressed"))
func _exit_tree() -> void:
	remove_tool_menu_item("Generate Morphon Registerer Script")

func _on_button_pressed():
	var classes := _scan_resources()
	var path = "res://addons/morphon/MorphonGeneratedRegisterer.gd"
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if !file:
		push_error("Failed to write script.")
		return
	
	var str : String = "extends Node\n\nfunc _init():"
	for i in classes.keys():
		str += "\n\tMorphonSerializer.register_script_by_path(\"" + i + "\",\"" + classes[i] + "\")"
	
	file.store_string(str)
	file.close()

	print("Script created at %s" % path)
	_register_autoload("_morphonRegisterer", path)

func _scan_resources() -> Dictionary[String, String]:
	var classes := ProjectSettings.get_global_class_list()
	var ret : Dictionary[String, String]
	
	for classDict in classes:
		var name : String = classDict["class"]
		var path : String = classDict["path"]
		var isAbstract : bool = classDict["is_abstract"]
		
		if isAbstract:
			continue
		
		if name == "MorphonSerializer" or name == "MorphonConfigFile":
			continue
		
		var script : Script = load(path)
		var instance := ClassDB.instantiate(script.get_instance_base_type())
		
		if instance is Resource:
			ret[name] = path
	
	return ret

func _register_autoload(name: String, path: String):
	if ProjectSettings.has_setting("autoload/" + name): 
		return
	
	ProjectSettings.set_setting("autoload/" + name, path)
	ProjectSettings.save()
	print("Autoload '%s' added. Go into 'Project -> Project Settings -> Globals' and enable it" % name)
