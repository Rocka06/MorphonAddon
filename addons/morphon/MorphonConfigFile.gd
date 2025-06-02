class_name MorphonConfigFile extends RefCounted

## A helper class for MorphonSerializer that can create and read JSON-style
## files with properly serialized [Resource] objects
##
## MorphonConfigFile works almost the exact same way as the built-in [ConfigFile] class
## but with one huge exception. It safely serializes custom Resource objects and saves it
## in JSON format.[br][br]
## [b]But how does it work?[/b][br]
## When you initialize a MorphonConfigFile, the addon maps the whole project,
## gets your custom [Resource] scripts and stores the path and name of these in a dictionary.
## This dictionary is then used for safe serialization and deserialization of your objects.[br][br]
## If your script extends a built-in resource and not the base [Resource] class 
## (for example [SpriteFrames]) and you want it to be serialized, you will need to implement
## [code]func _serialize() -> Dictionary[/code] and [code]func _deserialize(data : Dictionary)[/code]
## in your resource. [br][br]
## The addon also works with [b]C#[/b]![br][br]
## [b]Important[/b][br]
## This addon can't serialize Built-in Resources like [SpriteFrames].
## What it can do is that if that resource is not local to scene, it will save it's path,
## and later reload it.[br]
## Every object value is stored by reference, so if you modify it after [code]set_value[/code],
## it will be modified inside the MorphonConfigFile. If you don't want this, use [method set_cloned_value].
## This way it will store a copy of the object.[br][br]
## For additional information, go check out the [ConfigFile] documentation.

var _values : Dictionary[String, Dictionary]

func _init() -> void:
	MorphonSerializer._scan_and_register_resources()

## Assigns a value to the specified key of the specified section.[br]
## If either the section or the key do not exist, they are created. [br]
## Passing a [code]null[/code] value deletes the specified key if it exists, and deletes the section if it ends up empty once the key has been removed.
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

## Works the same as [code]set_value()[/code] but sets a cloned value of [code]value[/code].[br]
## Useful for objects where you don't want the object inside the [b]MorphonConfigFile[/b] to change.
func set_cloned_value(section : String, key : String, value):
	#The reason I wrote it this way is because .duplicate
	#doesn't always work
	
	var serialized = MorphonSerializer._SerializeRecursive(value)
	var deserialized = MorphonSerializer._DeserializeRecursive(serialized)
	
	set_value(section, key, deserialized)

## Returns the current value for the specified section and key. If either the section or the key do not exist, the method returns the fallback [code]default[/code] value. If [code]default[/code] is not specified or set to [code]null[/code], an error is also raised.
func get_value(section : String, key : String, default = null):
	if !_values.has(section) or !_values[section].has(key):
		if default == null:
			push_error("Couldn't find the given section ", section, " and key ", key, ", and no default was given.")
		return default

	return _values[section][key]

## Returns [code]true[/code] if the specified section exists.
func has_section(section : String) -> bool:
	return _values.has(section)

## Returns [code]true[/code] if the specified section-key pair exists.
func has_section_key(section : String, key : String) -> bool:
	if !_values.has(section):
		return false
	return _values[section].has(key)

## Returns an array of all defined section identifiers.
func get_sections() -> PackedStringArray:
	var array : PackedStringArray
	var keys := _values.keys()
	
	for i in keys:
		array.push_back(i)
	
	return array

## Returns an array of all defined key identifiers in the specified section. Raises an error and returns an empty array if the section does not exist.
func get_section_keys(section : String) -> PackedStringArray:
	var array : PackedStringArray

	if !_values.has(section):
		return array

	var keys := _values[section].keys()
	for i in keys:
		array.push_back(i)
	
	return array

## Deletes the specified section along with all the key-value pairs inside. Raises an error if the section does not exist.
func erase_section(section : String):
	if !_values.has(section):
		push_error("Cannot erase nonexistent section: ", section)
		return
	_values.erase(section)

## Deletes the specified key in a section. Raises an error if either the section or the key do not exist.
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

