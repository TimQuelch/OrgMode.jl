using OrgMode

using Test
using SafeTestsets

@testset "OrgMode.jl" begin
    @safetestset "Types" begin include("Types.jl") end
end
