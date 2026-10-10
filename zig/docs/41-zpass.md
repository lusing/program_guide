# 41 · 实战：随机数与密码生成器 zpass


> 对应示例：`examples/41_zpass/main.zig`（412 行，4 个测试）
>
> 随机数的完整路线图：三种随机源（DefaultPrng / io.random / io.randomSecure）、
> 模偏差理论 + 拒绝采样（数学核心）、zpass 密码生成器、UUID v4（位操作实战）、
> 随机时间序列（数据处理工具的积木）。
> 取材 Tsoukalos ch1（zpass + randomValues）与 ch2（zuuid + 随机时间序列练习）。
> 编码（hex/base64）的完整讨论在 26 章，本章只用到 `std.fmt.hex_charset`
> 做十六进制格式化——不重复 26 章的内容。
>
> 本章有 **5 条结论会推翻你可能听过的说法**，全部是 0.17.0 上实测的：
>
> 1. **「随机数就是 `rand()`」**。Zig 里**没有**全局随机函数。你必须显式选择
>    三种源之一：`std.Random.DefaultPrng`（软件 PRNG，吃 seed，可复现）、
>    `io.random(&buf)`（OS 熵播种的 PRNG，不可复现但不是 CSPRNG）、
>    `io.randomSecure(&buf)`（每次调用都向 OS 要新的密码学安全随机字节）。
>    0.17 里 `std.crypto.random` 已删除——`io.randomSecure` 是唯一的
>    CSPRNG 取法（41.1）。
> 2. **「`% N` 就能均匀取模」**。当 `2^bits % N != 0` 时，`% N` 是有偏的。
>    本章用 `u8 % 100` 做例子：256 个值分给 100 个桶，前 56 个桶各 3 次机会、
>    后 44 个各 2 次——偏差比 1.5:1。拒绝采样（discard + redraw）是
>    无偏的标准解法（41.2）。
> 3. **「密码生成就拼随机字符」**。如果你的字符集长度不整除 256（比如 84），
>    直接 `% charset_len` 会让前 `256 % 84 = 4` 个字符的出现概率
>    比其他字符高 25%。zpass 用拒绝采样修复（41.3）。
> 4. **「UUID 就是随机 16 字节」**。UUID v4 要求 byte 6 的高 4 位是
>    `0100`（版本 4）、byte 8 的高 2 位是 `10`（variant）——
>    两个位操作把随机字节变成合法的 RFC 4122 UUID（41.4）。
> 5. **「`std.time.milliTimestamp` 拿当前时间」**。0.17 里已删除。
>    正解是 `std.Io.Timestamp.now(io, .real).toMilliseconds()`（41.5）。
>
> **节号对应**：41.1–41.5 是示例 `main` 里的运行时小节（`begin("41.N …") …
> end("41.N")`，运行输出里能看到 `==== 41.N … 开始 ====`）；
> **41.6（坑位清单）与 41.7（验证方式）不在 `main` 里**——
> 示例 `main` 里确实有一个 `begin("41.6 坑位清单")` 运行时小节，内容是 5 条速览，
> 本文档 41.6 是它的完整展开，41.7 是本文档独有的验证指南。
>
> **稳定性纪律**：41.1 的三种随机源、41.3 的密码、41.4 的 UUID、
> 41.5 的时间序列值——这些每次运行都不同（它们就该不同）。
> 但 41.2 的模偏差演示是**纯数论**：`biasedCounts` 在 comptime 算出
> 确定性结果，`rejectionSampleMod100` 用固定 seed 的 PRNG 也是确定性的。
> 所以 41.2 的输出是逐字抄的，其余节的输出结构（格式、行数、断言结果）
> 是确定的，只有具体的字节值/密码/UUID 每次不同。

---

## 导读：这一章要推翻三个说法

**说法一："随机数就是 `rand()`。"**

C 里的 `rand()` 是一个全局状态函数——不需要 seed、不需要选择算法、
不需要考虑安全性，调就完了。Zig 里**没有**这种函数，这是故意的。
`std.Random.DefaultPrng.init(0xdeadbeef)` 要求你显式给 seed；
`io.random(&buf)` 要求你显式提供缓冲；`io.randomSecure(&buf)` 要求你
显式处理 `error.EntropyUnavailable`。这种"麻烦"是**设计出来的**——
它逼你在写第一行代码之前就想清楚：我要的是可复现的伪随机，
还是密码学安全的真随机？（41.1）

**说法二："`% N` 就能均匀取模。"**

`rand() % 100` 看起来没问题——0 到 255 均匀分布，取模后 0 到 99
应该也均匀分布吧？错。256 = 2×100 + 56，所以值 0 到 55 映射到
桶 0 到 55 各 3 次（0, 100, 200）、值 56 到 99 映射到桶 56 到 99 各 2 次
（56, 156）。前 56 个桶的概率是 3/256，后 44 个是 2/256——
**偏差比 1.5:1**。41.2 用 comptime 数论 + 固定 seed 实测双重验证，
然后给出标准解法：拒绝采样（rejection sampling）。

**说法三："密码生成就拼随机字符。"**

写一个 `password[i] = charset[rand() % charset_len]` 只要一行。
但如果你的字符集是 84 个字符（26 大写 + 26 小写 + 10 数字 + 22 符号），
`256 % 84 = 4`——前 4 个字符（`A` `B` `C` `D`）的出现概率是
4/256，其他 80 个是 3/256。**你的密码生成器有偏好**——
攻击者知道 `A` 比 `E` 更常见。zpass 的解法和 41.2 的理论完全一致：
拒绝采样（41.3）。

---

## main 函数与 I/O 设置

在进各小节之前，先看 `main` 的整体结构：

```zig
// examples/41_zpass/main.zig 第 323-338 行
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var out_buf: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &out_buf);
    const w = &stdout_impl.interface;
    defer w.flush() catch {};

    try section41_1(io, w);
    try section41_2(io, w);
    try section41_3(io, w, gpa);
    try section41_4(io, w);
    try section41_5(io, w);
    try section41_6(w);
}
```

逐行解释：

- **`init.io`**：0.17 的 I/O 调度器，由 runtime 注入。`io.random(&buf)`、
  `io.randomSecure(&buf)` 都需要它。
- **`init.gpa`**：通用分配器（`std.mem.Allocator`），41.3 的密码生成
  需要它来分配和释放密码缓冲。
- **`std.Io.File.stdout().writer(io, &out_buf)`**：创建一个 4KB 缓冲的
  stdout writer。`w` 是 `*std.Io.Writer`——所有 `try w.print(...)`
  都写到这个缓冲里，`defer w.flush()` 在 `main` 返回前把残余数据
  推到终端。
- **分节调用**：41.1 到 41.6 各是一个函数，按顺序调用。41.3 额外
  接收 `gpa`（需要分配器），其余只接收 `io` 和 `w`。

这个结构和 34 章的 zcache、40 章的 zunzip 完全一致——
`std.process.Init` 注入 I/O 和分配器，stdout 用 4KB 缓冲 writer，
`defer flush` 兜底。

---

## 41.1 三种随机源

Zig 0.17 里没有 `rand()`。你必须从三种源中显式选择：

