# 第 14 章 · 用群计算：伯恩赛德与 Pólya —— Julia 通道
#
# 旗子/项链/棋盘/赌盘四现场：Pólya 公式与暴力轨道计数双跑。

println("==== 14 用群计算：伯恩赛德与 Pólya")

# ---------- Pólya 通用件 ----------
"""Pólya：群元素以循环长列表给出，N = (1/|G|) Σ q^t(τ)。"""
polya(cycles_list::Vector{Vector{Int}}, q) =
    sum(cs -> BigInt(q)^length(cs), cycles_list) // length(cycles_list)

"""暴力：按轨道归并计数（数"新轨道"次数，不是 seen 的大小）。"""
function brute_orbits(pos::Int, q, action)
    seen = Set{Vector{Int}}(); orbits = 0
    for code in 0:(q^pos - 1)
        c = [mod1(d, q) for d in digits(code, base=q, pad=pos)]
        c in seen && continue
        orbits += 1
        union!(seen, Set(action(c)))
    end
    orbits
end

# ---------- 旗子：6 条纹 3 色，翻转（习题正文例） ----------
# 翻转 τ = (1 6)(2 5)(3 4)：循环长 [2,2,2]；恒等 [1,1,1,1,1,1]
flag = polya([[1,1,1,1,1,1], [2,2,2]], 3)
@assert flag == 378
flip_action(c) = Set([reverse(c), c])
@assert brute_orbits(6, 3, flip_action) == 378
println("6 条纹 3 色旗（翻转等价）：Pólya = 暴力 = 378 ✓")

# ---------- 项链：2 色 6 珠（旋转 / 二面体） ----------
n = 6
# 旋转 k 的循环结构：gcd(n,k) 个长 n/gcd 循环
rot_cycles(k) = fill(n ÷ gcd(n, k), gcd(n, k))
neck_rot = polya([rot_cycles(k) for k in 0:n-1], 2)
@assert neck_rot == 14
# 二面体：+ 3 个过对角反射（循环 [2,2,2] 型补 [1,1]? 实算）与 3 个过棱反射
# 6 珠二面体反射的循环长：过对珠 [1,2,2,1]→ 长度 4 循环（2 个不动点）；
# 过对棱 [2,2,2]。用循环指标验：Z = (x₁⁶ + x₂³ + 2x₃² + 2x₆ + 3x₁²x₂² + 3x₂³)/12
dih_cycles_list = [[1,1,1,1,1,1], [2,2,2],
                   fill(2, 3), fill(3, 2), [6], [6], fill(2, 3), fill(3, 2), [6],
                   [1,1,2,2], [1,1,2,2], [1,1,2,2],
                   fill(2, 3), fill(2, 3), fill(2, 3)]
# 上面手工排列易错，改由循环指标公式直接给出：
Z_neck6_dih(x1, x2, x3, x6) = (x1^6 + x2^3 + 2x3^2 + 2x6 + 3x1^2 * x2^2 + 3x2^3) // 12
@assert Z_neck6_dih(2, 2, 2, 2) == 13
@assert Z_neck6_dih(3, 3, 3, 3) == 92
println("2 色 6 珠：旋转 14；二面体 13；3 色二面体 92（循环指标公式）✓")

# ---------- 4×4 双色棋盘（例 2.159/2.163） ----------
# 16 格编号 0..15（行主序）。90° 旋转置换 r：行 i 列 j（0 基）→ (j, 3−i)
rot90(p) = [let i = divrem(x - 1, 4); (i[2] * 4 + (3 - i[1])) + 1; end for x in 1:16]
# 循环结构：恒等 16 个 1-循环；r90/r270 4 个 4-循环；r180 8 个 2-循环
polya_chess = polya([[fill(1, 16)...], [4, 4, 4, 4], [2,2,2,2,2,2,2,2], [4, 4, 4, 4]], 2)
@assert polya_chess == 16456 "(2^16 + 2·2^4 + 2^8)/4"
chess_action(c) = Set(begin
        p = identity.(1:16)
        acc = c
        s = Set([acc])
        for _ in 1:3
            # 施加一次 90° 旋转：新格 (j,3−i) 取旧格 (i,j) 的色
            acc = [acc[rot90(p)[x]] for x in 1:16]
            push!(s, acc)
        end
        s
    end)
@assert brute_orbits(16, 2, chess_action) == 16456
println("4×4 双色棋盘（C₄ 旋转）：Pólya = 暴力 = 16456（例 2.161）✓")

# ---------- 5 扇形 2 色赌盘（习题 2.140 形态） ----------
n5 = 5
rot5_cycles(k) = fill(n5 ÷ gcd(n5, k), gcd(n5, k))
roulette = polya([rot5_cycles(k) for k in 0:n5-1], 2)
@assert roulette == 8 "(2⁵ + 2 + 2 + 2 + 2)/5"
rot5_action(c) = Set(begin
        s = Set([c])
        for k in 1:4
            push!(s, [c[mod1(i - k, 5)] for i in 1:5])
        end
        s
    end)
@assert brute_orbits(5, 2, rot5_action) == 8
println("5 扇形 2 色赌盘：Pólya = 暴力 = 8 ✓")

println("END ====")
