// 03 · 类型：整数家族、浮点、字符、const/immutable 与转换
import std.stdio, std.conv, std.math : isNaN;

void main() {
    // ── 整数：固定位宽，字节序无关 ──────────────────────────
    byte  a =  8;        //  8 位有符号
    short b = 300;
    int   c = 100_000;   // 数字分隔符：编译期忽略
    long  d = 9_000_000_000_000L;
    ubyte e = 250;       //  8 位无符号
    uint  f = 4_000_000_000U;

    writeln("int 最大值 ", int.max, "，占 ", int.sizeof, " 字节");
    static assert(int.sizeof == 4);            // 编译期检查

    // 字面量进制：十进制 / 十六 / 二；D 没有 0o 八进制字面量（坑位清单）
    import std.conv : octal;
    writeln(0xDEAD, " ", 0b1010_1010, " ", octal!755, " ", 'A');

    // 整数溢出：D 定义为按 2 补码回绕（不是未定义行为）
    int maxed = int.max;
    writeln("int.max + 1 = ", maxed + 1);      // -2147483648
    // 想要检查溢出用 core.checkedint（文档章提）

    // ── 浮点：float / double / real ────────────────────────
    // real 在 x86 是 80 位扩展精度，别的平台可能等于 double
    real pi = 3.141592653589793L;
    writeln("real 精度演示：", pi * 1e10);
    writeln("float.epsilon = ", float.epsilon);
    // 浮点 == 比较是坑，用 approxEqual（19 章）

    // ── 字符：三种宽度，都是 Unicode 码点 ───────────────────
    char  ch  = 'A';     // UTF-8  码元（8 位）
    wchar wch = '汉';    // UTF-16 码元（16 位）
    dchar dch = '🚀';    // UTF-32 码点（32 位，任意字符）
    writeln(ch, " ", wch, " ", dch);
    writeln("dchar 大小：", dchar.sizeof, " 字节");

    // ── auto / const / immutable / enum ────────────────────
    auto x = 42;             // 类型推断：int
    const int y = 100;       // 运行期只读（初始化后不能改）
    immutable int z = 200;   // 深层不可变：可安全跨线程共享（16 章）
    enum speed = 300_000;    // 编译期常量：不占内存，内联进代码
    writeln(x, " ", y, " ", z, " ", speed);
    static assert(is(typeof(speed) == int));   // enum 保底层类型

    // ── 转换：cast（可能丢数据）与 to!（安全转换）────────────
    int  big = 300;
    byte truncated = cast(byte)big;            // 静默截断：44
    writeln("cast(byte)300 = ", truncated);
    auto parsed = "12345".to!int;              // std.conv：解析失败抛异常
    auto back   = 678.to!string;               // UFCS：等价 to!string(678)
    writeln(parsed + 1, " ", back);

    // 隐式转换规则：小 → 大、非 const → const 可以；反向必须显式
    long wide = c;             // int → long：隐式 OK
    // int narrow = d;         // long → int：编译错（显式 cast 才行）
    writeln("隐式加宽：", wide);
}

unittest {
    // 类型内省：.stringof / typeof / is 表达式
    static assert(int.stringof == "int");
    static assert(is(typeof(3.0) == double));
    assert(int.max == 2_147_483_647);
    assert(int.init == 0 && double.init.isNaN);   // .init：零值/NaN 初始化
}
