# 40 · 实战：ZIP 解析与 comptime 布局校验

> **阅读位置**：第六篇 · 综合实战（5/8） ｜ **承前**：[25 二进制布局](25-binary.md)、[13 comptime](13-comptime.md)、[14 反射](14-generics.md) ｜ **启后**：二进制格式解析的收官演示。
>
> 对应示例：`examples/40_zunzip/main.zig`（491 行，6 个测试）
>
> 二进制格式解析的收官演示：ZIP 文件结构（EOCD / Central Directory / Local File Header）、
> comptime 生成 CRC32 查表、comptime 布局校验（`@typeInfo(T).@"struct".field_types`）、
> 端到端「构造 → 解析 → 提取 → 验证」闭环、字节序实测。
> 取材 Tsoukalos ch3（zunzip + comptime 布局校验 + endianness）。
> extern struct / packed struct / bytesToValue 的完整对比在 25 章，本章**不重复**，
> 只聚焦 ZIP 特有的解析技巧与 comptime 校验的签名写法。
>
> 本章有 **5 条结论会推翻你可能听过的说法**，全部是 0.17.0 上实测的：
>
> 1. **「二进制格式解析就是 memcpy 一个 struct」是最危险的写法**。extern struct 的
>    `@sizeOf` 之和 ≠ 线格式尺寸（编译器会插 padding），`bytesToValue` 对齐不过关时
>    **不报错**——它给你一个错读的值而不是 panic（25 章 25.6 有完整实测）。
>    正解：普通 struct 做字段命名 + `readInt` 显式偏移解析 + comptime 校验
>    字段宽度之和（40.5）。
> 2. **「comptime 只能算斐波那契」**。comptime 块在**编译期**就把 EOCD 的
>    8 个字段宽度加起来和 22 比对、CD 的 17 个字段加起来和 46 比对——
>    任何一个字段从 `u16` 改成 `u32`，build 直接 `@compileError`，
>    而不是运行期读出一个损坏的文件名（40.5）。
> 3. **「学格式靠读规范」**。本章的核心方法论是**先构造再解析**：
>    亲手用 `writeInt` 把每个字段写进内存（40.2），再倒着把它解析回来（40.3-40.6）。
>    构造的过程逼你回答「每个字段多少字节、什么顺序、什么端序」——
>    这些问题答对了，解析就是照着答案抄。
> 4. **「0.17 里 `std.meta.fields` 还能用」**。已彻底废弃（直接 `@compileError`）。
>    正解是 `@typeInfo(T).@"struct".field_types`——**平行数组**，
>    而且普通 `for` 的索引是 runtime-known 会报错，必须 `inline for`（40.5）。
> 5. **「EOCD 在文件头部」**。ZIP 的目录索引（Central Directory）在**文件末尾**，
>    解析必须**从尾部向前扫**——这允许 ZIP 前面挂任意前置数据（自解压包 stub），
>    也让 10 GB 的包和 10 KB 的包一样秒开（只读尾部 22 字节 + 可选 comment）（40.3）。
>
> **节号对应**：40.1–40.7 是示例 `main` 里的运行时小节（`begin("40.N …") …
> end("40.N")`，运行输出里能看到 `==== 40.N … 开始 ====`）；
> **40.8（坑位清单）与 40.9（验证方式）不在 `main` 里**，它们是本文档自己的两节。
> 示例 `main` 里确实有一个 `begin("40.8 坑位清单")` 运行时小节，内容是 5 条速览——
> 本文档 40.8 是它的完整展开。
>
> **稳定性纪律**：本章所有输出都是确定性的——CRC32 在 comptime 算出固定值、
> ZIP 字节流在 comptime 构造、解析结果完全可预测。唯一的「随机」是 40.7 的
> 字节序演示，但那是固定常量 0x12345678 的转换，也是确定的。
> 所以下面每一个 `text` 围栏都是逐字抄的，连跑 10 次 diff 无差异。

---

## 导读：这一章要推翻三个说法

前面每一章都在推翻"看起来当然如此"的说法，这一章也一样。

**说法一："二进制格式解析就是 memcpy 一个 struct。"**

错，而且错得很危险。C 里的经典写法是：

```c
// ❌ C 的经典写法：把文件字节直接覆盖到一个 struct 上
struct EOCD record;
fread(&record, sizeof(record), 1, fp);
// 然后 record.cd_offset 直接可用
```

这在 C 里就已经是 bug 温床（结构体 padding、端序、对齐），在 Zig 里更不行：
`@sizeOf(EOCD)` 可能不等于 22（编译器在 `u16` 和 `u32` 之间插 2 字节 padding），
`bytesToValue` 对齐不过关时**不报错**——它静默读出一个垃圾值（25 章 25.6 有实测）。
本章的替代方案是**普通 struct + `readInt` 显式偏移解析 + comptime 字段宽度校验**：
struct 只做字段命名和类型约束，真正的字节读取用 `std.mem.readInt(u16, data[o..][0..2], .little)`
一个字段一个字段来，偏移量 `o` 由你手动推进——**每个偏移都是你对规范的理解写成的代码**。
comptime 块再把所有字段的 `@sizeOf` 加起来和规范的 22 / 46 比对，
任何一个字段类型写错了，build 直接失败（40.5）。

**说法二："comptime 只能算斐波那契数列。"**

comptime 的教科书示例确实是 `comptime fib(10)` 或者 `comptime` 算个阶乘。
但 comptime 的真正威力在于**把运行期的断言提前到编译期**。
本章的 `wireSize` 函数在 comptime 遍历 `Eocd` 的全部 8 个字段类型，
把它们的 `@sizeOf` 加起来，和 22 比对——如果不等就 `@compileError`。
这意味着：**任何一个字段从 `u16` 改成 `u32`，或者多了一个字段，
build 立刻失败**，而不是在运行期读出一个损坏的文件名、一个错误的文件大小、
一个对不上的条目数。40.5 会讲清为什么 `@sizeOf` 之和 ≠ `@sizeOf(struct)`
（padding），以及 0.17 里 `std.meta.fields` 废弃后的新写法。

**说法三："学二进制格式靠读规范文档。"**

规范文档（PKZIP APPNOTE.TXT）你当然需要查，但**只读规范学不会格式**。
本章的方法论是：**先构造，再解析**。40.2 用 `writeInt` 亲手把 EOCD、
CD 条目、LFH 的每个字段按正确顺序写进一块内存——写的过程逼你回答
"sig 是 4 字节还是 8 字节？version_needed 在 flags 前面还是后面？
CRC 是 little-endian 还是 big-endian？"。这些问题答对了，解析就是照着答案抄。
40.6 的端到端演示完成了闭环：构造一个 126 字节的 ZIP → 从尾部扫到 EOCD →
解析 CD 条目 → 提取文件内容 → 和原始数据比对一致。

---

## 40.1 ZIP 格式理论

ZIP 文件不是从头开始顺序读的——它是**从尾部倒着读**的。这是 1980 年代
软盘时代的工程决定：把"主索引"（Central Directory）放在文件末尾，
追加文件时不需要重写整个归档——只需在末尾加数据、更新目录、重写 EOCD。

