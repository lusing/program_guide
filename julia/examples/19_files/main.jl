# 19 文件与 IO：open/do、逐行、读写、Serialization、walkdir、路径族、流缓冲
# 运行：julia --startup-file=no main.jl（本示例自建临时数据，无需参数；传参则用作输出目录）

using Serialization

# ═══ 19.1 写文件：open + do（自动 close）
outdir = isempty(ARGS) ? mktempdir() : ARGS[1]
mkpath(outdir)
csv = joinpath(outdir, "scores.csv")
open(csv, "w") do io
    println(io, "name,math,english")
    println(io, "Alice,90,85")
    println(io, "Bob,72,88")
    println(io, "Carol,95,60")
end
@assert isfile(csv)

# ═══ 19.2 读文件：整体读 / 逐行读
content = read(csv, String)                  # 整个文件进一个字符串
@assert occursin("Alice,90,85", content)
lines = readlines(csv)                       # 全部行为 Vector{String}（无换行符）
@assert lines == ["name,math,english", "Alice,90,85", "Bob,72,88", "Carol,95,60"]
n = open(csv) do io                          # 逐行流式（大文件友好）；do 块的返回值就是表达式的值
    sum(length, eachline(io))
end
@assert n == sum(length, lines)
# 还可以按字节：read(io, 4) / read(io) / position(io) / seek(io, 0)

# ═══ 19.3 手写 CSV 解析（逗号分隔；字段无引号转义的简化版）
function parse_csv(path)
    rows = Vector{Vector{String}}()
    for (i, line) in enumerate(eachline(path))
        i == 1 && continue                   # 跳过表头
        push!(rows, split(line, ','))
    end
    rows
end
rows = parse_csv(csv)
@assert rows[1] == ["Alice", "90", "85"] && length(rows) == 3
avg(ks) = sum(parse(Int, r[ks]) for r in rows) / length(rows)
@assert avg(2) == (90 + 72 + 95) / 3
println("数学均分 = ", round(avg(2); digits = 1), "；英语均分 = ", round(avg(3); digits = 1))

# ═══ 19.4 Serialization：任意 Julia 值存盘（注意：Julia 版本间不保证兼容）
ser = joinpath(outdir, "data.ser")
serialize(ser, (header = ["name", "score"], data = [("Alice", 90), ("Bob", 72)]))
back = deserialize(ser)
@assert back.header == ["name", "score"] && back.data[2] == ("Bob", 72)

# ═══ 19.5 目录：mkpath / readdir / walkdir / 临时目录
sub1 = joinpath(outdir, "2026", "09")        # mkpath 一次建多层
mkpath(sub1)
touch(joinpath(sub1, "a.txt"))
touch(joinpath(sub1, "b.log"))
touch(joinpath(outdir, "root.txt"))
@assert isdir(sub1) && isfile(joinpath(sub1, "a.txt")) && !ispath(joinpath(outdir, "nope"))
@assert ispath(csv)
@assert "root.txt" in readdir(outdir)
# readdir 带 join：直接得到完整路径
paths = readdir(outdir; join = true)
@assert csv in paths
# walkdir：递归遍历（root, dirs, files）三元组
allfiles = String[]
for (root, dirs, files) in walkdir(outdir)
    for f in files
        push!(allfiles, relpath(joinpath(root, f), outdir))   # 相对路径便于断言
    end
end
@assert "root.txt" in allfiles && joinpath("2026", "09", "a.txt") in allfiles
@assert length(allfiles) == 5                # csv + ser + root.txt + a.txt + b.log

# ═══ 19.6 路径族：joinpath/basename/dirname/splitext/abspath/homedir
p = joinpath("G:", "code", "guide", "main.jl")   # 跨平台拼接（别手拼字符串）
@assert basename(p) == "main.jl" && dirname(p) == joinpath("G:", "code", "guide")
@assert splitext("data.tar.gz") == ("data.tar", ".gz")   # 只切最后一个扩展名
@assert abspath("x.jl") == joinpath(pwd(), "x.jl")
@assert isabspath("G:\\x") && !isabspath("x/y")
@assert occursin("Users", homedir()) || occursin("home", homedir()) || isdir(homedir())

# ═══ 19.7 stdout 是流：flush 与缓冲
print("缓冲未满时"); print("输出可能延迟")
println("——println 会连同缓冲一起交给传输层")
flush(stdout)                                 # 显式 flush 在长任务进度输出时有用
# stderr 重定向日志、stdin 读取输入：readline()（交互程序见 24 章 CLI）

println("工作目录：$(outdir)")
println("文件清单：$(sort(allfiles))")
println("==== 19 结束 ====")