| 源 | API | 可复现 | CSPRNG | 适用场景 |
|---|---|---|---|---|
| DefaultPrng | `std.Random.DefaultPrng.init(seed)` | 是（固定 seed） | 否 | 测试、模拟、游戏 |
| io.random | `io.random(&buf)` | 否 | 否 | 洗牌、非安全随机 |
| io.randomSecure | `try io.randomSecure(&buf)` | 否 | **是** | 密码、密钥、UUID |

### 41.1.1 辅助函数：hexPrefix

```zig
// examples/41_zpass/main.zig 第 22-30 行
/// 把前 n 个字节格式化成 "xx xx xx ..." 的十六进制串（纯演示用，不走分配器）。
fn hexPrefix(buf: []const u8, comptime n: usize) [n * 3 - 1]u8 {
    var out: [n * 3 - 1]u8 = undefined;
    for (buf[0..n], 0..) |b, i| {
        out[i * 3 + 0] = std.fmt.hex_charset[b >> 4];
        out[i * 3 + 1] = std.fmt.hex_charset[b & 15];
        if (i + 1 < n) out[i * 3 + 2] = ' ';
    }
    return out;
}
```

逐行解释：

- **`comptime n: usize`**：长度在编译期确定——返回类型 `[n * 3 - 1]u8`
  依赖 `n`，所以 `n` 必须是 comptime。这让你可以写
  `hexPrefix(&b0, 8)` 返回 `[23]u8`（8 字节 × 2 字符 + 7 个空格 = 23）。
- **`std.fmt.hex_charset`**：0.17 里的十六进制字符查找表，
  等价于 `"0123456789abcdef"`。26 章有 hex/base64 编码的完整讨论——
  这里只是用它做格式化，不涉及编码理论。
- **`b >> 4` / `b & 15`**：高 4 位和低 4 位分别映射到一个十六进制字符。
  这是字节 → 两个 hex 字符的标准做法。
- **返回定长数组而非切片**：`[n * 3 - 1]u8` 在栈上，不需要分配器。
  调用方可以直接 `try w.print("{s}", .{hexPrefix(&b0, 8)})`。

### 41.1.2 源 1：DefaultPrng（固定 seed，可复现）

```zig
// examples/41_zpass/main.zig 第 37-46 行
var prng = std.Random.DefaultPrng.init(0xdeadbeef);
const r = prng.random();
const b0: [8]u8 = .{
    r.int(u8), r.int(u8), r.int(u8), r.int(u8),
    r.int(u8), r.int(u8), r.int(u8), r.int(u8),
};
try w.print("DefaultPrng(seed=0xdeadbeef) 前 8 字节: {s}\n", .{hexPrefix(&b0, 8)});
// intRangeAtMost 是闭区间 [at_least, at_most]，内部走拒绝采样（见 41.2）。
const dice = r.intRangeAtMost(u8, 1, 6);
try w.print("intRangeAtMost(u8, 1, 6) 掷一次骰子: {d}\n", .{dice});
```

逐行解释：

- **`std.Random.DefaultPrng.init(0xdeadbeef)`**：创建一个 Xoshiro256++ 算法的
  PRNG 实例，seed 是 `0xdeadbeef`。**同一个 seed 永远产生同一个序列**——
  这是测试和模拟的关键属性。
- **`prng.random()`**：返回一个 `std.Random` 接口。这是 Zig 的设计亮点：
  不管你用 `DefaultPrng`、`Xoshiro128` 还是其他算法，`.random()` 返回的
  接口完全一致——消费随机数的代码不需要知道背后是哪种引擎。
- **`r.int(u8)`**：返回一个均匀分布的 `u8`（0 到 255）。连续调 8 次
  得到 8 个随机字节。
- **`r.intRangeAtMost(u8, 1, 6)`**：返回闭区间 `[1, 6]` 内的均匀随机整数——
  掷骰子。**关键：这个函数内部已经做了拒绝采样**（源码在
  `lib/std/Random.zig`），所以你不需要自己处理模偏差。
  41.2 会讲清它内部的原理。

### 41.1.3 源 2：io.random（OS 熵播种的 PRNG）

```zig
// examples/41_zpass/main.zig 第 50-58 行
var seed_buf: [32]u8 = undefined;
io.random(&seed_buf);
var prng2 = std.Random.DefaultPrng.init(std.mem.readInt(u64, seed_buf[0..8], .little));
const r2 = prng2.random();
const b1: [8]u8 = .{
    r2.int(u8), r2.int(u8), r2.int(u8), r2.int(u8),
    r2.int(u8), r2.int(u8), r2.int(u8), r2.int(u8),
};
try w.print("io.random 播种的 PRNG   前 8 字节: {s}\n", .{hexPrefix(&b1, 8)});
```

`io.random(&buf)` 是 0.17 的"接口播种"：让 Io 实现用 `randomSecure`
（或其退化机制）填一块种子内存。比裸 PRNG 多一层 OS 熵——seed 不可预测，
所以序列不可复现。但**底层算法还是 Xoshiro256++**——它是确定性的
伪随机算法，不是 CSPRNG。适合洗牌、模拟、游戏，不适合密码学用途。

### 41.1.4 源 3：io.randomSecure（CSPRNG）

```zig
// examples/41_zpass/main.zig 第 62-64 行
var csprng_buf: [8]u8 = undefined;
try io.randomSecure(&csprng_buf);
try w.print("io.randomSecure(CSPRNG) 前 8 字节: {s}\n", .{hexPrefix(&csprng_buf, 8)});
```

`io.randomSecure(&buf)` 每次调用都向 OS 要新的密码学安全随机字节
（macOS 上是 `arc4random` 或 `getrandom`，Linux 上是 `getrandom`，
Windows 上是 `BCryptGenRandom`）。**0.17 里 `std.crypto.random` 已删，
这是唯一正确的 CSPRNG 取法**。注意它返回 `!void`——可能返回
`error.EntropyUnavailable`，所以必须 `try`。

### 41.1.5 三种源的选择决策树

在实际项目中，按这个顺序问自己：

```
需要密码学安全吗？
├── 是（密码、密钥、UUID、会话令牌、nonce）
│   └── 用 io.randomSecure(&buf)
│       每次调用都向 OS 要新的随机字节
│       返回 !void，必须 try
│
└── 否（模拟、游戏、洗牌、测试、时间序列）
    └── 需要可复现吗？
        ├── 是（测试、调试、程序化生成）
        │   └── 用 std.Random.DefaultPrng.init(固定seed)
        │       同一个 seed 永远产生同一个序列
        │
        └── 否（洗牌、一次性模拟）
            └── 用 io.random(&buf) 播种 DefaultPrng
                seed 来自 OS 熵，序列不可复现
                但算法是 Xoshiro256++，不是 CSPRNG
```

三条规则：

1. **密码学安全 → `io.randomSecure`**。没有例外。`io.random` 和
   `DefaultPrng` 都不是 CSPRNG——它们的输出在足够长的样本面前
   是可预测的。