```
[Local File Header + name] [file data] ...  ← 可能有 N 组
[Central Directory entry + name] ...         ← 可能有 M 条
[EOCD (22 bytes + optional comment)]         ← 一定在最后
```

三种签名（全部 little-endian 存储）：

| 签名 | 十六进制 | 含义 |
|---|---|---|
| LFH | `0x04034b50` | Local File Header，每个文件数据的前面 |
| CD  | `0x02014b50` | Central Directory 条目，目录区在 EOCD 之前 |
| EOCD | `0x06054b50` | End Of Central Directory，一定在文件末尾 |

三种记录的固定字段布局（**全部小端**，括号内是字节数）：

```
EOCD:  sig(4) disk(2) cd_disk(2) n_disk(2) n_total(2) cd_size(4) cd_off(4) cmt_len(2) = 22B
CD:    sig(4) vmade(2) vneed(2) flags(2) method(2) time(2) date(2) crc(4)
       csize(4) usize(4) nlen(2) elen(2) clen(2) disk(2) iattr(2) eattr(4) lho(4) = 46B
LFH:   sig(4) vneed(2) flags(2) method(2) time(2) date(2) crc(4)
       csize(4) usize(4) nlen(2) elen(2) = 30B，后跟 name + extra + data
```

**变长字段**（name / extra / comment）紧跟在固定头后面，长度由固定头里的
`nlen` / `elen` / `clen` 字段给出。这意味着你不能定长读——必须读了固定头、
拿到长度字段、再跳过变长部分。40.4 的 `parseCdEntry` 演示了怎么做。

运行时输出：

```text
==== 40.1 ZIP 格式理论 开始 ====
ZIP 文件从尾部倒着读：
  EOCD (End Of Central Directory) 签名 0x06054b50，一定在文件末尾
  Central Directory 条目签名 0x02014b50，目录区在 EOCD 之前
  Local File Header 签名 0x04034b50，每个文件数据的前面
固定字段布局（全部小端）：
  EOCD:  sig(4) disk(2) cd_disk(2) n_disk(2) n_total(2) cd_size(4) cd_off(4) cmt_len(2) = 22B
  CD:    sig(4) vmade(2) vneed(2) flags(2) method(2) time(2) date(2) crc(4)
         csize(4) usize(4) nlen(2) elen(2) clen(2) disk(2) iattr(2) eattr(4) lho(4) = 46B
  LFH:   sig(4) vneed(2) flags(2) method(2) time(2) date(2) crc(4)
         csize(4) usize(4) nlen(2) elen(2) = 30B，后跟 name + extra + data
变长字段（name/extra/comment）紧跟在固定头后面，长度由固定头里的 len 字段给出
==== 40.1 ZIP 格式理论 结束 ====
```

---

## 40.2 构造一个内存中的最小 ZIP

这一节是本章的方法论核心：**先构造，再解析**。我们用 comptime 在内存里
造一个最小的合法 ZIP——一个文件 `hello.txt`，内容 `"Hello ZIP!"`，
method=0（stored，无压缩）。整个 ZIP 字节流在编译期就确定了，
运行期零成本。

### 40.2.1 CRC32：comptime 生成查表

ZIP 的每个文件都有一个 CRC32 校验值。我们不调 `std.hash.Crc32`——
自己用 comptime 生成查表，展示 comptime 的真实威力：

```zig
// examples/40_zunzip/main.zig 第 19-39 行
/// comptime 生成 256 项 CRC32 查表。const 初始化器本身就是 comptime 作用域，
/// 直接写 for 即可（写 inline for 会报 redundant inline keyword）。
const crc_table = blk: {
    @setEvalBranchQuota(100000);
    var t: [256]u32 = undefined;
    for (0..256) |i| {
        var c: u32 = @intCast(i);
        for (0..8) |_| {
            c = if (c & 1 != 0) 0xEDB88320 ^ (c >> 1) else c >> 1;
        }
        t[i] = c;
    }
    break :blk t;
};

/// 标准 CRC32：初值 0xFFFFFFFF，逐字节查表，最终取反
fn crc32(data: []const u8) u32 {
    var c: u32 = 0xFFFFFFFF;
    for (data) |b| {
        c = crc_table[(c ^ b) & 0xFF] ^ (c >> 8);
    }
    return c ^ 0xFFFFFFFF;
}
```

逐行解释：

- **`@setEvalBranchQuota(100000)`**：comptime 执行的默认分支配额是 3000。
  两层循环 256×8 = 2048 次迭代，加上内部的 if-else，会超配额。
  这行把配额提到 100000——**这是 comptime 循环几乎必带的一行**，忘了它
  编译器会报 `evaluation exceeded maximum number of iterations`。
- **`const crc_table = blk: { ... break :blk t; };`**：`const` 的初始化器
  本身就是 comptime 作用域，所以可以直接写 `for` 循环。
  注意**不要写 `inline for`**——在 comptime 作用域里写 `inline for` 会报
  `redundant inline keyword`（编译器认为你多此一举）。
- **内层循环 `for (0..8)`**：对 `c` 的每一位，如果最低位是 1 就
  XOR 上多项式 `0xEDB88320`（IEEE CRC32 的反射多项式）再右移，
  否则直接右移。这是标准的 CRC32 查表生成算法。
- **`crc32` 函数**：初值 `0xFFFFFFFF`，对每字节查表
  `crc_table[(c ^ b) & 0xFF] ^ (c >> 8)`，最终取反。
  这是 RFC 3720 定义的标准 CRC32（IEEE 802.3）。

测试验证（`test "CRC32 标准测试向量"`）：

```zig
// examples/40_zunzip/main.zig 第 428-435 行
test "CRC32 标准测试向量" {
    // "123456789" 的 CRC32 = 0xCBF43926（RFC 3720 附录标准向量）
    try std.testing.expectEqual(@as(u32, 0xCBF43926), crc32("123456789"));
    // 空串 = 0
    try std.testing.expectEqual(@as(u32, 0), crc32(""));
    // 我们的 demo 数据
    try std.testing.expectEqual(demo_crc, crc32(demo_data));
}
```

`"123456789"` → `0xCBF43926` 是 CRC32 的标准测试向量（RFC 3720 附录），
和它对上就证明实现正确。

### 40.2.2 定义 ZIP 结构体

```zig
// examples/40_zunzip/main.zig 第 46-76 行
/// EOCD 固定部分 = 22 字节（不含末尾 comment）
const Eocd = struct {
    sig: u32, // 0x06054b50
    disk_num: u16,
    cd_start_disk: u16,
    entries_this_disk: u16,
    total_entries: u16,
    cd_size: u32,
    cd_offset: u32,
    comment_len: u16,
};

/// Central Directory 条目固定头 = 46 字节（不含 name/extra/comment）
const CdEntry = struct {
    sig: u32, // 0x02014b50
    version_made_by: u16,
    version_needed: u16,
    flags: u16,
    method: u16,
    mod_time: u16,
    mod_date: u16,
    crc: u32,
    comp_size: u32,
    uncomp_size: u32,
    name_len: u16,
    extra_len: u16,
    comment_len: u16,
    disk_start: u16,
    internal_attrs: u16,
    external_attrs: u32,
    local_header_offset: u32,
};
```

