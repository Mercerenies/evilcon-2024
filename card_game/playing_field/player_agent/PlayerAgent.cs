using System;
using Godot;

public abstract partial class PlayerAgent : Node {
  [Export(PropertyHint.Enum, "BOTTOM,TOP")]
  public StringName ControlledPlayer { get; set; }

  public abstract void OnAddedToPlayingField(Variant playingField);

  public abstract void OnRemovedFromPlayingField(Variant playingField);
}
