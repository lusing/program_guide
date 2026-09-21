# 26 · 标准库全景：libphobos 与 druntime

> 对应示例：`examples/26_phobos/`（11 个模块域的巡礼 + 单测）
> 本章所有体积/开关数字均为本机实测（DMD 2.113，Linux x86_64；Windows 形态一并标注）。

## 26.1 libphobos 是什么：一个名字，两层内容

日常说的"Phobos 标准库"链接时叫 **libphobos2**。`ls /usr/lib | grep phobos`（Debian 系 dmd 包）：

```text
libdruntime.a            17 MB   ← 运行时：GC、线程、TypeInfo（core.*）
libphobos2.a             58 MB   ← 标准库本体（std.*）——静态链接用
libphobos2.so.0.113.0   8.8 MB   ← 同内容的动态库
```

Windows 对应物是 `phobos64.lib`（MSVC link 用）。关键认知：**你 `import` 的是源码**（`/usr/include/dlang/dmd/std/*.d`），**链接的是编译好的库**——dmd 默认静态链入，所以 hello world 也有 1 MB 上下。

## 26.2 两层地图：druntime（core.*）+ Phobos（std.*）

**druntime：看不见但离不开的运行时层**（每个 D 程序都活在它上面）：

| 模块 | 职责 | 教程 |
|---|---|---|
| `core.memory` | GC API：`GC.collect()`、`GC.stats()` | 15 章 |
| `core.thread` / `core.thread.osthread` | 线程、Thread 对象 | 16/17 章 |
| `core.atomic` | `atomicLoad/Store/Op`、`cas` | 17 章 |
| `core.sync` | Mutex/Semaphore/Condition/Barrier | 16 章 |
| `core.stdc` | C 标准库头（stdio/stdlib/math…） | 15/22 章 |
| `core.sys.posix` / `core.sys.linux` | 平台系统 API（unistd/socket…） | 22 章 |
| `core.time` | `Duration`/`MonoTime` 及 `5.days` 等单位字面量 | 16 章 |
| `object.d` | `Object`、`TypeInfo`、`Throwable`、数组 runtime 支撑 | 8/9 章 |

**Phobos：按域分类的全集**（⭐ = D 招牌，教程有专章）：

| 域 | 模块 | 一句话 |
|---|---|---|
| 算法与区间 ⭐ | `std.algorithm` `std.range` `std.array` | 惰性管道 + UFCS （13/14 章） |
| 元编程 | `std.meta` `std.traits` | `AliasSeq`/`staticMap`/`Filter`、`isNumeric`/`Fields`/`mangleof` 配套 |
| 类型构造 | `std.typecons` `std.sumtype` `std.variant` | `Tuple`/`Nullable`/`RefCounted`、类型安全 tagged union |
| 文本 | `std.string` `std.uni` `std.utf` `std.regex` `std.conv` `std.format` ⭐ | 切片字符串工具 + CTFE 正则 + `format!""` 编译期格式串 |
| 容器 | `std.container`（`Array`/`BinaryHeap`/`SList`/`DList`/`rbtree`） | GC 数组之外的正式容器 |
| 数学 | `std.math` `std.mathspecial` `std.numeric` `std.complex` `std.bigint` `std.random` `std.int128` | `isClose`、特殊函数、FFT、`BigInt` |
| IO 与系统 | `std.stdio` `std.file` `std.path` `std.mmfile` `std.process` `std.socket` `std.net.curl` | 文件/路径/进程/网络全家桶 |
| 序列化 | `std.json` `std.csv` `std.base64` `std.uuid` `std.digest` | JSON/CSV/Base64/UUID/MD5-SHA（`std.xml` 已移除，见 26.6） |
| 时间与并发 | `std.datetime` ⭐ `std.concurrency` `std.parallelism` | 类型安全日期运算、消息并发、数据并行 |
| 其他常用 | `std.getopt` `std.logger` `std.signals` `std.bitmanip` `std.demangle` `std.compiler` | 命令行解析、日志、信号槽、位域、反修饰（25 章） |
| 实验层 | `std.experimental.allocator` | 可插拔分配器（`make`/`dispose`/`Mallocator`） |

## 26.3 招牌模块细讲（示例 = 巡礼程序）

**std.meta / std.traits —— 编译期类型列表编程。** 对"类型/值的列表"（`AliasSeq`）做 `staticMap`（逐元变换）、`Filter`（谓词过滤）；`std.traits` 提供 `isNumeric`、`Fields`（取结构体字段类型表）、`Unqual` 等几百个谓词。模板元编程的整套词汇表。

**std.typecons —— 给类型系统补件。** `Tuple!(int,"x",int,"y")` 具名字段元组；`Nullable!T` 无指针的可空；`RefCounted`/`Scoped` 见 15 章。

**std.sumtype —— 类型安全的 tagged union。** 取值用 `match` 穷举分支（漏类型编译错），比 `std.variant` 的 `.get!T`（运行期抛错）更静态。

**std.bigint —— 任意精度整数。** `BigInt` 与内建整数混算，`30!` 一句话（`265252859812191058636308480000000`）。

**std.regex —— CTFE 编译正则。** `regex(r"...")` 在编译期构造自动机，运行时 `matchFirst` 零解析开销。

