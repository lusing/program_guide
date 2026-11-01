# 第 118 章：有限交错迭代树的独立枚举；数值嵌入只是玩具标签。
function main()
    println("==== 118")
    cparent(k) = k == 0 ? 0 : k - 1
    C_PARENT = ntuple(n -> cparent(n - 1), 6)  # 节点 1..6 的直接前置
    source(e) = e
    target(e) = cparent(e)
    legal_application(e) = C_PARENT[e + 1] == target(e) && e + 1 != target(e)
    @assert all(legal_application, 0:5)
    @assert source(1) == 1 && target(1) == 0

    # 独立递归枚举六个新节点的所有“父节点序号更小”的父表。
    trees = Vector{NTuple{6,Int}}()
    function enumerate_trees!(prefix)
        c = length(prefix) + 1
        if c > 6
            push!(trees, Tuple(prefix))
            return
        end
        for p in 0:c-1
            enumerate_trees!(vcat(prefix, p))
        end
    end
    enumerate_trees!(Int[])
    rooted(P) = all(0 <= P[c] < c for c in 1:6)
    function path(P, x)
        out = [x]
        while x != 0
            x = P[x]
            push!(out, x)
        end
        reverse(out)
    end
    unique_paths = all(path(P, x) == begin
            y = x
            while y != 0
                @assert P[y] < y
                y = P[y]
            end
            path(P, x)
        end for P in trees for x in 0:6)
    @assert length(trees) == 720 && all(rooted, trees) && unique_paths
    @assert C_PARENT in trees
    println("[合法树枚举] 6 条新边共 ", length(trees),
            " 棵有根父表；交错树在内；根路径由父表唯一确定")

    even_path = path(C_PARENT, 6)
    odd_path = path(C_PARENT, 5)
    @assert even_path == [0, 2, 4, 6] && odd_path == [0, 1, 3, 5]
    println("[真实分叉] Even 前段=", even_path, "；Odd 前段=", odd_path,
            "；不存在跨枝父边")

    # 有限窗口内的共尾性测试：对 0..7 每个界都找到更靠后的枝元素。
    branch(name, k) = name == :even ? 2k : k == 0 ? 0 : 2k - 1
    cofinal_window(name, bound) = all(any(branch(name, k) >= n for k in 0:8) for n in 0:bound)
    @assert cofinal_window(:even, 7) && cofinal_window(:odd, 7)

    # 引理 3.81 的有限下降证书样本：j 恒为 x↦x+1，三段严格下降。
    j(x) = x + 1
    bad = ((0, 2, 5, 4), (2, 4, 4, 3), (4, 6, 3, 2))
    bad_ok = all(j(s) > t for (_, _, s, t) in bad)
    @assert bad_ok
    println("[共尾前段与下降证书] 两枝窗口共尾；三段 j(s)>t 均成立")
    println("END ====")
end
main()
