
# NOTE: This file is not used for anything other than testing. Delete me someday plz :)

static func test():
    var z = RefCounted.new()
    var a = [0, 1, 2]
    var b = a.map(func(x): return x + 10)

    return [a, b]
