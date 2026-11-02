# -*- coding: utf-8 -*-
println("==== 04 independence")
# 第 04 章 Julia：独立性的有限精确账（Rational{Int}，不使用随机模拟）。
# ① 两枚公平硬币；② 9 点两两独立反例；③ 条件独立但边际相关；
# ④ 边际独立但给定 XOR 后依赖；⑤ 零相关但确定性依赖。

prob(pred, space) = count(pred, space)//length(space)

# ① 两枚公平硬币
coins = [(a, b) for a in 0:1 for b in 0:1]
A = xy -> xy[1] == 1
B = xy -> xy[2] == 1
@assert prob(A, coins) == 1//2
@assert prob(B, coins) == 1//2
@assert prob(xy -> A(xy) && B(xy), coins) == 1//4
println("two fair coins: P(A∩B)=1/4=P(A)P(B): OK")

# ② 洪书 9 点反例
points = ["aaa", "bbb", "ccc", "abc", "bca", "cba", "acb", "bac", "cab"]
Ai(i) = w -> w[i] == 'a'
A1, A2, A3 = Ai(1), Ai(2), Ai(3)
for f in (A1, A2, A3)
    @assert prob(f, points) == 1//3
end
for (f, g) in ((A1, A2), (A1, A3), (A2, A3))
    @assert prob(w -> f(w) && g(w), points) == 1//9
end
@assert prob(w -> A1(w) && A2(w) && A3(w), points) == 1//9
@assert 1//9 != (1//3)^3
println("nine-point example: pairwise independent, triple probability 1/9 != 1/27: OK")

# ③ 条件独立但边际不独立的混合模型
# 元组格式：(A, B, C, 权重)。C=0 时成功概率 1/5，C=1 时 4/5。
mixture = Tuple{Int,Int,Int,Rational{Int}}[]
for (c, p) in ((0, 1//5), (1, 4//5))
    for a in 0:1, b in 0:1
        w = (1//2) * (a == 1 ? p : 1-p) * (b == 1 ? p : 1-p)
        push!(mixture, (a, b, c, w))
    end
end

mass(; Aval=nothing, Bval=nothing, Cval=nothing) =
    sum(t[4] for t in mixture
        if (isnothing(Aval) || t[1] == Aval) &&
           (isnothing(Bval) || t[2] == Bval) &&
           (isnothing(Cval) || t[3] == Cval); init=0//1)

for c in (0, 1)
    denom = mass(Cval=c)
    pA = mass(Aval=1, Cval=c) // denom
    pB = mass(Bval=1, Cval=c) // denom
    pAB = mass(Aval=1, Bval=1, Cval=c) // denom
    @assert pAB == pA * pB
end
@assert mass(Aval=1) == 1//2
@assert mass(Bval=1) == 1//2
@assert mass(Aval=1, Bval=1) == 17//50
@assert 17//50 != 1//4
println("mixture model: A⊥B|C, but marginally P(A=1,B=1)=17/50: OK")

# ④ A、B 边际独立；C=A xor B 是对撞量
xor_space = [(a, b, xor(a, b)) for a in 0:1 for b in 0:1]
@assert prob(w -> w[1] == 1, xor_space) == 1//2
@assert prob(w -> w[2] == 1, xor_space) == 1//2
@assert prob(w -> w[1] == 1 && w[2] == 1, xor_space) == 1//4
given_c1 = filter(w -> w[3] == 1, xor_space)
@assert prob(w -> w[1] == 1, given_c1) == 1//2
@assert prob(w -> w[1] == 1 && w[2] == 1, given_c1) == 0
println("XOR collider: marginally independent, dependent after conditioning on C=1: OK")

# ⑤ 四点零相关但 Y=X^2
xs = [-2, -1, 1, 2]
ys = abs2.(xs)
EX = sum(xs)//4
EY = sum(ys)//4
cov = sum((x - EX) * (y - EY) for (x, y) in zip(xs, ys))//4
@assert EX == 0//1
@assert cov == 0//1
@assert all(y == x^2 for (x, y) in zip(xs, ys))
println("four-point quadratic relation: exact covariance 0, yet Y=X^2: OK")

println("END ====")
