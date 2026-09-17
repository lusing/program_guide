// 11 · 模板 I：泛型函数、模板约束与特化
import std.stdio, std.conv, std.traits, std.range;

// ── 函数模板：T 自动推断 ────────────────────────────────────
T myMax(T)(T a, T b) {
    return a > b ? a : b;              // 只要 T 支持 > 就能用
}

// ── 模板约束：把"隐含要求"写进签名 ──────────────────────────
// 比起 C++ 的"实例化失败才发现"，D 在选择重载时就检查约束
double average(T)(T[] xs)
    if (isNumeric!T)                   // isNumeric 来自 std.traits
{
    if (xs.empty) return 0;
    double total = 0;
    foreach (x; xs) total += x;
    return total / xs.length;
}

// 约束可以写任意编译期布尔表达式（函数体内再配 static if 细分派）
string describe(T)(T value) {
    static if (isIntegral!T)        return formatInt(value);
    else static if (isFloatingPoint!T) return formatFloat(value);
    else                            return value.to!string;
}

// ── eponymous 模板：值模板 ──────────────────────────────────
// 注意：必须用 static if 分段——写成 `n <= 1 ? 1 : n * Factorial!(n-1)`
// 三元式会在 n==1 时仍实例化 Factorial!0 → 无限递归（坑位清单头号）
template Factorial(int n) {            // 模板名即结果名 → 用起来像常量
    static if (n <= 1) enum Factorial = 1;
    else           enum Factorial = n * Factorial!(n - 1);
}

// is(...) 探针 + 值模板组合
template isNumeric(T) {
    enum isNumeric = isIntegral!T || isFloatingPoint!T;
}

// ── 特化：为特定类型走专属路径 ────────────────────────────────
string typeName(T)()           { return T.stringof; }
string typeName(T : double)()  { return "双精度"; }    // T:double 是特化匹配
string typeName(T : int[])()   { return "整数数组"; }
string typeName(T : ubyte)()   { return "小字节"; }

// ── 模板参数：类型、值、别名（三样都能当参数）─────────────────
// 别名参数：接收函数/lambda/模板（编译期多态的基石）
auto mapWith(alias fn, T)(T[] xs) {
    auto result = new typeof(fn(xs[0]))[xs.length];
    foreach (i, x; xs) result[i] = fn(x);
    return result;
}

// 模板默认参数 + 显式实例化
T castTo(T = double, V)(V v) { return cast(T)v; }

void main() {
    // 自动推断 + 显式指定
    writeln(myMax(3, 7), " ", myMax(2.5, 1.5), " ", myMax!long(3, 9_000_000_000));

    // 约束：string 不是数值类型，average("ab") 直接编译错（试删注释）
    writeln(average([1, 2, 3, 4]));            // 2.5
    writeln(average([1.5, 2.5]));              // 2

    // static if 分派
    writeln(describe(42), " ", describe(3.14), " ", describe("文本"));

    // 值模板：Factorial!5 在编译期就是常量
    writeln(Factorial!5);                      // 120
    writeln(Factorial!10);
    static assert(Factorial!10 == 3_628_800);

    // 特化：越"具体"的越优先匹配
    writeln(typeName!int, " ", typeName!double, " ", typeName!(int[]), " ", typeName!ubyte);

    // 别名参数：lambda 直接传
    auto squares = mapWith!(x => x * x)([1, 2, 3, 4]);
    writeln(squares);                          // [1, 4, 9, 16]
    auto lengths = mapWith!(s => s.length)(["D", "语言"]);
    writeln(lengths);                          // [1, 6]

    // 默认模板参数
    writeln(castTo(7), " ", castTo!float(7));
}

private:
string formatInt(T)(T v) { return "整数 " ~ v.to!string; }
string formatFloat(T)(T v) { return "浮点 " ~ v.to!string; }

unittest {
    assert(myMax(1, 2) == 2 && myMax("a", "b") == "b");
    assert(average([1, 2, 3]) == 2);
    static assert(Factorial!0 == 1 && Factorial!5 == 120);
    assert(typeName!double == "双精度");
    assert(typeName!(int[]) == "整数数组");
    assert(mapWith!(x => x + 1)([1, 2]) == [2, 3]);
    assert(castTo(3) == 3.0);
    // 约束在编译期拒绝错误类型：
    static assert(!__traits(compiles, average("abc")));   // string[] 不满足 isNumeric!T
}
