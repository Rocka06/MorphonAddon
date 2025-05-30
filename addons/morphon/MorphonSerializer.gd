@tool
class_name MorphonSerializer extends EditorPlugin

var _jsonTypes := [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_STRING_NAME]
var _registeredScripts : Dictionary[String, String]

func register_script(name : String, script : Script):
	if _registeredScripts.has(name):
		push_error("You have already registered a script named ", name)
		return
	
	_registeredScripts[name] = script.resource_path
func register_script_by_path(name : String, path : String):
	if _registeredScripts.has(name):
		push_error("You have already registered a script named ", name)
		return
	
	_registeredScripts[name] = path

func _SerializeRecursive(variant):
	if typeof(variant) in _jsonTypes:
		return variant
	
	if variant is Resource:
		var res := variant as Resource
		
		#Check if it is a custom resource or a built in one
		if res.get_class() == "Resource":
			return _SerializeResource(res)
	
		if !res.resource_local_to_scene:
			return res.resource_path
		
		return null
	
	if variant is Dictionary:
		var dict : Dictionary = variant
		var result : Dictionary
		var keys := dict.keys()
		
		for i in keys:
			result[i] = _SerializeRecursive(dict[i])
		
		return result
	
	if variant is Array:
		var arr : Array = variant
		var result : Array
		
		for i in arr:
			result.append(_SerializeRecursive(i))
			
		return result
	
	return JSON.from_native(variant)
func _DeserializeRecursive(variant):
	if variant is String:
		var str : String = variant
		if str.begins_with("res://"):
			if str.to_lower().ends_with(".gd") or str.to_lower().ends_with(".cs"):
				return null
			
			if _IsValidPath(str):
				return ResourceLoader.load(str)
		return variant
	
	if typeof(variant) in _jsonTypes:
		return variant
		
	if variant is Dictionary:
		var dict : Dictionary = variant
		var keys := dict.keys()
		var result : Dictionary
		
		if dict.has("type") and dict.has("args"):
			return JSON.to_native(dict)
		
		for i in keys:
			result[i] = _DeserializeRecursive(dict[i])
		
		if dict.has("._typeName"):
			return _DeserializeResource(result)
		
		return result
	
	if variant is Array:
		var arr : Array = variant
		var result : Array
		
		for i in arr:
			result.append(_DeserializeRecursive(i))
		
		return result
		
	return JSON.to_native(variant)

func _SerializeResource(res : Resource) -> Dictionary:
	var data : Dictionary
	
	if res.has_method("_serialize"):
		data = res._serialize()
	else:
		data = _GetResourceProperties(res)
	data = _SerializeRecursive(data)
	
	var scriptPath : String = res.get_script().resource_path
	
	data["._typeName"] = _registeredScripts.find_key(scriptPath)
	if data["._typeName"] == null:
		push_error("Script \"", scriptPath, "\" has not been registered! Register it with MorphonSerializer.RegisterScript(name, script)");
		return {}

	return data
func _DeserializeResource(dict : Dictionary):
	if dict.is_empty(): 
		return null
	
	if !dict.has("._typeName"):
		return null
	
	var scriptPath : String = _registeredScripts.find_key(dict["._typeName"])
	
	if scriptPath == null:
		push_error("Script name\"", dict["._typeName"], "\" has not been registered! Register it with MorphonSerializer.RegisterScript(name, script)");
		return null
	
	var script : Script = ResourceLoader.load(scriptPath)
	
	if !script:
		return null
	
	var res := Resource.new()
	res.set_script(script)
	
	if res.has_method("_deserialize"):
		res._deserialize(dict)
		return res
	
	var properties := _GetResourceProperties(res)
	var keys := properties.keys()
	for i in keys:
		if dict.has(i):
			res.set(i, dict[i])
	
	return res

func _IsValidPath(path : String) -> bool:
	if !path.begins_with("res://"):
		return false;

	if path.find("..") != -1:
		return false;

	var abs_path = ProjectSettings.globalize_path(path);
	var abs_root = ProjectSettings.globalize_path("res://");

	if !abs_path.begins_with(abs_root):
		return false;

	return true;
func _GetResourceProperties(res : Resource) -> Dictionary:
	var result : Dictionary
	var properties := res.get_property_list()
	
	for property in properties:
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result[property["name"]] = res.get(property["name"])
	
	return result
