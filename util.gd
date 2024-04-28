class_name Util
extends Node

# Utility class, autoloaded

static func free_all_children(node: Node):
    for child in node.get_children():
        child.free()


static func queue_free_all_children(node: Node):
    for child in node.get_children():
        child.queue_free()


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


static func max_by(array: Array, less_than: Callable):
    if len(array) == 0:
        return null  # No elements in array, so no maximum
    return array.reduce(func (acc, b):
        if less_than.call(acc, b):
            return b
        else:
            return acc)


# Takes an array and acts like Array.reduce(method, accum), but at
# each iteration, stop_condition is invoked with one argument (the
# current accumulator). If stop_condition returns true, iteration
# stops immediately and the current accumulator is true. In this way,
# this function can short-circuit.
static func reduce_while(array: Array, method: Callable, stop_condition: Callable, accum = null):
    if accum == null:
        accum = array[0]
        array = array.slice(1)
    for element in array:
        if stop_condition.call(accum):
            break
        accum = method.call(accum, element)
    return accum


# As reduce_while but with `await`able method and stop_condition.
static func reduce_while_async(array: Array, method: Callable, stop_condition: Callable, accum = null):
    if accum == null:
        accum = array[0]
        array = array.slice(1)
    for element in array:
        if await stop_condition.call(accum):
            break
        accum = await method.call(accum, element)
    return accum


class _AwaitAll extends RefCounted:
    signal callable_completed
    signal all_callables_completed

    var callables: Array
    var remaining: int

    func _init(callables: Array) -> void:
        self.callables = callables
        self.remaining = len(callables)
        self.callable_completed.connect(self._on_callable_completed)

    func run(i: int) -> void:
        await self.callables[i].call()
        self.callable_completed.emit()

    func run_all() -> void:
        for i in range(len(callables)):
            self.run(i)  # Do NOT await, fire and forget

    func _on_callable_completed() -> void:
        self.remaining -= 1
        if self.remaining == 0:
            self.all_callables_completed.emit()

# Takes an array of 0-argument callables. Calls them all and waits
# until all have completed.
static func await_all(array: Array) -> void:
    if len(array) == 0:
        # Corner case, nothing to do
        return

    # NOTE (HACK): There is an unfortunate corner case here. If the
    # array is nonempty but consists only of functions that do NOT
    # `await`, then this will hang forever, since there's a race
    # condition between the run_all() call and scheduling the response
    # to the signal.
    var awaiter = _AwaitAll.new(array)
    awaiter.run_all()
    await awaiter.all_callables_completed
