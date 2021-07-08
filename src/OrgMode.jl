"""
Provides functions to parse and process emacs Org Mode files.

The syntax tree of an org file can be read with [`parse`](@ref). This results in a tree-like
structure that can be accessed directly or processed with [`map`](@ref).

Heavily inspired by the Emacs lisp native parser
[`org-element`](https://orgmode.org/worg/dev/org-element-api.html)
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
