# 03 · 类型系统

> 对应示例：`examples/03_types/`

## 3.1 固定位宽整数

```d
byte   a =   8;    //  int8     ubyte  e = 250;   // uint8
short  b =  300;   // int16     ushort
int    c = 100_000;// int32     uint   f = 4_000_000_000U;
long   d = 9_000_000_000_000L;   // int64  ulong
size_t n = arr.length;           // 无符号，指针宽度（64 位系统=ulong）
```

- 数字分隔符 `_` 编译期忽略：`1_000_000`。
- 后缀：`U`（无符号）、`L`（long）。
- 字面量进制：`0xDEAD`（十六）、`0b1010_1010`（二）。**没有 `0o` 八进制字面量**——用 `std.conv` 的 `octal!755`（编译期校验）。

每个类型自带属性：

| 属性 | 含义 | 例 |
|---|---|---|
| `.max` / `.min` | 极值 | `int.max == 2_147_483_647` |
| `.init` | 初始零值（浮点是 NaN） | `int.init == 0` |
| `.sizeof` / `.alignof` | 大小/对齐（字节） | `int.sizeof == 4` |
| `.stringof` | 名字字符串 | `double.stringof == "double"` |

**整数溢出是定义行为**：按 2 补码回绕（`int.max + 1 == int.min`），不是 C 的 UB。想要检查用 `core.checkedint`。

## 3.2 浮点：float / double / real

```d
real pi = 3.141592653589793L;
```

`real` 是"硬件能给的最大浮点"——x86 上 80 位（80 位扩展精度），ARM 上通常等于 double。浮点**别用 `==`**，用 `std.math.isClose`（`approxEqual` 已弃用，23 章测试里再示范）。

## 3.3 字符：char / wchar / dchar——三种宽度全是 Unicode

```d
char  ch  = 'A';     // UTF-8  码元：8 位（汉字占 3 个）
wchar wch = '汉';    // UTF-16 码元：16 位
dchar dch = '🚀';    // UTF-32 码点：32 位，任意字符一个装得下
```

字符**字面量** `'汉'` 的类型是 `dchar`（编译器自动装最窄的可表示宽度）。字符串细节在 06 章——`.length` 按字节算是 D 最大的新手坑之一。

## 3.4 auto / const / immutable / enum

```d
auto x = 42;              // 推断：int
const int y = 100;        // 运行期只读（初始化后不可改，无传递性保证）
immutable int z = 200;    // 深层不可变：整个对象图冻住 → 可安全跨线程共享（16 章）
enum speed = 300_000;     // 编译期常量：不占内存，使用处内联
```

| | const | immutable | enum |
|---|---|---|---|
| 何时定 | 运行期 | 运行期 | 编译期 |
| 深度 | 只读视图 | 全冻 | 就是字面量 |
| 内存 | 占 | 占 | 不占 |

注意：**enum 变量保留底层类型**（`is(typeof(speed) == int)`）；声明 `immutable int[] s = ...` 时 immutable 会"传递"到元素（16 章讲 `immutable(int)[]` vs `immutable(int[])` 的坑）。

## 3.5 转换：cast 与 to!

```d
int big = 300;
byte t = cast(byte)big;          // 静默截断：44——你要为正确性负责
auto n = "12345".to!int;         // std.conv：解析，失败抛 ConvException
auto s = 678.to!string;          // UFCS：等价 to!string(678)
```

- **隐式转换**只允许"安全"方向：窄→宽、非 const→const；反向必须显式。
- `to!` 是 D 的瑞士军刀：数字↔字符串↔枚举↔布尔（`to!string(true) == "true"`）。
- 有符号↔无符号混算要小心：`-1 < 1u` 在 D 里是 `false`（-1 被提升为无符号巨数）——和 C 一样的坑，编译器会警告。

## 3.6 static assert：把类型事实钉进编译期

```d
static assert(int.sizeof == 4);
static assert(is(typeof(3.0) == double));
static assert(!__traits(compiles, "abc".to!int + 1));  // 探测"能不能编译"
```

`static assert` 是编译期断言——配合 12 章的 `__traits`/`is()` 就是 D 的编译期元编程地基。

## 3.7 坑位清单

1. **没有 `0o` 八进制字面量**：`0o755` 编译错；用 `import std.conv : octal; octal!755`。
2. **enum 函数已弃用**：`enum long f(int) {...}` 会报 Deprecation——普通函数在编译期上下文自动 CTFE（12 章），不再需要 enum 修饰函数。
3. `isFloating` 不存在，std.traits 里叫 **`isFloatingPoint`**。
4. `.isNaN` 在 `std.math`，`to!` 在 `std.conv`——**符号找不到九成是缺 import**，D 不会自动导入这些。
5. 数字字面量直接给 `ubyte`/`short` 要能装下：`ubyte b = 255;` OK；`ubyte b = 256;` 编译错。
6. `char` 参与算术会提升成 int：`'a' + 1` 是 int；赋回 char 要 cast。

---
