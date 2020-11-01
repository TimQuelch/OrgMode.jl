module Parser
export OrgParseException, parse

using ..Types

using Lazy

struct OrgParseException <: Exception
    msg::String
end

const HEADLINE_RE= r"^(\*+)\s+(.*?)?\s*?$"m
const NONEMPTY_LINE_RE= r"^.*\S+.*$"m

const ELEMENT_BEGIN_RE = IdDict(
    Clock => r"^\s*CLOCK:"m,
    LatexEnvironment => r"^\s*\\begin\{([A-Za-z0-9*]+)\}"m,
    Drawer => r"^\s*:((?:\w|[-_])+):\s*$"m,
    FixedWidthLine => r"^\s*:( |$)"m,
    Block => r"^\s*#\+begin_(\S+)\h*(?:\h(.*))?$"mi,
)

const DRAWER_END_RE = r"^\s*:end:\s*$"mi
function latexEndRegex(envtype)
    escaped = replace(envtype, "*" => raw"\*")
    Regex("\\\\end{$escaped}\\s*\$", "mi")
end

const BLOCK_TYPE_STRINGS = IdDict(
    CommentBlock => "comment",
    ExampleBlock => "example",
    ExportBlock => "export",
    SrcBlock => "src",
    VerseBlock => "verse",
    # CenterBlock => "center",
    # QuoteBlock => "quote",
)

macro p_str(s) s end
const PARAGRAPH_BREAK_REGEX = Regex(
    join([
        p"^(?:",                      # Start line and capture
        p"\*+|",                      # Headlines
        p"\[fn:[-_\w]+\]|",           # Footnote definitions
        p"%%\(|",                     # Diary sexps
        p"\s*(?:",                    # Lines starting with whitespace group
        p"$|",                        # Empty lines
        p"\||",                       # Tables
        p"\+[-+]+\s*$|",              # Tables
        # Comments, keywords, blocks
        p"#(?: |$|\+(?:BEGIN_\S+|\S+(?:[.*])?:[\s]*))|",
        p":(?: |$|.+:\s*$)|",         # Drawers and fixed width areas
        p"-{5,}\s*$|",                # Horizontal rules
        p"\\begin{([A-Za-z0-9*]+)}|", # LaTeX environments
        p"CLOCK:|",                   # Clock lines
        # Lists
        p"(?:[-+*]|(?:[0-9]+|[A-Za-z])[.\)])(?:\s|$)",
        p"))"]),
    "im")

function elementEnd(::Any, s)
    m = match(r"^"m, s, 2)
    @debug "Generic element end" m
    return isnothing(m) ? nothing : m.offset - 1
end

function elementEnd(t::Type{LatexEnvironment}, s)
    @debug "Latex element string" s ELEMENT_BEGIN_RE[t]
    b = match(ELEMENT_BEGIN_RE[t], s)
    @debug "Latex begin match" b
    r = latexEndRegex(b[1])
    @debug "Latex end regex" r sub=s[b.offset + length(b.match):end]
    e = match(r, s, b.offset + length(b.match))
    @debug "Latex environment beginning and end" b e
    return e.offset + length(e.match)
end

function elementEnd(t::Type{Block}, s)
    b = match(ELEMENT_BEGIN_RE[t], s)
    r = Regex("^\\s*#\\+end_$(b[1])\\s*\$", "mi")
    @debug "Block end regex" r
    e = match(r, s, b.offset + length(b.match))
    @debug "Block beginning and end" b e
    return e.offset + length(e.match)
end

function elementEnd(::Type{Drawer}, s)
    e = match(DRAWER_END_RE, s)
    @debug "Drawer end" e
    return e.offset + length(e.match)
end

function elementEnd(::Type{Paragraph}, s)
    @assert length(s) > 1
    e = match(PARAGRAPH_BREAK_REGEX, s, 2)
    @debug "Paragraph end" e
    if isnothing(e)
        return nothing
    else
        m = match(r"\n*", s, e.offset)
        if isnothing(m)
            return e.offset - 1
        else
            return m.offset + length(m.match) - 1
        end
    end
end

