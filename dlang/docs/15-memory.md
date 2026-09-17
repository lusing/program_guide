# 15 · 内存管理

> 对应示例：`examples/15_memory/`

## 15.1 默认世界：GC

```d
auto s = new Session("alpha");        // 分配即完事：没有 delete
auto arr = new int[](1_000_000);      // 大数组也走 GC（元素清零）
```

- **`delete` 已从语言移除**——GC 世界里你只有"分配权"。
- GC 是**分代、并发、可增量**的（druntime 默认配置），大多数工具/业务代码完全无感。
- 手动干预：`GC.collect()`（强制回收）、`GC.disable()/enable()`（暂停/恢复）、`GC.stats()`（内存统计，`.usedSize` 字段）。

## 15.2 @nogc：把 GC 关在门外

```d
@nogc int sumNoGc(scope const(int)[] xs) {     // scope：不逃逸；@nogc：不分配
    int total = 0;
    foreach (x; xs) total += x;
    return total;
    // return xs.map!(x => x).array;   // ← 打开这行直接编译错：array 需要 GC
}
```

`@nogc` 是**编译期护栏**：函数体里任何 GC 分配（new、`~=` 扩容、闭包逃逸、`.array`）都编译失败。实时系统、游戏帧循环、BetterC 边界全靠它兜底。给底层库的公开 API 标 `@nogc` 是美德。

## 15.3 手动内存：malloc + 切片

```d
import core.stdc.stdlib : malloc, free;

struct RawBuffer {
    double* data;
    size_t n;

    static RawBuffer make(size_t n) {
        auto p = cast(double*)malloc(double.sizeof * n);
        return RawBuffer(p, n);
    }

    @nogc double[] slice() return { return data[0 .. n]; }   // 指针 → 切片

    ~this() { if (data !is null) free(data); data = null; }  // RAII
    this(this) { assert(false, "禁止拷贝：会 double free"); }
}
```

模式：**malloc → 指针[0..n] 包成切片 → struct 析构里 free**——值语义 + 手动内存的合体，`@nogc` 世界的数据结构就长这样。

## 15.4 所有权工具箱（std.typecons）

```d
// RefCounted!T：引用计数的值包装
auto blob = RefCounted!FileBlob(cast(ubyte[])[1, 2, 3]);
{   auto b2 = blob; }                    // 计数+1/-1，最后一个释放
writeln(blob.refCountedPayload.bytes);   // 访问负载

// scoped!T：把类钉在栈上（不进 GC 堆，作用域结束析构）
auto s = scoped!Session("beta");
```

## 15.5 决策表

| 场景 | 工具 |
|---|---|
| 临时对象、无所谓 | GC（new） |
| 确定性释放（文件/锁/句柄） | struct + ~this（RAII，07 章） |
| 热路径 / @nogc / 实时 | 栈数组 + malloc + 切片 |
| 共享所有权 | `RefCounted!T` |
| 栈上对象（class 也行） | `scoped!T` |
| 只读共享 | `immutable`（16 章） |

## 15.6 GC 与外部资源

**别把"释放外部资源"寄托在 GC 上**：

```d
class Session {
    HANDLE fd;                        // 外部句柄（不是 GC 内存）
    ~this() { closeHandle(fd); }      // 时机不确定——可能永远不跑！
}
```

GC 只管内存，析构时机不确定（甚至进程退出都不跑）。外部资源用 struct RAII（07 章）或显式 close + `scope(exit)`（09 章）。

## 15.7 @safe / @trusted / @system

| | 含义 |
|---|---|
| `@safe` | 禁指针运算/转型等不安全操作——编译器验证 |
| `@trusted` | "我人工检查过，这段安全"——安全代码与不安全代码的桥 |
| `@system`（默认） | 不检查（C 级自由度） |

## 15.8 坑位清单

1. **`delete` 不能用**：老教程 `delete obj;` 在 2.113 是编译错——交给 GC 或用 RAII。
2. **`@nogc` 里连 `.array`/`~=` 拼接都不行**——它们要分配；字符串拼好了再传进来。
3. malloc 返回 `void*` 要 cast；**失败返回 null**——重要场合自己检查（示例注释里 enforce）。
4. `RefCounted!T(实参)` 的实参转给 T 的**构造器**——payload 是 struct 时给它写 `this(...)`，字段不能按位置塞。
5. `scoped!T` 得到的是**代理对象**，取字段用点号没问题，但它不是 T 本体（不能当 T 传出去）。
6. `GC.stats()` 是结构体（`usedSize`/`freeSize` 等字段），不是函数——打印用 `.usedSize`。
7. 拿指针切片（`data[0 .. n]`）后**别让 GC 世界引用它**（`new` 出来的对象里存这段切片）：GC 不追踪 malloc 内存，可能被收集器移走对象后悬空——需要时 `GC.addRange` 登记（进阶话题，先知道存在）。

---
