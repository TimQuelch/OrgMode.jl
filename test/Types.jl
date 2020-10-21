using OrgMode
using OrgMode.Types

@testset "Object" begin
    @test Object <: Environment
end

@testset "Element" begin
    @test Element <: Environment
end

@testset "GreaterElement" begin
    @test GreaterElement <: Element
end

@testset "Headline" begin
    @testset "Type" begin
        @test Headline <: GreaterElement

        for f in (:level, :title, :todo, :tags, :priority, :section, :headlines)
            @test hasfield(Headline, f)
        end
    end

    @testset "Constructors" begin
        h = Headline(level=1)
        @test h.level === 1
        @test h.title === nothing
        @test h.todo === nothing
        @test h.tags == []
        @test h.priority === nothing
        @test h.section === nothing
        @test h.headlines == []

        @test_throws DomainError Headline(level=-1)

        h = Headline(
            level=4,
            title="Headline title",
            todo="TODO",
            tags=["email", "noexport"],
            priority='A',
            section=Section([]),
            headlines=[Headline(level=1), Headline(level=2)])
        @test h.level == 4
        @test h.title == "Headline title"
        @test h.todo == "TODO"
        @test h.tags == ["email", "noexport"]
        @test h.priority == 'A'
        @test h.section isa Section
        @test h.headlines isa AbstractArray{Headline,1}
    end
end

@testset "PlainText" begin
    @test PlainText <: Object
    @test hasfield(PlainText, :contents)

    @test PlainText("Test string").contents == "Test string"
    @test PlainText("Test string\nWith newline").contents == "Test string\nWith newline"
    @test PlainText("   trailing  whitespace  ").contents == "   trailing  whitespace  "
end

@testset "Paragraph" begin
    @test Paragraph <: Element

    ts = [PlainText("a"), PlainText("b"), PlainText("c")]
    p = Paragraph([PlainText("a"), PlainText("b"), PlainText("c")])
    @test children(p) == ts
end

# TODO Update these to reflect functionalty changes
@testset "Basic Elements" begin
    text = PlainText("some text for the element")
    for T in [Clock, FixedWidthLine, LatexEnvironment]
        @test T <: Element
        @test T(text).contents == text
        @test T(text) == T(contents=text)
    end
end

@testset "Block" begin
    @test isabstracttype(Block)
    @test Block <: Element

    @testset "Simple blocks" begin
        text = "some text for the block"
        for T in [CommentBlock, ExampleBlock]
            @test T <: Block
            @test T(text).contents == text
            @test T(text) == T(contents=text)
        end
    end

    @testset "SrcBlock" begin
        @test SrcBlock <: Element

        text = "some source code"
        lang = "lang"
        @test SrcBlock(text, lang).language == lang
        @test SrcBlock(text, lang).contents == text
        @test SrcBlock(text, lang) == SrcBlock(language=lang, contents=text)
    end

    @testset "ExportBlock" begin
        @test ExportBlock <: Element

        text = "some exported content"
        back = "back"
        @test ExportBlock(text, back).backend == back
        @test ExportBlock(text, back).contents == text
        @test ExportBlock(text, back) == ExportBlock(backend=back, contents=text)
    end

    @testset "VerseBlock" begin
        @test VerseBlock <: Element

        ts = [PlainText("a"), PlainText("b"), PlainText("c")]
        @test children(VerseBlock(ts)) == ts
    end
end

@testset "Document" begin
    es = [Headline(level=1), Section([]), Headline(level=3)]
    d = Document(es)
    @test children(d) == es
end
