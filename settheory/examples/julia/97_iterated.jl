# 第 97 章：直接极限代表元对拍与临界点轨迹表。
println("==== 97")

# ── 有限直接系统：索引 {0,1,2,3}，e_{i,j} 为显式映射 ──
# M_i = ℤ；e_{0,1}(x)=2x, e_{1,2}(x)=x+3, e_{2,3}(x)=-x,
# e_{i,j} 由复合给出（交换图 e_{i,k}=e_{j,k}∘e_{i,j}）。
e01(x) = 2x
e12(x) = x + 3
e23(x) = -x

function eij(i, j, x)
    i == j && return x
    if (i, j) == (0, 1) return e01(x) end
    if (i, j) == (1, 2) return e12(x) end
    if (i, j) == (2, 3) return e23(x) end
    if i < j
        # 按链复合：0→1→2→3
        return eij(j-1, j, eij(i, j-1, x))
    end
    error("i > j")
end

# 交换图核对：对全部 i<j<k 与 x∈{-5..5}，e_{i,k}(x)=e_{j,k}(e_{i,j}(x))。
for i in 0:3, j in (i+1):3, k in (j+1):3, x in -5:5
    @assert eij(i, k, x) == eij(j, k, eij(i, j, x))
end

# ── 直接极限：A={(i,x)} 模 (i,x)~(k,y) ⟺ e_{i,l}(x)=e_{k,l}(y)（l≥i,k）──
function direct_limit_classes(points)
    classes = Vector{Vector{Tuple{Int,Int}}}()
    for p in points
        i, x = p
        placed = false
        for c in classes
            (k, y) = c[1]
            l = max(i, k)
            if eij(i, l, x) == eij(k, l, y)
                push!(c, p)
                placed = true
                break
            end
        end
        placed || push!(classes, [p])
    end
    return classes
end

pts = [(i, x) for i in 0:3 for x in -2:2]
classes = direct_limit_classes(pts)
# 终端像集：i=0:{-7,-5,-3,-1,1}, i=1:{-5,-4,-3,-2,-1}, i=2/3:{-2..2}
# 并 = {-7,-5,-4,-3,-2,-1,0,1,2} 恰 9 类。
@assert length(classes) == 9
total = sum(length(c) for c in classes)
@assert total == length(pts)
# 每类是等价关系：同类任两点在共同延伸处像相等。
for c in classes
    n = length(c)
    n > 1 && @assert all(begin
            (i, x), (k, y) = c[a], c[b]
            l = max(i, k)
            eij(i, l, x) == eij(k, l, y)
        end for a in 1:n for b in 1:n)
end

# ── 临界点轨迹表：κ_n = j^n(κ₀)，j(x)=x+1 ──
traj(n) = n  # j=id+1 从 0 出发的轨迹恰为 n
@assert [traj(n) for n in 0:5] == [0, 1, 2, 3, 4, 5]
@assert all(traj(n) < traj(n + 1) for n in 0:4)

println("Julia：交换图 4×3 对 × 11 点全过；直接极限 20 点恰 9 类；")
println("临界点轨迹 0,1,2,3,4,5 严格递增")
println("END ====")
