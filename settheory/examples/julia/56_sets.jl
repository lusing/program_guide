# 第 56 章：朴素集合的机器化（Makinson Ch1）
# 位掩码宇宙上的代数穷举 + 幂集计数 + Hasse 分层
println("==== 56")

meet(a, b) = a & b
uni(a, b) = a | b
diff(a, b) = a & ~b

function sets_channel()
    # ---- 一、Exercise 1.2.1 六个集合的包含关系 ----
    # A: <10 的正整数；B: <11 的素数；C: 1<x<6 的奇数；D: {1,2}；E: {1}；F: <8 的素数
    A = Set(1:9); B = Set([2,3,5,7]); C = Set([3,5])
    D = Set([1,2]); E = Set([1]); F = Set([2,3,5,7])
    S = Dict('A'=>A, 'B'=>B, 'C'=>C, 'D'=>D, 'E'=>E, 'F'=>F)
    incls = Tuple{Char,Char}[]
    for (k1, s1) in S, (k2, s2) in S
        k1 == k2 && continue
        s1 ⊆ s2 && push!(incls, (k1, k2))
    end
    println("  Exercise 1.2.1 非平凡包含（除各自自含与 ⊆A 外）：")
    for (k1, k2) in sort(incls)
        (k2 == 'A' || k1 == 'A') && continue
        println("    $k1 ⊆ $k2")
    end
    println("    B == F（外延公理：元素相同）: ", S['B'] == S['F'])

    # ---- 二、六元宇宙位掩码上的定律穷举（64×64×64）----
    ok = true
    for a in 0:63, b in 0:63, c in 0:63
        ok &= meet(a,b) == meet(b,a)
        ok &= uni(a,b) == uni(b,a)
        ok &= meet(a,b) == (a & b)          # 检查实现一致性
        ok &= meet(a, uni(b,c)) == uni(meet(a,b), meet(a,c))
        ok &= uni(a, meet(b,c)) == meet(uni(a,b), uni(a,c))
        ok &= meet(a, uni(a,b)) == a
        ok &= uni(a, meet(a,b)) == a
        ok &= diff(a, uni(b,c)) == meet(diff(a,b), diff(a,c))
        ok &= diff(a, meet(b,c)) == uni(diff(a,b), diff(a,c))
    end
    println("  交并差九律（64^3 穷举）：", ok ? "全部成立 ✓" : "有反例！")

    # ---- 三、差不交换的见证 ----
    d1 = diff(0b110011, 0b001111)   # {0,1,4,5} \ {0,1,2,3}
    d2 = diff(0b001111, 0b110011)
    println("  {0,1,4,5}\\{0,1,2,3} = $d1 ≠ $d2 = 反向差（差不交换）")

    # ---- 四、幂集 |P(A)| = 2^n：枚举 3 元集的全部子集并计数 ----
    A4 = Set(1:3)
    P3 = Set{Int}[]
    for mask in 0:7
        push!(P3, Set(filter(i -> (mask >> (i-1)) & 1 == 1, 1:3)))
    end
    println("  |P({1,2,3})| = $(length(P3)) = 2^3（枚举计数）")
    println("  逐点验证：", join(["2^$n=$(1<<n)" for n in 0:8], ", "))

    # ---- 五、Hasse 分层（按元素个数）----
    layers = Dict{Int,Vector{Int}}()
    for m in 0:7
        push!(get!(layers, count_ones(m), Int[]), m)
    end
    println("  P({0,1,2}) 的 Hasse 分层（按 popcount）：")
    for r in 0:3
        println("    第 $r 层：", sort(layers[r]))
    end

    # ---- 六、指数爆炸的直观 ----
    println("  指数爆炸：2^10=$(2^10)，2^30≈$(2^30)，2^100≈10^$(length(string(BigInt(2)^100))-1)")
    nothing
end

sets_channel()
println("END ====")
