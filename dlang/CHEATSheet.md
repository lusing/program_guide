# D 语言速查（DMD 2.113 实测版）

> 配套 [26 章教程](docs/01-overview.md)。所有条目在 DMD 2.113.0 / **Windows x64 + Linux x86_64 + macOS x86_64** 三平台验证（macOS 实测：DMD 2.113.0 + DUB 1.42.0，25 个示例全通过）。

## 编译与运行

```bash
dmd -w -run main.d                # 编译并运行（-w 警告当错误）
dmd -w -unittest -run main.d      # 只跑 unittest（main 不执行！）
dmd -w main.d -ofapp.exe          # 出 exe（PowerShell 里 -of 必须整体加引号！）
dmd -w -i -Isource source/app.d  # 多模块递归编译
dmd -w -betterC betterc.d         # 无 GC/运行时模式（main 必须 extern(C) int main()）
rdmd xx.d                         # 脚本式（随 DMD，缓存编译产物）
rdmd --eval='writeln([1,2,3].sum);'  # 一行式
dub build / dub run / dub test    # 工程三连（21 章）
dub run dfmt -- --inplace src/    # 跑注册表工具（25 章）
nm xx.o | ddemangle               # 反修饰链接器符号（25 章）
dustmite src ../test.sh           # 最小化 bug 复现（测试脚本在源码目录外！）
./app --DRT-gcopt=help            # 运行时开关：GC 调参（26 章）
```

## 语法骨架

```d
import std.stdio, std.algorithm, std.range, std.array, std.conv;

void main(string[] args) {
    // 变量/常量
    auto x = 42;  const y = 1;  immutable z = 2;  enum N = 3;
    // 集合
    int[3] fixed;  int[] dyn = [1, 2, 3];  int[string] aa = ["k": 1];
    // 控制流
    foreach (i, v; dyn) {}
    foreach (k, v; aa) {}
    final switch (值) { case ...: break; }        // case a: .. case b: 是范围语法
    // 函数/模板/约束
    // T f(T)(T a) if (约束) { }
}
```

## 函数特性

```d
void f(in int a, ref int b, out int c, lazy int d) {}   // in=scope const
int sum(T...)(T args) {}                                 // 类型安全变参
@property int front() { }                                // 属性函数：无括号调用
pure / nothrow / @safe / @nogc                          // 编译器验证的承诺
42.doubled                                              // UFCS：f(a,b) == a.f(b)
```

## 错误处理

```d
throw new Exception("msg", __FILE__, __LINE__);
enforce(cond, "msg");                          // 条件不满足就抛
try {} catch (Exception e) {} finally {}
scope (exit) 清理;  scope (failure) 回滚;  scope (success) 提交;   // 统一逆序执行
Nullable!int maybe;                            // maybe.isNull / .get / .get(-1)
int f(int x) in (x > 0) out (r; r > 0) do {}   // 契约（块体用 do 引导）
assertThrown!Ex(expr);  assertNotThrown!Ex(expr);
```

## 模板与编译期

```d
T maxOf(T)(T a, T b) if (isNumeric!T) { }     // 约束
template F(int n) { static if (n <= 1) enum F = 1; else enum F = n * F!(n-1); }
                                               // 值模板必须 static if（禁三元递归）
static if (isIntegral!T) { }                   // 编译期分支
static foreach (m; EnumMembers!E) { }          // 编译期循环（体内 break 要标签）
mixin(genGetters!"x");                         // string mixin：注入生成的代码
mixin template Traceable() { }  struct S { mixin Traceable; }
enum v = factorial(10);                        // CTFE：enum 右侧编译期求值
pragma(msg, "编译期日志");
__traits(allMembers, S);  __traits(compiles, expr);
```

## 区间与算法

```d
// 区间协议：empty / front / popFront（+save / back / opIndex 升级）
isInputRange!T;  isForwardRange!(int[]);       // 数组实参必须 !( ) 括住！
iota(0, 10, 3);  chain(a, b);  cycle(x).take(5);  recurrence!("a[n-1]+a[n-2]")(1, 1);
r.take(n);  r.drop(n);  r.retro;  r.stride(2);  zip(a, b);
xs.map!(x => x * 2).filter!(p).array;          // 惰性管道（UFCS）
xs.reduce!((a, b) => a + b);                   // 无种子
reduce!op(种子, xs);                            // 带种子：别 UFCS！
xs.fold!op;  xs.sort;  xs.sort!"a > b";  xs.sort!((a,b) => ...);
canFind / count!p / countUntil / all!p / any!p / sum / minElement / group / uniq / chunks
equal(r1, r2);                                 // 区间内容比较（== 只给数组）
sequence!"n"(0)                                // 无限自然数（iota(0) 是空区间！）
```

