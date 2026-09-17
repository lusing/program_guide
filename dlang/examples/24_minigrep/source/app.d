// 命令行编排层：getopt 解析 → 收集文件 → 并行 grep → 汇总输出
module minigrep.app;

import std.stdio, std.file, std.path, std.getopt, std.algorithm, std.array,
       std.parallelism, std.range, std.conv;
import std.exception : enforce;
import minigrep.grep;

void main(string[] args) {
    // ── 参数解析 ────────────────────────────────────────────
    Options opt;
    bool showHelp, noColor;
    uint jobs;
    try {
        auto parsed = getopt(args,
            "ignore-case|i", "忽略大小写", &opt.ignoreCase,
            "word|w",        "全词匹配",   &opt.wholeWord,
            "jobs|j",        "并行度（默认 CPU 核数）", &jobs,
            "no-color",      "关闭 ANSI 高亮", &noColor,
            "help|h",        "本帮助", &showHelp,
        );
        if (showHelp) {
            defaultGetoptPrinter("用法：minigrep [选项] <模式> [目录…]", parsed.options);
            return;
        }
        // getopt 原地剥掉已识别选项：args 现在只剩 [程序名, 位置参数…]
        auto pos = args[1 .. $].filter!(a => a.length > 0).array;
        if (pos.empty) {
            defaultGetoptPrinter("用法：minigrep [选项] <模式> [目录…]", parsed.options);
            return;
        }
        string pattern = pos[0];
        string[] roots = pos.length > 1 ? pos[1 .. $] : ["testdata"];

        // ── 文件收集：递归目录 ────────────────────────────────
        string[] files;
        foreach (root; roots) {
            if (isFile(root)) { files ~= root; continue; }
            enforce(exists(root), "路径不存在：" ~ root);
            files ~= dirEntries(root, SpanMode.depth)
                .filter!(de => de.isFile
                        && canFind([".txt", ".md", ".d"], de.name.extension))
                .map!(de => de.name).array;
        }
        enforce(files.length > 0, "没有可搜索的文件");

        // ── 并行搜索：一个文件一个任务 ────────────────────────
        auto pool = jobs > 0 ? new TaskPool(jobs) : taskPool;
        scope (exit) if (jobs > 0) pool.finish();   // 自建池要收尾（全局 taskPool 不用）
        Hit[][] perFile = new Hit[][](files.length);
        foreach (i, file; pool.parallel(files, 1))   // 自建池用成员形式；全局池才写 parallel(...)
            perFile[i] = grepText(readText(file), pattern, file, opt);

        // ── 汇总输出：文件聚组 + 行号 + 高亮 ──────────────────
        long total;
        foreach (i, hits; perFile) {
            if (hits.empty) continue;
            writefln("\033[35m%s\033[0m（%d 处）", files[i], hits.length);
            foreach (h; hits) {
                writefln("  \033[36m%4d\033[0m  %s", h.lineNo,
                    noColor ? h.line : highlight(h.line, pattern, opt));
                total++;
            }
        }
        writefln("共 %d 处命中，扫过 %d 个文件。", total, files.length);
    } catch (GetOptException e) {
        stderr.writeln("参数错误：", e.msg);
    } catch (Exception e) {
        stderr.writeln("错误：", e.msg);
    }
}

unittest {
    // 端到端（不依赖命令行）：直接调 grep 层读 testdata
    import std.file : readText, exists;
    if (exists("testdata/lyrics.txt")) {
        auto hits = grepText(readText("testdata/lyrics.txt"), "D", "testdata/lyrics.txt", Options());
        assert(hits.length > 0);
        foreach (h; hits)
            assert(matches(h.line, "D", Options()));
    }
}
