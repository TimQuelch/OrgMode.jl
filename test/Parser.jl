using OrgMode
using OrgMode.Types

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
            #+begin_src
            which aren't separated by empty lines
            #+end_src

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

        @test typeof.(children(s)) == [Paragraph, VerseBlock, SrcBlock, Paragraph, LatexEnvironment, Drawer]
    end
end

@testset "elementEnd" begin

    function testend(type, str, e)
        @test OrgMode.Parser.elementEnd(type, str) == findfirst(e, str)[1] - 1
    end

    function testend(type, test::Pair{String, String}, ::Any)
        @test OrgMode.Parser.elementEnd(type, test[1]) == findfirst(test[2], test[1])[1] - 1
    end

    function testend(type, tests::AbstractVector, e="#")
        @testset "$(split(string(type), ".")[end])" begin
            for test in tests
                testend(type, test, e)
            end
        end
    end

    testend(Clock, [
        "CLOCK: [2020-08-11 Tue 13:55]--[2020-08-11 Tue 14:03] =>  0:08\n#",
        "CLOCK: [2020-08-11 Tue 13:55]\n#",
    ])

    testend(FixedWidthLine, [
        ": fixed width line\n#",
        ":\n#",
        ": \n#",
    ])

    testend(LatexEnvironment, [
        "\\begin{equation}\nx+y\n\\end{equation}\n#",
        "\\begin{equation}\n\n\nx+y\n    \\end{equation}    \n#",
        "\\begin{align*}\n\n\nx+y\n    \\end{align*}    \n#",
        """
        \\begin{equation*}
        \\begin{bmatrix} 1 & 2 \\ 3 & 4 \\end{bmatrix}
        \\end{equation*}
        #
        """,
    ])

    testend(Block, [
        "#+begin_src abc\ncode\n#+end_src\n%",
        "   #+begin_src abc  \n code   \n   #+end_src   \n%",
        "   #+begin_verse \n code   \n   #+end_verse   \n%",
        "   #+begin_export abc  \n code   \n   #+end_export   \n%",
        "#+BEGIN_SRC abc\ncode\n#+END_SRC\n%",
        "#+BeGin_sRC abc\ncode\n#+EnD_Src\n%",
        "#+BeGin_veRse abc\ncode\n#+EnD_vErsE\n%",
    ], "%")

    testend(Paragraph, [
        "paragraph\nmorelines\n\n#",
        "paragraph\n* headline\n \n#" => "* headline",
    ])
end
