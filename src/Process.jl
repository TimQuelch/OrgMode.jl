"""
Provides functions for processing org trees
"""
module Process
export map, getall

using OrgMode.Types

using DocStringExtensions
using AbstractTrees
using Lazy

"""
    map(f, types, tree)

Apply a function `f` to the org [Types](@ref) `types` that are found in `tree`. Returns the
flattened results. `types` can be either a single type or an interable.

`tree` is any org type, however will most often the result of `OrgMode.parse`
"""
function map end

AbstractTrees.children(x::Union{Environment, Document}) = Types.children(x)

function map(f, types, tree)
    @>>(
        tree,
        PreOrderDFS,
        collect,
        filter(x -> any(t -> x isa t, types)),
        Base.map(f),
    )
end

map(f, type::DataType, tree) = map(f, (type,), tree)

getall(types, tree) = map(identity, types, tree)

end
