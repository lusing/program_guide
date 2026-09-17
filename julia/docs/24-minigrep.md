# 24 · 实战：迷你 grep（包工程）

> 对应示例：`examples/24_minigrep/`（包工程：MiniGrep 包 + env 环境 + CLI）
>
> 24 章集大成：包结构（17）、类型与方法（06/08）、正则（12）、异常（13）、文件（19）、多线程（21）、测试（18）。

## 24.1 目标与结构

一个真 grep 的微缩版：**正则模式、递归目录、多线程分片、ANSI 高亮、可测试的包**。

```text
examples/24_minigrep/
├── MiniGrep/               ← 可独立发布的包
│   ├── Project.toml        # name/uuid/version + [compat]
│   ├── src/MiniGrep.jl     # 核心库（纯函数，零 IO 假设之外的依赖）
│   └── test/runtests.jl    # 包级测试（Pkg.test 入口）
├── env/
│   ├── Project.toml        # [deps] MiniGrep + [sources] 路径依赖（17 章）
│   └── Manifest.toml       # instantiate 生成
├── main.jl                 # CLI 入口（@main，容忍空参数）
└── runtests.jl             # 端到端测试
```

**库与 CLI 分离**：MiniGrep 包只管搜索逻辑（易测试、可复用），main.jl 只管参数与展示——和 rust minigrep 的经典分层同构。

## 24.2 核心类型：Hit

```julia
struct Hit
    path::String
    lineno::Int
    line::String
    ranges::Vector{UnitRange{Int}}    # 命中区间（字节下标，可多段）
end

Base.:(==)(a::Hit, b::Hit) = a.path == b.path && a.lineno == b.lineno &&
                             a.line == b.line && a.ranges == b.ranges
```

`==` 必须自己定义（08 章坑位）：struct 默认 `==` 落到 `===`（身份），含 Vector 字段时两次搜索结果"长得一样"也不相等——实测多线程版与串行版的断言就挂在这里。

## 24.3 搜索内核：match_ranges → search_file → search_dir

```julia
match_ranges(pattern::Regex, line) =
    [m.offset:(m.offset + sizeof(m.match) - 1) for m in eachmatch(pattern, line)]
    # 正则 match 的 offset 是字节偏移——与 String 内部 UTF-8 一致

function search_file(pattern, path)
    hits = Hit[]
    try
        for (i, line) in enumerate(eachline(path))     # 19 章逐行流式
            rs = match_ranges(pattern, line)
            isempty(rs) || push!(hits, Hit(String(path), i, line, rs))
        end
    catch; end          # 读不了的（二进制/权限）跳过——grep 语义
    hits
end

function search_dir(pattern, root; extensions = (".txt", ".md", ".jl", ".csv", ".toml"))
    files = String[]    # walkdir 递归 + 扩展名过滤（19 章）
    for (dir, _, names) in walkdir(root), name in names
        any(ext -> endswith(name, ext), extensions) && push!(files, normpath(joinpath(dir, name)))
    end
    sort!(files)        # 文件序固定 → 结果确定性
    vcat(map(f -> search_file(pattern, f), files)...)
end
```

确定性是设计出来的：**文件排序 + 行号自然序**——同输入永远同输出（测试断言的前提）。

## 24.4 多线程版：分块 @spawn + 排序归并（21 章三板斧之"分块聚合"）

```julia
function search_dir_threads(pattern, root; ...)
    # ... 收集并排序 files 同上 ...
    chunks = [files[a:b] for k in 1:ntasks]          # 按线程数切块
    tasks = map(chunks) do chunk
        Threads.@spawn vcat(map(f -> search_file(pattern, f), chunk)...)   # 每块一个任务
    end
    hits = vcat(fetch.(tasks)...)                     # 收集
    sort!(hits; by = h -> (h.path, h.lineno))         # ★ 关键：归并后重排
    hits
end
```

任务完成的先后随机——**结果在聚合后重排**恢复确定性。实测断言 `search_dir_threads(...) == search_dir(...)`（依赖 24.2 的 `==`）。CLI 按线程数自动选路：`Threads.nthreads() > 1` 走并行版（build.ps1 以 `-t 4` 验证双路径）。

