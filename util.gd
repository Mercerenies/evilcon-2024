extends Node

# Utility class, autoloaded

func free_all_children(node: Node):
    for child in node.get_children():
        child.free()


func queue_free_all_children(node: Node):
    # Note: We could just do child.queue_free() for each child, but it
    # makes sense to await the idle frame only once and then free all
    # of them once it's safe to do so, rather than queuing up several
    # deletions separately on the same idle frame.
    var children = node.get_children()
    await get_tree().process_frame
    for child in children:
        child.free()


func filled_array(value, size: int) -> Array:
    var array = []
    array.resize(size)
    array.fill(value)
    return array
