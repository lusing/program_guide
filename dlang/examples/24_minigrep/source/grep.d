// 核心逻辑层：纯函数、无 IO、可单测（与 app.d 的命令行/并行编排解耦）
module minigrep.grep;

import std.algorithm, std.array;
import std.range : enumerate;
import std.string : indexOf;

/// 单条命中：文件、行号、该行内容
struct Hit {
    string file;
    size_t lineNo;
    string line;
}

/// 搜索选项（值类型，随便传）
struct Options {
    bool ignoreCase;   // -i
    bool wholeWord;    // -w
}

/// 判断一行是否命中（纯字符串逻辑）
bool matches(string line, string needle, const Options opt) {
    string hay = opt.ignoreCase ? toLowerAscii(line) : line;
    string key = opt.ignoreCase ? toLowerAscii(needle) : needle;
    if (!opt.wholeWord)
        return hay.canFind(key);
    // 全词匹配：前后是边界（行首/行尾/非字母数字下划线）
    // std.string.indexOf(s, needle, startIdx) 自带起始下标重载，找完返回 -1
    ptrdiff_t pos = 0;
    while ((pos = hay.indexOf(key, pos)) != -1) {
        bool leftOk  = pos == 0 || !isWordChar(hay[pos - 1]);
        bool rightOk = pos + key.length == hay.length || !isWordChar(hay[pos + key.length]);
        if (leftOk && rightOk) return true;
        pos++;
    }
    return false;
}

/// 在一段文本里搜出全部命中（文本行号从 1 开始）
Hit[] grepText(string text, string needle, string fileName, const Options opt) {
    Hit[] hits;
    foreach (i, line; text.splitter('\n').enumerate)
        if (matches(line, needle, opt))
            hits ~= Hit(fileName, i + 1, line);
    return hits;
}

/// 把命中片段加 ANSI 高亮（黄色底 + 黑字：\033[30;103m … \033[0m）
string highlight(string line, string needle, const Options opt) {
    string hay = opt.ignoreCase ? toLowerAscii(line) : line;
    string key = opt.ignoreCase ? toLowerAscii(needle) : needle;
    string out_;
    size_t pos = 0;
    while (true) {
        auto hit = hay.indexOf(key, pos);
        if (hit == -1) { out_ ~= line[pos .. $]; break; }
        out_ ~= line[pos .. hit]
            ~ "\033[30;103m" ~ line[hit .. hit + key.length] ~ "\033[0m";
        pos = hit + key.length;
    }
    return out_;
}

private:
bool isWordChar(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
        || (c >= '0' && c <= '9') || c == '_';
}

string toLowerAscii(string s) {          // 不引入 std.uni 的全 Unicode 大小写：ASCII 够用
    char[] r = s.dup;
    foreach (ref c; r)
        if (c >= 'A' && c <= 'Z') c += 32;
    return cast(string)r;
}

// ── 单元测试：核心逻辑不碰磁盘，毫秒级回归 ──────────────────
unittest {
    const Options def;

    // 大小写
    assert(matches("Hello D", "hello", Options(true)));
    assert(!matches("Hello D", "hello", def));

    // 全词：子串出现 ≠ 全词出现
    assert(matches("the theme", "the", def));                       // 普通模式：子串即命中
    assert(!matches("theme theater", "the", Options(false, true))); // 只作为子串 → 不中
    assert(matches("theme the end", "the", Options(false, true)));  // 中间那个是独立词 → 中

    // grepText 行号
    auto hits = grepText("alpha\nbeta gamma\nalpha", "alpha", "t.txt", def);
    assert(hits.length == 2);
    assert(hits[0].lineNo == 1 && hits[1].lineNo == 3);
    assert(hits[0].file == "t.txt");

    // 高亮
    auto hl = highlight("abXXcd", "xx", Options(true));
    assert(hl.canFind("\033[30;103mXX\033[0m"));
    assert(hl[0 .. 2] == "ab" && hl[$ - 2 .. $] == "cd");
}
