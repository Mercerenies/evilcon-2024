
# NOTE: This file is not used for anything other than testing. Delete me someday plz :)

static func test():
    var z = RefCounted.new()
    var a = [1, 2, 3, 4, 5]
    var a1 = a.reduce(func(a, b): return a + b)
    var a2 = a.reduce(func(a, b): return a + b, 10)

    var b = a.filter(func (z): return z % 2 == 0)

    return www()


static func www():
    return from_godot_docs()


static func from_godot_docs():
    var letters = ["A", "B", "C", "D", "E", "F"]

    var a = (letters.slice(0, 2))  # Prints ["A", "B"]
    var b = (letters.slice(2, -2)) # Prints ["C", "D"]
    var c = (letters.slice(-2, 6)) # Prints ["E", "F"]

    var d = (letters.slice(0, 6, 2))  # Prints ["A", "C", "E"]
    var e = (letters.slice(4, 1, -1)) # Prints ["E", "D", "C"]
    return [a, b, c, d, e]
