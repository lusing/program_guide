// 19 · 格式化与字符串：writef 占位符全集、std.conv 与 std.string
import std.stdio, std.format, std.conv, std.string, std.array, std.algorithm;
import std.uni : toLower, toUpper;
import std.utf : byDchar;
import std.range : walkLength;
import std.typecons : tuple;
import std.exception : assertThrown;

void main() {
    // ── 占位符：%s 是万能卡，其他是精修 ──────────────────────
    writefln("%s | %d | %x | %o | %b", 255, 255, 255, 255, 255);   // o=八进制输出
    writefln("%e %g", 12345.678, 0.00001);
    writefln("[%10s] [%-10s]", "D", "D");                   // 宽度：右对齐 / 左对齐
    writefln("[%08.3f] [%+.1f]", 3.14159, 2.5);             // 补零/符号/精度
    writefln("%%d 字面量：100%%");
    writefln("%s 的二进制 %b，十六进制 %08X", 42, 42, 0xbeef);

    // bool 按字符串输出；dchar 直接打字符
    writefln("%s %s", true, '汉');

    // ── 数组格式：%(...) 包住每个元素的格式 ────────────────────
    writefln("%(%d, %)", [1, 2, 3]);                        // 1, 2, 3
    writefln("%(%d-%)", [1, 2, 3]);                         // 1-2-3
    writefln("%(0x%02X %)", [0xde, 0xad, 0xbf]);            // 0xDE 0xAD 0xBF
    // tuple 数组：要嵌套两层 %(...)——外层走数组，内层走字段
    auto rows = [tuple("D", 2001), tuple("Go", 2009)];
    writefln("%(%(%s=%d; %)%)", rows);                      // D=2001; Go=2009;

    // format() 生成字符串（同引擎），sformat 已弃用别名
    auto s = format("%s 分 %s 秒", 8, 30);
    writeln(s);

    // ── 解析：formattedRead（format 的逆操作）──────────────────
    int minutes; int seconds;
    formattedRead("8 分 30 秒", "%s 分 %s 秒", &minutes, &seconds);
    writeln(minutes * 60 + seconds, " 秒");

    // ── std.conv：类型转换全家桶（解析失败抛 ConvException，不会 UB）──
    writeln(to!int("42") + 1, " ", to!double("3.5"));
    writeln(255.to!string, " ", true.to!string, " ", 3.14.to!string);
    auto rest = "123abc";
    writeln(parse!int(rest), " ← 只吃前缀，剩余：", rest);   // parse 要左值，吃剩的留在 rest
    // roundTo：四舍五入（不同 truncating cast）
    writeln(roundTo!int(2.7), " ", cast(int)2.7);           // 3 2

    // ── std.string：常用工具 ─────────────────────────────────
    auto messy = "  Hello,  D 语言  ";
    writeln("[", messstrip(messy), "]");
    writeln(messy.split(","));
    writeln(["D", "Go", "Zig"].join("-"));
    writeln("d language".capitalize);
    writeln("HELLO".toLower, " ", "hello".toUpper);
    writeln("a-b-c".replace("-", "+"));
    writeln("abc".dup.reverse);                             // reverse 只能用于可变副本
    writeln(indexOf("hello", "ll") >= 0, " ", "hello".count('l'));
    // 注意：writef/format 的"占位符与实参匹配"是运行期检查（FormatException），
    // 不是编译期检查——别指望编译器帮你抓 %d 配 string

    // ── UTF-8 陷阱复习（06 章欠的账）─────────────────────────
    string zh = "汉字";
    writeln(".length = ", zh.length, "（字节）");             // 6
    writeln("字符数 = ", zh.byDchar.walkLength);             // 2
    writeln("[", format("%6s", zh), "] 宽度按字节算！");      // 宽度坑：中文对齐会歪
}

// strip 的包装（std.string 的 strip 与局部变量演示）
string messstrip(string s) { return s.strip; }

unittest {
    assert(format("%d", 42) == "42");
    assert(format("%.2f", 1.5) == "1.50");
    assert(format("%05d", 42) == "00042");
    assert(format("%(%d|%)", [1, 2]) == "1|2");
    import std.typecons : tuple;
    assert(format("%(%(%s:%d; %)%)", [tuple("a", 1)]) == "a:1; ");
    assert(to!string(255) == "255");
    assert(to!int("42") == 42);            // 注意：to!int 不容忍前后空白（坑）
    assertThrown!ConvException(to!int("abc"));
    {
        auto r = "99 瓶";
        assert(parse!int(r) == 99 && r == " 瓶");
    }
    assert("  x ".strip == "x");
    assert("a,b".split(",") == ["a", "b"]);
    assert(["a", "b"].join("+") == "a+b");
    assert(roundTo!int(2.5) == 3 && cast(int)2.5 == 2);

    int h, m;
    size_t eaten = formattedRead("10:30", "%d:%d", &h, &m);
    assert(eaten == 2 && h == 10 && m == 30);

    import std.utf : byDchar;
    import std.range : walkLength;
    assert("中文".length == 6 && "中文".byDchar.walkLength == 2);
}