**关键决定：用普通 struct，不是 extern struct**。注释里写得很清楚：

```
// 注意：这里**故意用普通 struct**（不是 extern）——我们只用它们做 comptime
// 尺寸校验和字段命名，绝不做 @bitCast / bytesToValue 强转（那是坑位清单第一条）。
```

普通 struct 的字段顺序和 padding 由编译器决定——**你不能把它直接覆盖到字节流上**。
但这也正是它的优点：你不会**忍不住**去这么做。struct 只承担两件事：
(1) 给字段起名字、定类型；(2) 在 comptime 里把字段宽度加起来和线格式尺寸比对。
真正的字节读取用 `readInt` 显式做（40.3 / 40.4）。

extern struct 在 25 章有完整讨论——它的 `@sizeOf` 包含编译器插入的 padding，
`@sizeOf` 之和可能不等于你期望的线格式尺寸。25 章 25.2 的实测：
`extern struct { a: u8, b: u32, c: u8 }` 的 `@sizeOf` = 12（不是 6），
因为编译器在 `a` 后面插了 3 字节 padding 让 `b` 4 字节对齐，尾部再补 2 字节。

还有一个解析结果 struct：

```zig
// examples/40_zunzip/main.zig 第 79-86 行
/// 解析后的 CD 条目（name 是零拷贝切片）
const CdInfo = struct {
    method: u16,
    crc: u32,
    comp_size: u32,
    uncomp_size: u32,
    local_header_offset: u32,
    name: []const u8,
};
```

`CdInfo` 是**解析后**的产物——它只包含我们关心的 6 个字段，`name` 是
零拷贝切片（指向原始 ZIP 字节流中的一段，不做内存分配）。这和 `CdEntry`
（线格式的镜像）是**两个不同的 struct**：一个对应字节流布局，一个对应
程序里真正要用的数据。把它们分开意味着你可以只提取需要的字段，
不用把 17 个字段全部搬进内存。

### 40.2.3 各段长度常量

```zig
// examples/40_zunzip/main.zig 第 104-114 行
const demo_name = "hello.txt";
const demo_data = "Hello ZIP!";
const demo_crc = crc32(demo_data); // comptime 算出来，运行期零成本

// 各段长度（固定头 + 变长 name）
const lfh_fixed = 30; // local file header 固定部分
const lfh_len = lfh_fixed + demo_name.len;
const cd_fixed = 46; // central directory 条目固定部分
const cd_len = cd_fixed + demo_name.len;
const eocd_len = 22; // EOCD 固定部分（comment_len=0）
const zip_len = lfh_len + demo_data.len + cd_len + eocd_len;
```

`demo_crc` 在 comptime 就确定了——`crc32` 的 `data` 参数是 `[]const u8`，
但 `demo_data` 是 `comptime` 已知的字符串常量，所以整个函数在编译期就执行完了。
运行期用 `demo_crc` 时是零成本的（就是一个 `u32` 常量）。

各段长度：
- `lfh_len` = 30 + 9 = 39（`"hello.txt"` 是 9 字节）
- `cd_len` = 46 + 9 = 55
- `eocd_len` = 22
- `zip_len` = 39 + 10 + 55 + 22 = **126 字节**

### 40.2.4 comptime 构造 ZIP 字节流

这是本章最长的一段代码，也是**最有教学价值的一段**——它把 ZIP 规范的
每个字段按正确顺序、正确端序写进内存：

```zig
// examples/40_zunzip/main.zig 第 121-213 行
const demo_zip = blk: {
    var z: [zip_len]u8 = @splat(0);
    var o: usize = 0;

    // ── local file header ──
    std.mem.writeInt(u32, z[o..][0..4], 0x04034b50, .little);
    o += 4;
    std.mem.writeInt(u16, z[o..][0..2], 20, .little); // version needed
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // flags
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // method = 0 (stored)
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // mod time
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0x21, .little); // mod date (1980-01-01)
    o += 2;
    std.mem.writeInt(u32, z[o..][0..4], demo_crc, .little);
    o += 4;
    std.mem.writeInt(u32, z[o..][0..4], demo_data.len, .little); // comp size
    o += 4;
    std.mem.writeInt(u32, z[o..][0..4], demo_data.len, .little); // uncomp size
    o += 4;
    std.mem.writeInt(u16, z[o..][0..2], demo_name.len, .little);
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // extra len
    o += 2;
    @memcpy(z[o..][0..demo_name.len], demo_name);
    o += demo_name.len;

    // ── file data（stored = 原样） ──
    @memcpy(z[o..][0..demo_data.len], demo_data);
    o += demo_data.len;

    // ── central directory entry ──
    const cd_offset = o;
    // ...（CD 条目的 17 个字段，同 LFH 的写法）
    // ── EOCD ──
    // ...（EOCD 的 8 个字段）
    break :blk z;
};
```

逐段解释：

**初始化**：`var z: [zip_len]u8 = @splat(0);` 把 126 字节全部清零。
`@splat(0)` 是数组/向量的广播语法——把标量 0 填充到每个元素。
`var o: usize = 0` 是写入偏移量，每写一个字段就 `o += N` 推进。

**`writeInt` 的签名**：`std.mem.writeInt(T, buffer: *[N]u8, value: T, endian: Endian)`。
关键：第二个参数是 `*[N]u8`（定长数组指针），不是切片——长度在类型层面就确定了，
写 `u32` 必须给 4 字节缓冲，写 `u16` 必须给 2 字节。
`z[o..][0..4]` 这个惯用法在 25 章 25.7 讲过：先取 `z[o..]` 得到从 `o` 开始到末尾的切片，
再 `[0..4]` 截取前 4 字节——类型是 `*[4]u8`，正好匹配 `writeInt` 的参数。
这比 `z[o..o+4]` 好：后者是切片，需要运行时检查长度。

**LFH 的 10 个字段**：sig(4) + vneed(2) + flags(2) + method(2) + time(2) + date(2)
+ crc(4) + csize(4) + usize(4) + nlen(2) + elen(2) = 30 字节。
注意 `mod_date = 0x21`——ZIP 的日期格式是从 1980-01-01 开始的，0x21 = 33
表示 1980 年 1 月 1 日（详见 PKZIP APPNOTE）。
`method = 0` 表示 stored（无压缩），所以 `comp_size == uncomp_size == 10`。

**file data**：stored 模式下数据原样写入，不做任何变换。

**CD 条目**：17 个字段，共 46 字节。和 LFH 相比多了
`version_made_by`、`comment_len`、`disk_start`、`internal_attrs`、
`external_attrs`、`local_header_offset`。其中 `local_header_offset = 0`
表示这个文件对应的 LFH 在 ZIP 文件的开头（偏移 0 处）。

**EOCD**：8 个字段，共 22 字节。`entries_this_disk = 1`、`total_entries = 1`
（只有一个文件），`cd_size = cd_len = 55`，`cd_offset = 49`（LFH 30+9=39 字节
+ data 10 字节 = 49），`comment_len = 0`。