2. **测试 → 固定 seed 的 `DefaultPrng`**。测试必须可复现——
   如果测试失败，你需要能重放同样的输入序列来调试。
   `io.randomSecure` 的产出每次不同，不适合直接用在测试里。
   本章的测试（41.2.5 / 41.3.5 / 41.4.5）全部用固定 seed。
3. **性能敏感的非安全场景 → `io.random` 播种的 `DefaultPrng`**。
   `io.random` 只调一次 OS 熵（拿 seed），之后是纯软件 PRNG——
   比每次调 `randomSecure` 快得多。适合模拟、游戏、
   大规模随机数据生成。

### 41.1.6 运行时输出

```text
==== 41.1 三种随机源 开始 ====
DefaultPrng(seed=0xdeadbeef) 前 8 字节: de e2 22 97 58 23 d4 19
intRangeAtMost(u8, 1, 6) 掷一次骰子: 2
io.random 播种的 PRNG   前 8 字节: 52 76 92 34 f2 af de 2c
io.randomSecure(CSPRNG) 前 8 字节: 93 c6 35 22 53 dc a8 87
结论：三种源都能产字节；PRNG 可复现、CSPRNG 不可复现但抗预测。
==== 41.1 结束 ====
```

第一行（`de e2 22 97 ...`）是**每次运行都一样的**——固定 seed 的
DefaultPrng 保证可复现。后两行每次运行都不同——它们用了 OS 熵。

`intRangeAtMost(u8, 1, 6)` 的结果是 `2`——这个值在固定 seed 下
也是确定的（`0xdeadbeef` 播种的 PRNG 的第三个输出经过
`intRangeAtMost` 的拒绝采样后映射到 2）。

---

## 41.2 模偏差（modulo bias）——纯数学演示

这是本章的**数学核心**。不依赖任何随机源——用 comptime 数论证明偏差存在，
再用固定 seed 的 PRNG 实测验证。

### 41.2.1 理论：256 个值 % 100

```zig
// examples/41_zpass/main.zig 第 77-84 行
/// 统计 0..range 中每个值 v 的 v % mod 落在哪个桶，返回各桶计数。
/// 这是确定性的：不掷随机数，直接数论。
/// range 用 u32：演示里要表达 2^8 = 256，u8 装不下。
fn biasedCounts(comptime range: u32, comptime mod: u32) [mod]u32 {
    var counts = std.mem.zeroes([mod]u32);
    var v: u32 = 0;
    while (v < range) : (v += 1) {
        counts[v % mod] += 1;
    }
    return counts;
}
```

这个函数**不掷随机数**——它直接数：0 到 255 这 256 个整数，
每个 `% 100` 落到哪个桶，各落几次。结果是确定性的：

```
值 0   → 桶 0   （0 % 100 = 0）
值 1   → 桶 1   （1 % 100 = 1）
...
值 99  → 桶 99  （99 % 100 = 99）
值 100 → 桶 0   （100 % 100 = 0）
值 101 → 桶 1   （101 % 100 = 1）
...
值 199 → 桶 99  （199 % 100 = 99）
值 200 → 桶 0   （200 % 100 = 0）
...
值 255 → 桶 55  （255 % 100 = 55）
```

所以：
- 桶 0 到 55：各 3 次（v、v+100、v+200）
- 桶 56 到 99：各 2 次（v、v+100）

**偏差比 = 3/2 = 1.5**。如果你用 `rand() % 100` 生成 0 到 99 的随机数，
值 0 出现的概率是值 99 的 1.5 倍。

`comptime range: u32` 和 `comptime mod: u32`：两个参数都是 comptime，
所以 `biasedCounts(256, 100)` 在编译期就算出了结果——
`const counts = comptime biasedCounts(256, 100);` 是一个
`[100]u32` 常量数组，运行期零成本。

### 41.2.2 实测验证

```zig
// examples/41_zpass/main.zig 第 107-117 行
// 用固定 seed 的 PRNG 实测一次：掷 25600 次，看残差 0 和残差 99 的命中差。
var prng = std.Random.DefaultPrng.init(42);
const r = prng.random();
var hit0: u32 = 0;
var hit99: u32 = 0;
var i: u32 = 0;
while (i < 25600) : (i += 1) {
    const v = r.int(u8) % 100;
    if (v == 0) hit0 += 1;
    if (v == 99) hit99 += 1;
}
```

25600 次 = 100 × 256——如果无偏，每个桶应该命中 256 次。
实测结果：`hit0 = 281, hit99 = 238`。281/238 ≈ 1.18——
和理论值 1.5 有偏差（因为 25600 次还不够多，采样噪声），
但方向是一致的：桶 0 明显比桶 99 更频繁。

### 41.2.3 修复：拒绝采样

```zig
// examples/41_zpass/main.zig 第 88-94 行
/// 拒绝采样：从 [0, 256) 里拒绝 v >= bound 的值，直到取到 < bound 的。
/// bound 必须是 mod 的整数倍（调用方保证），这样 mod 之后各桶概率严格相等。
fn rejectionSampleMod100(r: std.Random) u8 {
    // floor(256/100)*100 = 200：只接受 0..199，模 100 后 0..99 各恰好 2 次机会。
    while (true) {
        const v = r.int(u8);
        if (v < 200) return v % 100;
    }
}
```

思路：**把有偏的部分扔掉**。256 个值里，只接受前 200 个（0 到 199），
拒绝 200 到 255。200 是 100 的整数倍（`floor(256/100) * 100 = 200`），
所以 0 到 199 这 200 个值 `% 100` 后，每个桶恰好 2 次——严格均匀。

代价：每次调用有 `(256-200)/256 = 21.875%` 的概率被拒绝重抽。
平均需要 `256/200 = 1.28` 次尝试——可接受。

### 41.2.4 为什么是 256 % 100 = 56

把 256 个值按顺序铺开来，每 100 个一组：

```
第 1 组：  0.. 99  → 桶 0..99 各 +1
第 2 组：100..199  → 桶 0..99 各 +1
第 3 组：200..255  → 桶 0..55  各 +1（只有 56 个值，不是 100 个）
```

前两组完美均匀——每个桶恰好 2 次。问题出在第三组：只有 56 个值
（200 到 255），它们落在桶 0 到 55。所以：

- 桶 0 到 55：2 + 1 = **3** 次
- 桶 56 到 99：2 次（没有第三组）

偏差比 = 3/2 = **1.5**。

一般化：对于 `2^bits` 个值 `% N`，设 `R = 2^bits % N`（余数）。
如果 `R == 0`，无偏。如果 `R != 0`，桶 0 到 R-1 各
`floor(2^bits / N) + 1` 次机会，桶 R 到 N-1 各 `floor(2^bits / N)`
次机会。偏差比 = `(floor(2^bits / N) + 1) / floor(2^bits / N)`。

几个常见例子：

| 位宽 | N | 2^bits % N | 偏差比 | 严重？ |
|---|---|---|---|---|
| 8 | 100 | 56 | 3/2 = 1.50 | 是 |
| 8 | 84 | 4 | 4/3 ≈ 1.33 | 是（41.3 的密码生成器） |
| 8 | 64 | 0 | 1.0（无偏） | 否 |
| 8 | 7 | 4 | 37/36 ≈ 1.03 | 轻微 |
| 32 | 100 | 96 | 42949673/42949672 ≈ 1.0 | 可忽略 |
| 32 | 3 | 1 | (2^31+1)/2^31 ≈ 1.0 | 可忽略 |

