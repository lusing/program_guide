# 12 字符串：Char/码点、UTF-8、插值、split/join/strip、正则、Printf
# 运行：julia --startup-file=no main.jl

# ═══ 12.1 Char：单个 Unicode 码点（32 位），不是字节
c = '中'
@assert c isa Char && sizeof(Char) == 4
@assert Int('A') == 65 && Char(20013) == '中'    # 码点 ↔ 字符
@assert 'a' < 'z'                                 # 按码点比较
@assert isletter('中') && isdigit('7') && isspace(' ')

# ═══ 12.2 String：不可变、UTF-8 编码；length 数码点，sizeof 数字节
s = "abc中文"
@assert length(s) == 5                            # 码点数
@assert sizeof(s) == 9                            # 字节数：3×1 + 2×3
@assert s[1] == 'a' && s[4] == '中'
@assert length(collect("aé中")) == 3              # collect 按码点拆开
# 字节索引陷阱：s[5] 对多字节字符可能抛 StringIndexError——遍历用迭代，别用字节下标猜
@assert firstindex(s) == 1 && lastindex(s) == 7   # lastindex = 最后一个码点的起始字节下标（"文"从第 7 字节起）
@assert collect("aé") == ['a', 'é']
# 字符串不可变：s[1] = 'x' 非法；改字符串 = 造新串
@assert "J" * "ulia" == "Julia"                   # * 拼接
@assert "ab" ^ 3 == "ababab"
@assert "Julia" == "Julia" && "Julia" === "Julia" # 字符串 === 逐字节比较（intern 无关）

# ═══ 12.3 插值与常用函数
name, ver = "Julia", 13
@assert "你好，$(name) $(ver)!" == "你好，Julia 13!"
# 插值陷阱：$var 后紧跟全角标点或半角 !/? 都会把它们吞进变量名——统一写 $(var)（02 章坑）
@assert string("a", 1, :b) == "a1b"               # string 万能拼接
@assert uppercase("abc") == "ABC" && lowercase("ÁB") == "áb"
@assert strip("  hi  ") == "hi" && lstrip("xxhix", 'x') == "hix"
@assert lpad("7", 3, '0') == "007" && rpad("7", 2) == "7 "
@assert split("a,b,,c", ',') == ["a", "b", "", "c"]
@assert split("a  b   c") == ["a", "b", "c"]      # 默认按空白、去空段
@assert join(["a", "b", "c"], "-") == "a-b-c"
@assert replace("a.b.c", "." => "-") == "a-b-c"   # 替换对（Pair）
@assert replace("a1b2", r"\d" => "#") == "a#b#"   # 正则替换
@assert occursin("ul", "Julia") && !occursin("xy", "Julia")
@assert startswith("Julia", "Ju") && endswith("Julia", "ia")
@assert findfirst("l", "Julia") == 3:3            # 返回范围（第 3 个码点）
@assert findall('a', "banana") == [2, 4, 6]
@assert reverse("abc中") == "中cba"
@assert "b" < "banana" < "c"                       # 字典序

# ═══ 12.4 正则：r"..." 字面量；match/eachmatch/matchrange
m = match(r"(\w+)@(\w+)\.\w+", "mail: a@b.com 结尾")
@assert m.match == "a@b.com"
@assert m.captures == ["a", "b"]
@assert m[1] == "a"                                # 捕获组下标访问
ms = collect(eachmatch(r"\d+", "a1 bb 22 c333"))
@assert length(ms) == 3 && ms[3].match == "333"
@assert occursin(r"^\d{3}$", "123")
@assert match(r"^Julia$", "Julia") !== nothing
# 常用模式：? 非贪婪、(?=...) 前瞻、i/s/m 旗标
@assert match(r"a.+?c"i, "ABC") !== nothing       # i 旗标忽略大小写

# ═══ 12.5 Printf：老朋友 sprintf 的 Julia 版（宏）
using Printf
@assert @sprintf("%.3f", π) == "3.142"
@assert @sprintf("%8.2f|%-6d|%s", 1.5, 42, "hi") == "    1.50|42    |hi"
@assert @sprintf("%05d", 42) == "00042"
@assert @sprintf("%x", 255) == "ff"
@assert @sprintf("%.1e", 12345.0) == "1.2e+04"
# @printf 直接打印（stdout）；宽度和精度与 C 一致

# ═══ 12.6 三引号与原始字符串
big = """
    整体缩进由结尾三引号所在列决定
        这行相对多缩进
    """
@assert occursin("这行相对多缩进", big)
raw_str = raw"C:\temp\new.txt"                    # raw：反斜杠不转义
@assert raw_str == "C:\\temp\\new.txt"

println("s = $(s)：length=$(length(s)) sizeof=$(sizeof(s))；m.captures = ", m.captures)
println("==== 12 结束 ====")
