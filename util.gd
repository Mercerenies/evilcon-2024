class_name Util
extends Node

# Utility class, autoloaded

static func free_all_children(node: Node):
    for child in node.get_children():
        child.free()


static func queue_free_all_children(node: Node):
    # Note: We could just do child.queue_free() for each child, but it
    # makes sense to await the idle frame only once and then free all
    # of them once it's safe to do so, rather than queuing up several
    # deletions separately on the same idle frame.
    var children = node.get_children()
    await RootHelper.get_tree().process_frame
    for child in children:
        child.free()


static func filled_array(value, size: int) -> Array:
    var array = []
    array.resize(size)
    array.fill(value)
    return array


static func splice_string(string: String, start: int, end: int, replacement: String = "") -> String:
    return string.substr(0, start) + replacement + string.substr(end)


static func replace_all_by_function(string: String, regex: RegEx, function: Callable) -> String:
    var result = regex.search(string)
    while result != null:
        var replacement = function.call(result)
        string = splice_string(string, result.get_start(), result.get_end(), replacement)
        result = regex.search(string)
    return string
