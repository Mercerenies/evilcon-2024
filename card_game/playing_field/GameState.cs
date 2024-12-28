using System;
using System.Threading.Tasks;
using Godot;

// Shim for PlayingField, adapting its methods to C#.
public partial class GameState : RefCounted {
  public Node2D PlayingField { get; }

  public GameState(Node2D playingField) {
    PlayingField = playingField;
  }

  public Task WithAnimation(Func<Node2D, Task> callable) {
    if ((bool)PlayingField.Get("plays_animation")) {
      return callable((Node2D)PlayingField.GetNode("AnimationLayer"));
    } else {
      return Task.CompletedTask;
    }
  }
}
