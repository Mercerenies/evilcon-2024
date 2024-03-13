extends Node2D

# TODO Put these three methods in a common superclass for everyone who needs them :)


func set_card(_card) -> void:
    # No-op to make this node compatible with CardStrip.
    pass


func on_added_to_strip(_strip) -> void:
    # No-op, no reaction to being added to strip.
    pass


func on_added_to_row(_strip) -> void:
    # No-op, no reaction to being added to row.
    pass
