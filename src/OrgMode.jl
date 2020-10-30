"""
The main public interface
"""
module OrgMode

using DocStringExtensions

@template MODULES =
    """
    $(DOCSTRING)
    # Exports
    $(EXPORTS)
    """

include("Types.jl")
include("Parser.jl")
include("Process.jl")
using .Types
using .Parser
using .Parser: parse
using .Process
using .Process: map

end
