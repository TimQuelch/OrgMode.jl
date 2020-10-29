"""
Contains type definitions
"""
module Types
export Document, Environment, Element, GreaterElement, Block, Object, Section, Headline, PlainText
export Paragraph, Clock, LatexEnvironment, FixedWidthLine, Drawer, CommentBlock, SrcBlock
export ExampleBlock, ExportBlock, VerseBlock, CenterBlock, QuoteBlock, SpecialBlock, GreaterBlock

export children

using AbstractTrees
using DocStringExtensions

@template (DEFAULT, TYPES) =
    """
    $(TYPEDEF)
    $(DOCSTRING)
    $(TYPEDFIELDS)
    """

@template (FUNCTIONS, METHODS, MACROS) =
    """
    $(TYPEDSIGNATURES)
    $(DOCSTRING)
    """

macro inherited(super, name, fields...)
    return quote
        Base.@kwdef struct $name <: $super
            $(fields...)
        end
    end
end

"The base type for a component of an Org Mode document. "
abstract type Environment end

"Fallback for `children` for any `Environment` types which don't have defined children"
children(::Environment) = []
AbstractTrees.children(x::Environment) = Types.children(x)

"""Objects are Environments that are 'smaller' than a paragraph.
Paragraphs (and other elements that contain 'text') are composed of different objects"""
abstract type Object <: Environment end
macro object(name, fields...) return :(@inherited(Object, $name, $(fields...))) end
# @object(Entity)
# @object(ExportSnippet)
# @object(InlineBabelCall)
# @object(InlineSrcBlock)
# @object(LatexFragment)
# @object(LineBreak)
# @object(Macro)
# @object(StatisticsCookies)
# @object(Target)
# @object(Timestamp)
"The base plain text object"
@object(PlainText, contents::String)

# abstract type GreaterObject <: Object end
# macro greater_object(name, fields...) return :(@inherited(GreaterObject, $name, $(fields...))) end
# @greater_object(FootnoteReference)
# @greater_object(Link)
# @greater_object(Subscript)
# @greater_object(Superscript)
# @greater_object(RadioTarget)
# @greater_object(TableCell)

# abstract type TextMarkup <: GreaterObject end
# macro text_markup(name, fields...) return :(@inherited(TextMarkup, $name, $(fields...))) end
# @text_markup(Bold)
# @text_markup(Verbatim)
# @text_markup(Italic)
# @text_markup(Strikethrough)
# @text_markup(Underline)
# @text_markup(Code)

"Elements are Environments that are on a level equivalent to a paragraph."
abstract type Element <: Environment end
macro element(name, fields...) return :(@inherited(Element, $name, $(fields...))) end
# @element(BabelCall)
"Clock line"
@element(Clock, contents::String)
# @element(Comment)
# @element(DiarySexp)
"""Fixed width lines are lines prefixed with a ':'.
The contents (without the ':') are stored in the `contents string`"""
@element(FixedWidthLine, contents::String)
# @element(HorizontalRule)
# @element(Keyword)
"A LaTeX environment surrounded by `\begin{<env>} ... \end{<env>}`"
@element(LatexEnvironment, contents::String, environment::String)
# @element(NodeProperty)
"A paragraph. Paragraphs contain many objects"
@element(Paragraph, children::Vector{Object})
children(p::Paragraph) = p.children
# @element(Planning)
# @element(TableRow)

"Blocks are surrounded by `#+begin_<type> ... #+end_<type>`"
abstract type Block <: Element end
macro block(name, fields...) return :(@inherited(Block, $name, $(fields...))) end
"Comment blocks are surrounded by `#+begin_comment ... #+end_comment`."
@block(CommentBlock, contents::String)
"Example blocks are surrounded by `#+begin_example ... #+end_example`."
@block(ExampleBlock, contents::String)
"Export blocks are surrounded by `#+begin_export backend ... #+end_export`."
@block(ExportBlock, contents::String, backend::String)
"""Source blocks are surrounded by `#+begin_src language ... #+end_src`.
TODO: Handle header args"""
@block(SrcBlock, contents::String, language::String)
"""Verse blocks are surrounded by `#+begin_verse ... #+end_verse`.
Verse blocks contain objects rather than unparsed text"""
@block(VerseBlock, children::Vector{Object})
children(x::VerseBlock) = x.children

"Greater elements are elements which can contain other elements"
abstract type GreaterElement <: Element end
macro greater_element(name, fields...)
    return :(@inherited(
        GreaterElement,
        $name,
        children::Vector{Element},
        $(fields...)))
end
children(x::GreaterElement) = x.children

"Drawers are collapsable sections surrounded with `:<name>: ... :end:`"
@greater_element(Drawer, name::String)
# @greater_element(PropertyDrawer)
# @greater_element(FootnoteDefinition)
"""A section contains the elements following a headline before another headline.
A section also occurs before the first headline"""
@greater_element(Section)

"""
A Headline in an org document

Headlines optionally include a single section, which contains the contents of the headline. Headlines also contain a list of their child headlines.
"""
Base.@kwdef struct Headline <: GreaterElement
    "Level of headline. i.e. the number of '*'s"
    level::Int
    "Optional text contents"
    title::Union{String, Nothing} = nothing
    "Optional TODO keyword"
    todo::Union{String, Nothing} = nothing
    "List of tags"
    tags::Vector{String} = []
    "Optional priority character"
    priority::Union{Char, Nothing} = nothing
    "Optional child section"
    section::Union{Section, Nothing} = nothing
    "Optional child headlines"
    headlines::Vector{Headline} = []
    function Headline(level, title, todo, tags, priority, section, headlines)
        if !(level > 0)
            throw(DomainError("Headline level must be greater than 0 ($level)"))
        end
        new(level, title, todo, tags, priority, section, headlines)
    end
end
children(x::Headline) = isnothing(x.section) ? x.headlines : vcat(x.section, x.headlines)

# @greater_element(InlineTask)
# @greater_element(Item)
# @greater_element(PlainList)
# @greater_element(Table)
# @greater_element(DynamicBlock)

abstract type GreaterBlock <: GreaterElement end
macro greater_block(name, fields...)
    return :(@inherited(
        GreaterBlock,
        $name,
        children::Vector{Element},
        $(fields...)))
end
@greater_block(CenterBlock)
@greater_block(QuoteBlock)
@greater_block(SpecialBlock, name::String)

"An org document. The children of a document can only be sections or headlines"
struct Document <: Environment
    elements::Vector{Union{Section,Headline}}
end
children(x::Document) = x.elements

end
