module Process
export map

using OrgMode.Types

using AbstractTrees
using Lazy

AbstractTrees.children(x::Document) = Types.children(x)
function AbstractTrees.children(x::Environment)
    try
        return Types.children(x)
    catch e
        if e isa MethodError
            return []
        else
            rethrow(e)
        end
    end
end

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