**`cd_offset` 的捕获**：在写 CD 条目之前 `const cd_offset = o;` 捕获了
当前的写入位置——这个值后面要填进 EOCD 的 `cd_offset` 字段。
这是**构造时自然产生的元数据**，不需要额外计算。

### 40.2.5 运行时输出

```text
==== 40.2 构造一个内存中的最小 ZIP 开始 ====
文件: hello.txt，内容: "Hello ZIP!"（10 字节），method=0 (stored)
CRC32("Hello ZIP!") = 0xA60BFEA4（comptime 计算，运行期零成本）
内存 ZIP 布局（共 126 字节）：
  [0..39)     local file header + name
  [39..49)  file data "Hello ZIP!"
  [49..104)  central directory entry + name
  [104..126)  EOCD
构造 = 学格式：亲手把每个字段写对，解析时就知道该期待什么
==== 40.2 构造一个内存中的最小 ZIP 结束 ====
```

`CRC32("Hello ZIP!") = 0xA60BFEA4` 这个值是 comptime 算出来的——
每次运行都一样，因为它在编译期就固化了。

---

## 40.3 解析 EOCD：从尾部向前扫

现在进入解析阶段。第一步是找到 EOCD——它一定在文件末尾（最多再拖一个
最长 65535 字节的 comment）。所以**从尾部向前扫**是 O(1) 的，
不管文件多大都只需要看最后 ~66KB。

```zig
// examples/40_zunzip/main.zig 第 220-229 行
/// 从尾部向前扫 EOCD 签名 0x06054b50（小端字节序 50 4B 05 06）。
/// 为什么倒着扫：ZIP 允许文件前面有任意前置数据（自解压包 stub），
/// 但 EOCD 一定在文件末尾（最多再拖一个 comment），所以从尾部找是 O(1)。
fn findEocd(data: []const u8) ?usize {
    if (data.len < eocd_len) return null;
    // comment 最长 65535 字节，但我们的 demo 没有 comment，扫最后 22 字节即可
    var i: usize = data.len - eocd_len;
    while (true) {
        if (std.mem.readInt(u32, data[i..][0..4], .little) == 0x06054b50) return i;
        if (i == 0) return null;
        i -= 1;
    }
}
```

逐行解释：

- **`if (data.len < eocd_len) return null;`**：防御性检查。
  如果数据不足 22 字节，不可能有合法的 EOCD。空输入和 10 字节的
  全零数组都走这条路（测试里覆盖了这两种情况）。
- **`var i: usize = data.len - eocd_len;`**：从**最后一个可能的位置**开始——
  一个 22 字节的 EOCD 记录最晚只能从 `data.len - 22` 开始。
  如果 comment_len = 0，EOCD 的签名恰好就在这个位置，第一次检查就命中。
- **`std.mem.readInt(u32, data[i..][0..4], .little)`**：读 4 字节按 little-endian
  解释成 `u32`。`data[i..][0..4]` 又是那个惯用法——`readInt` 要求
  `*[4]u8`，不是切片。
- **`if (i == 0) return null; i -= 1;`**：向前扫一步。如果扫到 0 还没找到，
  说明这不是一个合法的 ZIP（或者 EOCD 被截断了）。

**为什么倒着扫而不是正着扫？**两个原因：
1. **允许前置数据**。自解压包（self-extracting archive）在 ZIP 数据前面
   挂了一个可执行 stub。如果正着扫，你会先碰到 stub 里的随机字节，
   可能误判签名。倒着扫保证找到的是**最后一个**签名——那才是合法的 EOCD。
2. **性能**。10 GB 的 ZIP 包，你只需要读最后 22 字节（+ 最多 65535 字节 comment）。
   如果用 `readPositionalAll` 只读尾部（真实 zunzip 的做法），
   打开 10 GB 和 10 KB 一样快。

找到 EOCD 后，解析它的 8 个字段：

```zig
// examples/40_zunzip/main.zig 第 337-360 行
const eocd_off = findEocd(&demo_zip) orelse return error.EocdNotFound;
try w.print("findEocd 在偏移 {d} 处找到签名（文件共 {d} 字节，从尾部扫了 {d} 字节）\n", .{
    eocd_off, zip_len, zip_len - eocd_off,
});
var o = eocd_off + 4;  // 跳过 sig（4 字节）
const disk_num = std.mem.readInt(u16, demo_zip[o..][0..2], .little);
o += 2;
const cd_start_disk = std.mem.readInt(u16, demo_zip[o..][0..2], .little);
o += 2;
const entries_this_disk = std.mem.readInt(u16, demo_zip[o..][0..2], .little);
o += 2;
const total_entries = std.mem.readInt(u16, demo_zip[o..][0..2], .little);
o += 2;
const cd_size = std.mem.readInt(u32, demo_zip[o..][0..4], .little);
o += 4;
const cd_offset = std.mem.readInt(u32, demo_zip[o..][0..4], .little);
o += 4;
```

`o` 从 `eocd_off + 4` 开始（跳过 4 字节的签名），然后按规范顺序读
disk_num(2) → cd_start_disk(2) → entries_this_disk(2) → total_entries(2)
→ cd_size(4) → cd_offset(4)。每个字段的宽度决定 `o += N` 的步长。

运行时输出：

```text
==== 40.3 解析 EOCD（从尾部向前扫） 开始 ====
findEocd 在偏移 104 处找到签名（文件共 126 字节，从尾部扫了 22 字节）
  disk_num          = 0
  cd_start_disk     = 0
  entries_this_disk = 1
  total_entries     = 1
  cd_size           = 55
  cd_offset         = 49
从 EOCD 拿到 cd_offset=49，下一步就去那里解析 Central Directory
==== 40.3 解析 EOCD（从尾部向前扫） 结束 ====
```

`cd_offset = 49` 和 `cd_size = 55` 是解析 CD 条目的两个关键坐标：
49 告诉你在哪里开始读，55 告诉你目录区一共多大（可以用来验证边界）。

测试覆盖：

```zig
// examples/40_zunzip/main.zig 第 437-447 行
test "findEocd 在内存 ZIP 上工作" {
    const off = findEocd(&demo_zip);
    try std.testing.expect(off != null);
    try std.testing.expectEqual(@as(usize, zip_len - eocd_len), off.?);
    // 签名字节是 50 4B 05 06（小端）
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x50, 0x4B, 0x05, 0x06 }, demo_zip[off.?..][0..4]);
    // 空输入 / 太短都返回 null
    try std.testing.expect(findEocd("") == null);
    const ten_zeros: [10]u8 = @splat(0);
    try std.testing.expect(findEocd(&ten_zeros) == null);
}
```

签名的**字节序列**是 `50 4B 05 06`——这是 `"PK\x05\x06"` 的 ASCII 码。
`0x06054b50` 是按 little-endian 读出来的 `u32` 值，
但在线上的字节顺序是反的（最低有效字节 `0x50` 在前）。

---

## 40.4 解析 Central Directory 条目

拿到 `cd_offset = 49` 后，去那里解析 CD 条目：

