module MiniGrep

export Hit, search_file, search_dir, search_dir_threads, highlight

"""一次命中：文件、行号、该行内容、命中区间（字节下标，可多段）"""
struct Hit
    path::String
    lineno::Int
    line::String
    ranges::Vector{UnitRange{Int}}
end

# 注意：struct 默认的 == 落到 ===（按身份）——含 Vector 字段时两次搜索"长得一样"也不相等。
# 值语义要自己定义（08 章：不可变 + 纯 isbits 字段才有免费的逐位 ===）。
Base.:(==)(a::Hit, b::Hit) =
    a.path == b.path && a.lineno == b.lineno && a.line == b.line && a.ranges == b.ranges

"""行内全部命中的字节区间（正则匹配偏移即字节偏移）"""
match_ranges(pattern::Regex, line::AbstractString) =
    [m.offset:(m.offset + sizeof(m.match) - 1) for m in eachmatch(pattern, line)]

"""单文件搜索：返回 Hit 向量（行号从 1 起；IO 错误时返回空——grep 语义是"跳过打不开的"）"""
function search_file(pattern::Regex, path::AbstractString)
    hits = Hit[]
    try
        for (i, line) in enumerate(eachline(path))
            rs = match_ranges(pattern, line)
            isempty(rs) || push!(hits, Hit(String(path), i, line, rs))
        end
    catch
        # 读不了的（二进制/权限）直接跳过
    end
    hits
end

"""递归目录搜索（串行版）：只看文本类扩展名，结果按 (path, lineno) 排序保证确定性"""
function search_dir(pattern::Regex, root::AbstractString;
                    extensions = (".txt", ".md", ".jl", ".csv", ".toml"))
    files = String[]
    for (dir, _, names) in walkdir(root)
        for name in names
            if any(ext -> endswith(name, ext), extensions)
                push!(files, normpath(joinpath(dir, name)))
            end
        end
    end
    sort!(files)
    vcat(map(f -> search_file(pattern, f), files)...)
end

"""多线程版：文件分块派发给 @spawn 任务，结果合并后重排（与串行版输出一致）"""
function search_dir_threads(pattern::Regex, root::AbstractString;
                            extensions = (".txt", ".md", ".jl", ".csv", ".toml"))
    files = String[]
    for (dir, _, names) in walkdir(root)
        for name in names
            if any(ext -> endswith(name, ext), extensions)
                push!(files, normpath(joinpath(dir, name)))
            end
        end
    end
    sort!(files)
    isempty(files) && return Hit[]
    ntasks = min(Threads.nthreads(), length(files))
    chunks = [files[floor(Int, (k - 1) * length(files) / ntasks) + 1:floor(Int, k * length(files) / ntasks)]
              for k in 1:ntasks]
    tasks = map(chunks) do chunk
        Threads.@spawn begin
            vcat(map(f -> search_file(pattern, f), chunk)...)
        end
    end
    hits = vcat(fetch.(tasks)...)
    sort!(hits; by = h -> (h.path, h.lineno))
end

"""ANSI 高亮一行：命中区间红色加粗（区间是字节下标；匹配边界必在字符边界上，切安全）"""
function highlight(line::AbstractString, ranges::Vector{<:UnitRange{Int}})
    isempty(ranges) && return String(line)
    io = IOBuffer()
    prev = 1
    for r in ranges
        if first(r) > prev                                       # 命中前（可能为空：行首命中/相邻命中）
            print(io, SubString(line, prev, first(r) - 1))
        end
        print(io, "\e[1;31m", SubString(line, r), "\e[0m")       # 命中段
        prev = last(r) + 1
    end
    if prev <= sizeof(line)                                      # 尾段
        print(io, SubString(line, prev))
    end
    String(take!(io))
end

end # module
