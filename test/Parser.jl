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

        @test map(typeof, children(d)) == [Section, Headline, Headline]

        s1 = children(d)[1]
        @test map(typeof, children(s1)) == [Paragraph]

        h1 = children(d)[2]
        @test map(typeof, children(h1)) == [Section, Headline, Headline]
        @test map(c -> map(typeof, children(c)), children(h1)) == [[Paragraph], [Section], []]

        h2 = children(d)[3]
        @test map(typeof, children(h2)) == [Section]
        @test map(typeof, children(children(h2)[1])) == [Paragraph, Paragraph]
        ps = children(children(h2)[1])
        @test map(p -> map(typeof, children(p)), ps) == [[PlainText], [PlainText]]
    end
end
