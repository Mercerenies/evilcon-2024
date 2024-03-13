extends Node2D

const MushroomMan = preload("res://card_game/playing_card/cards/mushroom_man.gd")
const PotOfLinguine = preload("res://card_game/playing_card/cards/pot_of_linguine.gd")


func _ready():
    var bottom_deck = $PlayingField.get_deck(CardPlayer.BOTTOM)
    var top_deck = $PlayingField.get_deck(CardPlayer.TOP)
    bottom_deck.cards().replace_cards(_sample_deck())
    top_deck.cards().replace_cards(_sample_deck())
    bottom_deck.cards().shuffle()
    top_deck.cards().shuffle()

    #for _i in range(6):
    #    $PlayingField.get_discard_pile(CardPlayer.BOTTOM).cards().push_card(MushroomMan.new())

    await CardGameApi.draw_cards($PlayingField, CardPlayer.BOTTOM, 3)
    await CardGameApi.draw_cards($PlayingField, CardPlayer.TOP, 3)


func _sample_deck():
    return [
        MushroomMan.new(), MushroomMan.new(), MushroomMan.new(),
        MushroomMan.new(), MushroomMan.new(), MushroomMan.new(),
        MushroomMan.new(), MushroomMan.new(), MushroomMan.new(),
        PotOfLinguine.new(), PotOfLinguine.new(), PotOfLinguine.new(),
        PotOfLinguine.new(), PotOfLinguine.new(), PotOfLinguine.new(),
        PotOfLinguine.new(), PotOfLinguine.new(), PotOfLinguine.new(),
    ]
