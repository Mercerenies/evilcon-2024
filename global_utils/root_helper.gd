extends Node

# Singleton node that's autoloaded at the root of the scene tree.
# Used by some Util functions to get the tree. Note that we don't
# want Util itself to be an autoload, because that makes it
# inaccessible from @tool scripts, so we indirectly depend on
# the tree with this node.
