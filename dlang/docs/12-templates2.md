# 12 · 模板 II：CTFE、static if、mixin 与编译期反射

> 对应示例：`examples/12_templates2/`

## 12.1 ⭐ CTFE：编译期求值，没有 constexpr 关键字

```d
long factorial(long n) {              // 就是普通函数
    long r = 1;
    foreach (i; 2 .. n + 1) r *= i;
    return r;
}

enum f10 = factorial(10);                    // enum 右侧 → 编译期求值
static assert(factorial(20) == 2_432_902_008_176_640_000);
writeln(factorial(10));                      // 运行时调用同一个函数！
```

规则：**函数用在编译期位置就编译期算，用在运行期位置就运行时算**——一份代码两种执行模式。编译期位置：`enum` 右侧、`static assert` 条件、模板值实参、`pragma(msg)` 参数、数组长度……

```d
string slug(string s) { ... }                  // 字符串处理也能 CTFE
pragma(msg, slug("DLangGuide"));               // 编译期打印：d_lang_guide
```

限制：CTFE 里不能用内联汇编/不安全指针戏法/IO——纯计算 OK。

## 12.2 static if / static foreach：编译期分支与循环

```d
string typeInfoOf(T)() {
    static if (isIntegral!T)             return T.stringof ~ "（整数族）";
    else static if (isFloatingPoint!T)   return T.stringof ~ "（浮点族）";
    else                                 return T.stringof;
}
```

- `static if` 分支**不参与编译**（没选中的分支甚至可以有语法上依赖类型的代码）——比 C 预处理 #if 强（它懂类型），比 C++ `if constexpr` 早 15 年。
- `static foreach` 在编译期展开循环体——配合反射生成代码。

## 12.3 ⭐ mixin：把代码"注入"进去

**string mixin**——字符串（通常 CTFE 生成）被当源码编译：

```d
string genGetters(names...)() {                 // 编译期生成源码文本
    string code;
    foreach (n; names) code ~= "int " ~ n ~ "; ";
    return code;
}

struct Config {
    mixin(genGetters!"extra");                  // 产出：int extra;
}
```

**template mixin**——现成的声明块混入：

```d
mixin template Traceable() {
    string tag;
    void trace() const { writeln("trace ", tag); }
}
struct Config {
    mixin Traceable;                            // 字段+方法整套进来
}
```

**mixin + static foreach 生成 switch**（04 章欠的账）：

```d
enum Color { red, green, blue }
string pick(Color c) {
    final switch (c) {
        static foreach (m; EnumMembers!Color) {
            case m: return m.to!string;         // return 天然终止，绕开 break 陷阱
        }
    }
}
```

这就是"元编程即代码生成"——D 生态里序列化器/ORM 的魔法源头。

## 12.4 is 表达式与 __traits：编译期探针

```d
static assert(is(typeof(3.0) == double));
static assert(is(T == int[]));                  // 类型形状匹配
static assert(isForwardRange!(int[]));          // 13 章大量用

foreach (member; __traits(allMembers, Config))  // 反射成员名
    writeln(member);

static assert( __traits(compiles, cfg.extra));  // "能编译"本身是布尔
static assert(!__traits(compiles, cfg.nope));
```

`__traits(compiles, ...)` 是"鸭子类型检查器"——探测某个用法是否存在，是泛型代码的试错探针。

## 12.5 坑位清单

1. **enum 函数已弃用**：老教程 `enum long f(int n) {...}` → Deprecation。普通函数 + 编译期位置就够了。
2. **string mixin 里是 D 源码**：拼接时漏个分号，报错行号指向 mixin 处——调试技巧：先在普通函数里生成同样文本打印出来看。
3. **static foreach 体有多条语句要花括号**：不带括号只循环第一条——04 章的"case 穿透"事故就是它。
4. **static foreach 里裸 `break` 非法**（要求标签）——生成 case 时用 `return` 或 `break 标签:`。
5. `isNumeric` 这类判断可以自己用 eponymous 模板 + std.traits 组合（示例里有）——但先查 std.traits，别重复造轮子。
6. `pragma(msg, ...)` 输出在**编译阶段**——它不是 println，别在运行期逻辑里指望它。
7. CTFE 求值的函数里 `foreach` 没问题，但要避免 `cast` 指针运算等"运行期专属"操作，否则 CTFE 失败报错把你带回运行期。

---