## 内存

```d
auto o = new C(...);                // GC（delete 已废除）
GC.collect();  GC.stats().usedSize;
@nogc f() {}                        // 编译期禁 GC 分配
auto p = cast(int*)malloc(n * int.sizeof);  free(p);   // core.stdc.stdlib
auto rc = RefCounted!T(args);       // rc.refCountedPayload
auto o2 = scoped!C(args);           // 栈上类
```

## 并发

```d
// 消息传递（std.concurrency）
auto tid = spawn(&worker, thisTid);
tid.send(msg);  auto m = receiveOnly!T;
receive((int x) {}, (string s) {});
receiveTimeout(50.msecs, (string s) {});
receiveOnly!(immutable(int)[]);     // 形状要和 cast(immutable int[]) 一致！
// 数据并行（std.parallelism）
foreach (i, ref x; parallel(arr)) {}        // 索引是 size_t
taskPool.reduce!命名函数(种子, 数据);         // 禁内联 lambda
auto t = task!f(args); t.executeInNewThread(); t.yieldForce();  // 没有 force()
// 原子（core.atomic）
shared int c;  atomicOp!"+="(c, 1);  atomicLoad(c);  cas(&v, exp, new_);
```

## 格式化与转换

```d
writefln("%s %d %x %.2f %10s %-10s", ...);
writefln("%(%d, %)", arr);                 // 数组逐元素
writefln("%(%(%s=%d; %)%)", tupleArr);     // tuple 数组要嵌套
formattedRead(s, "%d:%d", &a, &b);
to!int("42");  255.to!string;  roundTo!int(2.7);
parse!int(rest);                           // 只吃前缀（要左值）
isClose(a, b);                             // approxEqual 已弃用
"  x ".strip;  s.split(",");  arr.join("+");  s.toLower;
str.byDchar.walkLength;                    // 字符数（str.length 是字节数）
```

## JSON（2.113 旧 API）

```d
auto jv = parseJSON(txt);
jv["k"].str / .integer / .boolean / .get!int;
jv["a"].array;  jv["o"].object;            // JSONValue[]
"k" in jv.object;                          // 返回指针！(!is null 判存在)
JSONValue root = JSONValue.emptyObject;
root["k"] = "v";  arr.array = [JSONValue(1)];
toJSON(root);  toJSON(root, true);         // pretty 是布尔第二参
```

## C 互操作

```d
extern (C) int printf(const(char)* fmt, ...);
extern (C) int cmp(const(void)* a, const(void)* b) { }   // 给 C 的回调
struct Packed { align(1) ubyte a; align(1) uint b; }     // 打包要逐成员
asm nothrow @nogc { rdtsc; }               // DMD x86-64 内联汇编
// -betterC：extern(C) int main() 必须
```

---

## ⚠ 2.113 实测坑位索引（老教程重灾区）

