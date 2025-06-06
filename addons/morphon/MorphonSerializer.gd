class_name MorphonSerializer

## Should automatic registration of scripts run?
static var Auto_Register_Custom_Resources := false
static var _autoRegRun := false

static var _jsonTypes := [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME]
static var _registeredScripts : Dictionary[String, String] = {}

static func _scan_and_register_resources():
	if !Auto_Register_Custom_Resources:
		return
	if _autoRegRun:
		return
	
	_autoRegRun = true
	
	var classes := ProjectSettings.get_global_class_list()
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
			register_script_by_path(name, path)

## Register a [Script] for serialization.
## If the name was already registered the function will throw an error. 
static func register_script(name : String, script : Script):
	if _registeredScripts.has(name):
		push_error("You have already registered a script named ", name)
		return
	
	_registeredScripts[name] = script.resource_path

## Register a [Script] for serialization by it's path.
## If the name was already registered the function will throw an error. 
static func register_script_by_path(name : String, path : String):
	if _registeredScripts.has(name):
		push_error("You have already registered a script named ", name)
		return
	
	_registeredScripts[name] = path

## Converts a [Variant] to a formatted [String] that can then be parsed using [method MorphonSerializer.str_to_var].
## [codeblock]
## var a = { "a": 1, "b": 2 }
## print(var_to_str(a))
## [/codeblock]
## [codeblock]
## {
## 	"a": 1,
## 	"b": 2
## }
## [/codeblock]
static func var_to_str(variant) -> String:
	_scan_and_register_resources()
	return var_to_str(_SerializeRecursive(variant))

## Encodes a [Variant] value to a [PackedByteArray]. Deserialization can be done with [method MorphonSerializer.bytes_to_var].
static func var_to_bytes(variant) -> PackedByteArray:
	_scan_and_register_resources()
	return var_to_bytes(_SerializeRecursive(variant))

## Converts a formatted string that was returned by [method MorphonSerializer.var_to_str] to the original [Variant]
## [codeblock]
## var data = '{ "a": 1, "b": 2 }' # data is a String
## var dict = str_to_var(data)     # dict is a Dictionary
## print(dict["a"])                # Prints 1
##[/codeblock]
static func str_to_var(str : String) -> Variant:
	_scan_and_register_resources()
	return _DeserializeRecursive(str_to_var(str))

## Decodes a [PackedByteArray] back to a [Variant] value.
static func bytes_to_var(bytes : PackedByteArray) -> Variant:
	_scan_and_register_resources()
	return _DeserializeRecursive(bytes_to_var(bytes))

static func _SerializeRecursive(variant):
	if typeof(variant) in _jsonTypes:
		return variant
	
	if variant is Resource:
		var res := variant as Resource
		
		if res.has_method("_serialize") and res.has_method("_deserialize"):
			return _SerializeResource(res)
		
		if !_GetResourceProperties(res).is_empty():
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
		
		if _IsValidPath(str):
			return ResourceLoader.load(str)
		
		return str
	
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
	_scan_and_register_resources()
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
static func _DeserializeResource(dict : Dictionary) -> Resource:
	_scan_and_register_resources()
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
	
	var res := ClassDB.instantiate(script.get_instance_base_type())
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
		return false

	if path.find("..") != -1:
		return false

	var abs_path = ProjectSettings.globalize_path(path)
	var abs_root = ProjectSettings.globalize_path("res://")

	if !abs_path.begins_with(abs_root):
		return false
		
	if path.to_lower().ends_with(".gd") or path.to_lower().ends_with(".cs"):
		return false

	return true
static func _GetResourceProperties(res : Resource) -> Dictionary:
	var result : Dictionary
	var properties := res.get_property_list()
	
	for property in properties:
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result[property["name"]] = res.get(property["name"])
	
	return result