## Saves the contents of the [b]MorphonConfigFile[/b] object to the file specified as a parameter. The output file uses a JSON-style structure.
## [br][br]
## Returns [constant OK] on success, or one of the other [enum Error] values if the operation failed.
func save(path : String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if !file:
		return FileAccess.get_open_error()

	file.store_string(encode_to_text())
	file.close()

	return OK

## Loads the config file specified as a parameter. The file's contents are parsed and loaded in the MorphonConfigFile object which the method was called on.
## [br][br]
## Returns [constant OK] on success, or one of the other [enum Error] values if the operation failed.
func load(path : String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)

	if !file:
		return FileAccess.get_open_error()

	var stringData := file.get_as_text()
	file.close()
	clear()

	return parse(stringData)

## Obtain the text version of this config file (the same text that would be written to a file).
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

## Parses the passed string as the contents of a config file. The string is parsed and loaded in the MorphonConfigFile object which the method was called on.
## [br][br]
## Returns [constant OK] on success, or one of the other [enum Error] values if the operation failed.
func parse(data : String) -> Error:
	var json := JSON.new()
	var err := json.parse(data)

	if (err != OK):
		print("JSON Parse Error: ", err)
		return err

	var jsonVariant = json.get_data()

	if jsonVariant is not Dictionary:
		return ERR_INVALID_DATA

	var dict : Dictionary = jsonVariant;
	var keys := dict.keys();
	
	# Check data before writing it to the object
	for sectionKey in keys:
		if dict[sectionKey] is not Dictionary:
			return ERR_INVALID_DATA
	
	for sectionKey in keys:
		var valueDict : Dictionary = dict[sectionKey]
		var valueKeys := valueDict.keys()
		
		for key in valueKeys:
			set_value(sectionKey, key, MorphonSerializer._DeserializeRecursive(valueDict[key]))
		
	return OK

## Loads the encrypted config file specified as a parameter, using the provided key to decrypt it. The file's contents are parsed and loaded in the MorphonConfigFile object which the method was called on.
## [br][br]
## Returns [constant OK] on success, or one of the other [enum Error] values if the operation failed.
func load_encrypted(path : String, key : PackedByteArray) -> Error:
	var file := FileAccess.open_encrypted(path, FileAccess.READ, key)

	if !file:
		return file.get_open_error()

	var stringData := file.get_as_text()
	file.close()
	clear()

	return parse(stringData)

## Loads the encrypted config file specified as a parameter, using the provided [code]password[/code] to decrypt it. The file's contents are parsed and loaded in the MorphonConfigFile object which the method was called on.
## [br][br]
## Returns [constant OK] on success, or one of the other [enum Error] values if the operation failed.
func load_encrypted_pass(path : String, password : String) -> Error:
	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.READ, password)

	if !file:
		return file.get_open_error()

	var stringData : String = file.get_as_text()
	file.close()
	clear()

	return parse(stringData)

## Saves the contents of the [b]MorphonConfigFile[/b] object to the AES-256 encrypted file specified as a parameter, using the provided [code]key[/code] to encrypt it. The output file uses a JSON-style structure.
## [br][br]
## Returns [constant OK] on success, or one of the other [enum Error] values if the operation failed.
func save_encrypted(path : String, key : PackedByteArray) -> Error:
	var file := FileAccess.open_encrypted(path, FileAccess.WRITE, key)
	if !file:
		return file.get_open_error()

	file.store_string(encode_to_text())
	file.close()

	return OK

## Saves the contents of the [b]MorphonConfigFile[/b] object to the AES-256 encrypted file specified as a parameter, using the provided [b]password[/b] to encrypt it. The output file uses a JSON-style structure.
## [br][br]
## Returns [constant OK] on success, or one of the other [enum Error] values if the operation failed.
func save_encrypted_pass(path : String, password : String) -> Error:
	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, password)
	if !file:
		return file.get_open_error()

	file.store_string(encode_to_text())
	file.close()

	return OK

## Removes the entire contents of the config.
func clear():
	_values.clear()
