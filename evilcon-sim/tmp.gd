
# NOTE: This file is not used for anything other than testing. Delete me someday plz :)

static func test():
    var xxx = []
    for aa in [1, 2, 3, 4, 5]:
        xxx.push_back(aa)
        if aa > 3:
            break

    var z = RefCounted.new()
    var a = [1, 2, 3, 4, 5]
    var a1 = a.reduce(func(a, b): return a + b)
    var a2 = a.reduce(func(a, b): return a + b, 10)

    var b = a.filter(func (z): return z % 2 == 0)

    return from_godot_docs1()


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


static func from_godot_docs1():
    var x1 = (range(4))        # Prints [0, 1, 2, 3]
    var x2 = (range(2, 5))     # Prints [2, 3, 4]
    var x3 = (range(0, 6, 2))  # Prints [0, 2, 4]
    var x4 = (range(4, 1, -1)) # Prints [4, 3, 2]
    return [x1, x2, x3, x4]
