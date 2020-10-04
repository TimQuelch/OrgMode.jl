module Types
export Document, Environment, Element, GreaterElement, Object, Section, Headline, PlainText, Paragraph, children

macro inherited(super, name, fields...)
    return quote
        Base.@kwdef struct $name <: $super
            $(fields...)
        end
    end
end

abstract type Environment end

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
@object(PlainText, contents::AbstractString)

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
# @element(Clock)
# @element(Comment)
# @element(DiarySexp)
# @element(FixedWidthLine)
# @element(HorizontalRule)
# @element(Keyword)
# @element(LatexEnvironment)
# @element(NodeProperty)
@element(Paragraph, children::AbstractArray{Object,1})
children(p::Paragraph) = p.children
# @element(Planning)
# @element(TableRow)

# abstract type Block <: Element end
# macro block(name, fields...) return :(@inherited(Block, $name, $(fields...))) end
# @block(CommentBlock)
# @block(ExampleBlock)
# @block(ExportBlock)
# @block(SrcBlock)
# @block(VerseBlock)

abstract type GreaterElement <: Element end
macro greater_element(name, fields...)
    return :(@inherited(
        GreaterElement,
        $name,
        children::AbstractArray{Element,1},
        $(fields...)))
end
children(x::GreaterElement) = x.children

# @greater_element(Drawer)
# @greater_element(PropertyDrawer)
# @greater_element(FootnoteDefinition)
@greater_element(Section)

Base.@kwdef struct Headline <: GreaterElement
    level::Int
    title::Union{AbstractString, Nothing} = nothing
    todo::Union{AbstractString, Nothing} = nothing
    tags::AbstractArray{AbstractString, 1} = []
    priority::Union{AbstractChar, Nothing} = nothing
    section::Union{Section, Nothing} = nothing
    headlines::AbstractArray{Headline, 1} = []
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

# abstract type GreaterBlock <: GreaterElement end
# macro greater_block(name, fields...) return :(@inherited(GreaterBlock, $name, $(fields...))) end
# @greater_block(CenterBlock)
# @greater_block(DynamicBlock)
# @greater_block(SpecialBlock)
# @greater_block(QuoteBlock)


struct Document
    elements::AbstractArray{Element,1}
end
children(x::Document) = x.elements

end
