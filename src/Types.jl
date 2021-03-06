module Types
export Document, Environment, Element, GreaterElement, Block, Object, Section, Headline, PlainText
export Paragraph, Clock, LatexEnvironment, FixedWidthLine, Drawer, CommentBlock, SrcBlock
export ExampleBlock, ExportBlock, VerseBlock, CenterBlock, QuoteBlock, SpecialBlock, GreaterBlock

export children

using AbstractTrees

macro inherited(super, name, fields...)
    return quote
        Base.@kwdef struct $name <: $super
            $(fields...)
        end
    end
end

abstract type Environment end
children(::Environment) = []
AbstractTrees.children(x::Environment) = Types.children(x)

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

abstract type Element <: Environment end
macro element(name, fields...) return :(@inherited(Element, $name, $(fields...))) end
# @element(BabelCall)
@element(Clock, contents::String)
# @element(Comment)
# @element(DiarySexp)
@element(FixedWidthLine, contents::String)
# @element(HorizontalRule)
# @element(Keyword)
@element(LatexEnvironment, contents::String, environment::String)
# @element(NodeProperty)
@element(Paragraph, children::Vector{Object})
children(p::Paragraph) = p.children
# @element(Planning)
# @element(TableRow)

abstract type Block <: Element end
macro block(name, fields...) return :(@inherited(Block, $name, $(fields...))) end
@block(CommentBlock, contents::String)
@block(ExampleBlock, contents::String)
@block(ExportBlock, contents::String, backend::String)
@block(SrcBlock, contents::String, language::String)
@block(VerseBlock, children::Vector{Object})
children(x::VerseBlock) = x.children

abstract type GreaterElement <: Element end
macro greater_element(name, fields...)
    return :(@inherited(
        GreaterElement,
        $name,
        children::Vector{Element},
        $(fields...)))
end
children(x::GreaterElement) = x.children

@greater_element(Drawer, name::String)
# @greater_element(PropertyDrawer)
# @greater_element(FootnoteDefinition)
@greater_element(Section)

Base.@kwdef struct Headline <: GreaterElement
    level::Int
    title::Union{String, Nothing} = nothing
    todo::Union{String, Nothing} = nothing
    tags::Vector{String} = []
    priority::Union{Char, Nothing} = nothing
    section::Union{Section, Nothing} = nothing
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

struct Document <: Environment
    elements::Vector{Element}
end
children(x::Document) = x.elements

end
