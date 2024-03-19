extends Node2D

const MushroomMan = preload("res://card_game/playing_card/cards/mushroom_man.gd")
const PotOfLinguine = preload("res://card_game/playing_card/cards/pot_of_linguine.gd")
const SpikyMushroomMan = preload("res://card_game/playing_card/cards/spiky_mushroom_man.gd")
const TinyTurtle = preload("res://card_game/playing_card/cards/tiny_turtle.gd")
const ZanyZombie = preload("res://card_game/playing_card/cards/zany_zombie.gd")
const GreedyEnemyAI = preload("res://card_game/playing_field/enemy_ai/greedy_enemy_ai.tscn")


func _ready():
    $PlayingField.replace_enemy_ai(GreedyEnemyAI.instantiate())
    var bottom_deck = $PlayingField.get_deck(CardPlayer.BOTTOM)
    var top_deck = $PlayingField.get_deck(CardPlayer.TOP)
    bottom_deck.cards().replace_cards(_sample_deck())
    top_deck.cards().replace_cards(_sample_deck())
    bottom_deck.cards().shuffle()
    top_deck.cards().shuffle()

    await CardGameTurnTransitions.begin_game($PlayingField)


func _sample_deck():
    return [
        MushroomMan.new(), MushroomMan.new(), MushroomMan.new(),
        SpikyMushroomMan.new(), SpikyMushroomMan.new(), SpikyMushroomMan.new(),
        TinyTurtle.new(), TinyTurtle.new(), TinyTurtle.new(),
        ZanyZombie.new(), ZanyZombie.new(), ZanyZombie.new(),
        PotOfLinguine.new(), PotOfLinguine.new(), PotOfLinguine.new(),
        PotOfLinguine.new(), PotOfLinguine.new(), PotOfLinguine.new(),
    ]
