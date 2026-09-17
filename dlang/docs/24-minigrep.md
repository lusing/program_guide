# 24 · 实战：迷你 grep

> 对应示例：`examples/24_minigrep/`（DUB 工程）

## 24.1 目标与结构

把前面 23 章串起来：一个**递归目录、多线程并行、ANSI 高亮、带单测**的迷你 grep。

```text
24_minigrep/
├── dub.json
├── source/
│   ├── app.d          ← 编排层：getopt → 收集文件 → 并行 → 输出
│   └── grep.d         ← 核心层：纯函数（matches/grepText/highlight），零 IO
└── testdata/          ← 固定语料（默认搜索目标，保证运行确定性）
```

**分层原则**：grep.d 不碰磁盘、不碰命令行——逻辑全部可单测；app.d 只做"胶水"（参数/文件/线程编排）。这是全部 D 工程的推荐结构。

## 24.2 核心层（grep.d）

```d
struct Hit { string file; size_t lineNo; string line; }
struct Options { bool ignoreCase; bool wholeWord; }

bool matches(string line, string needle, const Options opt) { ... }
Hit[] grepText(string text, string needle, string fileName, const Options opt) {
    Hit[] hits;
    foreach (i, line; text.splitter('\n').enumerate)      // 13 章：区间 enumerate
        if (matches(line, needle, opt))
            hits ~= Hit(fileName, i + 1, line);
    return hits;
}
string highlight(string line, string needle, const Options opt) {
    ... "\033[30;103m" ~ 命中片段 ~ "\033[0m" ...         // ANSI 转义
}
```

字符串搜索用 **std.string.indexOf**（自带起始下标重载，找不到 -1）——比自己写循环+std.algorithm 拼干净。

## 24.3 命令行层（app.d）

```d
auto parsed = getopt(args,
    "ignore-case|i", "忽略大小写", &opt.ignoreCase,
    "word|w",        "全词匹配",   &opt.wholeWord,
    "jobs|j",        "并行度",     &jobs,
    "no-color",      "关闭高亮",   &noColor,
    "help|h",        "帮助",       &showHelp,
);
if (showHelp) { defaultGetoptPrinter("用法：…", parsed.options); return; }
auto pos = args[1 .. $];            // getopt 原地剥掉已识别选项，位置参数留在这
```

## 24.4 并行搜索

```d
auto pool = jobs > 0 ? new TaskPool(jobs) : taskPool;
scope (exit) if (jobs > 0) pool.finish();

Hit[][] perFile = new Hit[][](files.length);
foreach (i, file; pool.parallel(files, 1))        // 自建池用成员形式（17 章坑位）
    perFile[i] = grepText(readText(file), pattern, file, opt);
```

每文件一个任务、结果按下标回写（无竞争）；`workUnitSize=1` 让任务粒度足够细。

## 24.5 测试策略

```d
unittest {                                    // grep.d：纯逻辑毫秒级回归
    assert(!matches("theme theater", "the", Options(false, true)));
    assert(matches("theme the end", "the", Options(false, true)));
    auto hl = highlight("abXXcd", "xx", Options(true));
    assert(hl.canFind("\033[30;103mXX\033[0m"));
}
unittest {                                    // app.d：端到端（有语料才跑）
    if (exists("testdata/lyrics.txt"))
        assert(grepText(readText("testdata/lyrics.txt"), "D", ...).length > 0);
}
```

## 24.6 用法

```bash
dub run                     # 默认搜 testdata，关键词 D
./bin/minigrep -i -w d      # 忽略大小写 + 全词
./bin/minigrep -j 4 --no-color Go testdata
```

## 24.7 本章新坑（前面章节没踩过的）

1. **`defaultGetoptPrinter(text, options)` 要两个参数**：options 从 `getopt` 返回值 `.options` 拿——单参数版本 2.113 编译不过。
2. **位置参数在原地改写的 `args` 里**：`getopt` 后 `args[0]` 仍是程序名，位置参数是 `args[1 .. $]`。
3. **私有函数别和标准库同名**：示例里自写 `indexOf` 与 std.algorithm/std.string 的同名符号在 UFCS 解析里打架——要么改名（示例改 `findFrom` 后干脆换成了 std.string.indexOf），要么选择性导入。
4. 测试里的断言**数据自己要核对**：`"the theme"` 的第一个 the 本来就是全词——错误期望让正确实现"看起来失败"（24 示例实测修订过）。

## 24.8 扩展练习

1. 加 `-c` 只输出计数；`-n` 关行号（现在的行号是默认）。
2. 用 13 章 range 改造：`grepText` 返回惰性区间而不是数组。
3. 加 `-r` 正则模式（`std.regex`）。
4. 把结果聚组改成 `File[string]` AA 按修改时间排序（std.datetime）。

---