**位宽越大，偏差越小**——但"可忽略"不等于"不存在"。密码学场景
要求严格的均匀分布，所以即使 32 位的偏差在统计上不可检测，
标准做法仍然是拒绝采样。

### 41.2.5 运行时输出

```text
==== 41.2 模偏差 开始 ====
256 个 u8 值 % 100 的桶计数：残差 0..55 各 3 次，残差 56..99 各 2 次
偏差比 = 3/2 = 1.50
实测（seed=42，25600 次 u8 % 100）：残差 0 命中 281 次，残差 99 命中 238 次
拒绝采样后（同样 25600 次）：残差 0 命中 247 次，残差 99 命中 299 次
拒绝采样后每个残差概率相等。
==== 41.2 结束 ====
```

注意拒绝采样后的数字（247 和 299）也不完全相等——这是**采样噪声**，
不是偏差。理论期望是各 256 次，实测 247 和 299 在合理范围内。
关键区别：有偏时**期望值本身就不等**（281 vs 238 的方向是系统性的），
无偏时期望值相等，差异只是随机波动。

用统计学术语说：有偏时**分布的均值就不在零点**（系统误差），
无偏时均值在零点但**方差不为零**（随机误差）。增大样本量可以
减小方差，但无法消除系统误差——这就是为什么拒绝采样是必须的。

### 41.2.6 测试

```zig
// examples/41_zpass/main.zig 第 344-354 行
test "biasedCounts 数论：256 % 100 → 残差 0..55 各 3 次，56..99 各 2 次" {
    const counts = comptime biasedCounts(256, 100);
    try std.testing.expectEqual(@as(u32, 3), counts[0]);
    try std.testing.expectEqual(@as(u32, 3), counts[55]);
    try std.testing.expectEqual(@as(u32, 2), counts[56]);
    try std.testing.expectEqual(@as(u32, 2), counts[99]);
    // 总数守恒：3*56 + 2*44 = 168 + 88 = 256。
    var total: u32 = 0;
    for (counts) |c| total += c;
    try std.testing.expectEqual(@as(u32, 256), total);
}
```

```zig
// examples/41_zpass/main.zig 第 356-374 行
test "拒绝采样：永不返回 >= bound 的值，且多次抽取覆盖所有残差" {
    var prng = std.Random.DefaultPrng.init(7);
    const r = prng.random();
    // 单值约束：rejectionSampleMod100 的返回值必在 [0, 100)。
    var i: u32 = 0;
    while (i < 10000) : (i += 1) {
        const v = rejectionSampleMod100(r);
        try std.testing.expect(v < 100);
    }
    // 覆盖性：1000 次内 0..99 每个残差都至少出现一次（固定 seed，确定性）。
    var prng2 = std.Random.DefaultPrng.init(7);
    const r2 = prng2.random();
    var seen = std.mem.zeroes([100]bool);
    i = 0;
    while (i < 1000) : (i += 1) {
        seen[rejectionSampleMod100(r2)] = true;
    }
    for (seen) |s| try std.testing.expect(s);
}
```

第二个测试有两层验证：
1. **值域约束**：10000 次调用的返回值全部 < 100（不会返回越界的值）。
2. **覆盖性**：1000 次内 0 到 99 每个残差至少出现一次——证明拒绝采样
   不会把某些值永远挡在外面。

---

## 41.3 zpass 密码生成器

现在把 41.2 的理论落地到一个真实的密码生成器。

### 41.3.1 字符集与模偏差

```zig
// examples/41_zpass/main.zig 第 142 行
/// 字符集：大小写字母 + 数字 + 常用符号。
/// 长度 26+26+10+22 = 84，84 不整除 256（256 % 84 = 4），
/// 所以必须拒绝采样 —— 这正是 41.2 理论的实际用武之地。
const PASSWORD_CHARSET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{}";
```

字符集长度 = 26 + 26 + 10 + 22 = **84**。`256 % 84 = 4`——
如果直接 `byte % 84`，前 4 个字符（`A` `B` `C` `D`）各 4 次机会，
其余 80 个各 3 次。前 4 个字符的出现概率是其他的 4/3 ≈ 1.33 倍。
**你的密码生成器有偏好**——攻击者知道 `A` 比 `E` 更常见。

### 41.3.2 generatePassword 函数

```zig
// examples/41_zpass/main.zig 第 146-163 行
/// 用 CSPRNG 字节 + 拒绝采样，无偏地从 PASSWORD_CHARSET 里挑 length 个字符。
/// 返回调用方拥有的切片（用同一 allocator free）。
fn generatePassword(io: std.Io, allocator: std.mem.Allocator, length: usize) ![]u8 {
    const charset_len = PASSWORD_CHARSET.len;
    // 最大的 256 的倍数 <= 256：floor(256/charset_len)*charset_len。
    // charset_len=84 → bound=252（84*3），拒绝 v >= 252 的字节。
    const bound: u16 = @as(u16, 256 / charset_len) * charset_len;

    const pw = try allocator.alloc(u8, length);
    var filled: usize = 0;
    while (filled < length) {
        var byte: [1]u8 = undefined;
        try io.randomSecure(&byte);
        const v: u16 = byte[0];
        if (v >= bound) continue; // 拒绝采样：丢弃会引入模偏差的尾部
        pw[filled] = PASSWORD_CHARSET[v % charset_len];
        filled += 1;
    }
    return pw;
}
```

逐行解释：

- **`const bound: u16 = @as(u16, 256 / charset_len) * charset_len;`**：
  `256 / 84 = 3`（整数除法），`3 * 84 = 252`。所以 `bound = 252`——
  只接受 0 到 251 的字节，拒绝 252 到 255。
  252 是 84 的整数倍（`84 * 3 = 252`），所以 0 到 251 这 252 个值
  `% 84` 后每个字符恰好 3 次——严格均匀。
- **`const v: u16 = byte[0];`**：把 `u8` 提升为 `u16`——
  因为 `bound` 是 `u16`，比较时类型要匹配。
  如果都用 `u8`，`v >= bound` 的比较在 `bound = 252` 时没问题，
  但养成提升的习惯更安全（如果 charset 更大、`bound` 超过 255 就不会溢出）。
- **`if (v >= bound) continue;`**：拒绝采样的核心——丢弃会引入偏差的尾部。
  这里 `continue` 跳到 `while` 的下一次迭代，重新取一个随机字节。
- **`pw[filled] = PASSWORD_CHARSET[v % charset_len];`**：
  `v` 在 `[0, 252)` 内，`v % 84` 在 `[0, 84)` 内——字符集索引合法。
- **返回 `![]u8`**：调用方拥有的切片，需要用同一个 allocator `free`。
  注意 `io.randomSecure` 返回 `!void`——可能 `error.EntropyUnavailable`。

### 41.3.3 运行时输出

