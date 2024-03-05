extends Node2D

const MushroomMan = preload("res://card_game/playing_card/cards/mushroom_man.gd")


func _ready():
    $PlayingCardDisplay.card_type = MushroomMan.new()
