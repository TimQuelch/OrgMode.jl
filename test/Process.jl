using OrgMode
using OrgMode: map, parse, getall
using OrgMode.Types

@testset "map" begin
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

    d = parse(basic)
    @test map(typeof, Headline, d) == [Headline, Headline, Headline, Headline]
    @test map(typeof, Section, d) == [Section, Section, Section, Section]
    @test map(typeof, [Headline, Section], d) == [Section, Headline, Section, Headline,
                                                  Section, Headline, Headline, Section]
    @test typeof.(getall(Section, d)) == [Section, Section, Section, Section]
    @test typeof.(getall([Headline, Section], d)) == [Section, Headline, Section, Headline,
                                                      Section, Headline, Headline, Section]
end
