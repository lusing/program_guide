// 18 · 文件与 IO：std.file、File 与路径处理
// 注意：std.file 和 std.stdio 同时导入时，write/copy 等符号会打架 → 冲突处用限定名（坑）
import std.file;         // 文件系统层：整读整写、目录、元信息
import std.stdio;        // 流式层：File、byLine、writef
import std.path;         // 纯路径字符串操作（不碰磁盘）
import std.process : environment, thisProcessID;
import std.algorithm, std.array;
import std.typecons : tuple;
import std.string : splitLines;
import std.range : enumerate;

void main() {
    auto dir = buildPath(tempDir, "dguide_demo");
    mkdirRecurse(dir);
    std.file.write(buildPath(dir, "a.txt"), "第一行：hello\n第二行：world\n");
    appendFile(buildPath(dir, "a.txt"), "第三行：D\n");

    // 读：readText 一次进内存（UTF-8 校验）
    auto text = readText(buildPath(dir, "a.txt"));
    writeln("读到 ", text.splitLines.length, " 行");
    foreach (i, line; text.splitLines.enumerate)
        writeln("  行", i, "：", line);

    // 逐行流式读大文件：File.byLine（不整读，内存友好）
    {
        File f = File(buildPath(dir, "a.txt"), "r");
        foreach (line; f.byLine)
            write("  [流式] ", line, " | ");
        writeln();
    }

    // 写文本/格式化：File 的 writef/writeln
    {
        File log = File(buildPath(dir, "log.txt"), "w");
        foreach (i; 1 .. 4)
            log.writefln("条目 %02d：值 %.2f", i, i * 1.5);
    }   // File 是 struct：作用域结束自动 close（RAII）

    // 复制 / 元信息
    std.file.copy(buildPath(dir, "a.txt"), buildPath(dir, "b.txt"));
    writeln("b.txt 大小 ", getSize(buildPath(dir, "b.txt")), " 字节");

    // 目录树遍历：dirEntries 三种模式
    mkdirRecurse(buildPath(dir, "sub"));
    std.file.write(buildPath(dir, "sub", "c.txt"), "嵌套");
    foreach (de; dirEntries(dir, SpanMode.depth))       // 深度优先（目录夹在中间）
        writeln("  [depth] ", de.name, de.isDir ? "/" : "");
    writeln("---");
    foreach (de; dirEntries(dir, SpanMode.breadth))     // 广度优先
        std.stdio.write(baseName(de.name), " ");        // 裸 write 会撞 std.file.write（坑）
    writeln();

    // 只挑 .txt
    auto txts = dirEntries(dir, SpanMode.depth)
        .filter!(de => de.isFile && de.name.extension == ".txt")
        .array;
    writeln("共 ", txts.length, " 个 .txt");

    // 路径操作
    auto p = buildPath("G:", "code", "guide", "dlang", "README.md");
    writeln("basename=", p.baseName, " dirname=", p.dirName);
    writeln("ext=", p.extension, " 改成 .bak → ", p.setExtension(".bak"));

    // 环境变量 / 进程信息
    writeln("PATH 前 20 字符：", environment.get("PATH")[0 .. 20]);
    writeln("本进程 PID：", thisProcessID);

    // 清理（rmdirRecurse 连目录一起删）
    rmdirRecurse(dir);
    assert(!exists(dir));
    writeln("清理完成");
}

// append 的包装（躲开 write/read 符号冲突的另一招：薄包装函数）
void appendFile(string path, string content) {
    File f = File(path, "a");
    f.write(content);
}

unittest {
    import std.file : exists, mkdirRecurse, rmdirRecurse, readText;
    auto dir = buildPath(tempDir, "dguide_unittest");
    mkdirRecurse(dir);
    std.file.write(buildPath(dir, "t.txt"), "中文内容");
    assert(readText(buildPath(dir, "t.txt")) == "中文内容");
    assert(exists(buildPath(dir, "t.txt")));
    assert(buildPath(dir, "t.txt").extension == ".txt");
    assert("a/b/c.d".baseName == "c.d");
    assert("a/b/c.d".dirName == "a/b");
    rmdirRecurse(dir);
}