```text
==== 41.3 zpass 密码生成 开始 ====
长度 12: ]8b}^@M@oW[6
长度 16: ]@me9#iMcv1[@E22
长度 20: _fRrwaDpg}ikw*pq}a6w
结论：3 个密码均满足长度与字符集约束（断言通过）。
==== 41.3 结束 ====
```

每次运行的密码都不同（它们用了 CSPRNG），但**格式是确定的**：
长度 12、16、20 各一个，每个字符都在 PASSWORD_CHARSET 里。

### 41.3.4 断言

```zig
// examples/41_zpass/main.zig 第 172-174 行
std.debug.assert(pw.len == len);
for (pw) |c| std.debug.assert(std.mem.indexOfScalar(u8, PASSWORD_CHARSET, c) != null);
```

两个断言：
1. 长度正确（`pw.len == len`）。
2. 每个字符都在字符集里（`indexOfScalar` 找不到就返回 `null`）。

`std.debug.assert` 在 Debug/ReleaseSafe 下会 panic，在 ReleaseFast/ReleaseSmall
下是 no-op——对于密码生成器，这两个断言在生产环境也应该检查
（改成 `if` + `return error`）。

### 41.3.5 为什么用 CSPRNG 而不是 PRNG

`generatePassword` 用 `io.randomSecure` 而不是固定 seed 的 PRNG——
这不是随意的选择。密码生成器的安全性完全取决于随机源的不可预测性：

- **固定 seed PRNG**：攻击者知道算法（Xoshiro256++）和 seed，
  就能预测密码。seed 一旦泄露，所有密码都暴露了。
- **`io.random` 播种的 PRNG**：seed 不可预测，但算法是确定性的——
  给定足够的输出样本，可以反推内部状态，进而预测后续输出。
- **`io.randomSecure`**：每次调用都向 OS 要新的随机字节。
  OS 的 CSPRNG（`arc4random` / `getrandom`）经过密码学分析，
  从输出反推内部状态在计算上不可行。

对于密码生成器，**没有"够随机就行"**——要么 CSPRNG，要么不安全。
这也是 41.1 的决策树把"需要密码学安全吗？"放在最顶层的原因。

### 41.3.6 测试

```zig
// examples/41_zpass/main.zig 第 390-411 行
test "zpass 密码：长度正确，所有字符都在字符集内（固定 seed，100 次迭代）" {
    var prng = std.Random.DefaultPrng.init(12345);
    const r = prng.random();
    const charset_len = PASSWORD_CHARSET.len;
    const bound: u16 = @as(u16, 256 / charset_len) * charset_len;
    var iter: u32 = 0;
    while (iter < 100) : (iter += 1) {
        // 复刻 generatePassword 的采样逻辑，但用固定 seed 的 PRNG 保证确定性。
        var pw: [20]u8 = undefined;
        var filled: usize = 0;
        while (filled < pw.len) {
            const v: u16 = r.int(u8);
            if (v >= bound) continue;
            pw[filled] = PASSWORD_CHARSET[v % charset_len];
            filled += 1;
        }
        // 长度天然是 20（数组定长）；验证字符集归属。
        for (pw) |c| {
            try std.testing.expect(std.mem.indexOfScalar(u8, PASSWORD_CHARSET, c) != null);
        }
    }
}
```

测试不用 `io.randomSecure`（不可复现），而是**复刻采样逻辑**但用
固定 seed 的 PRNG——100 次迭代 × 20 字符 = 2000 个字符全部验证
字符集归属。这是测试随机代码的标准做法：**逻辑相同，引擎换成可复现的**。

---

## 41.4 UUID v4 生成

UUID v4 是"几乎全靠随机数"的 UUID 版本——16 个随机字节，
但其中两个字节的高位被**位操作**改写成固定值，以满足 RFC 4122 的要求。

### 41.4.1 uuidV4：生成

```zig
// examples/41_zpass/main.zig 第 187-193 行
/// 生成一个 UUID v4：16 个 CSPRNG 字节，
/// byte6 高 4 位写成 0b0100（版本 4），byte8 高 2 位写成 0b10（variant 2）。
fn uuidV4(io: std.Io) ![16]u8 {
    var b: [16]u8 = undefined;
    try io.randomSecure(&b);
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 10xx（即 RFC 的 0b10）
    return b;
}
```

逐行解释：

- **`try io.randomSecure(&b)`**：16 个密码学安全随机字节。
  用 `randomSecure` 而不是 `io.random`——UUID 常用于数据库 ID 和
  会话令牌，安全性很重要。
- **`b[6] = (b[6] & 0x0f) | 0x40;`**：byte 6 的高 4 位改写成 `0100`（= 4）。
  - `b[6] & 0x0f`：保留低 4 位，高 4 位清零（`0x0f = 0b00001111`）。
  - `| 0x40`：高 4 位设为 `0100`（`0x40 = 0b01000000`）。
  - 合起来：byte 6 的高 4 位 = 版本号 4，低 4 位保持随机。
- **`b[8] = (b[8] & 0x3f) | 0x80;`**：byte 8 的高 2 位改写成 `10`。
  - `b[8] & 0x3f`：保留低 6 位，高 2 位清零（`0x3f = 0b00111111`）。
  - `| 0x80`：高 2 位设为 `10`（`0x80 = 0b10000000`）。
  - 合起来：byte 8 的高 2 位 = variant `10`，低 6 位保持随机。

UUID 标准形是 `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`——
第 13 个十六进制字符（byte 6 的高 4 位）永远是 `4`，
第 17 个（byte 8 的高 2 位）永远是 `8`、`9`、`a` 或 `b`（即 `10xx`）。

### 41.4.2 UUID v4 的位操作详解

两个位操作是 UUID v4 的核心。用具体数字走一遍：

**byte 6 的版本设置**：

```
随机 byte 6 = 0xCD = 0b11001101
                    ↑↑↑↑
                    高 4 位（要改成 0100）

b[6] & 0x0f     = 0b11001101 & 0b00001111
                = 0b00001101        ← 保留低 4 位，高 4 位清零
                = 0x0D

b[6] | 0x40     = 0b00001101 | 0b01000000
                = 0b01001101        ← 高 4 位设为 0100（= 4）
                = 0x4D
```

结果：byte 6 从 `0xCD` 变成 `0x4D`——高 4 位是 `4`（版本号），
低 4 位 `D` 保持随机。

**byte 8 的 variant 设置**：

```
随机 byte 8 = 0xFE = 0b11111110
                    ↑↑
                    高 2 位（要改成 10）

b[8] & 0x3f     = 0b11111110 & 0b00111111
                = 0b00111110        ← 保留低 6 位，高 2 位清零
                = 0x3E

b[8] | 0x80     = 0b00111110 | 0b10000000
                = 0b10111110        ← 高 2 位设为 10（variant）
                = 0xBE
```

结果：byte 8 从 `0xFE` 变成 `0xBE`——高 2 位是 `10`（variant），
低 6 位 `0b111110` 保持随机。

**为什么是 `&` 再 `|`？** 这是位操作的"先清后设"模式：
1. `& mask`：用掩码清零要修改的位，保留其他位。
2. `| value`：用 OR 设置目标值。因为目标位已经被清零，
   OR 不会影响到其他位。

