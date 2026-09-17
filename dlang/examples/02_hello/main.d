// 02 · 第一个程序：输出、格式化与单测
// 运行：dmd -w -run main.d
import std.stdio;   // writeln / writef 家族都在这

void main() {
    // writeln：任意数量参数，自动加换行
    writeln("你好，D 语言！");
    writeln("编号：", 42, "，π ≈ ", 3.14159);

    // writef / writefln：C 风格格式串（%s 万能，见下表）
    writefln("整数 %d，十六进制 0x%x，二进制 %b", 255, 255, 255);
    writefln("浮点 %.2f（两位小数），科学计数 %e", 3.14159, 12345.678);
    writefln("字符串 [%10s] 右对齐，[%-10s] 左对齐", "D", "D");
    writefln("百分号转义：100%%");

    // std.format 与 writef 同一套占位符（19 章细讲）
    import std.format : format;
    auto s = format("%s 个苹果，单价 %.1f 元", 3, 2.5);
    writeln(s);

    // pragma(msg)：编译期输出消息（不进运行时，CI 打日志用）
    // 编译时会在控制台打印一行：编译期消息：hello
    pragma(msg, "编译期消息：hello");
}

unittest {
    // unittest 块：dmd -w -unittest -run main.d 只跑测试不跑 main（见坑位）
    import std.format : format;
    assert(format("%d", 42) == "42");
    assert(format("%.2f", 3.14159) == "3.14");
    assert(format("%x", 255) == "ff");
}
