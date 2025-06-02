# MorphonAddon

MorphonAddon is a library for [Godot](https://godotengine.org/) 4.x that provides safe serialization and deserialization for custom `Resource` objects.
It works in both GDScript and C#, and offers a similar API similar to Godot's built-in `ConfigFile`.

## Features

- **Custom Resource Serialization:** Serialize and deserialize custom `Resource` objects, including nested and array structures.
- **JSON-based Format:** Stores data in a human-readable JSON format.
- **Automatic Resource Registration:** Automatically scans and registers all custom `Resource` scripts in your project for safe serialization.
- **C# and GDScript Support:** Works with both scripting languages in Godot.

## How It Works

When creating a MorphonConfigFile, the addon scans your project for custom `Resource` scripts, and registers them for serialization.
When saving, object data is serialized to dictionaries, and when loading, resources are reconstructed with their original registered scripts and property values.

To serialize custom resources that extend built-in types (e.g., `SpriteFrames`), implement the following methods in your script:
```gdscript
func _serialize() -> Dictionary
func _deserialize(data: Dictionary)
```
```csharp
public Dictionary Serialize();
public void Deserialize(Dictionary data);
```

> **Note:** Built-in resources (like `SpriteFrames`) are not serialized directly. If they are not local to the scene, their resource path will be stored and reloaded.

## Usage

### GDScript Example

```gdscript
var config := MorphonConfigFile.new()
var animal := Animal.new()
animal.Name = "Doggo"
config.set_value("Pets", "Animal", animal)
config.save("user://save.json")

config.clear()
config.load("user://save.json")
var loaded_animal = config.get_value("Pets", "Animal")
```

### C# Example

```csharp
MorphonConfigFile config = new();
config.SetValue("Data", "Vehicles", vehicles);
config.Save("user://csharpSave.json");

config.Clear();
config.Load("user://csharpSave.json");

Vehicle[] loadedVehicles = config.GetValue<Array<Vehicle>>("Data", "Vehicles").ToArray();
```

### Reference vs Cloning

- `set_value` / `SetValue`: Stores a reference for that object; later changes to the object are reflected in the config.
- `set_cloned_value` / `SetClonedValue`: Stores a deep copy; later changes to the object do not affect the saved data.

## Installation

Copy the `addons/morphon` directory into your project's `addons` folder and you are all done!

## Limitations

- Built-in resources are not serialized directly, and they are only saved by their paths if they are not local to scene.
- Only scripts inheriting from `Resource` or implementing the required interface are fully supported for serialization.

## Documentation

For detailed API usage, refer to the code documentation in:
- `addons/morphon/MorphonConfigFile.gd`
- `addons/morphon/MorphonSerializer.gd`
- `addons/morphon/MorphonBindings.cs`

The API closely mirrors Godot's `ConfigFile`, making integration straightforward for existing projects.
