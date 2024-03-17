extends Node

# Utility class, autoloaded

func free_all_children(node: Node):
    for child in node.get_children():
        child.free()


func queue_free_all_children(node: Node):
    var children = node.get_children()
    await get_tree().process_frame
    for child in children:
        child.free()


func filled_array(value, size: int) -> Array:
    var array = []
    array.resize(size)
    array.fill(value)
    return array
