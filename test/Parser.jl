using OrgMode
using OrgMode: Document, Section, Headline, Paragraph, children

const basic = """
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

@testset "parse" begin
    @testset "basic" begin
        @test typeof(OrgMode.parse(basic)) == Document

        d = OrgMode.parse(basic)
        @test_broken length(children(d)) == 3
        @test_broken typeof(children(d)[1] == Section)
        @test_broken typeof(children(d)[2] == Headline)
        @test_broken typeof(children(d)[3] == Headline)

        section = children(d)[1]
        @test length(children(section)) == 1
        @test_broken typeof(children(section)[1]) == Paragraph

        h1 = children(d)[2]
        @test_broken length(children(h1)) == 3
        @test_broken typeof(children(h1)[1]) == Section
        @test_broken length(children(children(h1)[1])) == 1
        @test_broken typeof(children(children(h1)[1])[1]) == Paragraph
        @test_broken typeof(children(h1)[2]) == Headline
        @test_broken length(children(children(h1)[2])) == 1
        @test_broken typeof(children(children(h1)[2])[1]) == Section
        @test_broken typeof(children(h1)[3]) == Headline
        @test_broken length(children(children(h1)[2])) == 0

        h2 = children(d)[3]
        @test length(children(h2)) == 1
        @test_broken typeof(children(h2)[1]) == Section
        @test_broken length(children(children(h2)[1])) == 2
        @test_broken typeof(children(children(h2)[1])[1]) == Paragraph
        @test_broken typeof(children(children(h2)[1])[2]) == Paragraph
    end
end