| # | 坑 | 正解 |
|---|---|---|
| 1 | `dmd -unittest` 编译的程序不跑 main | 测试/main 分开编译（build.ps1 两层） |
| 2 | PowerShell 裸 `-of=app.exe` 静默产出空名/无产物 | `'-of=app.exe'` 整体引号 |
| 3 | 没有 `0o755` 八进制字面量 | `std.conv.octal!755` |
| 4 | switch 范围写成 `case a .. b:` | `case a: .. case b:` |
| 5 | 接口方法带体不写 final 编译错 | `final string name() { }` |
| 6 | struct opEquals 用 ref 接不了右值 | `bool opEquals(const S o) const` |
| 7 | AA 读不存在的键抛 RangeError | `in` / `.get(k, 默认)` |
| 8 | `str.length` 是 UTF-8 字节数 | `.byDchar.walkLength` |
| 9 | `isXxxRange!int[]` 解析成 bool 数组 | `!(int[])` 括号 |
| 10 | eponymous 模板三元递归编译器崩 | `static if` 分段 |
| 11 | `iota(0)` 是空区间（单参=stop） | `sequence!"n"(0)` 做无限流 |
| 12 | `0 .. N` 只能用在 foreach | 函数传参用 `iota` |
| 13 | parallel 的索引是 size_t | 赋 int 元素要 cast |
| 14 | taskPool.reduce 用内联 lambda 触发弃用 | 模块级命名函数 |
| 15 | `Task.force` 不存在 | `yieldForce/spinForce/workForce` |
| 16 | `lazy` 是关键字 | 换变量名 |
| 17 | `cast(immutable int[])x` 是 `immutable(int)[]` | 两侧类型形状要一致 |
| 18 | worker 未捕获异常 → 主线程死等不报错 | worker 内 try-catch 回报消息 |
| 19 | std.file 与 std.stdio 的 write/copy 撞名 | 限定名 `std.file.write(...)` |
| 20 | tuple 数组格式 `%(%s:%d%)` 抛异常 | 嵌套 `%(%(%s:%d; %)%)` |
| 21 | `to!int(" 42 ")` 不吃空白 | 先 strip；`parse!` 要左值 |
| 22 | format 参数匹配是运行期检查 | FormatException 靠测试兜 |
| 23 | `toJSON` 没有 prettyPrint 选项 | `toJSON(v, true)` 布尔参 |
| 24 | 默认 JSONValue `~=` 追加抛"not an array" | 先 `v.array = [...]` |
| 25 | JSON 大整数抛 ConvOverflowException | 拆字段/当字符串处理 |
| 26 | betterC 用 `void main()` 链接失败 | `extern(C) int main()` |
| 27 | `align(1) struct` 不打包成员 | 逐成员 `align(1)` |
| 28 | enum 函数已弃用 | 普通函数 + CTFE |
| 29 | `.empty/.array` 找不到 | import std.range / std.array |
| 30 | 多个选择性 import 不能逗号串一行 | 分开写 |
| 31 | `TaskPool.close()` 不存在 | `finish()` |
| 32 | `parallel(r, n, pool)` 三参不存在 | 成员形式 `pool.parallel(r, n)` |
| 33 | dub test 叠 -unittest 配置双 main | 直接裸 `dub test` |
| 34 | `dmd -i` 找不到模块 | 加 `-Isource`；模块名=路径 |
| 35 | 普通 import 后 `模块名.函数` 限定失败 | 裸调用，或 `static import` |
| 36 | `approxEqual` 弃用 | `isClose`（std.math） |
| 37 | `getopt` 后位置参数去哪了 | 原地改写的 `args[1 .. $]` |
| 38 | `defaultGetoptPrinter(text)` 单参不行 | 传 `(text, parsed.options)` |
| 39 | 块式契约缺 `do` | `in {...} out (r) {...} do { 函数体 }` |
| 40 | 契约失败 catch Exception 接不住 | 抛的是 AssertError（Error 子类） |
| 41 | `Base64.encode(data)` 单参已移除 | 双参 + `encodeLength`/`decodeLength`（26 章实测） |
| 42 | `toHexString` 输出大写 | 要小写给 `toHexString!(LetterCase.lower)` |
| 43 | `SumType` 没有 `.get` | `match`（自由函数，UFCS 调，需 import match） |
| 44 | 类的 `mangleof` 不是 `_D` 开头 | `C4main6Parser` 式（C=class 标签）；函数才 `_D` |
| 45 | dustmite 测试脚本路径相对源码目录 | 脚本内 `dmd -run app.d`，调用 `dustmite src ../test.sh` |
| 46 | `--DRT-gcopt` 当 dmd 开关 | 是程序参数：`./app --DRT-gcopt=disable:1` |
| 47 | macOS：`dub` 报 `__dub_write_test_XXX: Operation not permitted` | 官方包二进制未签名，`~/` 下 unlink 被拒；`export DUB_HOME=<非 $HOME 目录>` 或 `codesign -s - dmd2/osx/bin/*` |
| 48 | macOS 想动态链 libphobos 省体积 | 包里只有 `.a`；`-defaultlib=libphobos2.so` 静默无效，`.dylib` 直接链接报错 |
| 49 | macOS 找不到 `dman` | 只有 Windows 版随包；用 dlang.org/phobos 或 zeal docset |
