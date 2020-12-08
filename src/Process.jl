module Process
export map, getall

using OrgMode.Types

using AbstractTrees
using Lazy

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
