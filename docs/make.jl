using OrgMode
using OrgMode.Types
using OrgMode.Parser
using OrgMode.Process
using Documenter

makedocs(;
    modules=[OrgMode, OrgMode.Types, OrgMode.Parser, OrgMode.Process],
    authors="Tim Quelch <tim@tquelch.com> and contributors",
    repo="https://github.com/TimQuelch/OrgMode.jl/blob/{commit}{path}#L{line}",
    sitename="OrgMode.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://TimQuelch.github.io/OrgMode.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Usage" => "usage.md",
        "Types" => "types.md",
    ],
)

deploydocs(;
    repo="github.com/TimQuelch/OrgMode.jl",
)
