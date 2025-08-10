class_name Util
extends Node

# Utility class, autoloaded


class Pair:
    var first
    var second

    func _init(first, second):
        self.first = first
        self.second = second

    func _to_string() -> String:
        return "Pair.new(%s, %s)" % [first, second]


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


static func min_by(array: Array, less_than: Callable):
    return max_by(array, func (a, b):
        return less_than.call(b, a))


static func max_on(array: Array, key: Callable):
    return max_by(array, func (a, b):
        return key.call(a) < key.call(b))


static func sum(array: Array):
    return array.reduce(func (a, b): return a + b, 0)


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


static func find_if(array: Array, predicate: Callable):
    for i in range(len(array)):
        if predicate.call(array[i]):
            return i
    return null


static func normalize_angle(angle: float) -> float:
    return fmod(fmod(angle, 2 * PI) + 2 * PI, 2 * PI)


# Merges all of the keys from the right dictionary into the left one,
# modifying the left dictionary in-place. If a key exists in both
# dictionaries, then `merge_function` is called with the key and both
# values, to determine a merged value to store in the left dictionary.
static func merge_dicts_in_place(left: Dictionary, right: Dictionary, merge_function: Callable) -> void:
    for key in right.keys():
        if key in left:
            left[key] = merge_function.call(key, left[key], right[key])
        else:
            left[key] = right[key]


# Stops when the end of the shorter array is reached.
static func zip(left: Array, right: Array) -> Array:
    var result = []
    for i in range(min(len(left), len(right))):
        result.push_back(Pair.new(left[i], right[i]))
    return result


static func ncr(n: int, r: int) -> int:
    if r > n or r < 0:
        return 0
    if 2 * r > n:
        return ncr(n, n - r) # Use symmetry property: nCr(n, r) = nCr(n, n - r)
    var numerator = 1
    var denominator = 1
    for i in range(r):
        numerator *= (n - i)
        denominator *= (i + 1)
    @warning_ignore("integer_division")
    return numerator / denominator


# Filter but operates in place on the input array.
static func filter_in_place(arr: Array, filter_func: Callable) -> void:
    var i = 0
    while i < len(arr):
        if filter_func.call(arr[i]):
            i += 1
        else:
            arr.remove_at(i)


# Filter but operates in place on the input array. More efficient than
# filter_in_place but does not preserve element ordering.
static func filter_swap_in_place(arr: Array, filter_func: Callable) -> void:
    var i = 0
    while i < len(arr):
        if filter_func.call(arr[i]):
            i += 1
        else:
            var tmp = arr[i]
            arr[i] = arr[len(arr) - 1]
            arr[len(arr) - 1] = tmp
            arr.pop_back()
