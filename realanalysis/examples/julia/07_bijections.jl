# 第 07 章 双射：Julia 通道。
# 有限集合上核对像、原像、单射/满射/双射、可逆与复合。
# 运行：julia --startup-file=no 07_bijections.jl

println("==== 07 bijections ====")

# --- 像与原像 ---------------------------------------------------------
image(f, A) = Set(f(x) for x in A)
preimage(f, A, G) = Set(x for x in A if f(x) in G)

A = Set([1, 2, 3])
@assert image(x -> 1, A) == Set([1])
println("const image of {1,2,3} = {1}")

Z = Set(-5:5)
@assert preimage(x -> x * x, Z, Set([16])) == Set([4, -4])
println("preimage of {16} under sq = {4,-4}")

# --- 单射 / 满射 / 双射（有限穷举） -----------------------------------
function is_injective(f, A)
    for x in A, y in A
        if f(x) == f(y) && x != y
            return false
        end
    end
    true
end

function is_surjective(f, A, B)
    image(f, A) == Set(B)
end

function is_bijective(f, A, B)
    is_injective(f, A) && is_surjective(f, A, B)
end

# x ↦ 2x on a finite set of reals (sample)
S = Set([-2.0, -1.0, 0.0, 1.0, 2.0])
T = Set([-4.0, -2.0, 0.0, 2.0, 4.0])
@assert is_injective(x -> 2x, S)
@assert is_bijective(x -> 2x, S, T)
println("x ↦ 2x bijective on sample")

# x ↦ x² not injective
R = Set([-2.0, -1.0, 0.0, 1.0, 2.0])
@assert !is_injective(x -> x^2, R)
println("x ↦ x² not injective")

# {1,2}→{1} constant: surjective, not injective
A12 = Set([1, 2]); B1 = Set([1])
@assert is_surjective(_ -> 1, A12, B1) && !is_injective(_ -> 1, A12)
println("{1,2}→{1} surjective not injective")

# {1}→{1,2}, 1↦1: injective, not surjective
A1 = Set([1]); B12 = Set([1, 2])
@assert is_injective(_ -> 1, A1) && !is_surjective(_ -> 1, A1, B12)
println("{1}→{1,2} injective not surjective")

# --- 可逆 ⇔ 双射：显式逆 y ↦ y/2 ------------------------------------
f = x -> 2x
g = y -> y / 2
@assert all(g(f(x)) == x for x in S)
@assert all(f(g(y)) == y for y in T)
println("f and g are two-sided inverses")

# --- 复合 -------------------------------------------------------------
comp(g, f) = x -> g(f(x))
@assert all(comp(x -> x^2, x -> 2x)(x) == 4 * x^2 for x in S)
@assert all(comp(g, f)(x) == x for x in S)
@assert all(comp(f, g)(y) == y for y in T)
println("composition: (sq ∘ double)(x)=4x²; inv∘f = id")

println("END ====")
