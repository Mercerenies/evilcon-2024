
# NOTE: This file is not used for anything other than testing. Delete me someday plz :)

class ZZZ:
    var x = 7

    static func a1():
        print("ZZZ.a1() called")

    static func a():
        print("ZZZ.a() called")
        a1()
        ZZZ.a1()

    func b1():
        print("ZZZ.b1() called")

    func b():
        print("ZZZ.b() called")
        b1()
        a1()
        self.b1()
        ZZZ.a1()

    func www():
        return func():
            return x

static func test():
    var tmp1 = ZZZ.new().www()
    print(tmp1.call())

    print(ZZZ.a1)
    print([1, 2, 1].min())
    print([1, 2, 1].max())
    print([].max())
    print([].min())

    ZZZ.new().b()
    ZZZ.a()

    var w = [1, 2, 3, 4]
    print(w.any(func(p): return p == 3))
    print(w.any(func(p): return p == 9))
    print(w.all(func(p): return p > 0))
    print(w.all(func(p): return p <= 3))

    var tt = Object.new()
    tt.e = 99
    print(tt.e + 2)

    print(PlayingCardCodex)
    print(PlayingCardCodex.ID.CHRIS_COGSWORTH)
    print(PlayingCardCodex.get_all_ids())

    print("CONTAINS:")
    print(3 in [1, 2, 3])
    print(3 in [1, 2, 4])
    print("ab" in "dabc")

    var z = 1
    match z:
        "A":
            print(1)
        "B":
            print("Z")

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

    var w = {
        "A": 3,
        "B": 4,
        "C": 5,
    }

    #print(w.keys())
    #print(w.values())

    #print(min(1, 0.5))
    #print(mini(1, 3))

    var x = [0, 4, 3, 5, 2, 1]
    x.sort()
    print(x)
    x.sort_custom(func(a, b): return b < a)
    print(x)

    var a = {"A": 1}
    var b = {"B": 2, "A": 99}
    a.merge(b, true)
    print(a)

    print(float(3.4))
    print(float(3))
    print(float(false))

    print(clampi(3.9, 1, 2))

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