**std.digest / std.base64 / std.uuid —— 数据变换。** MD5/SHA/RIPEMD 摘要族；Base64 三种方言（`Base64`/`Base64URL`/`Base64URLNoPadding`）；UUID v4 随机生成 + 解析。

**std.datetime —— 类型安全时间。** `Date(2026,9,21) + 5.days` 自动跨月闰年进位；`Clock.currTime`、`StopWatch`（23 章）、`core.time.Duration`。

**std.container —— 正式容器。** `redBlackTree`（有序去重集合）、`Array`（可扩展非 GC 数组）、`BinaryHeap` 等。

**std.experimental.allocator —— 可插拔分配器。** `make!T(allocator, args)` / `dispose(allocator, p)`；`Mallocator`（C malloc）、`GCAllocator`、`building_blocks` 里的组合器（`Segregator`/`FallbackAllocator` 等）——`@nogc` 高性能代码的零件库（15 章的逃逸术落到实处）。

## 26.4 静态 vs 动态链接（实测）

```bash
dmd -O mini.d -of=mini_static                    # 默认：静态链 libphobos2.a
dmd -O -defaultlib=libphobos2.so mini.d -of=mini_dyn
ls -la mini_*                                     # 实测：1,047,272 vs 34,640 字节（≈30 倍）
ldd mini_dyn | grep phobos                        # libphobos2.so.0.113 → 运行期依赖
```

- **静态（默认）**：单文件分发，无运行时依赖；体积 +1 MB 上下，多进程各持一份 GC 副本。
- **动态**：主程序瘦 30 倍，多个 D 程序共享一份 GC/运行时常驻内存；**分发必须带 `libphobos2.so` 或目标机装同版 dmd**（soname 带小版本号，跨版本不混用）。

## 26.5 运行时开关：--DRT-gcopt

不需要重编译就能调 GC/运行时行为——参数跟在**程序名后面**（不是 dmd 的开关）：

```text
$ ./gcapp --DRT-gcopt=help          # 实测打印全部可用项
disable:0|1      profile:0|1|2      gc:conservative|precise
initReserve:N    minPoolSize:N(1M)  maxPoolSize:N(64M)
parallel:N(99)   heapSizeFactor:N(2) cleanup:none|collect|finalize
$ ./gcapp --DRT-gcopt=disable:1     # 实测：GC 整场禁用（`new` 将抛 OutOfMemoryError）
```

多项目空格分隔：`./app --DRT-gcopt="profile:1 heapSizeFactor:3"`。程序内等价物是 `core.runtime.Runtime.rtOptions` / 环境变量 `GC_PROFILE` 等。

## 26.6 老代码迁移表（网上旧教程重灾区）

| 老写法 | 现状（2.113） | 迁移到 |
|---|---|---|
| `std.xml` | **已移除**（标准库里搜不到） | `std.json` / 第三方 dxml |
| `std.stream` `std.cstream` `std.socketstream` | 已移除 | `std.stdio.File` / `std.socket` |
| `std.typetuple` | 只剩 deprecated 转发 shim | `std.meta`（`AliasSeq` 等） |
| `std.c.*` | 已移除 | `core.stdc.*` |
| `std.date` / `std.perf` | 上古 | `std.datetime` / `std.datetime.stopwatch` |
| `std.md5` `std.sha1` | 已移除 | `std.digest.md` / `.sha` |
| `std.gc` `std.intrinsic` `std.intrinsics` | 已移除 | `core.memory` / `core.bitop` |
| `approxEqual` | 弃用 | `std.math.isClose` |
| `Base64.encode(data)` 单参 | **已移除**（源码顶部注释还是旧例子） | 双参 + `encodeLength`/`decodeLength`（见坑 1） |

## 26.7 坑位清单

1. **`Base64.encode(data)` 单参便捷版已移除**：`auto enc = Base64.encode(data, new char[Base64.encodeLength(n)])`；decode 同理用 `decodeLength`。模块 doc 注释里的单参示例是**残留旧文档**——以编译器报错为准。
2. **`toHexString` 默认大写**：`md5Of("abc").toHexString` → `900150983CD24FB…`；要小写显式给 `toHexString!(LetterCase.lower)`。
3. **`SumType` 没有 `.get`**：`.get!T` 是 `std.variant` 的 API；SumType 用自由函数 `match`（UFCS 调，需 `import std.sumtype : match`）。
4. **动态链 libphobos2.so 的分发陷阱**：soname 带 `0.113` 小版本，目标机版本不一致直接起不来——发布物要么静态链，要么把 so 一起带上。
5. **`--DRT-gcopt` 是程序参数**：写在程序名后；当成 dmd 开关会"静默无效"（程序照跑）。`--DRT-gcopt=help` 可验证通路。
6. **`std.experimental` 命名空间的承诺**：experimental 下的模块**不保证语义稳定**，但 `std.experimental.allocator` 事实上久经考验、DUB 生态大量依赖——可用，只是 import 路径深（`std.experimental.allocator.mallocator` 等）。
7. **`std.internal.*` / `std.*.internal.*` 千万别 import**：Phobos 实现内部模块，跨版本随意重构。

---
