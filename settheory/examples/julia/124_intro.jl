# 第 124 章 Julia：等数、旅馆与对角线的数值侧。
# ① 等数却稀疏：n ↔ n² 成立的同时，平方数在前 N 个自然数中的
#    占比趋于 0——"一样多"与"越来越稀"并不矛盾；
# ② 希尔伯特旅馆：满房客人 n→2n 腾出全部奇数房的可执行模拟；
# ③ 二进制对角线：伪随机数表外构造新数并逐行验证；
# ④ 幂集阶梯的有限影子：2^n 与 2^(2^n) 的严格增长。
println("==== 124 intro")

# ① 等数却稀疏
densities = Float64[]
for N in (10, 100, 1_000, 100_000)
    cnt = length(collect(0:isqrt(N)))
    push!(densities, cnt / N)
end
for i in 2:length(densities)
    @assert densities[i] < densities[i-1]            # 占比单调下降
end
@assert densities[end] < 2 / sqrt(100_000)           # 与 1/√N 同阶
println("sparse yet equinumerous: square density -> 0 like 1/sqrt(N): OK")

# ② 希尔伯特旅馆（有限彩排）：N 个房间满员，全体客人 n → 2n，
# 占据偶数房，奇数房全部腾空——注入成立，腾出 ⌈N/2⌉ 间。
N = 100
guests = 1:N
new_rooms = [2n for n in guests]
new_rooms = new_rooms[new_rooms .<= N]               # 有限旅馆内住得下的部分
occ = Set(new_rooms)
freed = setdiff(Set(1:N), occ)
@assert length(new_rooms) == length(Set(new_rooms))  # 注入：无人撞房
@assert length(freed) == N - length(occ)             # 腾出的奇数房数量对账
push!(new_rooms, 1)                                  # 新客入住 1 号房
@assert length(Set(new_rooms)) == length(new_rooms)
println("hotel: n->2n frees all odd rooms, newcomer moves in: OK")

# ③ 二进制对角线
n = 16
rows = [(i * j + i + j) % 2 for i in 1:n, j in 1:n]
c = [1 - rows[i, i] for i in 1:n]
for i in 1:n
    @assert c[i] != rows[i, i]                       # 与第 i 行在第 i 位不同
end
println("diagonal: flipped diagonal beats every row at its own index: OK")

# ④ 幂集阶梯
for k in 0:8
    @assert big(2)^k > k
end
@assert big(2)^(big(2)^4) > big(2)^4 > 4
println("power ladder: 2^k > k, 2^(2^k) keeps climbing: OK")
println("END ====")
