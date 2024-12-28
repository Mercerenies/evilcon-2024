using System;
using System.Threading.Tasks;
using Godot;

public abstract partial class PlayerAgent : Node {
  [Export(PropertyHint.Enum, "BOTTOM,TOP")]
  public StringName ControlledPlayer { get; set; }

  public abstract void OnAddedToPlayingField(GameState gameState);

  public abstract void OnRemovedFromPlayingField(GameState gameState);

  public abstract Task RunOneTurn(GameState gameState);

  public abstract void OnEndTurnButtonPressed(GameState gameState);

  public abstract bool SuppressesUserInput { get; }
}