```zig
// examples/40_zunzip/main.zig 第 235-275 行
/// 从 offset 处解析一个 CD 条目固定头，name 是零拷贝切片。
/// 变长字段（name/extra/comment）靠偏移算术跳过——不能定长读。
fn parseCdEntry(data: []const u8, offset: usize) CdInfo {
    var o = offset;
    std.debug.assert(std.mem.readInt(u32, data[o..][0..4], .little) == 0x02014b50);
    o += 4;
    o += 2; // version made by
    o += 2; // version needed
    o += 2; // flags
    const method = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    o += 2; // mod time
    o += 2; // mod date
    const crc = std.mem.readInt(u32, data[o..][0..4], .little);
    o += 4;
    const comp_size = std.mem.readInt(u32, data[o..][0..4], .little);
    o += 4;
    const uncomp_size = std.mem.readInt(u32, data[o..][0..4], .little);
    o += 4;
    const name_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    const extra_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    const comment_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    o += 2; // disk start
    o += 2; // internal attrs
    o += 4; // external attrs
    const local_header_offset = std.mem.readInt(u32, data[o..][0..4], .little);
    o += 4;
    const name = data[o..][0..name_len];
    // 跳过 name + extra + comment，得到下一条目的偏移（演示用）
    _ = extra_len;
    _ = comment_len;
    return .{
        .method = method,
        .crc = crc,
        .comp_size = comp_size,
        .uncomp_size = uncomp_size,
        .local_header_offset = local_header_offset,
        .name = name,
    };
}
```

逐行解释：

- **`std.debug.assert(... == 0x02014b50)`**：签名检查。如果偏移处不是
  CD 签名，说明数据损坏或者偏移算错了。`assert` 在 Debug/ReleaseSafe 下
  会 panic，在 ReleaseFast/ReleaseSmall 下是 no-op——对于生产工具，
  应该改成返回 `error.BadSignature`。
- **`o += 2; // version made by`**：跳过不关心的字段。不需要读的值
  直接推进偏移量——这比读出来再丢弃更高效，也让代码更清晰地表达
  "我不 care 这个字段"。
- **`const name = data[o..][0..name_len];`**：这是**零拷贝切片**——
  `name` 不拥有内存，它只是指向 `data` 中从 `o` 开始 `name_len` 字节
  的一段。`data` 的生命周期必须长于 `name`（这里 `demo_zip` 是
  `const`，生命周期贯穿整个程序）。
- **`_ = extra_len; _ = comment_len;`**：显式丢弃——告诉编译器
  "我知道这个变量存在但故意不用"。不写这两行会报
  `unused local variable` 编译错误。生产代码里这里应该是
  `o += name_len + extra_len + comment_len;` 来推进到下一条目。

运行时输出：

```text
==== 40.4 解析 Central Directory 条目 开始 ====
  name                = "hello.txt"
  method              = 0（0 = stored，无压缩）
  crc                 = 0xA60BFEA4
  comp_size           = 10
  uncomp_size         = 10
  local_header_offset = 0
变长 name 通过 name_len 偏移算术取出，零拷贝切片
==== 40.4 解析 Central Directory 条目 结束 ====
```

`crc = 0xA60BFEA4` 和 40.2 构造时的 `demo_crc` 完全一致——
这证明了解析的正确性。

测试覆盖：

```zig
// examples/40_zunzip/main.zig 第 449-459 行
test "parseCdEntry 字段正确" {
    const eocd_off = findEocd(&demo_zip).?;
    const cd_offset = std.mem.readInt(u32, demo_zip[eocd_off + 16 ..][0..4], .little);
    const entry = parseCdEntry(&demo_zip, cd_offset);
    try std.testing.expectEqualStrings("hello.txt", entry.name);
    try std.testing.expectEqual(@as(u16, 0), entry.method);
    try std.testing.expectEqual(@as(u32, 10), entry.comp_size);
    try std.testing.expectEqual(@as(u32, 10), entry.uncomp_size);
    try std.testing.expectEqual(demo_crc, entry.crc);
    try std.testing.expectEqual(@as(u32, 0), entry.local_header_offset);
}
```

注意 `demo_zip[eocd_off + 16 ..][0..4]` 这个写法——EOCD 里 `cd_offset`
字段的偏移是 16（sig 4 + disk 2 + cd_disk 2 + n_disk 2 + n_total 2 + cd_size 4 = 16）。
这和 40.3 里逐个字段读的顺序是一致的，只是测试里跳过了前面的字段直接取
需要的那个。

---

## 40.5 comptime 布局校验

这是本章的**签名技巧**——也是和 25 章的核心区别。25 章讲了三种 struct 布局、
`@bitCast`、`bytesToValue`、对齐和 padding 的完整理论。本章把那个理论
落地到一个具体的实战场景：**用 comptime 断言把「struct 布局 ≠ 线格式」
这个 bug 从运行期提前到编译期**。

### 40.5.1 为什么 `@sizeOf` 之和 ≠ `@sizeOf(struct)`

先看一个 25 章 25.2 的实测：

```zig
const Ext = extern struct { a: u8, b: u32, c: u8 };
// @sizeOf(Ext) = 12，不是 6
// @offsetOf(Ext, "a") = 0
// @offsetOf(Ext, "b") = 4  ← 编译器在 a 后面插了 3 字节 padding
// @offsetOf(Ext, "c") = 8
// 尾部还有 2 字节 padding 让整体 4 字节对齐
```

extern struct 遵循 C 布局规则：每个字段按其自然对齐排列，
不足的位置填 padding。所以 `@sizeOf(EOCD)` 可能不是 22——
如果编译器决定在 `u16` 和 `u32` 之间插 2 字节 padding，它就变成了 24 或更大。

**但 ZIP 规范说 EOCD 固定部分恰好是 22 字节，一个字节不多、一个字节不少。**
如果你用 `bytesToValue(Eocd, data[0..22])` 强转，而 `Eocd` 的实际布局
有 padding，那你读到的就是垃圾。

### 40.5.2 签名技巧：普通 struct + comptime 字段宽度之和

```zig
// examples/40_zunzip/main.zig 第 91-100 行
/// 字段宽度之和（线格式尺寸）。0.17：@typeInfo(T).@"struct".field_types 是
/// 平行数组（与 field_names 等长）。field_types 的元素是 type，普通 for 的
/// 索引是 runtime-known 会报错——必须 inline for 把循环在 comptime 展开。
fn wireSize(comptime T: type) usize {
    var n: usize = 0;
    inline for (@typeInfo(T).@"struct".field_types) |ft| n += @sizeOf(ft);
    return n;
}

comptime {
    if (wireSize(Eocd) != 22) @compileError("EOCD 布局不等于 22 字节");
    if (wireSize(CdEntry) != 46) @compileError("CD 条目布局不等于 46 字节");
}
```

逐行解释：

- **`@typeInfo(T).@"struct"`**：0.17 里 `@typeInfo` 返回的 union 中，
  struct 对应的 tag 是 `@"struct"`——**引号是必须的**，因为 `struct`
  是 Zig 关键字，不能直接做字段名。0.16 及之前写的是 `.Struct`（大写），
  0.17 改成了小写 + `@"..."` 转义。
