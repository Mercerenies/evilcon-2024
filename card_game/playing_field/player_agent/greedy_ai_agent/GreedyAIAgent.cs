using System;
using System.Threading.Tasks;
using Godot;

public partial class GreedyAIAgent : PlayerAgent {
  public override void OnAddedToPlayingField(GameState gameState) {
    // No action.
  }

  public override void OnRemovedFromPlayingField(GameState gameState) {
    // No action.
  }

  public override async Task RunOneTurn(GameState gameState) {
    while (true) {
      await gameState.WithAnimation(async (animationLayer) => {
        GetTimer().Start();
        await GetTimer().Timeout;
      });
      var nextCardType = GetNextCard(gameState);
      if (nextCardType == null) {
        break; // Turn is done.
      }
      await CardGameApi.call("play_card_from_hand", gameState.PlayingField, ControlledPlayer, nextCardType);
    }
  }

  private Variant? GetNextCard(GameState gameState) {
    return null; //// TODO
  }

  private Timer GetTimer() {
    return (Timer)GetNode("NextActionTimer");
  }

  public override void OnEndTurnButtonPressed(GameState gameState) {
    // AI-controlled agent; ignore user input.
  }

  public override bool SuppressesUserInput {
    get => true;
  }
}
