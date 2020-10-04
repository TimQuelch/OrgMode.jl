module Parser
export parse

using ..Types

using Lazy

const HEADLINE_REGEX = r"^(\*+)\s+(.*?)?\s*?$"m

nextHeadline(s, offset=1) = match(HEADLINE_REGEX, s, offset)
nextHeadline(s, offset, level) = match(Regex("^(\\*{1,$level})\\s+(.*?)?\\s*?\$", "m"), s, offset)

function parse(s, ::Type{Document})
    e = Element[]
    @debug "Parsing document from" s
    (section, headlines) = extractSectionAndHeadlines(s)
    return Document([section; headlines])
end

function parse(s, ::Type{Paragraph})
    @debug "Parsing paragraph from" s
    return Paragraph([PlainText(s)])
end

function parse(s, ::Type{Section})
    @debug "Parsing section from" s
    return @>>(split(s, r"\n{2,}"; keepempty=false),
               map(strip),
               filter(p -> !isempty(p)),
               map(p -> parse(p, Paragraph)),
               Section)
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
        next = nextHeadline(s, cur.offset+cur.match.ncodeunits, l)
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
    s = SubString(s, m.offset+m.match.ncodeunits)
    (section, headlines) = extractSectionAndHeadlines(s)
    return Headline(level=level, title=title, section=section, headlines=headlines)
end

parse(s) = parse(s, Document)

end
