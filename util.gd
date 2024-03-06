class_name Util
extends Node

# Static utility class

static func free_all_children(node: Node):
    for child in node.get_children():
        child.free()


static func filled_array(value, size: int) -> Array:
    var array = []
    array.resize(size)
    array.fill(value)
    return array