## 24.5 ANSI 高亮：字节区间的切分（12 章字节/码点的实践）

```julia
function highlight(line, ranges)
    io = IOBuffer()
    prev = 1
    for r in ranges
        if first(r) > prev                                   # 边界守卫：行首命中/相邻命中
            print(io, SubString(line, prev, first(r) - 1))
        end
        print(io, "\e[1;31m", SubString(line, r), "\e[0m")   # 红色加粗
        prev = last(r) + 1
    end
    prev <= sizeof(line) && print(io, SubString(line, prev))
    String(take!(io))
end
```

两个细节：`\e[1;31m ... \e[0m`（加粗红/复位）；`SubString(line, a, b)` 是**字节下标**——正则 offset 给的就是字节偏移，且匹配边界必在码点边界上，切分安全（实测中文前后缀均正确）。空前置/尾置段要跳过（`SubString(s, 5, 4)` 会炸——实测坑）。

## 24.6 CLI：@main 与空参数约定（02/17 章）

```julia
function run_cli(args)::Int
    if isempty(args)                      # 空参数 → 自建演示树（可验证入口的约定）
        root = make_demo_tree(mktempdir())
        pattern_s, dirs = "julia", [root]
    else
        length(args) >= 2 || (println("用法：main.jl PATTERN DIR [DIR...]"); return 0)
        pattern_s, dirs = args[1], args[2:end]
    end
    pattern = try Regex(pattern_s) catch e; e isa ArgumentError || rethrow(); ...; end
    ...
end
function @main(args)
    run_cli(args)
    println("==== 24 结束 ====")
end
```

错误处理三处（13 章策略）：坏正则消化为提示 + 返回 0；`search_file` 内部吞 IO 错跳过；其余 rethrow。

## 24.7 测试：单元 + 性质 + 端到端（18 章三件套）

```julia
# 单元：search_file 命中行号与内容
@test hits[1].lineno == 1 && hits[1].line == "alpha julia beta"
# 性质：串行 == 多线程（确定性）
@test search_dir(r"julia", tree) == search_dir_threads(r"julia", tree)
# 边界：高亮的多段/行首/中文前置
@test highlight("中文 julia", match_ranges(r"julia", "中文 julia")) == "中文 \e[1;31mjulia\e[0m"
# 端到端：CLI 函数带参调用 + @test_nowarn
@test run_cli(["(?i)julia", tree]) == 4     # 忽略大小写开关的语义验证
```

## 24.8 运行与验证

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 24_minigrep     # 工程：instantiate+运行+测试（-t 4）
julia --project=examples/24_minigrep/env examples/24_minigrep/main.jl "minigrep" docs examples
```

无参数运行自建演示树，实测输出（ANSI 高亮在支持终端可见红色）：

```text
README.md:2: Julia minigrep 实战：在 src 与 docs 中搜索 julia。
docs/note.md:2: - Julia 首字母大写时搜不到 julia（默认正则大小写敏感）
...
共 5 处命中（多线程，线程数 4）
```

## 24.9 延伸方向

- `-i`/`-n`/`-v` 旗标解析（ARGS 手撸或 Comonicon/ArgParse.jl）；
- 流式输出（Channel + @async 流水线，20 章）；
- gitignore 过滤、.git 二进制跳过（walkdir 里加谓词）；
- BenchmarkTools 对比串行/多线程在万级文件下的吞吐（16/21 章方法）。

## 24.10 坑位清单

1. **struct 含 Vector 字段的 `==`**：默认按身份——串行/多线程结果断言相等必挂；值语义自己定义（24.2 实测）。
2. **多线程结果要重排**：任务完成序随机——聚合后 `sort!(by = (path, lineno))` 恢复确定性（24.4）。
3. **高亮的空区间切片**：行首命中/相邻命中时 `SubString(line, prev, prev-1)` 抛错——前后段都要边界守卫（24.5 实测）。
4. **正则 offset 是字节不是码点**：与 String 内部编码一致所以安全；但拿去切 `collect(line)` 的结果数组就会错位——区间只配切原始字符串。
5. **CLI 入口别赌参数**：`-e include` 也会触发 `@main(String[])`（02 章实测）——空参数路径是验证的一部分，不是可有可无的礼貌。
