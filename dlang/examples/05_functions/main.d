// 05 · 函数：参数修饰、属性函数、闭包与 UFCS
import std.stdio, std.algorithm, std.array, std.conv, std.range,
       std.math : isNaN;

// ── 参数家族 ────────────────────────────────────────────────
int byValue(int x) {                 // 值传递（默认）：副本，改动不影响调用方
    x += 1;
    return x;
}

void byRef(ref int x) { x += 100; }  // ref：引用传递，能改调用方变量

int byOut(out int x) {               // out：引用传递且进入时先置 .init
    x = 42;                          // 未赋值就返回会拿到默认值（坑位清单）
    return x;
}

int byIn(in int x) {                 // in = scope const：只读视图（2.113 语义）
    return x * 2;
}

string greet(string name = "D 语言") {  // 默认参数（从右往左连续）
    return "你好，" ~ name;
}

// 可变参数：类型安全的 T...（编译期展开，不是 C 的 ...）
int sumAll(T...)(T args) {
    int total = 0;
    foreach (a; args) total += cast(int)a;   // 演示用；真实代码用模板约束限类型
    return total;
}

// ── 属性函数：像字段一样调用 ────────────────────────────────
struct Temperature {
    double celsius;
    @property double fahrenheit() const { return celsius * 9 / 5 + 32; }
    @property void fahrenheit(double f) { celsius = (f - 32) * 5 / 9; }
}

// ── pure / nothrow / @safe：编译器帮你验证语义 ──────────────
pure int addPure(int a, int b) { return a + b; }   // 无副作用，可缓存/可并行
nothrow double safeDiv(double a, double b) {        // 保证不抛异常
    return b == 0 ? double.nan : a / b;
}

// ── 嵌套函数与闭包 ──────────────────────────────────────────
int[] makeMultipliers(int base) {
    // 嵌套函数捕获外层变量；逃逸出函数 → 编译器自动堆分配闭包
    int mul(int x) { return x * base; }
    return [1, 2, 3].map!mul.array;   // mul 作为闭包传给 map
}

void main() {
    // 参数修饰对比
    int v = 10;
    writeln(byValue(v), " ", v);      // 11 10：副本
    byRef(v);
    writeln(v);                       // 110：真的改了
    int outVar;
    byOut(outVar);
    writeln(outVar);                  // 42
    writeln(byIn(21));                // 42
    writeln(greet(), " / ", greet("D"));  // 默认参数

    // 可变参数
    writeln(sumAll(1, 2, 3, 4));      // 10

    // 属性函数：无括号调用
    auto t = Temperature(25.0);
    writeln(t.fahrenheit);            // 77（没写 fahrenheit()）
    t.fahrenheit = 212;
    writeln(t.celsius);               // 100

    // pure / nothrow
    writeln(addPure(20, 22), " ", safeDiv(1, 0).isNaN);

    // 闭包
    writeln(makeMultipliers(10));     // [10, 20, 30]

    // ── UFCS：D 的招牌——任何函数都能像方法一样调用 ──────────
    int n = -5;
    auto s1 = n.to!string;            // 等价 to!string(n)
    auto s2 = "42".to!int.to!double;  // 链式转换
    writeln(s1, " ", s2);

    // 标准库算法全靠 UFCS 串成管道（13/14 章细讲）
    auto result = 10.iota                       // 0..9
        .map!(x => x * x)                       // 平方
        .filter!(x => x % 3 == 0)               // 留 3 的倍数
        .array;                                 // 收成数组
    writeln(result);                            // [0, 9, 36, 81]

    // 自己写的函数同样享受 UFCS
    writeln(42.doubled);                        // 84
}

int doubled(int x) { return x * 2; }

unittest {
    assert(byValue(1) == 2);
    int x;
    assert(byOut(x) == 42 && x == 42);
    assert(greet("X") == "你好，X");
    assert(sumAll(1, 2) == 3);
    assert(5.doubled == 10);
    assert([1, 2, 3].map!(x => x + 1).array == [2, 3, 4]);
}
