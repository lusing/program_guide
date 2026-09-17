# 10 · 错误处理 II：nothrow、Nullable 与契约

> 对应示例：`examples/10_errors2/`

## 10.1 nothrow：编译器保证不抛

```d
nothrow double safeRatio(double a, double b) {
    return b == 0 ? double.nan : a / b;      // 这里放 to!int 之类 → 直接编译错
}
```

`nothrow` 是**可验证承诺**：任何可能抛的表达式都进不了函数体。用途：异常边界外层（比如 C 回调里）、实时路径。和 Zig 的"错误集显式化"思路相反——D 用类型系统锁死"不抛"的那一侧。

## 10.2 Nullable!T：诚实的"可能没有"

```d
import std.typecons;

Nullable!long findUserId(string[] names, string target) {
    foreach (i, n; names)
        if (n == target) return nullable(cast(long)i);   // 有值：包上
    return Nullable!long();                              // 无值：默认构造
}

auto found = findUserId(names, "Bob");
if (!found.isNull) writeln(found.get);
writeln(found.get(-1));            // 带默认值取值：null 时给 -1
```

对比用魔数（-1 表示没找到）：调用方**必须**处理 isNull 才能拿值——类型逼你面对"没有"。（比 Rust 的 Option 弱：`get` 无保护版本也存在，约定靠自觉。）

## 10.3 契约式编程：in / out / invariant

D 把 DbC（Design by Contract）做进语言：

```d
// 表达式式（最紧凑）
int clampPos(int x)
    in (x > -100, "输入不能太小")
    out (r; r >= 0 && r <= 1000, "输出必须在 [0,1000]")
{
    return x < 0 ? 0 : (x > 1000 ? 1000 : x);
}

// 块式（复杂条件）
int divide(int a, int b)
    in {
        assert(b != 0, "除数不能为 0");
    }
    out (r) {
        assert(r * b <= a, "商异常");
    }
do {                                    // 注意契约块后的真正函数体用 do 引导
    return a / b;
}

// 类不变式：每个 public 方法进出自动检查
class BankAccount {
    long balance_;
    invariant() { assert(balance_ >= 0, "余额不能为负"); }
    void withdraw(long amount) { balance_ -= amount; }   // 减成负数 → 出口被 invariant 抓
}
```

- 契约违反抛 **AssertError**（Error 子类）——属于 bug，不是可恢复错误。
- `-release` 编译**剥离契约**：开发期狂查、发布版零开销。

## 10.4 错误分类决策表

| 情形 | 用什么 | 例 |
|---|---|---|
| 可恢复、调用方该处理 | `Exception` 子类 | 文件不存在、解析失败 |
| 程序 bug（不可恢复） | assert / 契约 / RangeError | 空指针、越界、违反不变式 |
| "没有值"不是错误 | `Nullable!T` | 查找、可选配置 |
| 性能敏感且错误常见 | 返回值 + enforce 分层 | 热路径解析 |
| 保证不抛 | `nothrow` | 边界回调 |

## 10.5 @safe 快注

`@safe` 函数里不能做指针转换等内存不安全操作——违反编译错。库的公开 API 标 `@safe` 是好习惯（内存细节 15 章展开）。

## 10.6 坑位清单

1. **契约违反抛 AssertError 不是 Exception**：测试里要 `assertThrown!Error(clampPos(-200))`——catch Exception 接不住。
2. **块式契约的函数体前缀是 `do`**——漏写是解析错误（老版本语法没有 do，旧教程照抄编译不过）。
3. **invariant 只在 public 方法边界检查**：private 方法直来直去不触发（也意味着你可以在 private 里暂时破坏不变式再修复）。
4. `-release` 剥离契约**也剥离 assert**——发布版别指望这些检查兜底。
5. `Nullable!int` 和 `int` 比较：`n == 0` 在有值时比较值、null 时是 false——但 `n + 1` 不能直接算，先 `.get`。
6. `nothrow` 函数里想调用可能抛的函数：`assumeWontThrow(f())`（std.exception）显式担保——担保错了是 UB。

---
