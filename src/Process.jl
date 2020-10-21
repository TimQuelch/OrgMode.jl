module Process
export map

using OrgMode.Types

using AbstractTrees
using Lazy

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

map(f, type::DataType, tree) = map(f, [type], tree)

end
