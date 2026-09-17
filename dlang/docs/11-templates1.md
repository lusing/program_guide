# 11 · 模板 I：泛型、约束与特化

> 对应示例：`examples/11_templates1/`

## 11.1 语法：模板参数放在函数名后

```d
T myMax(T)(T a, T b) {              // (T) 是模板参数，(T a, T b) 是运行参数
    return a > b ? a : b;
}
myMax(3, 7);                        // T 自动推断
myMax!long(3, 9_000_000_000);       // 显式实例化：名字!类型(实参)
```

对比 C++：没有 `template <typename T>` 前缀、没有 `<>`——D 把模板参数挪到函数名和参数表之间，调用处 `!` 引导。

## 11.2 ⭐ 模板约束：把隐含要求写进签名

```d
double average(T)(T[] xs)
    if (isNumeric!T)                // ← 约束：isNumeric 来自 std.traits
{ ... }

average("abc");                     // 编译错：约束不满足（好报错）
```

为什么比 C++ SFINAE/"实例化失败"强：

- **选择重载时就检查**——多个候选按约束分派，不是"选进去才发现身体不适配"。
- 报错信息直接说 `does not match template constraint`，而不是模板内部炸三层。
- 约束是任意**编译期布尔**：`if (is(T == int) || is(T == long))`、`if (T.sizeof <= 8)` 都行。

std.traits 是约束零件库：`isIntegral!T`、`isFloatingPoint!T`、`isSomeString!T`、`isArray!T`、`isAssociativeArray!T`……

## 11.3 值模板与 eponymous 惯用法

```d
template Factorial(int n) {                 // 模板参数可以是"值"
    static if (n <= 1) enum Factorial = 1;  // 结果名 == 模板名 → 像常量一样用
    else           enum Factorial = n * Factorial!(n - 1);
}
static assert(Factorial!10 == 3_628_800);   // 编译期常量
```

**必须用 `static if` 分段**，不能写成三元：

```d
enum Factorial = n <= 1 ? 1 : n * Factorial!(n - 1);   // ← 编译错！
```

三元的两个分支**都会被实例化**（即使运行时只走一边）→ `Factorial!0 → Factorial!-1 → Factorial!-2 → …` 无限递归直到编译器放弃。这是本章头号坑。

## 11.4 特化：`T : 具体类型`

```d
string typeName(T)()          { return T.stringof; }
string typeName(T : double)() { return "双精度"; }     // 更具体的匹配优先
string typeName(T : int[])()  { return "整数数组"; }

typeName!int       // "int"
typeName!double    // "双精度"
typeName!(int[])   // "整数数组"
```

`T : X` 读作"T 是 X 或 X 的派生/适配"。配合约束可以做精细分派链。

## 11.5 别名参数：函数也能当模板参数

```d
auto mapWith(alias fn, T)(T[] xs) {          // alias：接收任何编译期符号
    foreach (x; xs) fn(x);
}
mapWith!(x => x * x)([1, 2, 3]);             // lambda 直接传
```

`alias` 参数能装：函数、lambda、模板、其他符号——std.algorithm 的 `map!f`、`sort!"a > b"` 全靠它。

## 11.6 模板默认参数

```d
T castTo(T = double, V)(V v) { return cast(T)v; }
castTo(7);          // T 用默认 double：7.0
castTo!float(7);    // 显式覆盖
```

## 11.7 坑位清单

1. **eponymous 模板里禁用三元递归**——`static if` 分段是唯一正确姿势（原因见 11.3）。
2. **std.traits 是 `isFloatingPoint`**：`isFloating` 不存在（报"template not defined"，容易看成拼写建议没细读）。
3. 数组元素的 `.empty` 要 `import std.range`、`.array` 要 `import std.array`——模板体内用的符号**同样受 import 可见性管**。
4. 模板约束写 `if (...)`，不是 `where`/`requires`。
5. `!` 和 `<` 连写会被解析成 `!!<` 之类：`foo!<int>` OK，但 `a !< b` 不是合法比较——历史遗留，注意别把 `!(...)` 与否定搞混。
6. 特化匹配优先级是"更具体者赢"——多个同级特化同时匹配会二义性报错，别指望声明顺序。

---