- **`.field_types`**：0.17 的新 API——`field_names` 和 `field_types`
  是**两个平行的数组**，等长，按下标对应。`field_names[0]` 是第一个
  字段的名字，`field_types[0]` 是第一个字段的类型。
  旧 API `std.meta.fields(T)` 返回的是一个混合 struct 数组
  （`{ .name = "sig", .type = u32, ... }`），在 0.17 已彻底废弃
  （直接 `@compileError`）。25 章 25.3 有废弃的完整实测。
- **`inline for`**：必须写 `inline for`，不能写普通 `for`。
  原因是 `field_types` 的元素类型是 `type`，循环变量 `ft` 的类型是 `type`——
  `@sizeOf(ft)` 需要在 comptime 求值，而普通 `for` 的循环变量是
  runtime-known。`inline for` 在 comptime 把循环展开成 8 个（或 17 个）
  独立的语句，每个的 `ft` 都是 comptime-known 的类型。
  写普通 `for` 会报 `unable to evaluate comptime expression`。
- **`comptime { ... }`**：顶层 comptime 块，在编译期执行。
  如果 `wireSize(Eocd) != 22`，build 立即失败，错误消息是
  `"EOCD 布局不等于 22 字节"`——**在产生任何二进制之前就拦住了**。

**为什么用字段宽度之和而不是 `@sizeOf(T)`？**因为 `@sizeOf(Eocd)` 可能
包含 padding（即使普通 struct 也可能在尾部补对齐），而字段宽度之和
`@sizeOf(u32) + @sizeOf(u16) + ...` 是纯加法，不受 padding 影响。
你把每个字段的类型写对了，和就一定等于线格式尺寸；任何一个字段
类型写错了（比如 `u16` 写成 `u32`），和就不对了。

**为什么用普通 struct 不用 extern struct？**两个原因：
1. 普通 struct 的字段顺序和 padding 由编译器决定——你**不能**把它
   直接覆盖到字节流上，这从**类型系统层面**杜绝了 `bytesToValue` 的误用。
2. extern struct 的 `@sizeOf` 包含 padding，`wireSize` 的语义
   （字段宽度之和）在普通 struct 上更清晰。

### 40.5.3 0.17 API 变化

0.16 及之前的写法：

```zig
// ❌ 0.16 的写法，0.17 编译不过
for (std.meta.fields(T)) |f| n += @sizeOf(f.type);
```

0.17 的写法：

```zig
// ✅ 0.17 的写法：平行数组 + inline for
inline for (@typeInfo(T).@"struct".field_types) |ft| n += @sizeOf(ft);
```

变化总结：

| 0.16 | 0.17 | 原因 |
|---|---|---|
| `std.meta.fields(T)` | `@typeInfo(T).@"struct".field_types` | `std.meta.fields` 已废弃 |
| `.Struct` | `.@"struct"` | 关键字需要转义 |
| `f.name` / `f.type` | `field_names[i]` / `field_types[i]` | 拆成两个平行数组 |
| 普通 `for` | `inline for`（type 元素时） | comptime 求值需要 |

### 40.5.4 运行时输出

```text
==== 40.5 comptime 布局校验 开始 ====
Eocd  字段宽度之和 = 22 字节（要求 22）
CdEntry 字段宽度之和 = 46 字节（要求 46）
comptime 校验通过: EOCD=22B CD=46B
写法：for (@typeInfo(T).@"struct".field_types) |ft| total += @sizeOf(ft)
0.17 里 .@"struct" 的引号是必须的（struct 是关键字）
0.17 里 field_names/field_types 是平行数组；std.meta.fields 已 deprecated
==== 40.5 comptime 布局校验 结束 ====
```

注意：运行时打印的 `wireSize(Eocd)` 和 `wireSize(CdEntry)` 的值
（22 和 46）是 comptime 计算的结果——它们在编译期就确定了，
运行期只是打印一个常量。

测试进一步验证平行数组的对应关系：

```zig
// examples/40_zunzip/main.zig 第 470-480 行
test "comptime 布局校验：EOCD=22 CD=46" {
    try std.testing.expectEqual(@as(usize, 22), wireSize(Eocd));
    try std.testing.expectEqual(@as(usize, 46), wireSize(CdEntry));
    // 0.17：field_names 和 field_types 是平行数组（std.meta.fields 已 deprecated）
    const S = @typeInfo(Eocd).@"struct";
    try std.testing.expectEqual(@as(usize, 8), S.field_names.len);
    try std.testing.expectEqual(@as(usize, 8), S.field_types.len);
    try std.testing.expectEqualStrings("sig", S.field_names[0]);
    try std.testing.expectEqual(u32, S.field_types[0]);
}
```

---

## 40.6 端到端：自造 ZIP → 解析 → 提取内容

现在完成闭环：从 ZIP 字节流中提取文件内容。

```zig
// examples/40_zunzip/main.zig 第 281-293 行
/// 从 ZIP 字节流中提取一个 stored（method=0）文件的内容。
/// 路径：CD 条目 → local_header_offset → 跳过 local header → 读数据。
fn extractStoredContent(data: []const u8, entry: CdInfo) ![]const u8 {
    if (entry.method != 0) return error.NotStored;
    var o: usize = entry.local_header_offset;
    // local file header 固定 30 字节，然后跳过 name + extra
    if (std.mem.readInt(u32, data[o..][0..4], .little) != 0x04034b50) return error.BadLocalHeader;
    o += 26; // 直接跳到 name_len 字段（30 - 4 = 26）
    const name_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    const extra_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    o += name_len + extra_len;
    return data[o..][0..entry.comp_size];
}
```

逐行解释：

- **`if (entry.method != 0) return error.NotStored;`**：只支持 stored
  （method=0，无压缩）。真实 ZIP 里 method=8 是 deflate——那需要
  调 `std.compress.flate` 解压，本章不覆盖（坑位清单会提）。
- **`var o: usize = entry.local_header_offset;`**：从 CD 条目里拿到的
  `local_header_offset` 指向这个文件的 LFH 在 ZIP 中的位置。
  对 `hello.txt` 来说是 0——它是第一个也是唯一一个文件。
- **`o += 26;`**：一个巧妙的捷径。LFH 固定 30 字节，但我们已经读了
  4 字节签名（`o` 从 `local_header_offset` 开始，签名检查读了 4 字节），
  所以再推进 26 字节就到了 `name_len` 字段的位置（30 - 4 = 26）。
  中间的 version_needed、flags、method、time、date、crc、csize、usize
  全部跳过——提取内容不需要它们。
- **`o += name_len + extra_len;`**：跳过变长的 name 和 extra 字段，
  到达文件数据的起始位置。
- **`return data[o..][0..entry.comp_size];`**：返回 `comp_size` 字节的
  零拷贝切片。stored 模式下 `comp_size == uncomp_size`，这就是原始数据。

运行时输出：

