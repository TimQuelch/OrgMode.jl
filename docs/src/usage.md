# Usage

```@repl
using OrgMode
s = "A paragraph\n\n* Headline 1n\nSection content\n** Headline 1.1\nAnd more content"
d = OrgMode.parse(s)
OrgMode.children(d)
```

```@docs
OrgMode.parse
OrgMode.map
OrgParseException
```

## Internal modules

```@docs
OrgMode.Parser
OrgMode.Process
OrgMode.Types
```
