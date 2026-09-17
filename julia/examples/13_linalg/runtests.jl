# 13 示例测试：分解/最小二乘/稀疏语义
using Test
using LinearAlgebra
using SparseArrays
using Random
include("main.jl")

@testset "13_linalg" begin
    @testset "分解复用" begin
        Abig = [4.0 1.0 0.0; 1.0 3.0 1.0; 0.0 1.0 2.0]
        Fb = lu(Abig)
        for b in ([1.0, 0, 0], [0.0, 1, 0], rand(Xoshiro(7), 3))
            @test Fb \ b ≈ Abig \ b
        end
        @test cholesky(Abig).U' * cholesky(Abig).U ≈ Abig
        @test_throws PosDefException cholesky([1.0 2.0; 2.0 1.0])
    end
    @testset "最小二乘" begin
        Ad = [1.0 0.0; 1.0 1.0; 1.0 2.0]        # 三点拟合直线
        bd = [0.9, 2.2, 3.05]
        x̂ = Ad \ bd
        @test Ad' * (Ad * x̂ - bd) ≈ zeros(2) atol = 1e-12
        @test norm(Ad * x̂ - bd) <= norm(Ad * ([0.0, 1.0]) - bd)   # LS 解不劣于任何试探解
    end
    @testset "SVD 与条件数" begin
        Mr = [2.0 0.0; 0.0 3.0; 0.0 0.0]
        Ur, Sr, Vr = svd(Mr)
        @test Sr == [3.0, 2.0]                  # 奇异值降序
        @test rank(Mr) == 2 && rank([1.0 2.0; 2.0 4.0]) == 1
        @test cond(Diagonal([1.0, 1e-8])) == 1e8
    end
    @testset "稀疏" begin
        Sp = sparse([1, 2, 2, 3, 3], [1, 1, 2, 1, 3], [1.0, 1.0, 2.0, 2.0, 3.0], 3, 3)
        @test nnz(Sp) == 5 && Sp[3, 1] == 2.0
        @test Matrix(Sp) == [1 0 0; 1 2 0; 2 0 3]
        @test sparse(Matrix(Sp)) == Sp
        @test issparse(Sp * Sp)                  # 稀疏 × 稀疏保持稀疏
        b = Sp * ones(3)
        @test Sp \ b ≈ ones(3)
        @test isequal(spzeros(2, 2), sparse(zeros(2, 2)))
    end
end
