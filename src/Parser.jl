module Parser
export parse

using ..Types:  Document, Element, Headline

const HEADLINE_REGEX = r"^(\*+)\s+(.*?)?\s*?$"m

function parse(full)
    e = Element[]
    s = SubString(full)
    @info "Parsing document" s
    while (m = match(HEADLINE_REGEX, s)) !== nothing
        @info "Headline found" m.match m
        s = SubString(s, m.offset+m.match.ncodeunits)
        push!(e, Headline(level=length(m[1]), title=m[2]))
    end
    return Document(e)
end

end
