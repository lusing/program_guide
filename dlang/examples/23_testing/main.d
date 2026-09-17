// 23 · 测试与工具链：unittest 深入、断言家族、文档与度量
import std.stdio, std.exception, std.conv;
import std.algorithm : map;
import std.array : array;
import std.math : isClose;
import std.string : stripRight;
import std.datetime.stopwatch : StopWatch;

// ── 待测代码：一个小的温度转换器（带文档注释，-D 可生成 ddoc 文档）──

/// 摄氏转华氏。
///
/// Params:
///   celsius = 摄氏温度（允许任意值，包括低于绝对零度——由调用方保证物理合理性）
/// Returns:
///   对应华氏温度
double cToF(double celsius) {
    return celsius * 9 / 5 + 32;
}

/// 解析形如 "36.6C" / "98F" 的温度串，统一返回摄氏。
double parseTemp(string s) {
    s = s.stripRight;
    enforce(s.length >= 2, "温度串太短");
    auto unit = s[$ - 1];
    auto value = s[0 .. $ - 1].to!double;
    switch (unit) {
        case 'C', 'c': return value;
        case 'F', 'f': return (value - 32) * 5 / 9;
        default: throw new Exception("不认识单位：" ~ [unit]);
    }
}

// ── unittest 的组织：按功能分块，一个函数可以有多块 ──────────
unittest {                     // 基础功能
    assert(cToF(0) == 32);
    assert(cToF(100) == 212);
    assert(cToF(-40) == -40);  // 经典交叉点：-40C == -40F
}

unittest {                     // 边界与异常
    assertThrown!Exception(parseTemp("36.6"));
    assertThrown!Exception(parseTemp("36.6X"));
    assertNotThrown!Exception(parseTemp("36.6C"));
    assert(isClose(parseTemp("98.6F"), 37.0, 1e-3));   // 浮点比较用 isClose（approxEqual 已弃用）
    assert(isClose(parseTemp("36.6C"), 36.6));
}

// 模板代码的测试：写在模板声明旁边的 unittest 会随模板一起按实例化生成
struct Box(T) {
    T value;
    T doubled() const { return value + value; }
    unittest {                 // Box!int 被实例化的地方都带着这块测试
        assert(Box!int(21).doubled == 42);
    }
}
unittest {
    assert(Box!int(21).doubled == 42);
    assert(Box!double(1.5).doubled == 3.0);   // 换一种实例化也顺带验证
}

// ── 断言速查 ────────────────────────────────────────────────
// assert(expr)             布尔断言（-release 编译会剥离）
// assertThrown!Ex(expr)    期待抛 Ex（std.exception）
// assertNotThrown!Ex(expr) 期待不抛
// 没有 expectEqual/assertEquals——数组比较就用 assert(a == b)（元素级）
unittest {
    auto got = [1.0, 1.5, 2.0].map!(x => cToF(x)).array;
    assert(got == [33.8, 34.7, 35.6]);
}

void main() {
    writeln("main 只在无 -unittest 编译时执行（本示例 main 无业务逻辑）");

    // StopWatch 简易基准（基准数字只作参考，别写进断言）
    StopWatch sw;
    sw.start();
    long acc = 0;
    foreach (i; 0 .. 1_000_000)
        acc += cToF(i / 10.0) > 0 ? 1 : 0;
    sw.stop();
    writefln("一百万次 cToF：%s ms（acc=%s）", sw.peek.total!"msecs", acc);

    // 更多工具链能力（文档章细讲，命令行）：
    //   dmd -cov       → 生成 .lst 行覆盖率文件
    //   dmd -D -o- …   → 从 ddoc 注释生成文档
    //   rdmd xx.d      → 脚本式"编译+运行"一把梭
    //   dub test       → 工程级跑全部单测（21 章）
    //   dmd -g + WinDbg→ 调试符号（Windows 下 DMD 用 MSVC link.exe，PDB 原生支持）
}
