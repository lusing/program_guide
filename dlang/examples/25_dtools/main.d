// 25 · 工具链深入：符号修饰/反修饰、编译器内省（ddemangle 的"库内对应物"）
// 配套手动体验（本章文档 25.2-25.4，均在双平台实测）：
//   rdmd --eval='writeln([1,2,3].sum);'          脚本式执行
//   ./hello.d（#!/usr/bin/env rdmd 的 shebang 脚本）
//   nm hello.o | ddemangle                        反修饰链接器输出
//   dustmite src ../test.sh                       自动最小化 bug 复现
import std.stdio, std.demangle, std.compiler, std.string;

// ── 符号修饰（name mangling）：D 的"类型即符号名" ──────────────
// D 把完整类型签名编进符号名（模板实例也不例外），所以链接器错误里
// 才会出现 _D3std9algorithm... 这样的长串——ddemangle 管的就是它。
// 程序内可以用 mangleof 编译期取符号名、std.demangle.demangle 还原。

class Parser {
    int line;
    int parse(string src) { return cast(int) src.length + line; }
}

T twice(T)(T x) { return x + x; }

// ── 反修饰（demangle）测试 ────────────────────────────────────
unittest {
    // 类符号直接用 C 前缀形式（class 类型标签进符号名）：C4main6Parser
    enum cls = Parser.mangleof;
    assert(cls == "C4main6Parser");
    assert(demangle(cls) == cls);

    // 函数/变量才是 _D 开头，且带完整签名；string 在符号名里是 immutable(char)[]
    enum fn = Parser.parse.mangleof;
    assert(fn.startsWith("_D"));
    assert(demangle(fn) == "int main.Parser.parse(immutable(char)[])");

    // 模板实例：实例化参数 + 推导的属性全进符号名
    enum tf = (twice!int).mangleof;
    assert(demangle(tf) == "pure nothrow @nogc @safe int main.twice!(int).twice(int)");
}

// ── 编译器/平台内省（std.compiler / std.system）──────────────
unittest {
    assert(name == "Digital Mars D");        // 编译器身份
    assert(version_major == 2);              // 大版本
    // version_minor 对本教程锁定 113（2.113）
    static if (__traits(compiles, version_minor))
        assert(version_minor == 113);
}

void main() {
    // 1) mangleof → demangle 的对子：和命令行 ddemangle 同一套规则
    writeln("Parser.mangleof = ", Parser.mangleof);
    writeln("demangle        = ", demangle(Parser.mangleof));
    writeln("twice!int       = ", demangle((twice!int).mangleof));

    // 2) 未捕获异常/链接错误里的修饰名，都可以这样或 `xx | ddemangle` 还原
    //    （真实未捕获异常栈见 23 章；命令行管道用法见本章文档 25.3）

    // 3) 编译器身份：写跨编译器代码时分支用（LDC/GDC 同名常量各自的值）
    writefln("compiler = %s %s.%s", name, version_major, version_minor);
    version (D_Coverage)   writeln("本程序是 -cov 编译的");
    else                   writeln("本程序非 -cov 编译");

    // 4) 本章其余工具是"命令行工具"，程序内体验入口：
    //    rdmd / ddemangle / dustmite / dub run <工具包> —— 见文档 25.2-25.7
}
