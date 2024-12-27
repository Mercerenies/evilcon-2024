using Godot;
using System;
using System.Collections.Generic;
using Utils;

// Every PlayingField has an EventLogger. This is NOT intended to log
// all events, and indeed by default it logs absolutely nothing.
// However, playing cards can send events to this log, so that they
// can keep track of things that happened at a global level in the
// game.
//
// Note that, for things local to one card, CardMeta should be
// preferred. The EventLogger is intended for events that affect
// multiple cards.
public partial class EventLogger : RefCounted, ICloneable {
  private record EventTime(int TurnNumber, StringName PlayerName);

  private IDictionary<EventTime, List<StringName>> _events =
    new Dictionary<EventTime, List<StringName>>();

  public void LogEvent(int turnNumber, StringName playerName, StringName eventName) {
    var eventTime = new EventTime(turnNumber, playerName);
    var list = _events.GetOrAdd(eventTime, () => new List<StringName>());
    list.Add(eventName);
  }

  public bool HasEvent(int turnNumber, StringName playerName, StringName eventName) {
    var eventTime = new EventTime(turnNumber, playerName);
    return _events.GetOrElse(eventTime)?.Contains(eventName) ?? false;
  }

  public object Clone() {
    var newLogger = new EventLogger();
    foreach (var (eventTime, events) in _events) {
      foreach (var eventName in events) {
        newLogger.LogEvent(eventTime.TurnNumber, eventTime.PlayerName, eventName);
      }
    }
    return newLogger;
  }
}
