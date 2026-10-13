# 第 15 章 OD/HOD：可定义性闭包与 Berry 悖论演示
#
# 1. OD 的语义：cl({V_α}) 的生成——集合从序数层的可定义运算；
# 2. HOD 的遗传闭包计算（有限域）；
# 3. Berry 悖论（习题 15.17）的数值形态。

println("==== 15 OD 与 HOD")

# ---------- 一、可定义闭包的微型引擎 ----------

"从种子里经（配对/并）运算生成的闭包"
function definable_closure(seeds::Vector{String}, steps::Int)
    S = Set(seeds)
    for _ in 1:steps
        cur = collect(S)
        for x in cur, y in cur
            push!(S, "{$x,$y}")        # Gödel 配对为代表
            push!(S, "{$x}")           # 单点
        end
    end
    return S
end

# 种子：序数层的代表（∅ 与 {∅}——V_α 的骨架）
closure = definable_closure(["{}"], 3)
println("从 ∅ 出发 3 步的可定义闭包大小 = ", length(closure))
println("成员样本：", collect(closure)[1:min(5, end)])
@assert "{{},{}}" in closure            # {∅,{∅}} 可定义生成

# ---------- 二、HOD 的遗传判定（有限域） ----------

"集合的传递闭包（解析嵌套字符串的递归下降）"
function tc_of(s::String, seen=Set{String}())
    s in seen && return seen
    push!(seen, s)
    inner = s[2:end-1]
    (isempty(inner)) && return seen
    depth = 0; cur = ""; parts = String[]
    for c in inner
        c == '{' && (depth += 1)
        c == '}' && (depth -= 1)
        c == ',' && depth == 0 && (push!(parts, strip(cur)); cur = ""; continue)
        cur *= c
    end
    push!(parts, strip(cur))
    for p in parts
        tc_of(p, seen)
    end
    return seen
end

# HOD 判定：每个成员都在可定义闭包中
is_hod(x, closure) = tc_of(x) ⊆ closure

for x in ["{}", "{{}}", "{{},{}}"]
    println("  HOD($x) = ", is_hod(x, closure))
end
@assert is_hod("{}", closure)

# ---------- 三、Berry 悖论（习题 15.17） ----------

println("\nBerry 悖论的集合论形态：")
println("  假设'可定义'可定义 ⟹ 存在最小不可定义序数 δ")
println("  但'δ = 最小不可定义序数'恰是 δ 的定义——矛盾")
println("  ⟹ '可定义'本身不是集合论语言的谓词（Tarski 式分层）")
println("  OD 的安全性：参数限于序数（canonical 良序锚定自指被剪断）")

println("END ====")
