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

When you use MorphonConfigFile, the addon scans your project for custom `Resource` scripts and registers them for serialization.  
- **Saving:** Object data is converted to dictionaries.
- **Loading:** Objects are rebuilt with the correct script and property values.

> **Note:** Built-in resources (like `SpriteFrames`) are not serialized directly. If not local to the scene, only their path is stored and reloaded.

### Custom Serialization

To control which properties are saved or if you extend a built-in resource type (e.g., `SpriteFrames`),  you will have to implement these methods in your script:

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

## Limitations

- Built-in resources (like SpriteFrames) are not serialized directly, and they are only saved by their paths if they are not local to scene.
- Only scripts inheriting from `Resource` or implementing the required methods are fully supported for serialization.

## License

This project is licensed under the [MIT License](LICENSE).
