extends Node2D

const MushroomMan = preload("res://card_game/playing_card/cards/mushroom_man.gd")
const PotOfLinguine = preload("res://card_game/playing_card/cards/pot_of_linguine.gd")


func _ready():
    $PlayingCardDisplay.card_type = MushroomMan.new()
    $PlayingCardDisplay2.card_type = PotOfLinguine.new()