掩码的选择：
- `0x0f = 0b00001111`：低 4 位全 1（保留），高 4 位全 0（清零）。
- `0x3f = 0b00111111`：低 6 位全 1（保留），高 2 位全 0（清零）。
- `0x40 = 0b01000000`：只有 bit 6 是 1——设置版本号的最高位。
  版本号是 `0100`（= 4），所以 OR 的值是 `0x40`。
- `0x80 = 0b10000000`：只有 bit 7 是 1——设置 variant 的最高位。
  variant 是 `10`，所以 OR 的值是 `0x80`。

### 41.4.3 uuidToString：格式化

```zig
// examples/41_zpass/main.zig 第 197-211 行
/// 格式化成标准形 "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"（36 字符 + 4 个连字符）。
/// 连字符位置：8/13/18/23 字符处，对应字节 3、5、7、9 之后。
fn uuidToString(b: [16]u8) [36]u8 {
    var out: [36]u8 = undefined;
    var oi: usize = 0;
    for (b, 0..) |byte, i| {
        // UUID 的连字符位置：byte 3、5、7、9 之后（8-4-4-4-12 分组）。
        if (i == 4 or i == 6 or i == 8 or i == 10) {
            out[oi] = '-';
            oi += 1;
        }
        out[oi] = std.fmt.hex_charset[byte >> 4];
        out[oi + 1] = std.fmt.hex_charset[byte & 15];
        oi += 2;
    }
    return out;
}
```

逐行解释：

- **`for (b, 0..) |byte, i|`**：遍历 16 个字节，`i` 是字节索引（0 到 15）。
- **`if (i == 4 or i == 6 or i == 8 or i == 10)`**：在 byte 3、5、7、9 之后
  插入连字符——对应 UUID 的 8-4-4-4-12 分组。
  为什么是 `i == 4` 而不是 `i == 3`？因为 `i` 是**当前字节**的索引，
  在写 byte 4 之前要先写连字符（byte 0-3 已经写了 8 个 hex 字符）。
- **`out[oi] = std.fmt.hex_charset[byte >> 4];`**：高 4 位 → hex 字符。
- **`out[oi + 1] = std.fmt.hex_charset[byte & 15];`**：低 4 位 → hex 字符。
- **返回 `[36]u8`**：16 字节 × 2 hex 字符 + 4 连字符 = 36 字符。
  定长数组，不需要分配器。

### 41.4.4 uuidParse：解析（测试用）

```zig
// examples/41_zpass/main.zig 第 214-235 行
/// 解析回 16 字节（测试用）：跳过连字符，每两个十六进制字符还原一字节。
fn uuidParse(s: []const u8) ![16]u8 {
    if (s.len != 36) return error.BadLength;
    var out: [16]u8 = undefined;
    var oi: usize = 0; // 输出字节索引
    var i: usize = 0; // 输入字符索引
    while (i < s.len) {
        if (s[i] == '-') {
            i += 1;
            continue;
        }
        if (oi >= 16) return error.BadLength;
        const hi = std.mem.indexOfScalar(u8, std.fmt.hex_charset, s[i]) orelse return error.BadChar;
        i += 1;
        if (i >= s.len or s[i] == '-') return error.BadChar;
        const lo = std.mem.indexOfScalar(u8, std.fmt.hex_charset, s[i]) orelse return error.BadChar;
        i += 1;
        out[oi] = (@as(u8, @intCast(hi)) << 4) | @as(u8, @intCast(lo));
        oi += 1;
    }
    if (oi != 16) return error.BadLength;
    return out;
}
```

逐行解释：

- **`if (s.len != 36) return error.BadLength;`**：UUID 字符串必须恰好 36 字符。
- **`if (s[i] == '-') { i += 1; continue; }`**：跳过连字符。
- **`std.mem.indexOfScalar(u8, std.fmt.hex_charset, s[i])`**：在 hex 字符表里
  查找当前字符的位置——这个位置就是它的数值（`0` 到 `15`）。
  找不到（不是合法 hex 字符）就返回 `error.BadChar`。
- **`(@as(u8, @intCast(hi)) << 4) | @as(u8, @intCast(lo))`**：
  高 4 位左移 4 位，和低 4 位做 OR——还原原始字节。
- **`if (oi != 16) return error.BadLength;`**：如果解析完不是 16 字节，
  说明输入格式不对。

### 41.4.5 运行时输出

```text
==== 41.4 UUID v4 开始 ====
UUID v4 #1: e54e460f-69ac-4d82-a164-dc5e557b4a4b
UUID v4 #2: af9ca4d4-debb-4147-9bd3-39abbbe86dcd
结论：version nibble = 4，variant bits = 0b10，字符串定长 36。
==== 41.4 结束 ====
```

注意两个 UUID 的第 13 个字符（`4d82` 和 `4147` 的 `4`）都是 `4`——
这是版本号。第 17 个字符（`a164` 和 `9bd3` 的 `a` 和 `9`）都在
`[89ab]` 范围内——这是 variant 位。

### 41.4.6 为什么用 randomSecure 生成 UUID

UUID 常用于数据库主键和会话令牌——这两个场景都要求不可预测性：

- **数据库主键**：如果攻击者能预测下一个 UUID，就能探测数据库里
  有哪些记录（"这个 ID 存在吗？"）。不可预测的 UUID 关闭了
  这种信息泄露通道。
- **会话令牌**：如果攻击者能预测下一个会话 ID，就能劫持其他用户的
  会话。这是直接的安全漏洞。

和 41.3 的密码生成器一样，UUID 生成**没有"够随机就行"**——
要么 CSPRNG，要么不安全。`io.random` 播种的 PRNG 看起来
"每次不同"，但"不同"不等于"不可预测"。

### 41.4.7 断言与测试

```zig
// examples/41_zpass/main.zig 第 244-247 行
std.debug.assert((b[6] >> 4) == 4);
std.debug.assert((b[8] >> 6) == 0b10);
std.debug.assert(s.len == 36);
```

三个断言直接验证了 UUID v4 的两个关键性质：
1. byte 6 的高 4 位 == 4（版本号）。
2. byte 8 的高 2 位 == `0b10`（variant）。
3. 字符串长度 == 36。

```zig
// examples/41_zpass/main.zig 第 376-388 行
test "UUID v4：version nibble == 4，variant bits == 0b10，字符串长 36" {
    // 不走 OS 熵：手工构造 16 字节，走 uuidToString / uuidParse 验证格式逻辑。
    var b: [16]u8 = .{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10 };
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    const s = uuidToString(b);
    try std.testing.expectEqual(@as(usize, 36), s.len);
    try std.testing.expectEqual(@as(u4, 4), @as(u4, @truncate(b[6] >> 4)));
    try std.testing.expectEqual(@as(u2, 0b10), @as(u2, @truncate(b[8] >> 6)));
    // 解析回 16 字节应逐字节一致。
    const back = try uuidParse(&s);
    try std.testing.expectEqualSlices(u8, &b, &back);
}
```

测试用**手工构造**的 16 字节（不走 OS 熵），验证 `uuidToString` 和
`uuidParse` 的往返一致性：16 字节 → 字符串 → 16 字节，逐字节一致。
`@truncate` 把 `u8` 截断为 `u4` 或 `u2`——只保留需要的位数。

