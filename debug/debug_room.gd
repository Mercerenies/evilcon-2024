extends Node2D

const MushroomMan = preload("res://card_game/playing_card/cards/mushroom_man.gd")
const PotOfLinguine = preload("res://card_game/playing_card/cards/pot_of_linguine.gd")
const SpikyMushroomMan = preload("res://card_game/playing_card/cards/spiky_mushroom_man.gd")
const TinyTurtle = preload("res://card_game/playing_card/cards/tiny_turtle.gd")
const ZanyZombie = preload("res://card_game/playing_card/cards/zany_zombie.gd")
const SergeantSquare = preload("res://card_game/playing_card/cards/sergeant_square.gd")
const TriangleTrooper = preload("res://card_game/playing_card/cards/triangle_trooper.gd")
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
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.ZANY_ZOMBIE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.THE_INTERNET),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.GRAVESTONE_POLISHING),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.FURIOUS_PHANTOM),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.HONEY_JAR),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.FURIOUS_PHANTOM),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.BUSY_BEE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.UNPAID_INTERN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.UNPAID_INTERN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.UNPAID_INTERN),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SPARE_BATTERY),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.SECOND_COURSE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.WITH_EXTRA_CHEESE),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.METAL_SPIDER),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.NUCLEAR_POWER_PLANT),
        PlayingCardCodex.get_entity(PlayingCardCodex.ID.NUCLEAR_FUSION_PLANT),
    ]
