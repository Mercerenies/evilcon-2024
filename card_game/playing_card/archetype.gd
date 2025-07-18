class_name Archetype
extends Node


const HUMAN = 1
const NATURE = 2
const TURTLE = 3
const SHAPE = 4
const PASTA = 5
const CLOWN = 6
const ROBOT = 7
const BEE = 8
const NINJA = 9
const BOSS = 11
const UNDEAD = 12
const FARM = 22
const DEMON = 24


static func to_icon_index(archetype: int) -> int:
    # It's an implementation detail that these numbers match up.
    # Currently, it's simply the easiest way to store these.
    return archetype


static func all() -> Array:
    return [
        HUMAN,
        NATURE,
        TURTLE,
        SHAPE,
        PASTA,
        CLOWN,
        ROBOT,
        BEE,
        NINJA,
        BOSS,
        UNDEAD,
        FARM,
        DEMON,
    ]