---

## 41.5 随机时间序列生成器

最后一个应用：生成随机时间序列——数据处理工具的输入积木。
形状完全确定（点数、步长、起点），只有值是随机的。

### 41.5.1 TimePoint 与 generateTimeSeries

```zig
// examples/41_zpass/main.zig 第 258-283 行
const TimePoint = struct {
    /// 毫秒时间戳（epoch 起）。0.17 用 std.Io.Timestamp.now(io, .real).toMilliseconds()。
    ts_ms: i64,
    /// 测量值，[0, 100] 区间。
    value: f64,
};

/// 生成 n 个点的随机时间序列：起点 t0，步长 step_ms，值在 [0, 100]。
/// 形状确定（点数/步长/起点），只有 value 是随机的 —— 数据处理工具的输入积木。
fn generateTimeSeries(
    io: std.Io,
    n: usize,
    t0_ms: i64,
    step_ms: i64,
    out: []TimePoint,
) !void {
    var seed: [8]u8 = undefined;
    try io.randomSecure(&seed);
    var prng = std.Random.DefaultPrng.init(std.mem.readInt(u64, &seed, .little));
    const r = prng.random();
    for (out[0..n], 0..) |*p, i| {
        p.ts_ms = t0_ms + @as(i64, @intCast(i)) * step_ms;
        // intRangeAtMost 内部已拒绝采样，[0,100] 无偏。
        p.value = @floatFromInt(r.intRangeAtMost(u8, 0, 100));
    }
}
```

逐行解释：

- **`try io.randomSecure(&seed)`**：用 CSPRNG 取 8 字节 seed。
  这里用 `randomSecure` 而不是 `io.random`——时间序列的值不需要
  密码学安全，但 seed 用 CSPRNG 保证不可预测。
- **`std.Random.DefaultPrng.init(std.mem.readInt(u64, &seed, .little))`**：
  把 8 字节 seed 解释为 `u64`，播种 PRNG。之后用 PRNG（而不是
  每次调 `randomSecure`）生成值——PRNG 更快，而且这里不需要
  每个值都密码学安全。
- **`p.ts_ms = t0_ms + @as(i64, @intCast(i)) * step_ms;`**：
  时间轴完全确定——`t0 + i * step`。没有随机性。
- **`p.value = @floatFromInt(r.intRangeAtMost(u8, 0, 100));`**：
  值在 `[0, 100]` 区间内均匀分布。`intRangeAtMost` 内部已做
  拒绝采样（41.2 的理论），所以你不需要自己处理模偏差。
  `@floatFromInt` 把整数转成 `f64`。

### 41.5.2 设计决策：为什么时间轴确定、值随机

这个设计不是随意的——它解决了一个真实问题：**测试随机数据生成器时，
你怎么验证输出是对的？**

如果时间和值都随机，你唯一能验证的是"输出了 n 个点"——
时间对不对、步长对不对、范围对不对，全都验不了。
把**时间轴固定**（`t0 + i * step`）后，你可以精确断言：

```zig
// 伪代码：测试可以精确验证时间轴
try std.testing.expectEqual(@as(i64, 0), points[0].ts_ms);
try std.testing.expectEqual(@as(i64, 60000), points[1].ts_ms);
try std.testing.expectEqual(@as(i64, 120000), points[2].ts_ms);
// ...每个点的时间戳都是确定的
```

只有值需要验证范围（`0 <= value <= 100`）和类型（`f64`）——
这两个断言在固定 seed 下可以精确验证。

这个原则可以推广到所有随机代码的设计：**把确定的部分和随机的部分
分开**。确定的部分精确断言，随机的部分验证约束（范围、类型、分布）。
41.3 的密码生成器测试（固定 seed 验证字符集归属）和
41.4 的 UUID 测试（手工构造字节验证格式逻辑）用的是同一个原则。

### 41.5.3 运行时输出

```text
==== 41.5 随机时间序列 开始 ====
  idx | timestamp(ms) | value
------+---------------+------
  0   |             0 | 22.0
  1   |         60000 | 77.0
  2   |        120000 | 28.0
  3   |        180000 | 49.0
  4   |        240000 | 33.0
结论：时间轴确定（epoch + 60s 步进），只有 value 随机。
==== 41.5 结束 ====
```

时间戳列是确定的（0、60000、120000、180000、240000——60 秒步进），
值列每次运行都不同。这种「形状确定、值随机」的设计让测试可以
精确验证时间轴逻辑，同时保留值的随机性。

### 41.5.4 0.17 API 变化

`TimePoint.ts_ms` 的注释提到了 0.17 的时间 API 变化：

| 0.16 及之前 | 0.17 |
|---|---|
| `std.time.milliTimestamp()` | `std.Io.Timestamp.now(io, .real).toMilliseconds()` |
| `std.time.nanoTimestamp()` | `std.Io.Timestamp.now(io, .real).toNanoseconds()` |
| `std.time.microTimestamp()` | `std.Io.Timestamp.now(io, .real).toMicroseconds()` |
| `std.time.Timer` | 不存在（34 章 34.16 有完整讨论） |

`std.time.milliTimestamp` 在 0.17 已彻底删除。新的 API 需要传入
`io`（因为时间获取在某些平台上需要 I/O 权限）和时钟类型
（`.real` 是墙钟时间，`.mono` 是单调时钟——不受 NTP 校时影响，
适合测量耗时）。

两种时钟的区别：

| 时钟 | 方法 | 特点 | 适用场景 |
|---|---|---|---|
| `.real` | `toMilliseconds()` / `toNanoseconds()` | 墙钟时间，受 NTP 校时影响 | 日志时间戳、数据点标记 |
| `.mono` | `toNanoseconds()` | 单调递增，不受校时影响 | 测量耗时、超时判断 |

**不要用 `.real` 测量耗时**——NTP 校时可能让墙钟时间突然跳变
（向前或向后），导致你测出的"耗时"是负数或巨大正数。
34 章的 `std.time.Timer` 消失后，单调时钟的替代方案就是
`std.Io.Timestamp.now(io, .mono)`。

本章的 `generateTimeSeries` 没有直接调 `Timestamp.now`——
它接受 `t0_ms` 参数让调用方决定起点。但注释里写了 0.17 的正确写法，
因为真实场景里你几乎总是从"当前时间"开始生成序列。

### 41.5.5 完整的时间序列生成示例

把 `generateTimeSeries` 和 `Timestamp.now` 组合起来——
从当前时间开始生成一个最近 5 分钟的随机时间序列：

```zig
// 不在示例里，但展示了真实用法
const now_ms = std.Io.Timestamp.now(io, .real).toMilliseconds();
var points: [5]TimePoint = undefined;
try generateTimeSeries(io, 5, now_ms - 5 * 60_000, 60_000, &points);
// points[0].ts_ms = now - 5min, points[4].ts_ms = now
// 5 个点覆盖最近 5 分钟，每 60 秒一个
```

这个模式——用 `.real` 拿当前时间、用固定步长回溯——是监控数据、
传感器数据、日志分析工具的标准做法。`generateTimeSeries` 提供了
形状，调用方提供时间语义。

