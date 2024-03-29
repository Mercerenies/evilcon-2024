extends RefCounted

# Every PlayingField has a Randomness instance. This object basically
# delegates to a RandomNumberGenerator internally.
#
# Any card effects which use randomness to determine their outcome
# should go through this class on the PlayingField, so that other
# effects that alter randomness will respect that.
#
# This means that, if a card says "50% chance of drawing a card", then
# that should go through this class. Likewise, "summon a random card
# from deck" goes through this class. On the other hand, particle
# effects and other purely visual effects should NOT use this class
# and should simply use the global random number generator.
# Additionally, enemy AI should NOT use this class to make decisions.


var impl


func _init() -> void:
    impl = RandomNumberGenerator.new()
    impl.randomize()


func randi() -> int:
    return impl.randi()


func randi_range(from: int, to: int) -> int:
    # Both bounds are inclusive :)
    return impl.randi_range(from, to)


func choose(arr: Array) -> Variant:
    return arr[impl.randi() % arr.size()]
