# MorphonAddon

[![Godot 4.4+](https://img.shields.io/badge/Godot-4.4%2B-blue.svg)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

MorphonAddon is a **safe serialization library for Godot 4.4+** that works with both GDScript and C#. It lets you serialize and deserialize custom `Resource` objects (including nested and array structures) to human-readable JSON, with an API similar to Godot's built-in `ConfigFile` but without the risk of code injection.

> **Why?**  
> Godot’s built-in object serialization methods can execute arbitrary code during deserialization, posing security risks. MorphonAddon avoids this by safely reconstructing only registered custom Resources, keeping your data and users secure.

---

## Features

- **Safely serialize custom Resource objects:** Serialize and deserialize custom `Resource` objects into dictionaries, including nested and array structures, without the fear of code injections
- **JSON-based Format:** Stores data in a human-readable JSON format
- **Works out of the box:** You don't have to add any autoloads, or turn on any addons. Just copy the files into your project and you're good to go!
- **C# and GDScript Support:** Works perfectly with both scripting languages in Godot

---

## How It Works

When you create a MorphonConfigFile, the addon scans your project for custom `Resource` scripts and registers them for serialization.  
- **Saving:** Object data is converted to dictionaries.
- **Loading:** Objects are rebuilt with the correct script and property values.

> **Note:** Built-in resources (like `SpriteFrames`) are not serialized directly. If not local to the scene, only their path is stored and reloaded.

---

### Custom Serialization

To control which properties are saved, you will have to implement these methods in your script:

**GDScript**
```gdscript
func _serialize() -> Dictionary
func _deserialize(data: Dictionary)
```
**C#**
```csharp
public Dictionary _serialize();
public void _deserialize(Dictionary data);
```

In the `_serialize` method you have to return a Dictionary with a string key and a value of the property you want to be saved.
In the `_deserialize` method you have to read the properties back into your objects.

<details>
  <summary>GDScript Example</summary>

  ```gdscript
  class_name Cat extends Resource

  @export var name : String
  @export var age : int
  @export var color : Color

  func _serialize() -> Dictionary:
      return {"color": color}

  func _deserialize(data : Dictionary):
      color = data["color"]
  ```
  In this case only the `color` property will be saved.
</details>

#### This way you can also serialize built-in resources, for example SpriteFrames:

```gdscript

class_name SpriteFramesSerialized extends SpriteFrames

func _serialize() -> Dictionary:
	return {"animations": get("animations")}
	
func _deserialize(data : Dictionary):
	set("animations", data["animations"])
```

The saved data will look something like this:

```json
{
	"._typeName": "SpriteFramesSerialized",
	"animations": [
	{
	    "frames": [
		{
		    "duration": 1.0,
		    "texture": "res://node_2d.tscn::AtlasTexture_ir8iy"
		},
		{
		    "duration": 1.0,
		    "texture": "res://node_2d.tscn::AtlasTexture_hqns4"
		},
		{
		    "duration": 1.0,
		    "texture": "res://node_2d.tscn::AtlasTexture_x0ka3"
		},
		{
		    "duration": 1.0,
		    "texture": "res://node_2d.tscn::AtlasTexture_0h7mo"
		},
		{
		    "duration": 1.0,
		    "texture": "res://node_2d.tscn::AtlasTexture_nr8wp"
		},
		{
		    "duration": 1.0,
		    "texture": "res://node_2d.tscn::AtlasTexture_d2bti"
		}
	    ],
	    "loop": true,
	    "name": "default",
	    "speed": 5.0
	}
	]
}
```

---

### Resource Serialization Details

When serializing resources, the following logic is applied:

- **Custom Serialization Methods**:  
  If a resource implements `_serialize` and `_deserialize`, these methods will be used for serialization and deserialization.

- **Script Properties**:  
  If the resource has script properties, those properties will be serialized.

- **Resource Path Fallback**:  
  If neither of the above applies, the resource will be saved by its path but only if it is not local to the scene.

- **Limitation**:  
  If the resource is local to the scene and none of the above conditions are met, the resource cannot be serialized.

---

## Usage of MorphonConfigFile

<details>
<summary>GDScript example</summary>
First let's create a custom Resource script:
    
```gdscript
class_name Animal extends Resource

@export var Name : String
@export var Age : int

func speak:
	print("speak")
```

And then let's create a class named Cat that extends Animal:

```gdscript
class_name Cat extends Animal

@export var color : Color

func speak():
	print("meow")
```

Now lets save it with a MorphonConfigFile!
Actually, lets save a whole array of Animals!

```gdscript
extends Node

@export var AnimalList : Array[Animal]

func _ready() -> void:
	var config := MorphonConfigFile.new()
	config.set_value("Player", "Pets", AnimalList)
	config.save("user://save.json")
	  
	config.clear()
	config.load("user://save.json")
	
	for i in config.get_value("Player", "Pets") as Array[Animal]:
		i.speak()
		print(i.Name)
		print(i.Age)
```

After adding some animals to the array from the editor and running the code, we get this in the output:
  
```
speak
Dog
7
meow
Kitty
1
```

And the save file looks like this:
```json
{
    "Player": {
        "Pets": [
            {
                "._typeName": "Animal",
                "Age": 7,
                "Name": "Dog"
            },
            {
                "._typeName": "Cat",
                "Age": 1,
                "Name": "Kitty",
                "color": {
                    "args": [
                        1.0,
                        1.0,
                        0.482353001832962,
                        1.0
                    ],
                    "type": "Color"
                }
            }
        ]
    }
}
```

</details>

<details>
<summary>C# example</summary>
First let's create a custom Resource script:
    
```csharp
using Godot;

[GlobalClass]
public partial class Vehicle : Resource
{
    [Export] public string brand;
    [Export] public Color color;

    public override string ToString()
    {
        return $"{brand}: {color}";
    }
}
```

And then let's create a class named Car that inherits from Vehicle:

```csharp
using Godot;

[GlobalClass]
public partial class Car : Vehicle
{
    [Export] public int year;

    public override string ToString()
    {
        return $"{brand}: {color}, {year}";
    }
}
```

Now lets save an array of Vehicles with a MorphonConfigFile!

```csharp
using System.Linq;
using Godot;
using Godot.Collections;

public partial class TestCsharp : Node
{
    [Export] Vehicle[] vehicles;

    public override void _Ready()
    {
        MorphonConfigFile config = new();

        config.SetValue("Data", "Vehicles", vehicles);
        config.Save("user://csharpSave.json");

        config.Clear();
        config.Load("user://csharpSave.json");

        Vehicle[] loadedVehicles = config.GetValue("Data", "Vehicles").AsGodotObjectArray<Vehicle>();

        foreach (Vehicle vehicle in loadedVehicles)
        {
            GD.Print(vehicle.ToString());
        }
    }
}

```

After adding some vehicles to the array from the editor and running the code, we get this in the output:
  
```
Ford: (6.73831E-07, 0.752693, 0.752693, 1), 2004
Lamborghini: (0, 0.564706, 0, 0.615686)
Mazda: (0.8, 0, 0, 1), 1989
```

And the save file looks like this:
```json
{
    "Data": {
        "Vehicles": [
            {
                "._typeName": "Car",
                "brand": "Ford",
                "color": {
                    "args": [
                        0.000000673830982123036,
                        0.752692997455597,
                        0.752692997455597,
                        1.0
                    ],
                    "type": "Color"
                },
                "year": 2004
            },
            {
                "._typeName": "Vehicle",
                "brand": "Lamborghini",
                "color": {
                    "args": [
                        0.0,
                        0.564706027507782,
                        0.0,
                        0.615685999393463
                    ],
                    "type": "Color"
                }
            },
            {
                "._typeName": "Car",
                "brand": "Mazda",
                "color": {
                    "args": [
                        0.800000011920929,
                        0.0,
                        0.0,
                        1.0
                    ],
                    "type": "Color"
                },
                "year": 1989
            }
        ]
    }
}
```

</details>

---

### ⚠️ Resource Script Registration

MorphonSerializer supports automatic registration of custom resource scripts for serialization.  
This feature is controlled by the `Auto_Register_Custom_Resources` flag which is turned off by default:

- **Automatic Registration (recommended for most cases):**  
  When `MorphonSerializer.Auto_Register_Custom_Resources` is set to `true`, all scripts that extend `Resource` (or any other built-in resource where the script implements `_serialize` and `_deserialize`) will be automatically registered when serialization occurs.

- **Manual Registration:**  
  If `Auto_Register_Custom_Resources` is `false`, you will have to manually register each script you wish to serialize using `MorphonSerializer.register_script(name, script)` (or `register_script_by_path(name, path)`).

**Warning:**  
If a script is not registered (manually or automatically), serialization and deserialization for its resources will fail.

#### Example: Manual Script Registration

```gdscript
# Suppose you have a custom resource script at 'res://my_resource.gd'

MorphonSerializer.register_script_by_path("MyResource", "res://my_resource.gd")
```

- Use a unique name for each script.
- Registration should be done before any (de)serialization takes place.

**Tip:**  
For most projects, enabling `Auto_Register_Custom_Resources` is easier and less error-prone.

---

### Reference vs Cloning in MorphonConfigFile

I also added an extra method `set_cloned_value` that first clones the object, and then stores it in the config. 

- `set_value` / `SetValue`: Stores a reference for that object; later changes to the object are reflected in the config.
- `set_cloned_value` / `SetClonedValue`: Stores a deep copy; later changes to the object do not affect the saved data.

As you can see, the usage is the exact same for the MorphonConfigFile as for the built-in ConfigFile class, but without arbitrary code execution on deserialization!

---

## Extra Utilities

`MorphonSerializer.var_to_bytes` `MorphonSerializer.bytes_to_var` and `MorphonSerializer.var_to_str` `MorphonSerializer.str_to_var` work like the built-in ones, but without unsafe code execution.

**These also don't support built-in resource serialization (like SpriteFrames). Those will only be saved by their paths only if they are not local to scene**

<details>
<summary>Example</summary>

```gdscript
extends Node

@export var AnimalList: Array[Animal]

func _ready() -> void:
    print(MorphonSerializer.var_to_str(AnimalList))
```
</details>

---

## Installation

- Copy the `addons/morphon` directory into your project's `addons` folder and you are all done!
- **If you want to use the library with C# the path to the addon must be `res://addons/morphon` or it won't work**

## License

This project is licensed under the [MIT License](LICENSE).
