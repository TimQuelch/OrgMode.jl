using OrgMode
using OrgMode.Types
using OrgMode.Parser

@testset "parse" begin
    @testset "basic" begin

        basic = """
            This is a basic org document
            with some multiline paragraphs

            * And some headings
            These headings contain text
            ** And nested headings
            That also contain text
            ** And another that doesn't
            * Finally we go back to level one
            and close off with some text

            but this text is split into two paragraphs
            """
        @debug "Testing document:\n$basic"

        d = OrgMode.parse(basic)
        @test typeof(d) == Document

        @test typeof.(children(d)) == [Section, Headline, Headline]

        s1 = children(d)[1]
        @test typeof.(children(s1)) == [Paragraph]

        h1 = children(d)[2]
        @test typeof.(children(h1)) == [Section, Headline, Headline]
        @test (c -> typeof.(c)).(children.(children(h1))) == [[Paragraph], [Section], []]

        h2 = children(d)[3]
        @test typeof.(children(h2)) == [Section]
        @test typeof.(children(children(h2)[1])) == [Paragraph, Paragraph]
        ps = children(children(h2)[1])
        @test (c -> typeof.(c)).(children.(ps)) == [[PlainText], [PlainText]]
    end

    @testset "elements" begin
        section = """
            This is a basic org document
            with some multiline paragraphs

            #+begin_verse
            with various blocks
            #+end_verse
            #+begin_src language
            which aren't separated by empty lines
            #+end_src

            : A fixed width line

            Also some LaTeX maths

            \\begin{equation}
            f(x) = y^2
            \\end{equation}

            :testing:
            and a drawer
            :end:
            """
        @debug "Testing section:\n$section"

        s = OrgMode.parse(section, Section)
        @test typeof(s) == Section

        @test typeof.(children(s)) == [Paragraph, VerseBlock, SrcBlock, FixedWidthLine, Paragraph, LatexEnvironment, Drawer]
    end

    @testset "LatexEnvironment" begin
        b = OrgMode.parse("\\begin{equation}\n1+1\n\\end{equation}", LatexEnvironment)
        @test typeof(b) == LatexEnvironment
        @test b.environment == "equation"
        @test b.contents == "1+1"

        s = "\begin{equation*} \begin{bmatrix} 1 & 2 \\ 3 7 4 \end{bmatrix} \end{equation*}"
        b = OrgMode.parse(escape_string(s), LatexEnvironment)
        @test typeof(b) == LatexEnvironment
        @test b.environment == "equation*"
        @test b.contents == escape_string("\begin{bmatrix} 1 & 2 \\ 3 7 4 \end{bmatrix}")
    end

    @testset "FixedWidthLine" begin
        b = OrgMode.parse(":text\n", FixedWidthLine)
        @test typeof(b) == FixedWidthLine
        @test b.contents == "text\n"

        b = OrgMode.parse(":\t\t  text with spaces \n", FixedWidthLine)
        @test typeof(b) == FixedWidthLine
        @test b.contents == "\t\t  text with spaces \n"

        b = OrgMode.parse(":  text\n", FixedWidthLine)
        @test typeof(b) == FixedWidthLine
        @test b.contents == "  text\n"
    end

    @testset "SrcBlock" begin
        b = OrgMode.parse("#+begin_src language\nsrc\n#+end_src", Block)
        @test typeof(b) == SrcBlock
        @test b.language == "language"
        @test b.contents == "src"

        b = OrgMode.parse("#+bEgIn_Src lanGuAge\n\ttabbed\n\t\tindented\n\n#+eNd_Src", Block)
        @test typeof(b) == SrcBlock
        @test b.language == "lanGuAge"
        @test b.contents == "\ttabbed\n\t\tindented\n"

        @test_throws OrgParseException OrgMode.parse("#+begin_src\nsrc\n#+end_src", Block)
        @test_throws OrgParseException OrgMode.parse("#+begin_src    \nsrc\n#+end_src", Block)
    end

    @testset "ExportBlock" begin
        b = OrgMode.parse("#+begin_export backend\nexport\n#+end_export", Block)
        @test typeof(b) == ExportBlock
        @test b.backend == "backend"
        @test b.contents == "export"

        b = OrgMode.parse("#+bEgIn_Export bAckEnd\n\ttabbed\n\t\tindented\n\n#+eNd_Export", Block)
        @test typeof(b) == ExportBlock
        @test b.backend == "bAckEnd"
        @test b.contents == "\ttabbed\n\t\tindented\n"

        @test_throws OrgParseException OrgMode.parse("#+begin_export\nsrc\n#+end_src", Block)
        @test_throws OrgParseException OrgMode.parse("#+begin_export    \nsrc\n#+end_src", Block)
    end

    @testset "CommentBlock" begin
        b = OrgMode.parse("#+begin_comment\ncomment\n#+end_comment", Block)
        @test typeof(b) == CommentBlock
        @test b.contents == "comment"

        b = OrgMode.parse("#+bEgIn_Comment\n\ttabbed\n\t\tindented\n\n#+eNd_Comment", Block)
        @test typeof(b) == CommentBlock
        @test b.contents == "\ttabbed\n\t\tindented\n"
    end

    @testset "ExampleBlock" begin
        b = OrgMode.parse("#+begin_example\nexample\n#+end_example", Block)
        @test typeof(b) == ExampleBlock
        @test b.contents == "example"

        b = OrgMode.parse("#+bEgIn_Example\n\ttabbed\n\t\tindented\n\n#+eNd_Example", Block)
        @test typeof(b) == ExampleBlock
        @test b.contents == "\ttabbed\n\t\tindented\n"
    end

    @testset "VerseBlock" begin
        s = """
            #+begin_verse
            Here is some verse

            With multiple lines
            #+end_verse
            """

        b = OrgMode.parse(s, Block)
        @test typeof(b) == VerseBlock
        @test typeof.(children(b)) == [PlainText]
    end