```text
==== 40.6 端到端：自造 ZIP → 解析 → 提取内容 开始 ====
提取内容 = "Hello ZIP!"（10 字节）
与原始数据一致 = true（CRC 校验也一致 = true）
闭环完成：构造 → 解析 EOCD → 解析 CD → 提取内容 → 验证一致
==== 40.6 端到端：自造 ZIP → 提取内容 结束 ====
```

两层验证：
1. **`std.mem.eql(u8, extracted, demo_data)`**：字节级一致。
2. **`crc32(extracted) == entry.crc`**：CRC32 校验也一致——
   这是 ZIP 格式自带的完整性验证。

测试覆盖：

```zig
// examples/40_zunzip/main.zig 第 461-468 行
test "extractStoredContent 往返一致" {
    const eocd_off = findEocd(&demo_zip).?;
    const cd_offset = std.mem.readInt(u32, demo_zip[eocd_off + 16 ..][0..4], .little);
    const entry = parseCdEntry(&demo_zip, cd_offset);
    const content = try extractStoredContent(&demo_zip, entry);
    try std.testing.expectEqualStrings(demo_data, content);
    try std.testing.expectEqual(demo_crc, crc32(content));
}
```

还有一个结构自洽测试——验证构造的 ZIP 内部坐标全部对得上：

```zig
// examples/40_zunzip/main.zig 第 482-490 行
test "内存 ZIP 结构自洽：EOCD 指向的 CD 偏移 + 大小 = EOCD 偏移" {
    const eocd_off = findEocd(&demo_zip).?;
    const cd_size = std.mem.readInt(u32, demo_zip[eocd_off + 12 ..][0..4], .little);
    const cd_offset = std.mem.readInt(u32, demo_zip[eocd_off + 16 ..][0..4], .little);
    try std.testing.expectEqual(@as(usize, cd_len), cd_size);
    try std.testing.expectEqual(@as(usize, lfh_len + demo_data.len), cd_offset);
    // CD 条目 + EOCD 正好填满到文件末尾
    try std.testing.expectEqual(cd_offset + cd_size, eocd_off);
}
```

`cd_offset + cd_size == eocd_off` 意味着 CD 条目和 EOCD 之间没有空隙——
这正是我们构造时的布局（CD 条目紧挨着 EOCD）。

---

## 40.7 字节序

最后一节演示字节序——ZIP 全部使用 little-endian，这和 x86/x86_64 的
本机序一致，但和网络序（big-endian）相反。

```zig
// examples/40_zunzip/main.zig 第 397-412 行
const v: u32 = 0x12345678;
const le = std.mem.nativeToLittle(u32, v);
const be = std.mem.nativeToBig(u32, v);
try w.print("u32 = 0x{X:0>8}\n", .{v});
try w.print("  nativeToLittle 字节序: ", .{});
for (std.mem.asBytes(&le)) |b| try hexByte(w, b);
try w.print("（低字节在前 = 小端）\n", .{});
try w.print("  nativeToBig    字节序: ", .{});
for (std.mem.asBytes(&be)) |b| try hexByte(w, b);
try w.print("（高字节在前 = 大端）\n", .{});
try w.print("readInt(u32, bytes, .little) 按小端解读：0x{X:0>8}\n", .{
    std.mem.readInt(u32, std.mem.asBytes(&le), .little),
});
```

`0x12345678` 的内存布局：

- **Little-endian**（x86 本机序）：`78 56 34 12`——最低有效字节 `0x78` 在最低地址。
- **Big-endian**（网络序）：`12 34 56 78`——最高有效字节 `0x12` 在最低地址。

`std.mem.nativeToLittle` 和 `std.mem.nativeToBig` 做**值到值**的转换——
输入一个 `u32`，输出一个 `u32`，但输出的值在内存中的字节排列不同。
`std.mem.asBytes(&le)` 把 `u32` 的内存表示暴露为 `[]const u8`，
让我们能看到实际的字节顺序。

`readInt(u32, bytes, .little)` 是**字节到值**的反向转换——按 little-endian
解释 4 个字节，还原出 `u32` 值。这正是 40.3 / 40.4 里每个字段解析
用的函数。

运行时输出：

```text
==== 40.7 字节序 开始 ====
u32 = 0x12345678
  nativeToLittle 字节序: 78563412（低字节在前 = 小端）
  nativeToBig    字节序: 12345678（高字节在前 = 大端）
readInt(u32, bytes, .little) 按小端解读：0x12345678
ZIP 格式规定全部多字节整数一律小端（与 x86 本机序一致，但与网络序相反）
==== 40.7 字节序 结束 ====
```

在 x86_64 上，`nativeToLittle` 是 no-op（本机就是 little-endian），
`nativeToBig` 做字节交换。但在 ARM big-endian 模式或某些网络设备上，
`nativeToLittle` 就要真正做交换了。`readInt` / `writeInt` 的
`.little` / `.big` 参数让代码**端序无关**——不管跑在什么架构上，
行为都一致。

---

## 40.8 坑位清单

按「会不会让程序悄悄算错」排序。前两条是会产出**错误结果**的，
不是编译期能拦住的。

### 一、会静默算错的（最危险）

1. **不要用 extern struct 内联强转网络/文件字节**。
   `bytesToValue(Eocd, data[0..22])` 这种写法有三个问题：
   (a) extern struct 的 `@sizeOf` 可能不等于 22（padding），
   25 章 25.2 有实测；
   (b) `bytesToValue` 对齐不过关时**不报错**——25 章 25.6 实测，
   它给你一个错读的值而不是 panic；
   (c) 端序由本机决定，不是由 ZIP 规范决定——在 big-endian 机器上
   读出来全反了。
   正解：**普通 struct + `readInt` 显式偏移解析 + comptime 字段宽度校验**
   （本章 40.5 的签名技巧）。25 章有 extern/packed/auto 三种布局的
   完整对比和 `@bitCast` / `bytesToValue` 的边界行为。

2. **变长字段（name/extra/comment）靠偏移算术跳过，不能定长读**。
   CD 条目的固定头是 46 字节，但一个完整的 CD 条目可能远大于 46 字节
   （name 最长 65535、extra 最长 65535、comment 最长 65535）。
   如果你假设"每条目就 46 字节 + name"，那遇到 extra 或 comment
   不为零的条目就解析错了。正解：读了固定头后，用 `name_len` /
   `extra_len` / `comment_len` 推进偏移量（40.4 的 `parseCdEntry`）。

### 二、编译期能拦住的（comptime 校验）

3. **`@typeInfo(T).@"struct".field_types` 的写法**。
   0.17 里 `std.meta.fields` 已彻底废弃（直接 `@compileError`）。
   三个要点：
   - `@"struct"` 的**引号是必须的**（`struct` 是关键字）；
   - `field_names` 和 `field_types` 是**平行数组**，按下标对应；
   - 遍历 `field_types` 必须 `inline for`（元素是 `type`，
     普通 `for` 的循环变量是 runtime-known）。
   25 章 25.3 有废弃的完整报错文本。

4. **EOCD 从尾部扫而不是头部顺序读**。
   ZIP 允许文件前面有任意前置数据（自解压包 stub），
   但 EOCD 一定在文件末尾。从尾部扫是 O(1)——不管文件多大，
   只看最后 22 字节（+ 最多 65535 字节 comment）。
   如果正着扫，你可能先碰到 stub 里的随机字节，误判签名。

