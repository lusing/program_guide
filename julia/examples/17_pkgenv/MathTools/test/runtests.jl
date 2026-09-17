using Test
using MathTools

@testset "MathTools 包测试（Pkg.test 的入口）" begin
    @test average([1.0, 2.0, 3.0]) == 2.0
    @test variance([1.0, 2.0, 3.0]) ≈ 1.0
    @test variance([1.0, 2.0, 3.0]; corrected = false) ≈ 2 / 3
    @test movavg([1.0, 2.0, 3.0, 4.0], 2) ≈ [1.5, 2.5, 3.5]
    @test_throws ArgumentError movavg([1.0], 2)
    @test_throws ArgumentError zscore([5.0, 5.0])
    @test sum(zscore([1.0, 2.0, 3.0])) ≈ 0 atol = 1e-12
end
