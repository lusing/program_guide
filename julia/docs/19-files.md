# 19 · 文件与 IO

> 对应示例：`examples/19_files/`

## 19.1 open + do：自动 close

```julia
open(path, "w") do io           # 块退出自动 close（异常也关）
    println(io, "name,math,english")
    println(io, "Alice,90,85")
end
```

模式串与 C 一致：`"r"`（默认）`"w"` `"a"` `"r+"`…… 实测坑：**`open(p, append=true)` 的关键字不生效**（静默走默认写模式）——追加必须 `open(p, "a")`。

## 19.2 读：整读、逐行、字节

```julia
content = read(path, String)      # 整个文件进一个字符串
lines = readlines(path)           # 全部行 → Vector{String}（去行尾符）
n = open(path) do io              # 逐行流式（大文件友好）；do 块的返回值即表达式值
    sum(length, eachline(io))
end
# 更底层：read(io, 4)、position(io)、seek(io, 0)
```

eachline 也能直接吃路径：`for line in eachline(path)`。

## 19.3 实战：手写 CSV 解析

```julia
function parse_csv(path)
    rows = Vector{Vector{String}}()
    for (i, line) in enumerate(eachline(path))
        i == 1 && continue               # 跳表头
        push!(rows, split(line, ','))
    end
    rows
end
avg(ks) = sum(parse(Int, r[ks]) for r in rows) / length(rows)
```

不带引号转义的简化版（真实 CSV 用 CSV.jl）——但展示的正则/分割/解析三连是通用功。

## 19.4 Serialization：任意 Julia 值存盘

```julia
using Serialization
serialize(path, (header = ["name", "score"], data = [("Alice", 90)]))
back = deserialize(path)
back.data[2] == ("Bob", 72)
```

快而省事；**不承诺跨 Julia 大版本兼容**——长期存档用 CSV/JSON/Arrow 这类稳定格式。

## 19.5 目录：readdir / walkdir / mkpath

```julia
mkpath(joinpath(outdir, "2026", "09"))      # 一次建多层（mkdir -p）
touch(path)                                  # 空文件/改时间戳
isdir / isfile / ispath                      # 三连判定
readdir(outdir)                              # 文件名数组
readdir(outdir; join = true)                 # 直接给完整路径
for (root, dirs, files) in walkdir(outdir)   # 递归三元组
    for f in files
        push!(allfiles, joinpath(root, f))
    end
end
rm(dir; recursive = true, force = true)      # 删目录（测试沙箱清理）
```

## 19.6 路径族

```julia
joinpath("G:", "code", "guide", "main.jl")   # 跨平台拼接（别手拼字符串）
basename(p) / dirname(p)
splitext("data.tar.gz")      # ("data.tar", ".gz")——只切最后一个扩展名
abspath("x.jl") / isabspath("G:\\x")
relpath(target, base)        # 相对路径（walkdir 断言好用）
homedir() / tempdir() / pwd()
```

注意分隔符：Windows 上输出含 `\`——**断言路径用 `joinpath` 构造期望值**，别硬编码 `/` 或 `\`。

## 19.7 stdout/stderr 与缓冲

```julia
print("无换行"); print("继续")
println("——println 顺带刷缓冲")     # 行缓冲（TTY）或块缓冲（管道）
flush(stdout)                        # 长任务进度显式刷新
stderr 重定向日志、readline() 读 stdin（交互程序用）
```

管道下 Julia 输出是块缓冲——本教程示例末行打印"==== NN 结束 ===="再退出，保证进程结束时缓冲全部落盘（build.ps1 靠它验证输出完整）。

## 19.8 坑位清单

1. **`open(p, append = true)` 不追加**：关键字被静默忽略——模式串 `open(p, "a")` 才对（19.1 实测）。
2. **顶层 do 块里给全局累加**：soft scope 又来了（04 章）——让 do 块**返回**结果再赋值：`n = open(p) do io; ...; end`（19.2 实测修法）。
3. **println 不加换行符时追加会接行**：`print(io, "无换行")` 后另开句柄 println，两段在同一条"行"里——行是换行符定义的（19 章示例实测）。
4. **Serialization 不跨版本**：换 Julia 大版本反序列化可能失败——交换格式用 CSV/JSON（19.4）。
5. **Windows 路径断言**：`joinpath`/`relpath` 产 `\`——期望值同样用 joinpath 构造（19.6）。
6. **文件写完不 flush/close 就读**：do 块保证 close；手写 `io = open(...)` 别忘 close——异常路径漏关是老 bug 高发区。
