using OrgMode

using Test
using SafeTestsets

@testset "OrgMode.jl" begin
    @safetestset "Types" begin include("Types.jl") end
    @safetestset "Parser" begin include("Parser.jl") end
    @safetestset "Process" begin include("Process.jl") end
end
