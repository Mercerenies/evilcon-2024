class_name Operator
extends RefCounted

# Miscellaneous operators, written as functions to be used as
# higher-order functions in calls like Array.reduce.

static func plus(a, b):
    return a + b


static func and_(a, b):
    return a and b


static func or_(a, b):
    return a or b
