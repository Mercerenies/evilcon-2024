
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

    return [fmod(7, 3.4), PI]


static func www():
    return from_godot_docs()


static func from_godot_docs():
    var letters = ["A", "B", "C", "D", "E", "F"]

    print(letters.slice(0, 2))  # Prints ["A", "B"]
    print(letters.slice(2, -2)) # Prints ["C", "D"]
    print(letters.slice(-2, 6)) # Prints ["E", "F"]

    print(letters.slice(0, 6, 2))  # Prints ["A", "C", "E"]
    print(letters.slice(4, 1, -1)) # Prints ["E", "D", "C"]


static func from_godot_docs1():
    print(range(4))        # Prints [0, 1, 2, 3]
    print(range(2, 5))     # Prints [2, 3, 4]
    print(range(0, 6, 2))  # Prints [0, 2, 4]
    print(range(4, 1, -1)) # Prints [4, 3, 2]
