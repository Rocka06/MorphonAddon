class_name MorphonConfigFile extends RefCounted

var _values : Dictionary[String, Dictionary]

func set_value(section : String, key : String, value):
	if (value == null):
		#Erase key.
		if !_values.has(section):
			return

		_values[section].erase(key)
		if _values[section].is_empty():
			_values.erase(section)

		return

	if !_values.has(section):
		#Insert section-less keys at the beginning.
		_values[section] = {}

	_values[section][key] = value

func get_value(section : String, key : String, default = null):
	if !_values.has(section) or !_values[section].has(key):
		if default == null:
			push_error("Couldn't find the given section ", section, " and key ", key, ", and no default was given.")
		return default

	return _values[section][key]

func has_section(section : String) -> bool:
	return _values.has(section)

func has_section_key(section : String, key : String) -> bool:
	if !_values.has(section):
		return false
	return _values[section].has(key)

func get_sections() -> PackedStringArray:
	var array : PackedStringArray
	var keys := _values.keys()
	
	for i in keys:
		array.push_back(i)
	
	return array

func get_section_keys(section : String) -> PackedStringArray:
	var array : PackedStringArray

	if !_values.has(section):
		return array

	var keys := _values[section].keys()
	for i in keys:
		array.push_back(i)
	
	return array

func erase_section(section : String):
	if !_values.has(section):
		push_error("Cannot erase nonexistent section: ", section)
		return
	_values.erase(section)

func erase_section_key(section : String, key : String):
	if !_values.has(section):
		push_error("Cannot erase nonexistent section: ", section)
		return
		
	if !_values[section].has(key):
		push_error("Cannot erase nonexistent key: ", key)
		return
	
	_values[section].erase(key)
	if (_values[section].is_empty()):
		_values.erase(section)

func save(path : String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if !file:
		return FileAccess.get_open_error()

	file.store_string(encode_to_text())
	file.close()

	return OK

func load(path : String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)

	if !file:
		return FileAccess.get_open_error()

	var stringData := file.get_as_text()
	file.close()
	clear()

	return parse(stringData)

func encode_to_text() -> String:
	var dict : Dictionary
	
	var sectionKeys := _values.keys()
	for sectionKey in sectionKeys:
		var nestedDict : Dictionary
		
		var keys = _values[sectionKey].keys()
		for key in keys:
			nestedDict[key] = MorphonSerializer._SerializeRecursive(_values[sectionKey][key])
		
		dict[sectionKey] = nestedDict
	
	return JSON.stringify(dict)

func parse(data : String) -> Error:
	var json := JSON.new()
	var err := json.parse(data)

	if (err != OK):
		print("JSON Parse Error: ", err)
		return err

	var jsonVariant = json.get_data()

	if jsonVariant is not Dictionary:
		return ERR_INVALID_DATA

	clear()

	var dict : Dictionary = jsonVariant;
	var keys := dict.keys();
	
	for sectionKey in keys:
		if dict[sectionKey] is not Dictionary:
			clear()
			return ERR_INVALID_DATA
		
		var valueDict : Dictionary = dict[sectionKey]
		var valueKeys := valueDict.keys()
		
		for key in valueKeys:
			set_value(sectionKey, key, MorphonSerializer._DeserializeRecursive(valueDict[key]))
		
	return OK

func load_encrypted(path : String, key : PackedByteArray) -> Error:
	var file := FileAccess.open_encrypted(path, FileAccess.READ, key)

	if !file:
		return file.get_open_error()

	var stringData := file.get_as_text()
	file.close()
	clear()

	return parse(stringData)

func load_encrypted_pass(path : String, password : String) -> Error:
	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.READ, password)

	if !file:
		return file.get_open_error()

	var stringData : String = file.get_as_text()
	file.close()
	clear()

	return parse(stringData)
	
func save_encrypted(path : String, key : PackedByteArray) -> Error:
	var file := FileAccess.open_encrypted(path, FileAccess.WRITE, key)
	if !file:
		return file.get_open_error()

	file.store_string(encode_to_text())
	file.close()

	return OK

func save_encrypted_pass(path : String, password : String) -> Error:
	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, password)
	if !file:
		return file.get_open_error()

	file.store_string(encode_to_text())
	file.close()

	return OK

func clear():
	_values.clear()

func reload_from_serialized_copy():
	parse(encode_to_text())