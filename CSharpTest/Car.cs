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