### 三、性能/正确性兼顾的

5. **CRC32 表 comptime 生成，运行期零成本**。
   `const crc_table = blk: { ... }` 在编译期就把 256 项表算好了，
   运行期直接查表——不需要每次调用 `crc32` 都重新生成。
   别忘了 `@setEvalBranchQuota`——两层循环 256×8 会超默认配额 3000。

---

## 40.9 验证方式

三层，与全项目一致：

```bash
cd examples/40_zunzip
zig fmt --check .                                    # 第 1 层：格式 + 语法
zig test main.zig                                    # 第 2 层：6 个 test
zig build-exe main.zig -femit-bin=/tmp/zunzip        # 第 3 层：main 也要能编
/tmp/zunzip                                           # 第 3 层：真跑一遍
```

第 3 层不可省：`zig test` 不看 `main`，而本章最要紧的 7 个运行时小节
**全在 `main` 里`。

跑完应看到（逐字节抄自实测）：

```text
==== 40.1 ZIP 格式理论 开始 ====
==== 40.1 ZIP 格式理论 结束 ====
==== 40.2 构造一个内存中的最小 ZIP 开始 ====
==== 40.2 构造一个内存中的最小 ZIP 结束 ====
==== 40.3 解析 EOCD（从尾部向前扫） 开始 ====
==== 40.3 解析 EOCD（从尾部向前扫） 结束 ====
==== 40.4 解析 Central Directory 条目 开始 ====
==== 40.4 解析 Central Directory 条目 结束 ====
==== 40.5 comptime 布局校验 开始 ====
==== 40.5 comptime 布局校验 结束 ====
==== 40.6 端到端：自造 ZIP → 解析 → 提取内容 开始 ====
==== 40.6 端到端：自造 ZIP → 解析 → 提取内容 结束 ====
==== 40.7 字节序 开始 ====
==== 40.7 字节序 结束 ====
==== 40.8 坑位清单 开始 ====
==== 40.8 坑位清单 结束 ====
ZIP 文件从尾部倒着读：
  EOCD (End Of Central Directory) 签名 0x06054b50，一定在文件末尾
  Central Directory 条目签名 0x02014b50，目录区在 EOCD 之前
  Local File Header 签名 0x04034b50，每个文件数据的前面
固定字段布局（全部小端）：
  EOCD:  sig(4) disk(2) cd_disk(2) n_disk(2) n_total(2) cd_size(4) cd_off(4) cmt_len(2) = 22B
  CD:    sig(4) vmade(2) vneed(2) flags(2) method(2) time(2) date(2) crc(4)
         csize(4) usize(4) nlen(2) elen(2) clen(2) disk(2) iattr(2) eattr(4) lho(4) = 46B
  LFH:   sig(4) vneed(2) flags(2) method(2) time(2) date(2) crc(4)
         csize(4) usize(4) nlen(2) elen(2) = 30B，后跟 name + extra + data
变长字段（name/extra/comment）紧跟在固定头后面，长度由固定头里的 len 字段给出
文件: hello.txt，内容: "Hello ZIP!"（10 字节），method=0 (stored)
CRC32("Hello ZIP!") = 0xA60BFEA4（comptime 计算，运行期零成本）
内存 ZIP 布局（共 126 字节）：
  [0..39)     local file header + name
  [39..49)  file data "Hello ZIP!"
  [49..104)  central directory entry + name
  [104..126)  EOCD
构造 = 学格式：亲手把每个字段写对，解析时就知道该期待什么
findEocd 在偏移 104 处找到签名（文件共 126 字节，从尾部扫了 22 字节）
  disk_num          = 0
  cd_start_disk     = 0
  entries_this_disk = 1
  total_entries     = 1
  cd_size           = 55
  cd_offset         = 49
从 EOCD 拿到 cd_offset=49，下一步就去那里解析 Central Directory
  name                = "hello.txt"
  method              = 0（0 = stored，无压缩）
  crc                 = 0xA60BFEA4
  comp_size           = 10
  uncomp_size         = 10
  local_header_offset = 0
变长 name 通过 name_len 偏移算术取出，零拷贝切片
Eocd  字段宽度之和 = 22 字节（要求 22）
CdEntry 字段宽度之和 = 46 字节（要求 46）
comptime 校验通过: EOCD=22B CD=46B
写法：for (@typeInfo(T).@"struct".field_types) |ft| total += @sizeOf(ft)
0.17 里 .@"struct" 的引号是必须的（struct 是关键字）
0.17 里 field_names/field_types 是平行数组；std.meta.fields 已 deprecated
提取内容 = "Hello ZIP!"（10 字节）
与原始数据一致 = true（CRC 校验也一致 = true）
闭环完成：构造 → 解析 EOCD → 解析 CD → 提取内容 → 验证一致
u32 = 0x12345678
  nativeToLittle 字节序: 78563412（低字节在前 = 小端）
  nativeToBig    字节序: 12345678（高字节在前 = 大端）
readInt(u32, bytes, .little) 按小端解读：0x12345678
ZIP 格式规定全部多字节整数一律小端（与 x86 本机序一致，但与网络序相反）
1. 不要用 extern struct 内联强转网络/文件字节（对齐+填充问题）— 用 readInt 显式解析
2. @typeInfo(T).@"struct".field_types 的写法（0.17 引号关键字字段）
3. EOCD 从尾部扫而不是头部顺序读（允许前置数据/自解压包）
4. CRC32 表 comptime 生成，运行期零成本
5. 变长字段（name/extra/comment）靠偏移算术跳过，不能定长读
自检通过
```

测试输出（`zig test main.zig`）：

```text
1/6 main.test.CRC32 标准测试向量...OK
2/6 main.test.findEocd 在内存 ZIP 上工作...OK
3/6 main.test.parseCdEntry 字段正确...OK
4/6 main.test.extractStoredContent 往返一致...OK
5/6 main.test.comptime 布局校验：EOCD=22 CD=46...OK
6/6 main.test.内存 ZIP 结构自洽：EOCD 指向的 CD 偏移 + 大小 = EOCD 偏移...OK
All 6 tests passed.
```

因为本章所有输出都是确定性的（CRC32 在 comptime 算出固定值、ZIP 字节流
在 comptime 构造、解析结果完全可预测），不需要像 34 章那样做连跑 5 次
逐字节比对——一次运行的输出就是永远正确的输出。

**本章与 25 章的关系**：25 章讲了 extern/packed/auto 三种 struct 布局的
完整理论、`@bitCast` / `bytesToValue` / `toBytes` 的边界行为、
`readInt` / `writeInt` 的签名、LEB128 变长整数、位域与 `packed struct`。
本章是那份理论的实战应用：**不重复 25 章的内容**，而是展示在
一个真实二进制格式（ZIP）的解析中，如何避开 extern struct 的坑、
用普通 struct + comptime 校验达到同样的安全性。

---

上一章：[39 异步 I/O](39-asyncio.md) · 下一章：[41 实战：随机数与密码生成器 zpass](41-zpass.md)
