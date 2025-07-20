
# NOTE: This file is not used for anything other than testing. Delete me someday plz :)

static func test():
    var z = RefCounted.new()
    var a = [1, 2, 3, 4, 5]
    var a1 = a.reduce(func(a, b): return a + b)
    var a2 = a.reduce(func(a, b): return a + b, 10)

    var b = a.filter(func (z): return z % 2 == 0)

    return [a, b, len(b)]
