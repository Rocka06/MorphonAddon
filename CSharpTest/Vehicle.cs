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
