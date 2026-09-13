using Test

add(a, b) = a + b

@testset "basic math" begin
    @test add(1, 2) == 3
    @test add(-1, 1) == 0
    @test sum([1, 2, 3]) == 6
end

println("tests passed")

