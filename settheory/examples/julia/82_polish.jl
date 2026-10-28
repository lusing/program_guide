# 第 82 章：有限 Banach–Mazur 影子——逆向归纳、策略提取与全对手验证。
println("==== 82")

const DEPTH = 6

function make_solver(S)
    memo = Dict{Vector{Int},Bool}()
    function z(s)
        length(s) == DEPTH && return s in S
        get!(memo, s) do
            iseven(length(s)) ?
                any(z([s; b]) for b in (0, 1)) :
                all(z([s; b]) for b in (0, 1))
        end
    end
    z
end

function make_strategy(S)
    z = make_solver(S)
    function pick(s)
        for b in (0, 1)
            t = [s; b]
            if iseven(length(s))
                z(t) && return b
            else
                !z(t) && return b
            end
        end
        return 0
    end
    pick
end

# 稳赢验证：胜方按策略应对另一方全部 2^3 条路径，每条终局都须命中。
function verify(S)
    z = make_solver(S)
    winner = z(Int[])
    pick = make_strategy(S)
    paths = Iterators.product(fill(0:1, 3)...)
    if winner
        for foe in paths
            s = Int[]
            for b in foe
                s = [s; pick(s); b]
            end
            @assert s in S
        end
        return "zhang"
    else
        for foe in paths
            s = Int[]
            for a in foe
                s = [s; a; pick([s; a])]
            end
            @assert !(s in S)
        end
        return "lisi"
    end
end

allseq = [collect(p) for p in Iterators.product(fill(0:1, DEPTH)...)]
S1 = Set(v for v in allseq if count(==(1), v) >= 4)          # 李四可全 0
S4 = Set(v for v in allseq if v[1] == 1)                      # 张三首手锁定
S8 = Set(v for v in allseq if iseven(count(==(1), v)))        # 末手李四定奇偶
S9 = Set(v for v in allseq if v[1] + v[3] + v[5] >= 2)        # 张三自己的位

@assert verify(S1) == "lisi"
@assert verify(S4) == "zhang"
@assert verify(S8) == "lisi"
@assert verify(S9) == "zhang"
z = make_solver(S4)
@assert z(Int[]) && !z([0])
@assert make_strategy(S4)(Int[]) == 1

println("Julia：四组深度 6 赛局逆向归纳——两组张三稳赢、两组李四稳赢；")
println("稳赢策略经 2^3 条对手路径穷举验证（命题 3.9 的有限影子）")
println("END ====")
