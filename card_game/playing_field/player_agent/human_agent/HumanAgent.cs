using System;
using System.Threading.Tasks;
using Godot;

public partial class HumanAgent : PlayerAgent {
  private TaskCompletionSource? _endOfTurn = null;

  public override void OnAddedToPlayingField(GameState gameState) {
    // No action.
  }

  public override void OnRemovedFromPlayingField(GameState gameState) {
    // No action.
  }

  public override async Task RunOneTurn(GameState gameState) {
    if (_endOfTurn != null) {
      throw new InvalidOperationException();
    }

    _endOfTurn = new TaskCompletionSource();
    await _endOfTurn.Task;
    _endOfTurn = null;
  }

  public override void OnEndTurnButtonPressed(GameState gameState) {
    if (_endOfTurn != null) {
      _endOfTurn.TrySetResult();
    }
  }

  public override bool SuppressesUserInput {
    get => false;
  }
}