---

## 41.6 坑位清单

按「会不会让程序悄悄算错/出安全问题」排序。

### 一、安全相关的（最严重）

1. **`std.crypto.random` 在 0.17 不存在**。
   0.16 及之前的 `std.crypto.random` 是一个全局 CSPRNG 接口，
   0.17 已彻底删除。正解是 `try init.io.randomSecure(&buf)`——
   每次调用都向 OS 要新的密码学安全随机字节。
   注意它返回 `!void`（可能 `error.EntropyUnavailable`），必须 `try`。
   如果你看到网上有代码写 `std.crypto.random.int(u8)`，那是旧版 API。

2. **模偏差： `% N` 当 `2^bits % N != 0` 时有偏**。
   这是**安全问题**不是数学洁癖——有偏的密码生成器给攻击者
   提供了统计线索。`u8 % 100` 的偏差比是 1.5:1（41.2 有完整推导）。
   正解：拒绝采样——只接受 `< floor(2^bits / N) * N` 的值，
   拒绝尾部。`r.intRangeAtMost` 内部已做拒绝采样，手写 `%` 才踩坑。

3. **`io.random` 不是 CSPRNG**。
   `io.random(&buf)` 用 OS 熵播种一个 PRNG——seed 不可预测，
   但算法是 Xoshiro256++（确定性的）。适合洗牌、模拟、游戏，
   **不适合**密码、密钥、UUID。那些场景用 `io.randomSecure`。

### 二、API 变化

4. **`std.time.milliTimestamp` 在 0.17 不存在**。
   正解：`std.Io.Timestamp.now(io, .real).toMilliseconds()`。
   需要传入 `io` 和时钟类型（`.real` 墙钟 / `.mono` 单调）。
   41.5 的 `TimePoint` 注释里有完整写法。

5. **PRNG 需要 seed：固定 seed 可复现（测试友好），`io.random` 每次不同**。
   `std.Random.DefaultPrng.init(0xdeadbeef)` 的产出永远一致——
   这是特性不是 bug。测试随机代码时，**复刻采样逻辑但换成固定 seed 的 PRNG**
   （41.3.5 的测试就是这么做的）。如果程序行为每次运行都不同，
   先把随机源换成固定 seed 再调试。

---

## 41.7 验证方式

三层，与全项目一致：

```bash
cd examples/41_zpass
zig fmt --check .                                    # 第 1 层：格式 + 语法
zig test main.zig                                    # 第 2 层：4 个 test
zig build-exe main.zig -femit-bin=/tmp/zpass         # 第 3 层：main 也要能编
/tmp/zpass                                            # 第 3 层：真跑一遍
```

第 3 层不可省：`zig test` 不看 `main`，而本章最要紧的 5 个运行时小节
**全在 `main` 里`。

跑完应看到（结构确定，具体字节值/密码/UUID 每次不同）：

```text
==== 41.1 三种随机源 开始 ====
DefaultPrng(seed=0xdeadbeef) 前 8 字节: de e2 22 97 58 23 d4 19
intRangeAtMost(u8, 1, 6) 掷一次骰子: 2
io.random 播种的 PRNG   前 8 字节: [每次不同]
io.randomSecure(CSPRNG) 前 8 字节: [每次不同]
结论：三种源都能产字节；PRNG 可复现、CSPRNG 不可复现但抗预测。
==== 41.1 结束 ====
==== 41.2 模偏差 开始 ====
256 个 u8 值 % 100 的桶计数：残差 0..55 各 3 次，残差 56..99 各 2 次
偏差比 = 3/2 = 1.50
实测（seed=42，25600 次 u8 % 100）：残差 0 命中 281 次，残差 99 命中 238 次
拒绝采样后（同样 25600 次）：残差 0 命中 247 次，残差 99 命中 299 次
拒绝采样后每个残差概率相等。
==== 41.2 结束 ====
==== 41.3 zpass 密码生成 开始 ====
长度 12: [12 个字符]
长度 16: [16 个字符]
长度 20: [20 个字符]
结论：3 个密码均满足长度与字符集约束（断言通过）。
==== 41.3 结束 ====
==== 41.4 UUID v4 开始 ====
UUID v4 #1: [36 字符，第 13 位是 4，第 17 位是 8/9/a/b]
UUID v4 #2: [同上]
结论：version nibble = 4，variant bits = 0b10，字符串定长 36。
==== 41.4 结束 ====
==== 41.5 随机时间序列 开始 ====
  idx | timestamp(ms) | value
------+---------------+------
  0   |             0 | [0-100]
  1   |         60000 | [0-100]
  2   |        120000 | [0-100]
  3   |        180000 | [0-100]
  4   |        240000 | [0-100]
结论：时间轴确定（epoch + 60s 步进），只有 value 随机。
==== 41.5 结束 ====
==== 41.6 坑位清单 开始 ====
1. std.crypto.random 在 0.17 不存在 —— 用 init.io.randomSecure(&buf)
2. std.time.milliTimestamp 在 0.17 不存在 —— 用 std.Io.Timestamp.now(io, .real).toMilliseconds()
3. 模偏差：% N 当 2^bits % N != 0 时有偏；拒绝采样是无偏的标准解法
4. PRNG 需要 seed：固定 seed 可复现（测试友好），io.random 每次不同
5. r.intRangeAtMost 内部已处理无偏，手写 % 才踩坑
==== 41.6 结束 ====
```

注意 41.1 的第一行（`de e2 22 97 58 23 d4 19`）和 41.2 的所有数字
**每次运行都完全一样**——它们用了固定 seed 或 comptime 数论。
其余行每次不同。

测试输出（`zig test main.zig`）：

```text
1/4 main.test.biasedCounts 数论：256 % 100 → 残差 0..55 各 3 次，56..99 各 2 次...OK
2/4 main.test.拒绝采样：永不返回 >= bound 的值，且多次抽取覆盖所有残差...OK
3/4 main.test.UUID v4：version nibble == 4，variant bits == 0b10，字符串长 36...OK
4/4 main.test.zpass 密码：长度正确，所有字符都在字符集内（固定 seed，100 次迭代）...OK
All 4 tests passed.
```

**稳定性说明**：41.2 的输出是确定性的（comptime 数论 + 固定 seed PRNG），
可以逐字节比对。41.1 / 41.3 / 41.4 / 41.5 的输出包含随机值，
但**结构**（行数、格式、断言结果）是确定的。测试全部用固定 seed
或手工构造的数据，保证 `zig test` 的结果可复现。

**本章与其他章的关系**：26 章有 hex/base64 编码的完整讨论——
本章只用到 `std.fmt.hex_charset` 做格式化，不涉及编码理论。
25 章有二进制数据与内存布局的完整讨论——本章的 UUID 位操作
（`& 0x0f | 0x40`）假设你已熟悉位运算，25 章 25.11 有
`@popCount` / `@clz` / `@ctz` / `@bitReverse` 等位操作的内建函数。

---

上一章：[40 实战：ZIP 解析与 comptime 布局校验](40-zunzip.md) · 下一章：[42 内存服务](42-memsrv.md)
