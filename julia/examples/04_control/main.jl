# 04 控制流：if/三元/短路、while/for、range、break/continue、一切皆表达式
# 运行：julia --startup-file=no main.jl

# ═══ 04.1 if / elseif / else——是表达式，有返回值
function classify(n::Int)
    if n < 0
        "负数"
    elseif n == 0
        "零"
    elseif ismultiple(n, 3) && ismultiple(n, 5)
        "三五公倍"
    else
        "其他"
    end
end
ismultiple(n::Int, base::Int) = mod(n, base) == 0
@assert classify(-2) == "负数" && classify(0) == "零"
@assert classify(15) == "三五公倍" && classify(7) == "其他"

# if 的值可以直接赋给变量（Julia 没有三元之外的"语句"）
parity = if iseven(4) "偶" else "奇" end
@assert parity == "偶"

# ═══ 04.2 三元与短路求值：a ? b : c、&&、||
@assert (5 > 3 ? "大" : "小") == "大"
# 短路当控制流：&& 当"则"，|| 当"否则"
function checkpos(n)
    n > 0 && return "正"
    n < 0 || return "零"
    return "负"
end
@assert checkpos(5) == "正" && checkpos(0) == "零" && checkpos(-1) == "负"
# 注意：& / | 是按位与非短路，用在布尔上是"两边都算"

# ═══ 04.3 while 与 for——for 遍历一切可迭代物
function countdown(n)
    acc = 0
    i = n
    while i > 0
        acc += i
        i -= 1
    end
    acc
end
@assert countdown(100) == 5050

# for-in：range、数组、字符串（按码点）、字典
# 注意：顶层 for 里给已有全局变量赋值（+=）在脚本模式会 UndefVarError（soft scope 坑，
# 见 04.7）—— accumulate 必须放进函数。REPL 里同一段代码反而能跑，坑上加坑。
function sumstep(range)
    total = 0
    for i in range              # 1,3,5,7,9（start:step:stop）
        total += i
    end
    total
end
@assert sumstep(1:2:9) == 25

function chars(s)
    letters = ""
    for ch in s                 # 字符串按 Unicode 码点迭代
        letters *= ch
    end
    letters
end
@assert chars("abc中文") == "abc中文"

# 倒序与显式步长
rev = []
for i in 5:-1:1
    push!(rev, i)
end
@assert rev == [5, 4, 3, 2, 1]

# ═══ 04.4 break 与 continue——以及"Julia 没有 labeled break"
function firstnegrow(m)        # 找第一个含负数的行号：用 flag + 双重循环
    for (i, row) in enumerate(eachrow(m))
        hasneg = false
        for v in row
            if v < 0
                hasneg = true
                break           # 只跳出内层——外层靠 flag 协调
            end
        end
        hasneg && return i      # && 短路当"则"：hasneg 为真才 return
    end
    return 0
end
m = [1 2; 3 -4; -5 6]
@assert firstnegrow(m) == 2
function countodd(itr)         # continue 跳过本轮回
    c = 0
    for v in itr
        iseven(v) && continue
        c += 1
    end
    c
end
@assert countodd(1:10) == 5

# ═══ 04.5 @goto/@label：函数体内的显式跳转（顶层作用域不可用！）
function collatz_len(n::Int)   # while 的 goto 版本：标签循环
    len = 0
    @label loop
    n == 1 && return len
    n = iseven(n) ? n ÷ 2 : 3n + 1
    len += 1
    @goto loop
end
@assert collatz_len(6) == 8    # 6→3→10→5→16→8→4→2→1 共 8 步
@assert collatz_len(1) == 0

# ═══ 04.6 嵌套循环与笛卡尔积、外层变量遮蔽
pairs = Tuple{Int,Char}[]
for (i, c) in Iterators.product(1:2, 'x':'y')
    push!(pairs, (i, c))
end
@assert length(pairs) == 4 && (1, 'x') in pairs
# for 循环变量每次迭代都是新作用域：外层 x 不被内层污染
x = 99
for x in 1:3; end
@assert x == 99                # 外层 x 不受影响

println("classify(15) = ", classify(15), "；firstnegrow = ", firstnegrow(m), "；collatz_len(6) = ", collatz_len(6))
println("==== 04 结束 ====")
