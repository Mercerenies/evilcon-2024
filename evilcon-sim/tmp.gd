
# NOTE: This file is not used for anything other than testing. Delete me someday plz :)

static func test():
    var z = RefCounted.new()
    var a = [[0]]
    var b = a.duplicate()
    var c = a.duplicate(true)
    a[0].push_back(1)
    a[0].append(2)

    return "a %s b%s" % [z, 3]