function extractElement(s)
    type = findfirst(re -> startswith(s, re), ELEMENT_BEGIN_RE)
    if isnothing(type)
        type = Paragraph
    end
    endpos = elementEnd(type, s)
    @debug "Extracting element of type $type. end position identified at $endpos"
    if isnothing(endpos)
        return (parse(s, type), "")
    else
        return (parse(SubString(s, 1, endpos - 1), type), SubString(s, endpos))
    end
end

nextHeadline(s, offset=1) = match(HEADLINE_RE, s, offset)
nextHeadline(s, offset, level) = match(Regex("^(\\*{1,$level})\\s+(.*?)?\\s*?\$", "m"), s, offset)

function parse(s, ::Type{Document})
    e = Element[]
    @debug "Parsing document from" s
    (section, headlines) = extractSectionAndHeadlines(s)
    elements = []
    if !isnothing(section)
        push!(elements, section)
    end
    if !isnothing(headlines)
        append!(elements, headlines)
    end
    return Document(elements)
end

function parse(s, ::Type{Paragraph})
    @debug "Parsing paragraph from" s
    return Paragraph([PlainText(s)])
end

function parse(s, t::Type{Block})
    @debug "Parsing block from" s
    m = match(ELEMENT_BEGIN_RE[t], s)
    type = findfirst(s -> s == lowercase(m[1]), BLOCK_TYPE_STRINGS)
    s = strip(s)
    inner = SubString(s, findfirst('\n', s) + 1, findlast('\n', s)-1)
    if type === VerseBlock
        return type([PlainText(inner)])
    elseif type === SrcBlock || type === ExportBlock
        if isnothing(m[2])
            throw(OrgParseException("`export` and `src` blocks must contain data: $m.match"))
        end
        return type(inner, m[2])
    end
    return type(inner)
end

function parse(s, t::Type{LatexEnvironment})
    @debug "Parsing Latex environment from" s
    b = match(ELEMENT_BEGIN_RE[t], s)
    e = findall(latexEndRegex(b[1]), s)[end][begin]
    return LatexEnvironment(strip(SubString(s, b.offset + length(b.match), e-1)), b[1])
end

function parse(s, t::Type{Drawer})
    @debug "Parsing $t from" s
    m = match(ELEMENT_BEGIN_RE[t], s)
    s = strip(s)
    contents = strip(SubString(s, findfirst('\n', s), findlast('\n', s)))
    return Drawer(name=m[1], children=extractElements(contents))
end

function parse(s, ::Type{FixedWidthLine})
    @debug "Parsing FixedWidthLine from" s
    return FixedWidthLine(lstrip(s, ':'))
end

function parse(s, ::Type{Section})
    @debug "Parsing section from" s
    return Section(extractElements(s))
end

function extractElements(s)
    els = Element[]
    while (m = match(NONEMPTY_LINE_RE, s); !isnothing(m))
        el, s = extractElement(SubString(s, m.offset))
        push!(els, el)
    end
    return els
end

function extractSectionAndHeadlines(s)
    @debug "Extracting section and headlines from" s
    next = nextHeadline(s)
    @debug "Headline found" headline=next
    sectionStr = isnothing(next) ? s : SubString(s, 1, next.offset-1)
    section = isempty(strip(sectionStr)) ? nothing : parse(sectionStr, Section)

    headlines = Headline[]
    while !isnothing(next)
        cur = next
        l = length(cur[1])
        @debug "Searching for headline of level $l or less"
        next = nextHeadline(s, cur.offset + length(cur.match), l)
        if isnothing(next)
            @debug "No headline found"
            hsub = SubString(s, cur.offset)
        else
            @debug "Headline found" headline=next
            @assert length(next[1]) <= l
            @debug "Substring" s cur.offset next.offset
            hsub = SubString(s, cur.offset, next.offset-1)
        end
        if !isempty(hsub)
            push!(headlines, parse(hsub, Headline))
        end
    end

    @debug "Extracted " section headlines
    return (section, headlines)
end

function parse(s, ::Type{Headline})
    @debug "Parsing headline from" s
    m = nextHeadline(s)
    @debug "Headline itself is" m
    level = length(m[1])
    title = m[2]
    s = SubString(s, m.offset + length(m.match))
    (section, headlines) = extractSectionAndHeadlines(s)
    return Headline(level=level, title=title, section=section, headlines=headlines)
end

parse(s) = parse(s, Document)

end
