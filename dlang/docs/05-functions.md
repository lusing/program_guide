# 05 · 函数

> 对应示例：`examples/05_functions/`

## 5.1 参数修饰全家福

```d
int byValue(int x) { x += 1; return x; }       // 默认：值拷贝
void byRef(ref int x) { x += 100; }            // 引用：改调用方本体
int byOut(out int x) { x = 42; return x; }     // 出参：进入时先置 .init，必须赋值后返回
int byIn(in int x) { return x * 2; }           // in = scope const：只读视图
```

- `ref`/`out` **调用处也要写**：`byOut(outVar)` 要写 `byOut(out outVar)`——实参必须左值。
- `out` 的语义：进函数先重置为 `.init`——读"传入值"是错误用法。
- `in` 在 2.113 就是 `scope const`（老教程里说"in 未来会变"的时代结束了）。

## 5.2 默认参数与类型安全变参

```d
string greet(string name = "D 语言") { ... }       // 默认值从右往左连续

int sumAll(T...)(T args) {                          // T...：编译期展开
    int total = 0;
    foreach (a; args) total += cast(int)a;
    return total;
}
sumAll(1, 2, 3, 4);      // 10：每个实参类型可以不同
```

`T...` 不是 C 的 `...`（那种无类型的不安全变参）——它是模板元组，类型信息全保留。

## 5.3 @property：像字段的函数

```d
struct Temperature {
    double celsius;
    @property double fahrenheit() const { return celsius * 9 / 5 + 32; }
    @property void fahrenheit(double f) { celsius = (f - 32) * 5 / 9; }
}

auto t = Temperature(25.0);
writeln(t.fahrenheit);     // 无括号调用 getter
t.fahrenheit = 212;        // setter 也无括号
```

## 5.4 pure / nothrow / @safe：让编译器替你背书

```d
pure int addPure(int a, int b) { return a + b; }     // 无副作用：同输入必同输出
nothrow double safeDiv(double a, double b) {         // 保证不抛异常
    return b == 0 ? double.nan : a / b;
}
```

- `pure`：不读写全局可变状态——编译器可缓存、可并行、可 CTFE。
- `nothrow`：编译器**验证**函数体内任何路径都不抛（违规直接编译错）。
- `@safe`/`@trusted`/`@system`：内存安全分级（15 章结合内存讲）。

这些是可选标注，但库代码标了就是给调用方的**机器可查契约**。

## 5.5 嵌套函数与闭包

```d
int[] makeMultipliers(int base) {
    int mul(int x) { return x * base; }    // 捕获外层 base
    return [1, 2, 3].map!mul.array;        // 作为闭包传出去 → 堆分配
}
```

嵌套函数可以读外层局部变量；**逃逸出定义域**（被返回/存进结构）时编译器自动把捕获装箱到堆——这就是 D 的闭包，无需手写 capture。

## 5.6 ⭐ UFCS：D 的招牌

**任何** `f(a, b)` 都能写成 `a.f(b)`——第一个参数提到前面当"接收者"：

```d
import std.conv, std.algorithm, std.range, std.array;

int n = -5;
n.to!string;                          // == to!string(n)
"42".to!int.to!double;                // 链式转换

10.iota.map!(x => x * x).filter!(x => x % 3 == 0).array;   // 管道！
```

价值在哪？

1. **从左往右读**：数据 → 变换 → 变换，而不是里三层外三层的 `array(filter(map(iota(10), f), g))`。
2. **自定义函数免费升级**：你写的 `int doubled(int)` 自动获得 `42.doubled` 调用权。
3. **泛型扩展**：不改类型定义就能"给它加方法"——D 没有 C#/Kotlin 的 extension 语法，因为根本不需要。

UFCS 也是 std.algorithm 全家能用管道串起来的机制基础（13/14 章）。

## 5.7 函数模板初见

```d
T myMax(T)(T a, T b) { return a > b ? a : b; }   // 尖括号没了：() 前面的 (T) 是模板参数
myMax(3, 7);          // T 推断为 int
myMax!long(3, 7);     // 显式指定
```

D 的模板语法是 `名字(模板参数)(运行参数)`——11 章系统讲（约束/特化/值模板）。

## 5.8 坑位清单

1. **UFCS 找不到符号 ≈ 缺 import**：`42.to!string` 报 "no property to" 就是没 `import std.conv`——D 没有全局自动导入。
2. **`lazy` 是关键字**（惰性参数存储类），不能当变量名。
3. `out` 参数进入时被重置为 `.init`——想在函数里读"调用前的值"是逻辑错误。
4. 嵌套函数捕获外层变量后逃逸 → 堆分配闭包：热路径上注意（`@nogc` 函数里这么干直接编译错，15 章）。
5. 函数重载**不按返回值**；`to!T` 这类"返回值决定行为"的用模板参数实现。
6. D 的 `main` 可以是 `void main()`（默认返回 0）或 `int main()`（自定退出码）或 `void main(string[] args)`——但 BetterC 模式必须 `extern(C) int main()`（22 章）。

---
