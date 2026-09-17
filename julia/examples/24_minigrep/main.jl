# 24 实战：迷你 grep——包工程（MiniGrep 包 + CLI）
# 结构：MiniGrep/（src + test）+ env/（环境）+ 本 CLI
# 运行（build.ps1 自动 --project=env）：
#   julia --project=env main.jl                    # 无参数 → 自建演示树
#   julia --project=env main.jl PATTERN DIRS...    # 实际用法（PATTERN 是正则）
#   julia --project=env -t 4 main.jl PATTERN DIRS... # 多线程搜索

using MiniGrep

"""建一棵演示文件树（无参数运行时用）"""
function make_demo_tree(root)
    mkpath(joinpath(root, "src"))
    mkpath(joinpath(root, "docs"))
    write(joinpath(root, "README.md"),
        """
        # Demo 项目
        Julia minigrep 实战：在 src 与 docs 中搜索 julia。
        """)
    write(joinpath(root, "src", "app.jl"),
        """
        # julia 入口
        function main()
            println("julia minigrep demo")   # julia 再次出现
        end
        """)
    write(joinpath(root, "docs", "note.md"),
        """
        # 笔记
        - Julia 首字母大写时搜不到 julia（默认正则大小写敏感）
        - 想忽略大小写用 (?i)julia(?-i)
        """)
    write(joinpath(root, "data.bin"), "\0\0binary\0julia\0")   # 二进制被扩展名过滤
    root
end

"""CLI 主逻辑（可被测试直接调用）：返回命中总数"""
function run_cli(args)::Int
    if isempty(args)
        root = make_demo_tree(mktempdir())
        pattern_s, dirs = "julia", [root]
        println("（无参数：自建演示树 $(root) 搜索 /julia/）")
    else
        length(args) >= 2 || (println("用法：main.jl PATTERN DIR [DIR...]（PATTERN 是正则）"); return 0)
        pattern_s, dirs = args[1], args[2:end]
    end
    pattern = try
        Regex(pattern_s)
    catch e
        e isa ArgumentError || rethrow()
        println("非法正则：$(pattern_s)")
        return 0
    end
    use_threads = Threads.nthreads() > 1
    hits = Hit[]
    for dir in dirs
        append!(hits, use_threads ? search_dir_threads(pattern, dir) : search_dir(pattern, dir))
    end
    for h in hits
        println(relpath(h.path), ":", h.lineno, ": ", highlight(h.line, h.ranges))
    end
    println("共 $(length(hits)) 处命中（$(use_threads ? "多线程" : "串行")，线程数 $(Threads.nthreads())）")
    length(hits)
end

function @main(args)
    run_cli(args)                    # 入口必须容忍空参数（演示路径）
    println("==== 24 结束 ====")
end
