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

        Vehicle[] loadedVehicles = config.GetValue<Array<Vehicle>>("Data", "Vehicles").ToArray();

        foreach (Vehicle vehicle in loadedVehicles)
        {
            GD.Print(vehicle.ToString());
        }
    }
}
