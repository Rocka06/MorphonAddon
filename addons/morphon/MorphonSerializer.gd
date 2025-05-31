class_name MorphonSerializer

static var _jsonTypes := [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME]
static var _registeredScripts : Dictionary[String, String]

static var _autoRegRun := false

static func _scan_and_register_resources(path := "res://"):
	if _autoRegRun:
		return
		
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
				register_script(name, script)
			elif script.has_method("_serialize") and script.has_method("_deserialize"):
				register_script(name, script)

		file_name = dir.get_next()
	dir.list_dir_end()

static func register_script(name : String, script : Script):
	if _registeredScripts.has(name):
		push_error("You have already registered a script named ", name)
		return
	
	_registeredScripts[name] = script.resource_path
static func register_script_by_path(name : String, path : String):
	if _registeredScripts.has(name):
		push_error("You have already registered a script named ", name)
		return
	
	_registeredScripts[name] = path

static func _SerializeRecursive(variant):
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
static func _DeserializeRecursive(variant):
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
			#We dont want to deserialize this
			if i == "._typeName":
				result[i] = dict[i]
				continue
			
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

static func _SerializeResource(res : Resource) -> Dictionary:
	var data : Dictionary
	
	if res.has_method("_serialize"):
		data = res._serialize()
	else:
		data = _GetResourceProperties(res)
	data = _SerializeRecursive(data)
	
	var scriptPath : String = res.get_script().resource_path
	
	if _registeredScripts.find_key(scriptPath) == null:
		push_error("Script \"", scriptPath, "\" has not been registered! Register it with MorphonSerializer.RegisterScript(name, script)");
		return {}

	data["._typeName"] = _registeredScripts.find_key(scriptPath)
	return data
static func _DeserializeResource(dict : Dictionary):
	if dict.is_empty(): 
		return null
	
	if !dict.has("._typeName"):
		return null
	
	if !_registeredScripts.has(dict["._typeName"]):
		push_error("Script name\"", dict["._typeName"], "\" has not been registered! Register it with MorphonSerializer.RegisterScript(name, script)");
		return null
	
	var scriptPath : String = _registeredScripts[dict["._typeName"]]
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

static func _IsValidPath(path : String) -> bool:
	if !path.begins_with("res://"):
		return false;

	if path.find("..") != -1:
		return false;

	var abs_path = ProjectSettings.globalize_path(path);
	var abs_root = ProjectSettings.globalize_path("res://");

	if !abs_path.begins_with(abs_root):
		return false;

	return true;
static func _GetResourceProperties(res : Resource) -> Dictionary:
	var result : Dictionary
	var properties := res.get_property_list()
	
	for property in properties:
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result[property["name"]] = res.get(property["name"])
	
	return result