end

function testend(type, str, e)
    result = OrgMode.Parser.elementEnd(type, str) == findfirst(e, str)[1] - 1
    if !result
        pos = OrgMode.Parser.elementEnd(type, str)
        real = findfirst(e, str)[1] - 1
        @warn "End identified at $pos ($(escape_string(str[pos:pos]))), expected at $real ($e)"
    end
    return result
end

function testend(type, test::Pair{String, String}, ::Any)
    result = OrgMode.Parser.elementEnd(type, test[1]) == findfirst(test[2], test[1])[1] - 1
    if !result
        pos = OrgMode.Parser.elementEnd(type, test[1])
        real = findfirst(test[2], test[1])[1] - 1
        @warn "End identified at $pos ($(escape_string(test[1][pos:pos]))), expected at $real ($(test[2]))"
    end
    return OrgMode.Parser.elementEnd(type, test[1]) == findfirst(test[2], test[1])[1] - 1
end

macro testends(type, e, tests...)
    block = Expr(:block)
    block.args = [:(@test testend($type, $test, $e)) for test in [tests...]]
    return :(@testset $(split(string(type), '.')[end]) $block)
end

@testset "elementEnd" begin

    @testends(
        Clock,
        "#",
        "CLOCK: [2020-08-11 Tue 13:55]--[2020-08-11 Tue 14:03] =>  0:08\n#",
        "CLOCK: [2020-08-11 Tue 13:55]\n#",
    )

    @testends(
        FixedWidthLine,
        "#",
        ": fixed width line\n#",
        ":\n#",
        ": \n#",
    )

    @testends(
        LatexEnvironment,
        "#",
        "\\begin{equation}\nx+y\n\\end{equation}\n#",
        "\\begin{equation}\n\n\nx+y\n    \\end{equation}    \n#",
        "\\begin{align*}\n\n\nx+y\n    \\end{align*}    \n#",
        """
        \\begin{equation*}
        \\begin{bmatrix} 1 & 2 \\ 3 & 4 \\end{bmatrix}
        \\end{equation*}
        #
        """,
    )

    @testends(
        Block,
        "%",
        "#+begin_src abc\ncode\n#+end_src\n%",
        "   #+begin_src abc  \n code   \n   #+end_src   \n%",
        "   #+begin_verse \n code   \n   #+end_verse   \n%",
        "   #+begin_export abc  \n code   \n   #+end_export   \n%",
        "#+BEGIN_SRC abc\ncode\n#+END_SRC\n%",
        "#+BeGin_sRC abc\ncode\n#+EnD_Src\n%",
        "#+BeGin_veRse abc\ncode\n#+EnD_vErsE\n%",
    )

    @testends(
        Paragraph,
        "#",
        "paragraph\nmorelines\n\n#",
        "paragraph\n* headline\n \n#" => "* headline",
        "paragraph\n[fn:label] contents\n \n#" => "[fn",
        "paragraph\n%%(diary-anniversary 10 31 2000)\n \n#" => "%%(diary",
        "paragraph\n| table | table \n \n#" => "| table",
        "paragraph\n | table | table \n \n#" => " | table",
        "paragraph\n+-+-+-+- \n \n#" => "+-+-+",
        "paragraph\n  +-+-+-+- \n \n#" => "  +-+-+",
        "paragraph\n#+begin_src emacs-lisp\n#+end_src\n \n#" => "#+begin",
        "paragraph\n  #+begin_src emacs-lisp\n#+end_src\n \n#" => "  #+begin",
        "paragraph\n  #+begin_verse\n#+end_src\n \n#" => "  #+begin",
        "paragraph\n: fixed-width\n \n#" => ": fixed-width",
        "paragraph\n : fixed-width\n \n#" => " : fixed-width",
        "paragraph\n :\n \n#" => " :",
        "paragraph\n:\n \n#" => ":",
        "paragraph\n:drawer:\ncontents\n:end: \n#" => ":drawer:",
        "paragraph\n  :drawer:\ncontents\n:end: \n#" => "  :drawer:",
        "paragraph\n----- \n#" => "---",
        "paragraph\n---------- \n#" => "---",
        "paragraph\n    ---------- \n#" => "    ---",
        "paragraph\n\\begin{equation}\n1+1\n\\end{equation}\n#" => "\\begin",
        "paragraph\n  \\begin{equation}\n1+1\n\\end{equation}\n#" => "  \\begin",
        "paragraph\nCLOCK: [00:00:00]\n#" => "CLOCK:",
        "paragraph\n CLOCK: [00:00:00]\n#" => " CLOCK:",
        "paragraph\n- list item\n- another list\n#" => "- list",
        "paragraph\n  - list item\n- another list\n#" => "  - list",
        "paragraph\n  * list item\n- another list\n#" => "  * list",
        "paragraph\n  + list item\n- another list\n#" => "  + list",
        "paragraph\n  5) list item\n- another list\n#" => "  5) list",
        "paragraph\n  5. list item\n- another list\n#" => "  5. list",
        "paragraph\n  a) list item\n- another list\n#" => "  a) list",
        "paragraph\n  a. list item\n- another list\n#" => "  a. list",
    )

    @testends(
        Drawer,
        "#",
        ":name:\ncontents\n:end:\n#",
        "   :name:  \ncontents\n   :end:\n#",
        "   :name:  \ncontents\n   :end:   \n#",
        ":name:\n  contents  \n  \n more contents\n\n\n:end:\n#",
        ":NAME:\ncontents\n:END:\n#",
        ":nAmE:\ncontents\n:eNd:\n#",
        ":nAmE:\ncontents\n  :eNd: \n#",
    )
end
