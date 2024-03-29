## THIS FILE WAS GENERATED BY AN AUTOMATED RUBY TASK!
## ANY MODIFICATIONS MADE TO THIS FILE MAY BE OVERWRITTEN!

class_name PlayingCardCodex
extends Node

enum ID {
    NULL_MINION = 0,
    MUSHROOM_MAN = 1,
    POT_OF_LINGUINE = 2,
    SPIKY_MUSHROOM_MAN = 3,
    TINY_TURTLE = 4,
    ZANY_ZOMBIE = 5,
    TRIANGLE_TROOPER = 6,
    SERGEANT_SQUARE = 7,
    RHOMBUS_RANGER = 8,
    PENTAGON_PROTECTOR = 9,
    CAPTAIN_CIRCLE = 10,
    RAVIOLI_RUNT = 11,
    BUSY_BEE = 12,
    CORNY_ACORN = 13,
    GOLDEN_ACORN = 14,
    ROBOT_MITE = 15,
    MEATBALL_MAN = 16,
    UNPAID_INTERN = 17,
    BABY_CLOWN = 18,
    SPAGHETTI_MONSTER = 19,
    PENNE_PIKEMAN = 20,
    PENNE_SHARPSHOOTER = 21,
    TEMP_WORKER = 22,
    IT_WORKER = 23,
    CONTRACTOR = 24,
    MIDDLE_MANAGER = 25,
}

static func get_entity_script(n: int) -> GDScript:
    match n:
        ID.NULL_MINION:
            return load("./card_game/playing_card/cards/null_minion.gd") as GDScript
        ID.MUSHROOM_MAN:
            return load("./card_game/playing_card/cards/mushroom_man.gd") as GDScript
        ID.POT_OF_LINGUINE:
            return load("./card_game/playing_card/cards/pot_of_linguine.gd") as GDScript
        ID.SPIKY_MUSHROOM_MAN:
            return load("./card_game/playing_card/cards/spiky_mushroom_man.gd") as GDScript
        ID.TINY_TURTLE:
            return load("./card_game/playing_card/cards/tiny_turtle.gd") as GDScript
        ID.ZANY_ZOMBIE:
            return load("./card_game/playing_card/cards/zany_zombie.gd") as GDScript
        ID.TRIANGLE_TROOPER:
            return load("./card_game/playing_card/cards/triangle_trooper.gd") as GDScript
        ID.SERGEANT_SQUARE:
            return load("./card_game/playing_card/cards/sergeant_square.gd") as GDScript
        ID.RHOMBUS_RANGER:
            return load("./card_game/playing_card/cards/rhombus_ranger.gd") as GDScript
        ID.PENTAGON_PROTECTOR:
            return load("./card_game/playing_card/cards/pentagon_protector.gd") as GDScript
        ID.CAPTAIN_CIRCLE:
            return load("./card_game/playing_card/cards/captain_circle.gd") as GDScript
        ID.RAVIOLI_RUNT:
            return load("./card_game/playing_card/cards/ravioli_runt.gd") as GDScript
        ID.BUSY_BEE:
            return load("./card_game/playing_card/cards/busy_bee.gd") as GDScript
        ID.CORNY_ACORN:
            return load("./card_game/playing_card/cards/corny_acorn.gd") as GDScript
        ID.GOLDEN_ACORN:
            return load("./card_game/playing_card/cards/golden_acorn.gd") as GDScript
        ID.ROBOT_MITE:
            return load("./card_game/playing_card/cards/robot_mite.gd") as GDScript
        ID.MEATBALL_MAN:
            return load("./card_game/playing_card/cards/meatball_man.gd") as GDScript
        ID.UNPAID_INTERN:
            return load("./card_game/playing_card/cards/unpaid_intern.gd") as GDScript
        ID.BABY_CLOWN:
            return load("./card_game/playing_card/cards/baby_clown.gd") as GDScript
        ID.SPAGHETTI_MONSTER:
            return load("./card_game/playing_card/cards/spaghetti_monster.gd") as GDScript
        ID.PENNE_PIKEMAN:
            return load("./card_game/playing_card/cards/penne_pikeman.gd") as GDScript
        ID.PENNE_SHARPSHOOTER:
            return load("./card_game/playing_card/cards/penne_sharpshooter.gd") as GDScript
        ID.TEMP_WORKER:
            return load("./card_game/playing_card/cards/temp_worker.gd") as GDScript
        ID.IT_WORKER:
            return load("./card_game/playing_card/cards/it_worker.gd") as GDScript
        ID.CONTRACTOR:
            return load("./card_game/playing_card/cards/contractor.gd") as GDScript
        ID.MIDDLE_MANAGER:
            return load("./card_game/playing_card/cards/middle_manager.gd") as GDScript
        _:
            push_warning("Invalid ID value: %d" % n)
            return null


static func get_entity(n: int):
    return get_entity_script(n).new()
