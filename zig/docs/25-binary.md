# 25 · 二进制数据与内存布局

> 对应示例：`examples/25_binary/main.zig`（970 行）
>
> 文本格式看 20 章的 JSON；真实世界的另一半是二进制：文件头、网络协议帧、硬件寄存器。
> 取材Tsoukalos《Systems Programming with Zig》ch3——extern struct、packed struct、字节序三板斧，
> 加《Learning Zig》ch8/12 的位域与 C ABI。
>
> 本章有六条结论会**推翻你可能听过的说法**：
>
> 1. **`@bitCast` 在 0.17 拒绝裸结构体**。`const w: u16 = @bitCast(ext_struct_value)` 直接编译失败：
>    `error: cannot @bitCast from 'main.Record'`。**唯一例外是 `packed struct`**。
>    extern struct 连普通 struct 都不如——它是唯一"布局合法"的那种，却偏偏不能 `@bitCast`。
> 2. **`packed struct` 的字段取地址在 0.17 是允许的**（这是相对旧版的重大行为变化，见25.10）。
>    但返回的指针类型带 bit offset（`*align(2:1:2) u2`），传给普通 `*u2` 参数会编译失败。
> 3. **`std.mem.valueToBytes` 在 0.17 已不存在**。等价物是 `std.mem.toBytes`。
>    同样消失的还有 `std.fmt.fmtSliceHexLower`（换成 `std.fmt.bytesToHex`）。
> 4. **旋转不是内建函数**。`@rotl` / `@rotr` / `@rotateLeft` 三个名字在 0.17 全是
>    `error: invalid builtin function`，正解是 `std.math.rotl(T, v, n)`。
> 5. **`std.meta.fields` 已彻底废弃**（直接 `@compileError`）。0.16 教程里的
>    `for (std.meta.fields(T)) |f| @sizeOf(f.type)` 在 0.17 编译不过，
>    必须换成 `@typeInfo(T).@"struct".field_types`——而且**只能 `inline for`** 遍历（见 25.3）。
>
> 6. **旋转不是内建函数**这条还有一个孪生兄弟：**`std.fmt.fmtSliceHexLower` 也没了**，
>    换成了 `std.fmt.bytesToHex`，而它的签名只有 2 个参数（没有分隔符参数）——见 25.12。
>
> 另外两条本教程独有的发现：
>
> - **`bytesToValue` 对齐不过关时不报错**。它给你一个错读的值，而不是 panic。
>   这是"silently wrong"比"crash"危险得多的典型案例（见 25.6）。
> - **`@bitSizeOf` 对 `extern struct` 是编译错误**，对 `packed struct` 和整数才有效。
>   "这个类型占多少个**位**"这个问题，对有填充的布局没有唯一答案（见 25.2）。
>
> 本章所有输出都在 **0.17.0 + x86_64-macos** 上实测。示例刻意**一处地址都不打印**
>（所有会泄漏地址的位置都改成打印 `@typeName`），所以下面每一个 `text` 围栏都是逐字抄的，
> 没有"把地址替换成文字描述"这种手工处理。这不是洁癖：地址每次运行都不一样，
> 抄进文档就是教读者去和地址字符串做对比。
>
> **关于代码围栏**：带 `// examples/25_binary/main.zig 第 N-M 行` 的是从示例文件逐字复制的
> （本教程用一个脚本逐块比对首尾行校验过，20 个块全部逐字一致）。**不带标注的块**分两类：
> 反例（❌ 开头，编译不过的写法）和标准库签名（从 `lib/std/` 抄的）。
> 另外有 12 个 `text` 块是**编译错误原文**——它们来自本章为探测这些行为临时写的
> 一次性探针文件（`p15.zig` / `p46.zig` / `p54.zig` / `pr1.zig` / `pr2.zig` / `pr3.zig` /
> `pt.zig` / `pu3.zig` / `pu4.zig`），报错里的文件名和行号就是那些探针的，
> 不是示例文件的——示例文件能编过，不会有这些错误。另有 3 个块（25.6 的
> `unaligned ok?`、25.10 的 `bitCast=0xAB123456`、以及 25.5 的 `cannot @bitCast`）
> 也是探针输出，正文里都注明了探针文件名。

---

## 25.1 为什么协议解析必须懂内存布局

线上的东西只有字节。没有 `int`、没有 `struct`、没有"端序"这个概念——只有一串按偏移排列的 8 位数。你说的"读一个 u32"，实际是三件事的复合：**4 个字节** + **一个端序约定** + **一个对齐约定**。这三个约定猜错任何一个，都不会崩溃，只会**静默地读出垃圾值**。崩溃的 bug 你会立刻发现，静默的 bug 会写进数据库、发到对端、算进账单。

Zig 给你的三种 struct 布局，对应三种不同的"字节排列承诺"。先看同一组字段（`a: u8, b: u32, c: u8`）在三种布局下的实测 `@sizeOf` / `@offsetOf`：

```zig
// examples/25_binary/main.zig 第 16-25 行
// ═══ 25.2 三种布局的样本类型：字段完全相同，只有 layout 关键字不同 ═══

/// auto（普通 struct）：字段顺序由编译器定，实测 u32被挪到最前
const Auto = struct { a: u8, b: u32, c: u8 };

/// extern（C 布局）：声明顺序 + 自然对齐 + 尾部补齐
const Ext = extern struct { a: u8, b: u32, c: u8 };

/// packed（位级紧密）：按声明顺序一位一位排，零填充
const Packed = packed struct(u32) { a: u8, b: u8, c: u8, d: u8 };
```

```zig
// examples/25_binary/main.zig 第 203-221 行
// ═══ 25.1 为什么协议解析必须懂内存布局 ═══
begin("25.1 为什么协议解析必须懂内存布局");
err.print("线上的东西只有字节：没有 int、没有 struct、没有 endianness\n", .{});
err.print("「读一个 u32」= 4 个字节 + 一个端序约定 + 一个对齐约定\n", .{});
err.print("三个约定猜错任何一个→ 静默读出垃圾值（不是崩溃，是数据错）\n", .{});
err.print("本章三种布局的实测@sizeOf（同一组字段 a:u8 b:u32 c:u8）：\n", .{});
err.print("  auto   size={d:>2} align={d} a@{d} b@{d} c@{d}\n", .{
    @sizeOf(Auto), @alignOf(Auto), @offsetOf(Auto, "a"), @offsetOf(Auto, "b"), @offsetOf(Auto, "c"),
});
err.print("  extern size={d:>2} align={d} a@{d} b@{d} c@{d}\n", .{
    @sizeOf(Ext), @alignOf(Ext), @offsetOf(Ext, "a"), @offsetOf(Ext, "b"), @offsetOf(Ext, "c"),
});
err.print("  packed size={d:>2} align={d} a@{d} b@{d} c@{d} d@{d}（字段是a b c d 四个 u8）\n", .{
    @sizeOf(Packed),        @alignOf(Packed),
    @offsetOf(Packed, "a"), @offsetOf(Packed, "b"),
    @offsetOf(Packed, "c"), @offsetOf(Packed, "d"),
});
err.print("⚠️ auto 的 b@0（声明在中间却排到最前）——这就是「不能上线路」的铁证\n", .{});
end("25.1 为什么协议解析必须懂内存布局");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.1 为什么协议解析必须懂内存布局 开始 ====
线上的东西只有字节：没有 int、没有 struct、没有 endianness
「读一个 u32」= 4 个字节 + 一个端序约定 + 一个对齐约定
三个约定猜错任何一个→ 静默读出垃圾值（不是崩溃，是数据错）
本章三种布局的实测@sizeOf（同一组字段 a:u8 b:u32 c:u8）：
  auto   size= 8 align=4 a@4 b@0 c@5
  extern size=12 align=4 a@0 b@4 c@8
  packed size= 4 align=4 a@0 b@1 c@2 d@3（字段是a b c d 四个 u8）
⚠️ auto 的 b@0（声明在中间却排到最前）——这就是「不能上线路」的铁证
==== 25.1 为什么协议解析必须懂内存布局 结束 ====
```

**三种布局的实测数据表**（这是本章最该记住的一张表）：

| 布局 | 类型定义 | `@sizeOf` | `@alignOf` | `@offsetOf` | 字段宽度之和 | 差值来源 |
|---|---|---|---|---|---|---|
| `auto` | `struct { a: u8, b: u32, c: u8 }` | **8** | 4 | `a@4 b@0 c@5` | 6 | **重排**（b 挪到最前）+ 尾部对齐 |
| `extern` | `extern struct { a: u8, b: u32, c: u8 }` | **12** | 4 | `a@0 b@4 c@8` | 6 | 3 字节内部填充（a 后）+ 3 字节尾部填充 |
| `packed` | `packed struct(u32) { a: u8, b: u8, c: u8, d: u8 }` | **4** | 4 | `a@0 b@1 c@2 d@3` | 4 | 无（位级紧密） |

注意 `packed` 那一行**字段不同**（是 `a b c d` 四个 `u8`，不是三个）——因为 `packed struct` 的字段必须是能铺满背板的位宽，`u32` 字段没法在 `u32` 背板里排下（25.10 会实测这个限制）。

`auto` 那一行是全章最刺眼的地方：声明顺序是 `a, b, c`，实测偏移是 `4, 0, 5`。**声明在中间的 `b` 被挪到了第 0 字节。** 编译器这么干完全合法——普通 struct 的内存布局是编译器的自由，它按对齐最优重排字段。所以 `auto struct` **永远不能上线路**：换编译器版本、换优化级别、换目标架构，偏移都可能变，而你的对端不会跟着变。

---

## 25.2 三种布局的 `@typeInfo` 形状与 `@bitSizeOf`

三种布局在 `@typeInfo` 里的差别就一个字段：`.layout`。它的类型是 **`std.lang.Type.ContainerLayout`**（注意不是 `std.builtin.Type.Layout`——0.17 里 `std.builtin.Type` 是个 union，没有 `Layout` 成员，写全名会报 `union 'lang.Type' has no member named 'Layout'`）。取值只有三个：`.auto` / `.@"extern"` / `.@"packed"`。

`packed struct` 还多一个 `backing_integer` 字段（背板整数类型），`auto` / `extern` 的是 `null`。

```zig
// examples/25_binary/main.zig 第 223-242 行
// ═══ 25.2 三种布局的 @typeInfo 形状与 @bitSizeOf ═══
begin("25.2 三种布局的 @typeInfo 形状");
inline for (.{ Auto, Ext, Packed, Flags }) |T| {
    const S = @typeInfo(T).@"struct";
    err.print("{s:<7} layout={s:<7} size={d:>2} align={d} backing_integer={any}\n", .{
        @typeName(T), @tagName(S.layout), @sizeOf(T), @alignOf(T), S.backing_integer,
    });
}
err.print("@bitSizeOf 只对 packed 和整数类型有意义：\n", .{});
err.print("  Pk(u32背板)={d}  Flags(u16 背板)={d}  u24={d}\n", .{
    @bitSizeOf(Packed), @bitSizeOf(Flags), @bitSizeOf(u24),
});
err.print("⚠️ @bitSizeOf(Ext) 编译失败：no bit size available for type（extern 有填充，位数无定义）\n", .{});
err.print("@offsetOf 给字节偏移，@bitOffsetOf 给位偏移——packed 里两者不同：\n", .{});
const F2 = packed struct(u16) { a: u1, b: u3, c: u4, d: u8 };
err.print("  a: offsetOf={d} bitOffsetOf={d}\n", .{ @offsetOf(F2, "a"), @bitOffsetOf(F2, "a") });
err.print("  b: offsetOf={d} bitOffsetOf={d}\n", .{ @offsetOf(F2, "b"), @bitOffsetOf(F2, "b") });
err.print("  d: offsetOf={d} bitOffsetOf={d}\n", .{ @offsetOf(F2, "d"), @bitOffsetOf(F2, "d") });
err.print("  → a/b/c 三个非字节对齐字段的 offsetOf 全是 0（挤在第0 个字节里）\n", .{});
end("25.2 三种布局的 @typeInfo 形状");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.2 三种布局的 @typeInfo 形状 开始 ====
main.Auto layout=auto    size= 8 align=4 backing_integer=null
main.Ext layout=extern  size=12 align=4 backing_integer=null
main.Packed layout=packed  size= 4 align=4 backing_integer=u32
main.Flags layout=packed  size= 2 align=2 backing_integer=u16
@bitSizeOf 只对 packed 和整数类型有意义：
  Pk(u32背板)=32  Flags(u16 背板)=16  u24=24
⚠️ @bitSizeOf(Ext) 编译失败：no bit size available for type（extern 有填充，位数无定义）
@offsetOf 给字节偏移，@bitOffsetOf 给位偏移——packed 里两者不同：
  a: offsetOf=0 bitOffsetOf=0
  b: offsetOf=0 bitOffsetOf=1
  d: offsetOf=1 bitOffsetOf=8
  → a/b/c 三个非字节对齐字段的 offsetOf 全是 0（挤在第0 个字节里）
==== 25.2 三种布局的 @typeInfo 形状 结束 ====
```

`inline for (.{ Auto, Ext, Packed, Flags })` 这个写法值得单独说一句：**元组里的类型必须是类型本身**（不是 `@TypeOf(x)`），而且要用 `inline for`——`for` 在运行时展开元组时拿不到类型值。

`@bitSizeOf` 只对 `packed struct` 和整数类型有意义。对 `extern struct` 用它是编译错误：

```text
p54.zig:5:43: error: no bit size available for type 'p54.Ext'
    std.debug.print("{d}\n", .{@bitSizeOf(Ext)});
                                          ^~~
p54.zig:2:20: note: struct declared here
const Ext = extern struct { a: u8, b: u32 };
            ~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~^^^
```

道理很直白：`extern struct` 有对齐填充，"这个类型占多少个**位**"这个问题没有唯一答案。`packed` 没有填充，所以答案就是背板的位宽。

最后那三行是本章最容易被忽略但最有用的一组对比：**`@offsetOf` 给字节偏移，`@bitOffsetOf` 给位偏移，两者在 `packed struct` 里完全不同。** 字段 `a`（u1）、`b`（u3）、`c`（u4）全部挤在第 0 个字节里，所以它们的 `@offsetOf` **都是 0**；只有 `@bitOffsetOf` 才告诉你 `a` 在 bit 0、`b` 在 bit 1。写位域操作时你要的是后者。

---

## 25.3 `auto struct` 的字段会被重排：用 `@offsetOf` 钉死

这一节专门把 25.1 那张表里最刺眼的一行展开。`auto` 布局下字段顺序完全由编译器决定，实测就是"`u32` 优先"——因为对齐要求最高的字段会被放到最前面，让后面的小字段填它留下的空隙。

```zig
// examples/25_binary/main.zig 第 244-257 行
// ═══ 25.3 auto 的字段会被重排：用 @offsetOf 钉死 ═══
begin("25.3 auto struct 的字段会被重排");
err.print("Auto{{ a: u8, b: u32, c: u8 }} 声明顺序 = a, b, c\n", .{});
err.print("实测 offsetOf: a@{d} b@{d} c@{d}  ← b 被挪到最前，a/c 被挤开\n", .{
    @offsetOf(Auto, "a"), @offsetOf(Auto, "b"), @offsetOf(Auto, "c"),
});
err.print("sizeOf={d}（1+4+1=6，被对齐撑到 8）wireSize={d}（字段宽度之和）\n", .{
    @sizeOf(Auto), wireSize(Auto),
});
err.print("wireSize({d}) != sizeOf({d}) ⇒ auto布局下这两个数**永远**不相等\n", .{
    wireSize(Auto), @sizeOf(Auto),
});
err.print("⇒ 所以 auto struct 只能进内存，不能上线（0.17 里它的用途是内存里的快结构体）\n", .{});
end("25.3 auto struct 的字段会被重排");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.3 auto struct 的字段会被重排 开始 ====
Auto{ a: u8, b: u32, c: u8 } 声明顺序 = a, b, c
实测 offsetOf: a@4 b@0 c@5  ← b 被挪到最前，a/c 被挤开
sizeOf=8（1+4+1=6，被对齐撑到 8）wireSize=6（字段宽度之和）
wireSize(6) != sizeOf(8) ⇒ auto布局下这两个数**永远**不相等
⇒ 所以 auto struct 只能进内存，不能上线（0.17 里它的用途是内存里的快结构体）
==== 25.3 auto struct 的字段会被重排 结束 ====
```

`wireSize` 这个辅助函数是本章的诊断工具，值得单独看：

```zig
// examples/25_binary/main.zig 第 43-50 行
/// 25.2 把"字段宽度之和"算出来——wire 尺寸 ≠ @sizeOf 就说明编译器插了填充
fn wireSize(comptime T: type) usize {
    const S = @typeInfo(T).@"struct";
    var n: usize = 0;
    // ⚠️ 0.17：`field_types` 是平行数组，只能 inline for 遍历（普通 for 会报错）
    inline for (S.field_types) |ft| n += @sizeOf(ft);
    return n;
}
```

**⚠️ 这里有一个 0.17 的硬性限制：`field_types` 是平行数组，只能用 `inline for` 遍历。** 写成普通 `for` 会编译失败——报错原文（探针 `q.zig`）：

```text
q.zig:6:11: error: values of type 'type' must be comptime-known, but index value is runtime-known
    for (S.field_types) |ft| n += @sizeOf(ft);
         ~^~~~~~~~~~~~
q.zig:6:11: note: types are not available at runtime
```

`field_types` 的元素是**类型值**，而普通 `for` 的索引是运行时值，所以拿不到类型。`field_names` / `field_attrs` 同理（它们分别是运行时字符串切片和属性结构体，只能 `inline for`）。三条要一起遍历就写：

```zig
inline for (S.field_names, S.field_types, S.field_attrs) |n, t, a| { _ = n; _ = t; _ = a; }
```

**并且 `std.meta.fields` 在 0.17 已经是死路**：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/meta.zig:248:20: error: deprecated in favor of @typeInfo
pub const fields = @compileError("deprecated in favor of @typeInfo");
                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
referenced by:
    main: p49.zig:6:18
```

注意它是**声明处直接 `@compileError`**——不是你调用时报"已废弃"，是连符号定义本身就是一个编译错误。0.16 教程里那段经典代码在 0.17 完全跑不了：

```zig
// ❌ 0.16 写法，0.17 编译失败：deprecated in favor of @typeInfo
var n: usize = 0;
for (std.meta.fields(Record)) |f| n += @sizeOf(f.type);
```

```zig
// ✅ 0.17 写法
const S = @typeInfo(Record).@"struct";
var n: usize = 0;
inline for (S.field_types) |ft| n += @sizeOf(ft);
```

`wireSize(T) != @sizeOf(T)` 在 `auto` 布局下**永远**成立（重排 + 对齐两个原因同时存在），所以它可以当一个粗筛：任何 wire 结构体如果这两个数不等，就说明有填充要处理。但它**不能**区分"重排导致"和"填充导致"——要区分得看 `@offsetOf`（25.4）。

---

## 25.4 `extern struct`：C 布局 + `comptime` 布局守卫

`extern struct` 承诺三件事：**字段按声明顺序**、**每个字段按自然对齐**、**尾部补齐到 `@alignOf` 的倍数**。这就是 C ABI，也是所有"别人按字节解释"的数据唯一的合法容器。

```zig
// examples/25_binary/main.zig 第 27-33 行
/// 25.4 线协议记录头：extern struct 是"上线路"的唯一选择
const Record = extern struct {
    magic: u16,
    version: u8,
    kind: u8,
    length: u32,
};
```

```zig
// examples/25_binary/main.zig 第 259-281 行
// ═══ 25.4 extern struct：C 布局 + comptime 布局守卫 ═══
begin("25.4 extern struct：C 布局 + 布局守卫");
err.print("Ext{{ a: u8, b: u32, c: u8 }}：a@{d} b@{d} c@{d} size={d}（c 在 @8，@sizeOf 补到 12 的倍数 → 尾部 3 字节填充）\n", .{
    @offsetOf(Ext, "a"), @offsetOf(Ext, "b"), @offsetOf(Ext, "c"), @sizeOf(Ext),
});
err.print("wireSize(Ext)={d} sizeOf(Ext)={d} ⇒差 {d} 字节是编译器插的对齐填充\n", .{
    wireSize(Ext), @sizeOf(Ext), @sizeOf(Ext) - wireSize(Ext),
});
err.print("Record{{magic:u16,version:u8,kind:u8,length:u32}}：\n", .{});
err.print("  a@{d}(magic) v@{d}(version) k@{d}(kind) len@{d}(length) size={d}\n", .{
    @offsetOf(Record, "magic"), @offsetOf(Record, "version"),
    @offsetOf(Record, "kind"),  @offsetOf(Record, "length"),
    @sizeOf(Record),
});
err.print("  wireSize={d} == sizeOf={d} ⇒ 字段顺序恰好无填充，comptime 守卫通过\n", .{
    wireSize(Record), @sizeOf(Record),
});
err.print("守卫写法（wire≠sizeOf 就@compileError，实测报错见文档 25.4）：\n", .{});
err.print("  if (wireSize(Record) != @sizeOf(Record)) @compileError(...)\n", .{});
err.print("⚠️ extern也**禁止非 2 的幂次位宽**：extern struct{{ a: u24 }} 编译失败\n", .{});
err.print("   报错：extern structs cannot contain fields of type 'u24'\n", .{});
err.print("   note: only integers with 0 or power of two bits are extern compatible\n", .{});
end("25.4 extern struct：C 布局 + 布局守卫");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.4 extern struct：C 布局 + 布局守卫 开始 ====
Ext{ a: u8, b: u32, c: u8 }：a@0 b@4 c@8 size=12（c 在 @8，@sizeOf 补到 12 的倍数 → 尾部 3 字节填充）
wireSize(Ext)=6 sizeOf(Ext)=12 ⇒差 6 字节是编译器插的对齐填充
Record{magic:u16,version:u8,kind:u8,length:u32}：
  a@0(magic) v@2(version) k@3(kind) len@4(length) size=8
  wireSize=8 == sizeOf=8 ⇒ 字段顺序恰好无填充，comptime 守卫通过
守卫写法（wire≠sizeOf 就@compileError，实测报错见文档 25.4）：
  if (wireSize(Record) != @sizeOf(Record)) @compileError(...)
⚠️ extern也**禁止非 2 的幂次位宽**：extern struct{ a: u24 } 编译失败
   报错：extern structs cannot contain fields of type 'u24'
==== 25.4 extern struct：C 布局 + 布局守卫 结束 ====
```

`Ext`（`u8, u32, u8`）和 `Record`（`u16, u8, u8, u32`）的对比是这一节的核心：

- `Ext`：`a@0`，但 `u32` 要 4 字节对齐，所以 `b@4`（中间空 3 字节）；`c@8`，`@sizeOf` 补到 12 的倍数（尾部空 3 字节）。**总填充 6 字节**。
- `Record`：先放 `u16`（占 0-1），再放 `u8`（占 2）、`u8`（占 3）——**恰好填满前 4 字节**，然后 `u32` 落在偏移 4（本来就4 对齐），结束。**零填充**，`wireSize == @sizeOf == 8`。

**字段顺序不是审美问题，是协议兼容性问题。** `Record` 这种"从大到小"的排法能消掉所有填充，而 `Ext` 这种"从小的开始"会浪费一半空间。这也是为什么 C 里所有 packing 技巧（`#pragma pack`、`__attribute__((packed))`、手写 `__attribute__((aligned))`）全是在跟这件事较劲。

**⚠️ `extern struct` 也禁止非 2 的幂次位宽字段**（探针 `pu4.zig`）：

```text
pu4.zig:2:30: error: extern structs cannot contain fields of type 'u24'
const T = extern struct { a: u24 };
                             ^~~
pu4.zig:2:30: note: only integers with 0 or power of two bits are extern compatible
```

注意报错里那句 note：**"only integers with 0 or power of two bits are extern compatible"**。`u24` 有 24 位，不是 2 的幂次，C 的 ABI 里没有它的表示。这个限制和 `packed struct` 正好相反——25.10 会看到 `u24` 在 `packed struct` 里**完全合法**。

### 布局守卫真的会让编译失败（实测）

守卫不是装饰。把 `Record` 换成有填充的版本（探针 `ab.zig`）：

```zig
const Bad = extern struct { a: u8, b: u32, c: u16 };
comptime {
    if (@typeInfo(Bad).@"struct".layout != .@"extern") @compileError("线协议结构体必须是 extern struct");
    if (wireSize(Bad) != @sizeOf(Bad)) {
        @compileError("Bad 有填充字节：wire=" ++
            std.fmt.comptimePrint("{d}", .{wireSize(Bad)}) ++
            " sizeOf=" ++ std.fmt.comptimePrint("{d}", .{@sizeOf(Bad)}));
    }
}
```

实测报错原文：

```text
ab.zig:12:9: error: Bad 有填充字节：wire=7 sizeOf=12
        @compileError("Bad 有填充字节：wire=" ++
        ^~~~~~~~~~~~~
```

**报错里带上了具体的数字**（`wire=7 sizeOf=12`），这是 `std.fmt.comptimePrint` 的用处——`@compileError` 只吃 comptime 已知的字符串，直接写 `@compileError("有填充")` 你只知道"有问题"，不知道差多少。`wire=7`（1+4+2）vs `sizeOf=12`（`u32` 要 4 对齐所以 `c` 落到@8，尾部补到 12）一眼看出问题在哪。

这就是"wire 尺寸 ≠ `@sizeOf` 就编译失败"这条守卫的完整形态：**它把一个运行期才会暴露的字节错位问题，提前到编译期**。示例里的 `Record` 恰好零填充所以守卫通过，但守卫本身是常开的——改一个字段顺序它就立刻拦下来。

---

## 25.5 `@bitCast` 的 0.17 限制：为什么 extern struct 不行

这是本章最重要的一条 0.17 迁移信息。旧教程里到处流传的这段代码：

```zig
// ❌ 0.17 编译失败（这就是本章的 Record）
const rec = Record{ .magic = 0xBEEF, .version = 1, .kind = 2, .length = 8 };
const w: u16 = @bitCast(rec);
```

实测报错（探针文件就叫 `main.zig`，所以类型名是 `main.Record`）：

```text
main.zig:6:29: error: cannot @bitCast from 'main.Record'
    const w: u16 = @bitCast(rec);
                            ^~~
main.zig:2:23: note: struct declared here
const Record = extern struct { magic: u16, version: u8, kind: u8, length: u32 };
               ~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

**`extern struct` 不行，普通 `struct` 更不行**——两种都报同一句 `cannot @bitCast from '...'`。

这不是 bug，是设计。0.17 收紧了 `@bitCast` 的适用范围：**只有 `packed struct`（它的内存表示在定义上就等于背板整数）才允许 `@bitCast` 进出。** 对于有对齐填充可能的布局（`auto` / `extern`），`@bitCast` 会是"未定义"的——`@sizeOf(Record) == 8`，但里面哪个字节是哪个字段、要按什么顺序搬，编译器不打算给你答案。

**`packed struct` 是唯一例外**，实测通过：

```zig
// examples/25_binary/main.zig 第 35-41 行
/// 25.10 位域：packed struct(u16) 是唯一允许 @bitCast 进出的 struct 形态
const Flags = packed struct(u16) {
    enabled: bool, // bit 0
    mode: u2, // bit 1-2
    reserved: u5, // bit 3-7
    level: u8, // bit 8-15
};
```

```zig
// examples/25_binary/main.zig 第 283-306 行
// ═══ 25.5 ⚠️ @bitCast 在 0.17 拒绝裸结构体 ═══
begin("25.5 @bitCast 的0.17 限制");
err.print("0.17 实测：`const w: u16 = @bitCast(ext_struct_value)` 编译失败\n", .{});
err.print("  报错文本：error: cannot @bitCast from 'main.Record'\n", .{});
err.print("  extern struct 不行、普通 struct 更不行（extern 已经是唯一\"合法\"布局了）\n", .{});
err.print("**唯一例外是 packed struct**（它的内存表示就是背板整数）：\n", .{});
const f1 = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
const board: u16 = @bitCast(f1);
err.print("  Flags{{enabled,mode=0b10,level=0x5A}} @bitCast→ u16 = 0x{X:0>4}\n", .{board});
const f2: Flags = @bitCast(board);
err.print("  u16 0x{X:0>4} @bitCast→ Flags = enabled={} mode={d} level=0x{X:0>2}\n", .{
    board, f2.enabled, f2.mode, f2.level,
});
err.print("位分配从低位起：bit0=enabled bit1-2=mode bit3-7=reserved bit8-15=level\n", .{});
err.print("⇒ 正确写法：std.mem.asBytes(&v) 拿字节，再readInt/writeInt（**显式端序**）\n", .{});
const r = Record{ .magic = 0xBEEF, .version = 1, .kind = 2, .length = 8 };
const rb = std.mem.asBytes(&r);
err.print("  asBytes(&Record) 类型 = {s}，len={d}（= @sizeOf，切不出越界）\n", .{
    @typeName(@TypeOf(rb)), rb.len,
});
err.print("  指向的数组对齐 = {d}（= @alignOf(Record)），内容 = {X}\n", .{
    @alignOf(Record), rb.*,
});
end("25.5 @bitCast 的0.17 限制");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.5 @bitCast 的0.17 限制 开始 ====
0.17 实测：`const w: u16 = @bitCast(ext_struct_value)` 编译失败
  报错文本：error: cannot @bitCast from 'main.Record'
  extern struct 不行、普通 struct 更不行（extern 已经是唯一"合法"布局了）
**唯一例外是 packed struct**（它的内存表示就是背板整数）：
  Flags{enabled,mode=0b10,level=0x5A} @bitCast→ u16 = 0x5A05
  u16 0x5A05 @bitCast→ Flags = enabled=true mode=2 level=0x5A
位分配从低位起：bit0=enabled bit1-2=mode bit3-7=reserved bit8-15=level
⇒ 正确写法：std.mem.asBytes(&v) 拿字节，再readInt/writeInt（**显式端序**）
  asBytes(&Record) 类型 = *align(4) const [8]u8，len=8（= @sizeOf，切不出越界）
  指向的数组对齐 = 4（= @alignOf(Record)），内容 = EFBE010208000000
==== 25.5 @bitCast 的0.17 限制 结束 ====
```

`0x5A05` 这个值值得停下来看一眼。`Flags{enabled=true, mode=0b10, level=0x5A}` 编成 `0x5A05`：

- bit0 = `enabled` = 1 → `0x0001`
- bit1-2 = `mode` = 0b10 = 2 → `0b10` << 1 = `0x0004`
- bit3-7 = `reserved` = 0
- bit8-15 = `level` = 0x5A → `0x5A00`

合计 `0x5A00 | 0x0004 | 0x0001 = 0x5A05`。**位分配从低位起，按声明顺序往上排**——这和 C 的位域约定一致，也是为什么 `level`（声明在最后）落在最高字节。

**正确写法是 `std.mem.asBytes` + `readInt`/`writeInt`**。上面输出里 `asBytes(&Record)` 的内容是 `EFBE010208000000`，注意这是**本机序（小端）**：`magic` 是 `u16` 值 `0xBEEF`，小端存成 `EF BE`。如果你要上线，这个字节序必须是协议规定的那个（见 25.8）。

关于 `asBytes` 的返回值有两点实测结论：

1. **它返回的是带对齐的指针**，类型是 `*align(N) [N]u8`（N = `@alignOf(T)`）。0.16 返回的是不带 align 的 `*[N]u8`。
2. **长度就是 `@sizeOf(T)`，切不出越界的**——这是编译期保证的，因为返回类型里的数组长度是 comptime 已知的。

⚠️ 但 `@alignOf(@TypeOf(asBytes(&x)))` 拿到的是**指针本身**的对齐（x86_64 上是 8），不是它指向的数组的对齐。要问后者得用 `@typeInfo(@TypeOf(ab)).pointer.attrs.@"align"`——而且字段名是 `@"align"`（`align` 是关键字，必须转义），实测值是 `@alignOf(u32) == 4`。

---

## 25.6 字节 API 家族：`toBytes` / `asBytes` / `bytesToValue` / `bytesAsValue`

0.17 的 `std.mem` 里有四个"值↔ 字节"方向的函数。它们最容易混的地方是**返回值是值拷贝还是指针**：

| 函数 | 方向 | 返回 |拷贝？ | 0.17 状态 |
|---|---|---|---|---|
| `std.mem.toBytes(value)` | 值 → 字节 | `[N]u8` | **值拷贝** |✅ 存在（0.16 的 `valueToBytes` 等价物） |
| `std.mem.asBytes(&value)` | 值 → 字节 | `*align(N) [N]u8` | **指针**，零拷贝 | ✅ 存在，返回类型带 align |
| `std.mem.bytesToValue(T, bs)` | 字节 → 值 | `T` | **值拷贝** | ✅ 存在 |
| `std.mem.bytesAsValue(T, bs)` | 字节 → 值 | `*T` | **指针视图** | ✅ 存在，保留指针属性 |
| `std.mem.valueToBytes(value)` | 值 → 字节 | — | — | ❌ **0.17 不存在** |

**⚠️ `std.mem.valueToBytes` 在 0.17 已被移除**，实测：

```text
p15.zig:10:23: error: root source file struct 'mem' has no member named 'valueToBytes'
    const vb = std.mem.valueToBytes(t);
               ~~~~~~~^~~~~~~~~~
```

它的替代品就是 `std.mem.toBytes`。注意 `toBytes` **接受值**（不是指针），返回 `[@sizeOf(@TypeOf(value))]u8`，实现是 `return asBytes(&value).*`——所以它本质上是"取指针再解引用拷贝一份"。

实测的报错原文（探针 `d.zig`）：

```text
d.zig:3:22: error: root source file struct 'mem' has no member named 'valueToBytes'
    const v = std.mem.valueToBytes(@as(u32, 1));
              ~~~~~~~^~~~~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/mem.zig:1:1: note: struct declared here
const mem = @This();
^~~~~
```

注意报错说**没有成员**（`has no member named`），不是"已废弃"——0.17 把这类改名 API 直接删干净了，所以 `@hasDecl(std.mem, "valueToBytes")` 返回 `false`（示例的 test 块用 `@hasDecl` 把这条钉住了）。

```zig
// examples/25_binary/main.zig 第 308-332 行
// ═══ 25.6 asBytes / bytesAsValue / bytesToValue / toBytes ═══
begin("25.6 字节 API 家族");
err.print("std.mem.toBytes(value)      → [N]u8（**值拷贝**，N = @sizeOf(T)）\n", .{});
err.print("std.mem.asBytes(&value)     → *align(N) [N]u8（**带对齐**的指针，不拷贝）\n", .{});
err.print("std.mem.bytesToValue(T, bs)  → T（**值拷贝** = bytesAsValue(T,bs).*）\n", .{});
err.print("std.mem.bytesAsValue(T, bs) → *T（指针视图，保留指针属性）\n", .{});
err.print("⚠️ std.mem.valueToBytes 在 0.17 **不存在**（实测 hasDecl=false）\n", .{});
var v32: u32 = 0x12345678;
const tb = std.mem.toBytes(v32);
err.print("toBytes(u32 0x12345678) = {x}（本机小端）\n", .{tb});
const back = std.mem.bytesToValue(u32, &tb);
err.print("bytesToValue 回去= 0x{X:0>8}（往返一致）\n", .{back});
const ab = std.mem.asBytes(&v32);
err.print("asBytes(&u32) 类型 = {s}（align 来自 T 的 @alignOf={d}）\n", .{
    @typeName(@TypeOf(ab)), @alignOf(u32),
});
// extern struct 整体 view
const raw align(@alignOf(Record)) = [_]u8{ 0xEF, 0xBE, 0x01, 0x02, 0x08, 0x00, 0x00, 0x00 };
const rec = std.mem.bytesToValue(Record, &raw);
err.print("bytesToValue(Record, 对齐的字节块) = magic=0x{X} v={d} k={d} len={d}\n", .{
    rec.magic, rec.version, rec.kind, rec.length,
});
err.print("⚠️ 对齐不过关时bytesToValue **不报错**，直接给你一个错读的值（实测）\n", .{});
err.print("   → 所以 extern view 只在\"你确信这块内存是对齐的\"地方用\n", .{});
end("25.6 字节 API 家族");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.6 字节 API 家族 开始 ====
std.mem.toBytes(value)      → [N]u8（**值拷贝**，N = @sizeOf(T)）
std.mem.asBytes(&value)     → *align(N) [N]u8（**带对齐**的指针，不拷贝）
std.mem.bytesToValue(T, bs)  → T（**值拷贝** = bytesAsValue(T,bs).*）
std.mem.bytesAsValue(T, bs) → *T（指针视图，保留指针属性）
⚠️ std.mem.valueToBytes 在 0.17 **不存在**（实测 hasDecl=false）
toBytes(u32 0x12345678) = 78563412（本机小端）
bytesToValue 回去= 0x12345678（往返一致）
asBytes(&u32) 类型 = *align(4) [4]u8（align 来自 T 的 @alignOf=4）
bytesToValue(Record, 对齐的字节块) = magic=0xBEEF v=1 k=2 len=8
⚠️ 对齐不过关时bytesToValue **不报错**，直接给你一个错读的值（实测）
   → 所以 extern view 只在"你确信这块内存是对齐的"地方用
==== 25.6 字节 API 家族 结束 ====
```

###⚠️ 本章最危险的一条：`bytesToValue` 不检查对齐

旧版文档说"`bytesToValue` 对齐吃不满时它会当场报错而不是静默错读——这正是它比 `@ptrCast` 直转安全的原因"。**这个说法在 0.17 是错的。** 实测：

```zig
// 不带 align 标注的字节数组 → bytesToValue 照样成功
const bad = [_]u8{ 0xEF, 0xBE, 0x01, 0x02, 0x08, 0, 0, 0 };
const r2 = std.mem.bytesToValue(Record, &bad);
std.debug.print("unaligned ok? {any}\n", .{r2});
```

```text
aligned: magic=0xBEEF v=1 k=2 len=8
unaligned ok? .{ .magic = 48879, .v = 1, .kind = 2, .len = 8 }
```

看仔细：**`aligned` 那行 `magic=0xBEEF`，`unaligned` 那行 `magic = 48879` = `0xBEEF` 的十进制**——这次恰好读对了（x86 对未对齐访问宽容），但**它没有任何机制保证下次也对**。在 ARM（比如 Apple Silicon）上，未对齐的 `u16`/`u32` load 会直接 SIGBUS 崩溃；在优化开启的 ReleaseFast 里，`0xBEEF` 可能变成别的。

原因在std 源码里：`bytesAsValue` 的实现就是一句 `@ptrCast`，而 `bytesAsValueReturnType` 走 `CopyPtrAttrs(B, .one, T)`——**它保留传入指针的对齐属性，不会提高它**。所以传进去 `*[8]u8`（align 1），出来的就是 `*align(1) Record`。Zig 允许你持有这个指针（合法但不安全），不会拦你。

**结论：extern struct 的整体 view 只在"你百分之百确信这块内存是对齐的"地方用**——比如一个 `align(@alignOf(T))` 标注的局部数组，或者一个 `extern` 声明的 C 全局变量。协议解析请走25.7 的 `readInt`。

---

## 25.7 `readInt` / `writeInt`：显式端序 + 零对齐要求

如果 25.6 讲的是"整体 view"，那这一节讲的是"逐字段读"。**这是本章最常用的一节。**

签名（0.17 实测，从报错信息里能看到 std 的真实源码）：

```zig
pub inline fn readInt(comptime T: type, buffer: *const [@divExact(@typeInfo(T).int.bits, 8)]u8, endian: Endian) T
pub inline fn writeInt(comptime T: type, buffer: *[@divExact(@typeInfo(T).int.bits, 8)]u8, value: T, endian: Endian) void
```

两个要点：

1. **数组长度 N 由 `T` 的位宽推导**（`@divExact(bits, 8)`），你不用也不能自己指定。给错长度是编译错误。
2. **`endian` 参数是必填的**（`.little` / `.big`）。没有"本机序"这个选项——这是刻意的，见 25.8。

```zig
// examples/25_binary/main.zig 第 334-347 行
// ═══ 25.7 readInt / writeInt：不要求对齐是最大优势 ═══
begin("25.7 readInt / writeInt：显式端序 + 零对齐要求");
var buf: [9]u8 = @splat(0);
std.mem.writeInt(u32, buf[1..5], 0xAABBCCDD, .big); // 偏移 1，**故意不对齐**
err.print("writeInt(u32, buf[1..5], 0xAABBCCDD, .big) → dump={X}\n", .{buf});
err.print("  buf[1..5] 地址 % 4 = 1（未对齐），x86 能跑，ARM 会 trap\n", .{});
err.print("  这就是 readInt 相对 @ptrCast 的最大优势：它只按字节搬，不生成对齐 load\n", .{});
err.print("  readInt(u32, buf[1..5], .big)    = 0x{X:0>8}\n", .{std.mem.readInt(u32, buf[1..5], .big)});
err.print("  readInt(u32, buf[1..5], .little) = 0x{X:0>8}（同一批字节，反过来读）\n", .{std.mem.readInt(u32, buf[1..5], .little)});
err.print("⚠️ N 必须精确等于 T 的字节数：给 readInt(u32) 喂 8 字节数组会编译失败\n", .{});
err.print("   报错：expected type '*const [4]u8', found '*const [8]u8'\n", .{});
err.print("   签名：readInt(T, *const [@divExact(bits,8)]u8, endian) → T（N 由 T 推导）\n", .{});
err.print("⚠️ u24 也支持但要 3 字节（给 4 字节同样编译失败）\n", .{});
end("25.7 readInt / writeInt：显式端序 + 零对齐要求");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.7 readInt / writeInt：显式端序 + 零对齐要求 开始 ====
writeInt(u32, buf[1..5], 0xAABBCCDD, .big) → dump=00AABBCCDD00000000
  buf[1..5] 地址 % 4 = 1（未对齐），x86 能跑，ARM 会 trap
  这就是 readInt 相对 @ptrCast 的最大优势：它只按字节搬，不生成对齐 load
  readInt(u32, buf[1..5], .big)    = 0xAABBCCDD
  readInt(u32, buf[1..5], .little) = 0xDDCCBBAA（同一批字节，反过来读）
⚠️ N 必须精确等于 T 的字节数：给 readInt(u32) 喂 8 字节数组会编译失败
   报错：expected type '*const [4]u8', found '*const [8]u8'
   签名：readInt(T, *const [@divExact(bits,8)]u8, endian) → T（N 由 T 推导）
⚠️ u24 也支持但要 3 字节（给 4 字节同样编译失败）
==== 25.7 readInt / writeInt：显式端序 + 零对齐要求 结束 ====
```

### 不要求对齐是最大优势

注意 `buf[1..5]` 这个切片的地址 **模 4 = 1**——完全未对齐。`readInt` / `writeInt` **完全不 care**：它们的实现是 `@bitCast` 一个字节数组（`[N]u8` 的对齐要求是 1），然后按端序拼起来。编译器不会为它们生成任何对齐 load 指令。

对比一下两条路：

```zig
// ❌ 危险：指针 cast，保留 T 的对齐要求，未对齐地址上运行是 UB
const p: *align(4) const u32 = @ptrCast(@alignCast(buf[1..5].ptr));
const v1 = p.*;

// ✅ 安全：readInt 只按字节搬，任何偏移都能读
const v2 = std.mem.readInt(u32, buf[1..5], .big);
```

在 x86_64 上两者都能跑出正确结果（x86 允许未对齐访问）。在 **aarch64** 上，第一种会在未对齐时触发 SIGBUS，第二种永远安全。本教程的18 章（交叉编译）会实际编出 aarch64 目标——这段代码在那边能不能活，一试就知道。

### `N` 必须精确等于 `sizeof(T)`

给错长度是编译错误，而且报错信息很友好（会同时列出 std 的真实签名）。下面是探针 `pr1.zig` 的原样输出（`b` 声明为 `[8]u8`）：

```text
pr1.zig:5:36: error: expected type '*const [4]u8', found '*const [8]u8'
    const v = std.mem.readInt(u32, &b, .little);
                                   ^~
pr1.zig:5:36: note: pointer type child '[8]u8' cannot cast into pointer type child '[4]u8'
pr1.zig:5:36: note: array of length 8 cannot cast into an array of length 4
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/mem.zig:1957:49: note: parameter type declared here
pub inline fn readInt(comptime T: type, buffer: *const [@divExact(@typeInfo(T).int.bits, 8)]u8, endian: Endian) T {
```

注意最后那行 `note` 把 std 的签名原文也打出来了——`N` 不是你能传的参数，是从 `@divExact(bits, 8)` **推导**出来的，这也解释了为什么它不接受你手写的数字。

`u24` 也支持，但要**正好 3 字节**（探针 `pr2.zig`，`b` 是 `[4]u8`）：

```text
pr2.zig:5:36: error: expected type '*const [3]u8', found '*const [4]u8'
    const v = std.mem.readInt(u24, &b, .little);
                                   ^~
pr2.zig:5:36: note: pointer type child '[4]u8' cannot cast into pointer type child '[3]u8'
pr2.zig:5:36: note: array of length 4 cannot cast into an array of length 3
```

从**切片**（而不是数组指针）上读也支持，写法是 `sl[off..][0..N]`——先按偏移切，再取定长：

```zig
const sl: []u8 = storage[0..];
const off: usize = 4;
std.mem.writeInt(u32, sl[off..][0..4], 0x11223344, .little);
```

但要注意 `sl[off..]` 这种写法**只在能静态推断长度时才能传给 `readInt`**。运行时长度的切片直接传会报错：

```text
pr3.zig:7:29: error: coercion from slice to array pointer type '*[4]u8' requires length to be known at compile-time
    std.mem.writeInt(u32, sl[off..], 0x11223344, .little);
                          ~~^~~~~~~
```

所以 **`[0..4]` 那个切片是必须的**——它把长度变成 comptime 已知。

### 同一批字节、两种端序

`dump=00AABBCCDD00000000` 是按 `.big` 写进去的。同一批字节用 `.little` 读，得到 `0xDDCCBBAA`——**字节序不是"数据变了"，是"解释方式变了"**。这就是为什么协议解析必须显式写端序：写错了不会报错，只会让你读出一个"看起来很合理"的错数（`0xDDCCBBAA` ≈ 37.2 亿，是个合法的 u32）。

---

## 25.8 字节序：网络序与 `htons` / `ntohs`

`builtin.cpu.arch.endian()` 在 0.17 返回 **`std.lang.Endian`** 枚举（不是 0.16 的 `std.builtin.Endian`），取值 `.little` / `.big`，而且它是**编译期常量**——所以 `const native = builtin.cpu.arch.endian()` 之后可以直接 comptime 分支。

```zig
// examples/25_binary/main.zig 第 349-376 行
// ═══ 25.8 字节序：为什么协议必须显式写端序 ═══
begin("25.8 字节序：网络序与 htons/ntohs");
const native = builtin.cpu.arch.endian();
err.print("builtin.cpu.arch.endian() 类型 = {s}，本机值 = {s}\n", .{
    @typeName(@TypeOf(native)), @tagName(native),
});
err.print("它是**编译期常量**（const native = ... 直接 comptime if 分支）\n", .{});
const value: u32 = 0x12345678;
err.print("同一个 u32=0x12345678 的三种字节面貌：\n", .{});
err.print("  本机序 native        {x}（{s} 机器上就是这个顺序）\n", .{
    std.mem.asBytes(&value).*, @tagName(native),
});
err.print("  大端   nativeToBig   {x}\n", .{std.mem.asBytes(&std.mem.nativeToBig(u32, value)).*});
err.print("  小端   nativeToLittle {x}\n", .{std.mem.asBytes(&std.mem.nativeToLittle(u32, value)).*});
err.print("x86/ARM 桌面端都是小端⇒ nativeToBig 是真交换；大端机器上是空操作\n", .{});
const port: u16 = 8080;
const port_be = htons(port);
err.print("端口 8080：本机字节 {x} → htons 后 {x}\n", .{
    std.mem.asBytes(&port).*, std.mem.asBytes(&port_be).*,
});
err.print("自实现 htons/ntohs（不依赖 std.mem 的 4 个变体）：\n", .{});
err.print("  htons(0x1234)=0x{X:0>4}  ntohs(htons(0x1234))=0x{X:0>4}（交换是自逆的，往返一致）\n", .{
    htons(0x1234), ntohs(htons(0x1234)),
});
err.print("⚠️ 为什么必须交换：网络协议规定多字节整数一律大端（网络序）\n", .{});
err.print("   小端主机直接 memcpy 端口号出去→ 对端读到 0x901f（38609）而不是 8080\n", .{});
err.print("⚠️ readInt 的 .little/.big 是**第三种**语义（读文件格式用），别和 htons 混用\n", .{});
end("25.8 字节序：网络序与 htons/ntohs");
```

```zig
// examples/25_binary/main.zig 第 597-604 行
/// 25.8 自实现网络序转换（不依赖 std.mem.nativeToBig 等4 个变体）
fn htons(v: u16) u16 {
    return if (builtin.cpu.arch.endian() == .little) @byteSwap(v) else v;
}

fn ntohs(v: u16) u16 {
    return htons(v); // 交换是自逆的
}
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.8 字节序：网络序与 htons/ntohs 开始 ====
builtin.cpu.arch.endian() 类型 = lang.Endian，本机值 = little
它是**编译期常量**（const native = ... 直接 comptime if 分支）
同一个 u32=0x12345678 的三种字节面貌：
  本机序 native        78563412（little 机器上就是这个顺序）
  大端   nativeToBig   12345678
  小端   nativeToLittle 78563412
x86/ARM 桌面端都是小端⇒ nativeToBig 是真交换；大端机器上是空操作
端口 8080：本机字节 901f → htons 后 1f90
自实现 htons/ntohs（不依赖 std.mem 的 4 个变体）：
  htons(0x1234)=0x3412  ntohs(htons(0x1234))=0x1234（交换是自逆的，往返一致）
⚠️ 为什么必须交换：网络协议规定多字节整数一律大端（网络序）
   小端主机直接 memcpy 端口号出去→ 对端读到 0x901f（38609）而不是 8080
⚠️ readInt 的 .little/.big 是**第三种**语义（读文件格式用），别和 htons 混用
==== 25.8 字节序：网络序与 htons/ntohs 结束 ====
```

### 端口 8080 的经典事故

这是本章最值得记住的一个具体数字。`8080 = 0x1F90`。在小端机器上，内存里的字节是 `90 1F`。

- 如果你**不交换**就把这2 字节 `memcpy` 到网络缓冲区，对端按大端读，得到 `0x901F = 38609`——**连到了完全不相干的端口**。
- 正确做法是先 `htons`（= `@byteSwap`，小端机器上）把它变成 `0x901F`，字节序列变成 `1F 90`，对端大端读回来正好是 8080。

上面输出里 `端口 8080：本机字节 901f → htons 后 1f90` 就是这个过程。**注意 `htons(0x1234)` 的结果是 `0x3412` 而不是 `0x1234`**——如果你在大端机器上跑，`htons` 是空操作，输出会不同。所以这两个值都写进测试里，并且用 `builtin.cpu.arch.endian()` 做前置条件。

### `readInt` 的端序参数是"第三种"语义

这一点很容易混。Zig 里有**三套**端序相关的 API，语义各不相同：

| API | 语义 | 用途 |
|---|---|---|
| `readInt` / `writeInt` 的 `.little`/`.big` | **文件/线格式**：这一批字节按什么顺序解释 | 解析 WAV、ELF、自定义协议 |
| `htons` / `ntohs`（自己实现） | **网络栈**：把主机序整数转成网络序（约定为大端） | socket API |
| `nativeToBig` / `nativeToLittle` / `bigToNative` / `littleToNative` | **本机序 ↔ 目标序的原地值变换** | 已有本机序缓冲区要换序时 |

`nativeToBig(u32, 0x12345678)` 在小端机器上得到 `0x78563412`——**它的字节面貌**变成了 `12345678`（大端）。它不是"把这个值变成大端的数"，而是"把这个值的字节排列换成大端"。这个双重含义是 std 的历史包袱，实际用的时候记住：**`nativeToBig` 之后再 `asBytes` 看到的字节序才是你要的**。

---

## 25.9 变长整数：LEB128（varint）

定长编码的代价：值 1 也要占 4 字节。LEB128（也叫 varint、varuint）按需分配——每字节 7 个数据位，最高位是"还有后续"标志。

```zig
// examples/25_binary/main.zig 第 165-179 行
/// 25.9 LEB128 无符号变长整数：7 位一组，最高位是"还有后续"标志
fn putVarint(out: []u8, value_in: usize) !usize {
    var v = value_in;
    var i: usize = 0;
    while (true) {
        if (i >= out.len) return error.NoSpaceLeft;
        if (v < 0x80) {
            out[i] = @intCast(v);
            return i + 1;
        }
        out[i] = @intCast((v & 0x7F) | 0x80); // 低 7 位 + 续位
        v >>= 7;
        i += 1;
    }
}
```

**⚠️ 注意 `shift` 的类型是 `u6`**。7 位一组，最多 10 组（64 位），`7 * 9 = 63` 需要 6 位，所以 `u6` 刚好。写成 `u5` 会在64 位值上溢出——这是实测踩过的。

```zig
// examples/25_binary/main.zig 第 378-406 行
// ═══ 25.9 变长整数 varint / LEB128 ═══
begin("25.9 变长整数：LEB128");
err.print("定长编码的代价：值 1 也要占 4 字节。LEB128 按需分配：\n", .{});
err.print("  {d:>6} → {d} 字节\n", .{ 0, blkLen(0) });
err.print("  {d:>6} → {d} 字节\n", .{ 1, blkLen(1) });
err.print("  {d:>6} → {d} 字节\n", .{ 127, blkLen(127) });
err.print("  {d:>6} → {d} 字节（跨过 0x7F就要多一组）\n", .{ 128, blkLen(128) });
err.print("  {d:>6} → {d} 字节\n", .{ 300, blkLen(300) });
err.print("  {d:>6} → {d} 字节（64 位 usize 最多 10 字节）\n", .{ std.math.maxInt(u64), blkLen(std.math.maxInt(u64)) });
err.print("边界用例（0 / 127 / 128 / 16383 / 16384 / 2^32-1）：\n", .{});
for ([_]usize{ 0, 127, 128, 16383, 16384, std.math.maxInt(u32) }) |v| {
    var tmp: [10]u8 = undefined;
    const n = try putVarint(&tmp, v);
    var got: usize = 0;
    const m = try getVarint(tmp[0..n], &got);
    err.print("  {d:>10} → {d} 字节 {X} → 解回 {d}（消耗 {d} 字节）{s}\n", .{
        v, n, tmp[0..n], got, m,
        if (got == v and m == n) "✓" else "✗",
    });
}
err.print("⚠️ 恶意输入防御：① i >= 5 直接 BadVarint（u32 上限）② 字节不够 BadVarint\n", .{});
var junk: usize = 0;
err.print("   getVarint(6 个连续续位)  = {s}（超出 u32 的 5 字节上限 → 拒）\n", .{
    @errorName(varintErr(getVarint(&[_]u8{ 0x80, 0x80, 0x80, 0x80, 0x80, 0x80 }, &junk))),
});
err.print("   getVarint(单个 0x80)     = {s}（有续位但没数据 → 拒）\n", .{
    @errorName(varintErr(getVarint(&[_]u8{0x80}, &junk))),
});
end("25.9 变长整数：LEB128");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.9 变长整数：LEB128 开始 ====
定长编码的代价：值 1 也要占 4 字节。LEB128 按需分配：
       0 → 1 字节
       1 → 1 字节
     127 → 1 字节
     128 → 2 字节（跨过 0x7F就要多一组）
     300 → 2 字节
  18446744073709551615 → 10 字节（64 位 usize 最多 10 字节）
边界用例（0 / 127 / 128 / 16383 / 16384 / 2^32-1）：
           0 → 1 字节 00 → 解回 0（消耗 1 字节）✓
         127 → 1 字节 7F → 解回 127（消耗 1 字节）✓
         128 → 2 字节 8001 → 解回 128（消耗 2 字节）✓
       16383 → 2 字节 FF7F → 解回 16383（消耗 2 字节）✓
       16384 → 3 字节 808001 → 解回 16384（消耗 3 字节）✓
  4294967295 → 5 字节 FFFFFFFF0F → 解回 4294967295（消耗 5 字节）✓
⚠️ 恶意输入防御：① i >= 5 直接 BadVarint（u32 上限）② 字节不够 BadVarint
   getVarint(6 个连续续位)  = BadVarint（超出 u32 的 5 字节上限 → 拒）
   getVarint(单个 0x80)     = BadVarint（有续位但没数据 → 拒）
==== 25.9 变长整数：LEB128 结束 ====
```

### 边界用例是这一节的重点

看 `128` 的编码：`8001`。低 7 位是 `0x00`，续位 `1` → 字节 `0x80`；剩下 `128 >> 7 = 1`，`1 < 0x80` → 字节 `0x01`。合起来 `80 01`。

再看 `16383 = 0x3FFF`：`FF 7F`。低 7 位 `0x7F` + 续位 = `0xFF`；`16383 >> 7 = 127 = 0x7F`，`127 < 0x80` → `0x7F`。

`4294967295 = 0xFFFFFFFF`：`FF FF FF FF 0F`——**5 字节**，正好是 `getVarint` 里 `if (i >= 5) return error.BadVarint` 的边界。

**⚠️ 两道防御缺一不可**：

1. **`i >= 5` 上限**：`0x80 0x80 0x80 0x80 0x80 0x80`（6 个续位）如果不限，会一直读到切片末尾；更糟的是某些实现会无限增长 `acc` 直到溢出。
2. **`i >= src.len`**：`0x80`（有续位但没数据）必须报 `BadVarint`，不能读越界。

**这两条顺序不能反**。如果先读 `src[i]` 再判长度，那是越界读；如果先判长度但不限字节数，`0x80 × 100` 会变成一个"合法但荒谬"的长度值，后果更坏（25.14 会看到解码器怎么用 `TooLarge` 兜住它）。

**⚠️ std 里没有 varint**。实测 `@hasDecl(std, "varint")` 是 `false`，`putVarInt` / `getVarInt` / `zigzag` 全都不存在。所以这个手写实现是必需的，不是练手。

---

## 25.10 位域与 `packed struct`

位域（bit field）是"一个字节里塞多个小字段"的经典手法。Zig 用 `packed struct` 实现它。

```zig
// examples/25_binary/main.zig 第 408-445 行
// ═══ 25.10 位域与 packed struct ═══
begin("25.10 位域与 packed struct");
err.print("Flags 是 packed struct(u16)，四个字段共1+2+5+8 = 16 bit\n", .{});
err.print("改一个字段，观察背板整数怎么变（网络协议里这就是「标志位」）：\n", .{});
inline for (.{
    Flags{ .enabled = false, .mode = 0, .reserved = 0, .level = 0 },
    Flags{ .enabled = true, .mode = 0, .reserved = 0, .level = 0 },
    Flags{ .enabled = false, .mode = 0b11, .reserved = 0, .level = 0 },
    Flags{ .enabled = false, .mode = 0, .reserved = 0, .level = 0xFF },
    Flags{ .enabled = true, .mode = 0b01, .reserved = 0b11111, .level = 0xA5 },
}) |f| {
    const b: u16 = @bitCast(f);
    err.print("  enabled={} mode=0b{b:0>2} level=0x{X:0>2} → 0x{X:0>4}\n", .{
        f.enabled, f.mode, f.level, b,
    });
}
err.print("取地址：0.17 **允许** &f.field，但类型是带 bit offset 的指针：\n", .{});
var fv = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
err.print("  &fv.level 类型 = {s}（字节对齐的那个字段，看起来正常）\n", .{@typeName(@TypeOf(&fv.level))});
err.print("  &fv.mode  类型 = {s}（bit 1-2，**不是**字节对齐）\n", .{@typeName(@TypeOf(&fv.mode))});
err.print("⚠️ 把 &fv.mode 传给 fn(*u2) 会编译失败（bit offset 无法隐式降为 0）：\n", .{});
err.print("   报错：expected type '*u2', found '*align(2:1:2) u2'\n", .{});
err.print("   note: pointer host size '2' cannot cast into pointer host size '0'\n", .{});
err.print("   note: pointer bit offset '1' cannot cast into pointer bit offset '0'\n", .{});
err.print("⇒ 修法一：显式标注 *align(2:1:2) u2；修法二：把整个背板 @bitCast 出来再取地址\n", .{});
err.print("packed struct 的其它实测事实：\n", .{});
const U24F = packed struct(u32) { a: u24, b: u8 };
err.print("  packed struct(u32){{a:u24,b:u8}} 合法：size={d} bits={d}（u24 **可以**进 packed）\n", .{
    @sizeOf(U24F), @bitSizeOf(U24F),
});
const Odd = packed struct { a: u3, b: u3, c: u3 };
err.print("  packed struct 不写背板（三个 u3 = 9 位）：size={d} bits={d} align={d}（补齐到 2 字节）\n", .{
    @sizeOf(Odd), @bitSizeOf(Odd), @alignOf(Odd),
});
err.print("⚠️ 但 extern struct{{ a: u24 }} 编译失败：extern structs cannot contain fields of type 'u24'\n", .{});
err.print("   （0 或 2 的幂次位宽才有 C 兼容布局）\n", .{});
err.print("⚠️ packed struct(u32){{ a: u24 }} 字段装不满背板 → backing integer bit width does not match\n", .{});
end("25.10 位域与 packed struct");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.10 位域与 packed struct 开始 ====
Flags 是 packed struct(u16)，四个字段共1+2+5+8 = 16 bit
改一个字段，观察背板整数怎么变（网络协议里这就是「标志位」）：
  enabled=false mode=0b00 level=0x00 → 0x0000
  enabled=true mode=0b00 level=0x00 → 0x0001
  enabled=false mode=0b11 level=0x00 → 0x0006
  enabled=false mode=0b00 level=0xFF → 0xFF00
  enabled=true mode=0b01 level=0xA5 → 0xA5FB
取地址：0.17 **允许** &f.field，但类型是带 bit offset 的指针：
  &fv.level 类型 = *align(2:8:2) u8（字节对齐的那个字段，看起来正常）
  &fv.mode  类型 = *align(2:1:2) u2（bit 1-2，**不是**字节对齐）
⚠️ 把 &fv.mode 传给 fn(*u2) 会编译失败（bit offset 无法隐式降为 0）：
   报错：expected type '*u2', found '*align(2:1:2) u2'
   note: pointer host size '2' cannot cast into pointer host size '0'
   note: pointer bit offset '1' cannot cast into pointer bit offset '0'
⇒ 修法一：显式标注 *align(2:1:2) u2；修法二：把整个背板 @bitCast 出来再取地址
packed struct 的其它实测事实：
  packed struct(u32){a:u24,b:u8} 合法：size=4 bits=32（u24 **可以**进 packed）
  packed struct 不写背板（三个 u3 = 9 位）：size=2 bits=9 align=2（补齐到 2 字节）
⚠️ 但 extern struct{ a: u24 } 编译失败：extern structs cannot contain fields of type 'u24'
   （0 或 2 的幂次位宽才有 C 兼容布局）
⚠️ packed struct(u32){ a: u24 } 字段装不满背板 → backing integer bit width does not match
==== 25.10 位域与 packed struct 结束 ====
```

那五行"改一个字段看背板"是这一节的精髓——**协议里的"标志位"就是这玩意儿**：

- `enabled` 从 false 改true：`0x0000 → 0x0001`（bit 0）
- `mode` 从 0 改`0b11`：`0x0000 → 0x0006`（`0b11 << 1 = 0x06`，bit 1-2）
- `level` 从 0 改 `0xFF`：`0x0000 → 0xFF00`（bit 8-15，整体搬到高字节）
- 全开`{enabled=true, mode=0b01, reserved=0b11111, level=0xA5}`：`0xA5FB`
  = `0xA500 | 0x00FB`，其中 `0xFB = 0b1111_1011` = reserved 全1（bit3-7）+ mode=`0b01`（bit1-2）+ enabled=1（bit0）

### ⚠️ 重大行为变化：`packed` 字段取地址在 0.17 被允许

旧教程里普遍写着"`packed struct` 的字段不可取地址，`&f.level` 直接编译错"。**这个说法在 0.17 已经不成立。** 实测：

```zig
var f = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
const pb = &f.b;      // ✅ 编译通过
const pd = &f.d;      // ✅ 编译通过
pm.* = 0b11;          // ✅ 往 packed 子字段写也合法
```

而且指针能正常工作——`pm.* = 7` 之后 `f.b == 7`，双向都对。

**但代价是类型变了**。`&fv.mode` 的类型不是 `*u2`，而是 **`*align(2:1:2) u2`**——这个类型 encodes 了三件事：宿主大小 2 字节、bit offset 为 1（`mode` 从 bit 1 开始）、字段宽度 2 位。它不能隐式降级成普通 `*u2`，因为那会丢掉"从 bit 1 开始"这个信息。所以：

```text
pt.zig:7:10: error: expected type '*u2', found '*align(2:1:2) u2'
    take(&f.mode);
         ^~~~~~~
pt.zig:7:10: note: pointer host size '2' cannot cast into pointer host size '0'
pt.zig:7:10: note: pointer bit offset '1' cannot cast into pointer bit offset '0'
pt.zig:3:12: note: parameter type declared here
fn take(p: *u2) u2 { return p.*; }
           ^~~
```

**报错信息里含 bit offset**（`pointer bit offset '1'`）——这是识别"这是 packed 字段指针问题"而不是"普通对齐问题"的标志。普通对齐问题的报错只有 `host size` 那一条。

两种修法：

```zig
// 修法一：显式标注带bit offset 的指针类型
const pm: *align(2:1:2) u2 = &f.mode;
pm.* = 0b11;

// 修法二（更常用）：把整个背板 @bitCast 出来，在整数上操作
const board: u16 = @bitCast(f);
//改 board 的某些位…
const back: Flags = @bitCast(board);
```

修法二更好：因为它是纯整数运算，能用上 `&` `|` `^` `~` 全部位运算符，不会遇到"这个字段跨了字节边界怎么办"的问题。修法一只在"我只想读写这一个字段"时用。

### `packed struct` 的三条硬规则

**规则一：`u24` 在 `packed struct` 里完全合法**（但 `extern struct` 不行，见 25.4）：

```text
size=4 bits=32 a@0 b@3
bitCast=0xAB123456
```

（探针 `pfx.zig`：`T = packed struct(u32) { a: u24, b: u8 }`，`a = 0x123456`、`b = 0xAB`。注意 `@offsetOf(T, "b") == 3` —— `u24` 占了 3 个**字节**，`b` 紧跟在第 3 字节上；而 `@bitCast` 出来的 `0xAB123456` 说明小端机器上 `a` 占了低 24 位。整个结构体的内存面貌就是背板整数本身。）

实测 `packed struct(u32) { a: u24, b: u8 }` 的 `@sizeOf` = 4、`@bitSizeOf` = 32、`@offsetOf(a)` = 0、`@offsetOf(b)` = 3（因为 `a` 占 24 位 = 3 字节）。探针里取 `a = 0x123456`、`b = 0xAB`，`@bitCast` 到 `u32` 得 `0xAB123456`——**`b` 落在高 8 位，`a` 占低 24 位**，位分配顺序和 25.10 开头那张表一致。

**规则二：字段位宽之和必须**恰好**等于背板位宽**。少一位也不行（探针 `pu3.zig`）：

```text
pu3.zig:2:18: error: backing integer bit width does not match total bit width of fields
const T = packed struct(u32) { a: u24 };
          ~~~~~~~^~~~~~~~~~~~~~~~~~~~~~
pu3.zig:2:25: note: backing integer 'u32' has bit width '32'
const T = packed struct(u32) { a: u24 };
                        ^~~
```

**规则三：可以省略背板类型**，但那样 `@sizeOf` 会向上补齐到整数字节。`packed struct { a: u3, b: u3, c: u3 }` 是 9 位，实测 `size=2 bits=9 align=2`——**9 位占了 2 字节**。省不了。

---

## 25.11 位操作：`@popCount` / `@clz` / `@ctz` / `@bitReverse` /旋转

协议解析之外，位操作本身也是日常。0.17 里这些内建函数的实测行为：

```zig
// examples/25_binary/main.zig 第 447-467 行
// ═══ 25.11 位操作 ═══
begin("25.11 位操作 @popCount / @clz / @ctz / @bitReverse / rotl");
const x: u16 = 0b1011_0110_1100_0001;
err.print("x = 0b{x}（{d} 位）\n", .{ x, @bitSizeOf(u16) });
err.print("  @popCount  = {d}（1 的个数；返回类型由位宽推导，不是 usize）\n", .{@popCount(x)});
err.print("  @clz      = {d}（leading zeros，前导零个数）\n", .{@clz(x)});
err.print("  @ctz      = {d}（trailing zeros，尾部零个数）\n", .{@ctz(x)});
err.print("  @bitReverse= 0b{x}（整个字位序翻转）\n", .{@bitReverse(x)});
err.print("  rotl 4    = 0b{x}   rotr 4 = 0b{x}\n", .{
    std.math.rotl(u16, x, 4), std.math.rotr(u16, x, 4),
});
err.print("⚠️ @ctz(0) = {d}（=类型位宽，u8 上是 8）；@popCount(0) = {d}\n", .{ @ctz(@as(u8, 0)), @popCount(@as(u8, 0)) });
err.print("⚠️ 旋转**不是**内建函数：@rotl / @rotr / @rotateLeft 在 0.17 全部 invalid builtin function\n", .{});
err.print("   正解是 std.math.rotl(T, v, n) / std.math.rotr(T, v, n)\n", .{});
err.print("@clz/@ctz 的返回类型 = {s}（u16 → u5，装得下0..16）\n", .{@typeName(@TypeOf(@ctz(x)))});
err.print("实用场景：@ctz 找最低位 1（枚举的位索引），@popCount 数标志位：\n", .{});
const mask: u8 = 0b1001_0110;
err.print("  mask=0b{b:0>8} popCount={d} ctz={d} clz={d}\n", .{
    mask, @popCount(mask), @ctz(mask), @clz(mask),
});
end("25.11 位操作 @popCount / @clz / @ctz / @bitReverse / rotl");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.11 位操作 @popCount / @clz / @ctz / @bitReverse / rotl 开始 ====
x = 0bb6c1（16 位）
  @popCount  = 8（1 的个数；返回类型由位宽推导，不是 usize）
  @clz      = 0（leading zeros，前导零个数）
  @ctz      = 0（trailing zeros，尾部零个数）
  @bitReverse= 0b836d（整个字位序翻转）
  rotl 4    = 0b6c1b   rotr 4 = 0b1b6c
⚠️ @ctz(0) = 8（=类型位宽，u8 上是 8）；@popCount(0) = 0
⚠️ 旋转**不是**内建函数：@rotl / @rotr / @rotateLeft 在 0.17 全部 invalid builtin function
   正解是 std.math.rotl(T, v, n) / std.math.rotr(T, v, n)
@clz/@ctz 的返回类型 = u5（u16 → u5，装得下0..16）
实用场景：@ctz 找最低位 1（枚举的位索引），@popCount 数标志位：
  mask=0b10010110 popCount=4 ctz=1 clz=0
==== 25.11 位操作 @popCount / @clz / @ctz / @bitReverse / rotl 结束 ====
```

### ⚠️ 旋转不是内建函数

这是本章第二个"推翻说法"的点。三个候选名字在 0.17 全部不存在：

```text
pr2.zig:5:32: error: invalid builtin function: '@rotl'
    std.debug.print("{x}\n", .{@rotl(u16, x, 4)});
                               ^~~~~~~~~~~~~~~~
```

```text
error: invalid builtin function: '@rotr'
```

```text
error: invalid builtin function: '@rotateLeft'
```

正解是 **`std.math.rotl(T, v, n)` / `std.math.rotr(T, v, n)`**（注意有类型参数 `T` 在前）。

### 返回类型是"刚好装得下"的那个宽度

`@popCount` / `@clz` / `@ctz` 的返回类型**不是 `usize`**，而是由输入位宽推导的最小无符号整数：

- `u8` 输入 → `u4`（能装 0..8）
- `u16` 输入 → `u5`（能装 0..16）

实测 `@typeName(@TypeOf(@ctz(x)))` = `u5`。这在写测试时很关键——`expectEqual(@as(usize, 4), @ctz(u8_val))` 会**类型不匹配而编译失败**，必须写 `@as(u4, 4)`。

### 边界值：`@ctz(0)` 等于位宽

```text
mask=0b10010110 popCount=4 ctz=1 clz=0
```

`mask = 0x96 = 0b1001_0110`：`@popCount` = 4（四个 1）、`@ctz` = 1（最低位的 1 在 bit 1）、`@clz` = 0（最高位就是 1）。

`@ctz(0)` 返回 **8**（u8 的位宽），不是 0 也不是报错。`@popCount(0)` 返回 0。这两个边界值都写进了测试——因为它们是"我以为会 panic 但其实不会"的典型。

---

## 25.12 `std.mem` 的字节工具箱（逐个实测）

除了 `readInt`/`writeInt`，`std.mem` 里还有一批纯字节操作。逐个实测：

```zig
// examples/25_binary/main.zig 第 469-491 行
// ═══ 25.12 std.mem 的字节工具箱 ═══
begin("25.12 std.mem 字节工具箱（逐个实测）");
var rev8 = [_]u8{ 1, 2, 3, 4, 5 };
std.mem.reverse(u8, &rev8);
err.print("reverse(u8, {{1,2,3,4,5}})     = {x}（就地翻转）\n", .{rev8});
var rev16 = [_]u16{ 0x0102, 0x0304 };
std.mem.reverse(u16, &rev16);
err.print("reverse(u16, {{0x0102,0x0304}}) = {{{d},{d}}}（按元素翻，不是按字节翻）\n", .{ rev16[0], rev16[1] });
var sa: u32 = 0xAAAAAAAA;
var sb: u32 = 0x55555555;
std.mem.swap(u32, &sa, &sb);
err.print("swap(u32)0xAAAAAAAA<->0x55555555 → 0x{X:0>8}, 0x{X:0>8}\n", .{ sa, sb });
err.print("zeroes([4]u8) = {x}   zeroes(u32) = 0x{X:0>8}（全类型都支持）\n", .{
    std.mem.zeroes([4]u8), std.mem.zeroes(u32),
});
const gpa = std.heap.page_allocator;
const cat = try std.mem.concat(gpa, u8, &.{ "ab", "cd", "ef" });
defer gpa.free(cat);
err.print("concat(u8, {{\"ab\",\"cd\",\"ef\"}})  = {s}（len={d}，唯一会分配的那个）\n", .{ cat, cat.len });
const hex = std.fmt.bytesToHex(rev8, .lower);
err.print("std.fmt.bytesToHex(rev8, .lower) = {s}（返回定长数组值拷贝，零分配）\n", .{hex});
err.print("⚠️ std.fmt.fmtSliceHexLower 在 0.17 **不存在**（实测 hasDecl=false）\n", .{});
end("25.12 std.mem 字节工具箱（逐个实测）");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.12 std.mem 字节工具箱（逐个实测） 开始 ====
reverse(u8, {1,2,3,4,5})     = 0504030201（就地翻转）
reverse(u16, {0x0102,0x0304}) = {772,258}（按元素翻，不是按字节翻）
swap(u32)0xAAAAAAAA<->0x55555555 → 0x55555555, 0xAAAAAAAA
zeroes([4]u8) = 00000000   zeroes(u32) = 0x00000000（全类型都支持）
concat(u8, {"ab","cd","ef"})  = abcdef（len=6，唯一会分配的那个）
std.fmt.bytesToHex(rev8, .lower) = 0504030201（返回定长数组值拷贝，零分配）
⚠️ std.fmt.fmtSliceHexLower 在 0.17 **不存在**（实测 hasDecl=false）
==== 25.12 std.mem 字节工具箱（逐个实测） 结束 ====
```

逐个说明：

| 函数 | 签名要点 | 实测要点 |
|---|---|---|
| `std.mem.reverse(T, items)` | `items` 是**可变切片** | 就地翻转。`u8` 翻字节；`u16` **按元素翻**（`{0x0102, 0x0304}` → `{0x0304, 0x0102}` = `{772, 258}`），不是把每个元素内部也翻 |
| `std.mem.swap(T, &a, &b)` | 两个**指针** | 交换两个值 |
| `std.mem.zeroes(T)` | 返回 `T` | 全类型支持（整数、数组、struct…） |
| `std.mem.concat(allocator, T, slices)` | `slices` 是 `[]const []const T` | **本节唯一会分配内存的**。实测 `concat(u8, ...)` 得 `"abcdef"`，`concat(u16, ...)` 得 `{1,2,3}` |
| `std.fmt.bytesToHex(input, .lower/.upper)` | 返回 `[input.len * 2]u8` | 零分配的值拷贝。**只接受 2 个参数**（没有分隔符参数） |

### ⚠️ 三个API 消失

`std.fmt.fmtSliceHexLower` / `fmtSliceHexUpper` / `fmtSliceHex` 在 0.17 全部 `hasDecl == false`。替代品是 `std.fmt.bytesToHex`，而它的签名也变了：

```text
p46.zig:10:60: error: expected 2 argument(s), found 3
    const sep = try std.fmt.bufPrint(&buf, "{s}", .{std.fmt.bytesToHex(b, .lower, ' ')});
                                                    ~~~~~~~^~~~~~~~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/fmt.zig:1140:5: note: function declared here
pub fn bytesToHex(input: anytype, case: Case) [input.len * 2]u8 {
```

**只接受 2 个参数，没有分隔符参数。** 要带分隔符得自己写循环。

---

## 25.13 协议实战：编码 → 十六进制 dump → 解码

现在把前面所有东西拼起来，做一个完整的小协议。

```zig
// examples/25_binary/main.zig 第 66-163 行（节选：常量声明与错误集合，中间 encode/decode 见下）
/// 25.12 协议帧：magic(2) + version(1) + flags(2) + varint 长度 + 载荷 + 校验和
pub const Proto = struct {
    /// 帧最大载荷：定长数组让整个编解码器零分配
    pub const max_payload = 64;
    /// 帧头固定部分：magic(2) + version(1) + flags(2) = 5 字节
    pub const header_len = 5;
    /// magic：协议标识，解码器第一个检查项
    pub const magic: u16 = 0xBEEF;
    /// 当前协议版本
    pub const version: u8 = 1;

    /// 一帧的解码结果：切片指向调用方的缓冲区，零拷贝
    pub const Frame = struct {
        version: u8,
        flags: Flags,
        /// varint 解出来的载荷长度
        len: usize,
        /// 载荷字节（指向输入缓冲区的内部）
        payload: []const u8,
    };

    /// 解码失败的原因集合——每一种都用test 钉住（见 25.13）
    pub const DecodeError = error{
        Truncated,          // 输入比帧头还短
        BadMagic,           // magic 不匹配（不是本协议的数据）
        BadVersion,         // 版本不认识
        BadVarint,          // varint 超过 5 字节或高位全 1 溢出
        LengthOverrun,      // 声明的长度超出剩余字节
        TooLarge,           // 声明的长度超过 max_payload
        ChecksumMismatch,   // 校验和不匹配（传输损坏 / 恶意篡改）
    };

    /// 累加校验和：简单加法，够演示"完整性检查"这件事
    pub fn checksum(bytes: []const u8) u16 {
        var sum: u16 = 0;
        for (bytes) |b| sum +%= b;
        return sum;
    }
```

编码器（**注意每一个 `writeInt` 都显式写了 `.big`**）：

```zig
    pub fn encode(out: []u8, flags: Flags, payload: []const u8) !usize {
        if (payload.len > max_payload) return error.TooLarge;
        var vbuf: [5]u8 = @splat(0);
        const vlen = try putVarint(vbuf[0..], payload.len);
        const need = header_len + vlen + payload.len + 2;
        if (out.len < need) return error.NoSpaceLeft;
        var i: usize = 0;
        std.mem.writeInt(u16, out[i..][0..2], magic, .big); // 网络序（大端）
        i += 2;
        out[i] = version;
        i += 1;
        std.mem.writeInt(u16, out[i..][0..2], @bitCast(flags), .big); // packed → 背板 → 显式端序
        i += 2;
        @memcpy(out[i..][0..vlen], vbuf[0..vlen]); // varint 长度
        i += vlen;
        @memcpy(out[i..][0..payload.len], payload);
        i += payload.len;
        std.mem.writeInt(u16, out[i..][0..2], checksum(out[0..i]), .big);
        i += 2;
        return i;
    }
```

解码器（**每一步都检查边界**，注释里标了检查顺序）：

```zig
    pub fn decode(buf: []const u8) DecodeError!Frame {
        // 1) 帧头都不够
        if (buf.len < header_len) return error.Truncated;
        // 2) magic
        if (std.mem.readInt(u16, buf[0..2], .big) != magic) return error.BadMagic;
        // 3) 版本
        const ver = buf[2];
        if (ver != version) return error.BadVersion;
        // 4) flags（packed struct 的背板往返）
        const flags: Flags = @bitCast(std.mem.readInt(u16, buf[3..5], .big));
        // 5) varint 长度：从偏移 5 开始解，最多 5 字节
        var n: usize = 0;
        const vlen = try getVarint(buf[header_len..], &n);
        // 6) 长度上限（先限上界，再验剩余字节——顺序不能反）
        if (n > max_payload) return error.TooLarge;
        const body = header_len + vlen;
        if (buf.len < body + n + 2) return error.LengthOverrun;
        // 7) 校验和覆盖除末尾2 字节以外的全部内容
        if (std.mem.readInt(u16, buf[body + n ..][0..2], .big) != checksum(buf[0 .. body + n]))
            return error.ChecksumMismatch;
        return .{
            .version = ver,
            .flags = flags,
            .len = n,
            .payload = buf[body..][0..n],
        };
    }
};
```

```zig
// examples/25_binary/main.zig 第 493-520 行
// ═══ 25.13 协议实战：编码 → hex dump → 解码 ═══
begin("25.13 协议实战：编码 → 十六进制 dump → 解码");
err.print("协议布局（全部大端/网络序）：\n", .{});
err.print("  [0..2) magic  u16 = 0x{X:0>4}\n", .{Proto.magic});
err.print("  [2]    version u8  = {d}\n", .{Proto.version});
err.print("  [3..5) flags   u16 = packed struct(u16) 背板\n", .{});
err.print("  [5..)  length  varint（LEB128，1-5 字节）\n", .{});
err.print("  [..n)  payload 载荷 {d} 字节\n", .{Proto.max_payload});
err.print("  [末尾2) checksum u16 = 前面所有字节的 u16 累加和\n", .{});
err.print("定长部分是 {d} 字节 + varint 长度 + 载荷 + 2\n", .{Proto.header_len});

const demo_flags = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
const payload = "hello wire";
var frame: [128]u8 = undefined;
const n = try Proto.encode(&frame, demo_flags, payload);
err.print("\n编码 flags=0x{X:0>4} payload=\"{s}\"（{d} 字节）→ 共 {d} 字节\n", .{
    @as(u16, @bitCast(demo_flags)), payload, payload.len, n,
});
err.print("十六进制 dump：\n", .{});
var dump_buf: [256]u8 = undefined;
err.print("{s}", .{hexDump(dump_buf[0..], frame[0..n], 16)});
const decoded = try Proto.decode(frame[0..n]);
err.print("解码成功：version={d} flags=0x{X:0>4} len={d} payload=\"{s}\"\n", .{
    decoded.version, @as(u16, @bitCast(decoded.flags)), decoded.len, decoded.payload,
});
err.print("payload 是**零拷贝切片**：ptr 在frame 内部，decoded.len = {d}\n", .{decoded.len});
err.print("往返一致 = {}\n", .{std.mem.eql(u8, decoded.payload, payload)});
end("25.13 协议实战：编码 → 十六进制 dump → 解码");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.13 协议实战：编码 → 十六进制 dump → 解码 开始 ====
协议布局（全部大端/网络序）：
  [0..2) magic  u16 = 0xBEEF
  [2]    version u8  = 1
  [3..5) flags   u16 = packed struct(u16) 背板
  [5..)  length  varint（LEB128，1-5 字节）
  [..n)  payload 载荷 64 字节
  [末尾2) checksum u16 = 前面所有字节的 u16 累加和
定长部分是 5 字节 + varint 长度 + 载荷 + 2

编码 flags=0x5A05 payload="hello wire"（10 字节）→ 共 18 字节
十六进制 dump：
  0000  be ef 01 5a 05 0a 68 65 6c 6c 6f 20 77 69 72 65  |...Z..hello wire|
  0010  06 02                                            |..|
解码成功：version=1 flags=0x5A05 len=10 payload="hello wire"
payload 是**零拷贝切片**：ptr 在frame 内部，decoded.len = 10
往返一致 = true
==== 25.13 协议实战：编码 → 十六进制 dump → 解码 结束 ====
```

逐字节读这个 dump（18 字节）：

| 偏移 | 字节 | 含义 |
|---|---|---|
| `0000` | `be ef` | magic = `0xBEEF`（**大端**：高字节在前） |
| `0002` | `01` | version = 1 |
| `0003` | `5a 05` | flags = `0x5A05`（大端）—— packed struct 背板 |
| `0005` | `0a` | length varint = **10**（`0x0A < 0x80`，1 字节搞定） |
| `0006` | `68 65 6c 6c 6f 20 77 69 72 65` | `"hello wire"` 的 ASCII |
| `0010` | `06 02` | checksum = `0x0602`（大端） |

**注意 magic 存成了 `be ef` 而不是 `ef be`**——因为协议规定大端。而 25.5 里同一个 `Record` 通过 `asBytes` 看到的是 `EFBE`（本机小端）。**这就是"同一份数据、两种字节序"的全部区别。**

checksum 可以手算验证：`BE + EF + 01 + 5A + 05 + 0A + 68+ 65 + 6C + 6C + 6F + 20 + 77 + 69 + 72 + 65`，按 u16 累加（溢出丢弃）：

`0xBE + 0xEF = 0x1AD` → `0xAD`
`+ 0x01 = 0xAE`，`+0x5A = 0x108` → `0x08`，`+0x05 = 0x0D`，`+0x0A = 0x17`
`+0x68 = 0x7F`，`+0x65 = 0xE4`，`+0x6C = 0x150` → `0x50`，`+0x6C = 0xBC`，`+0x6F = 0x12B` → `0x2B`，`+0x20 = 0x4B`
`+0x77 = 0xC2`，`+0x69 = 0x12B` → `0x2B`，`+0x72 = 0x9D`，`+0x65 = 0x102` → **`0x0602`** ✓

### `hexDump` 有个坑：不能返回局部数组

第一版 `hexDump` 写成 `fn hexDump(bytes: []const u8, width: usize) [512]u8`，返回完整缓冲区。调用方 `{s}` 打印它——结果输出了 512 字节的**垃圾**（栈上残留数据），hex dump 的两行被淹没在一堆 `�` 里。修法有两个：

```zig
// ✅ 正确：输出缓冲区由调用方提供，返回有效前缀
fn hexDump(out: []u8, bytes: []const u8, width: usize) []const u8 {
    var fbs = std.Io.Writer.fixed(out);
    const w = &fbs;
    // ... 循环写 ...
    return w.buffered();
}
```

```zig
// ❌ 危险：返回"缓冲区 + 长度"两个独立值，调用方很容易用错
fn hexDump2(out: [512]u8, bytes: []const u8) struct { buf: [512]u8, len: usize } { ... }
```

`std.Io.Writer.fixed` 返回的 writer **本身就是那个 buffer 的视图**（实测：`var w = std.Io.Writer.fixed(&buf); w.print(...)` 直接能用，没有 `.interface` 字段——0.17 里 `std.Io.Writer` 没有 `interface` 成员，写 `&fbs.interface` 会报 `no field named 'interface'`）。

---

## 25.14 恶意输入：篡改字节 → 优雅失败

**这是本章的收官节，也是最重要的工程实践。** 一个二进制解析器如果对恶意输入不稳健，它就是个安全漏洞。

```zig
// examples/25_binary/main.zig 第 522-566 行
// ═══ 25.14 篡改字节 → 每种失败都要优雅 ═══
begin("25.14 恶意输入：篡改字节 → 优雅失败");
err.print("逐个篡改/破坏，每种都必须返回**具体的 error**而不是崩溃：\n", .{});
// ⚠️ 关键：`frame[0..n]` 是**切片**，赋值给 var 只是复制指针（别名同一块内存）。
//    写 `var bad = frame[0..n]` 之后改 bad 就是改 frame——后面每一项测的
//    都是被上一项污染过的数据（实测全部报 BadMagic 就是这个坑）。
//    正解：每次用 @memcpy 把干净数据复制进独立的暂存区。
const good = frame[0..n];
var scratch: [128]u8 = undefined;
// 1) 截断
err.print("  截断到 3 字节        → {s}\n", .{@errorName(decodeErr(Proto.decode(good[0..3])))});
// 2) magic 不匹配
@memcpy(scratch[0..n], good);
scratch[0] ^= 0xFF;
err.print("  翻转 magic 首字节    → {s}\n", .{@errorName(decodeErr(Proto.decode(scratch[0..n])))});
// 3) 版本不对
@memcpy(scratch[0..n], good);
scratch[2] = 0x99;
err.print("  版本改 0x99          → {s}\n", .{@errorName(decodeErr(Proto.decode(scratch[0..n])))});
// 4) 篡改载荷但不改校验和
@memcpy(scratch[0..n], good);
scratch[Proto.header_len + 1] ^= 0x01;
err.print("  篡改载荷 1 字节      → {s}（长度仍合法，只能靠校验和抓）\n", .{
    @errorName(decodeErr(Proto.decode(scratch[0..n]))),
});
// 5) 长度字段被改成巨大的值 → 越界
@memcpy(scratch[0..n], good);
scratch[Proto.header_len] = 0x7F; // varint 低 7 位全 1，长度被放大
err.print("  varint 长度改0x7F    → {s}（声明长度超过 max_payload）\n", .{
    @errorName(decodeErr(Proto.decode(scratch[0..n]))),
});
// 6) 篡改 flags（长度不变，校验和失配）
@memcpy(scratch[0..n], good);
scratch[3] ^= 0x01;
err.print("  篡改 flags 高字节    → {s}\n", .{@errorName(decodeErr(Proto.decode(scratch[0..n])))});
// 7) 载荷超过 max_payload：编码器自己先拒
var small: [8]u8 = undefined;
err.print("  encode 载荷 65 字节  → {s}（编码器上界检查）\n", .{
    @errorName(encodeErr(Proto.encode(&small, demo_flags, &oversized_payload()))),
});
// 8) 尾部砍掉 1 字节（校验和不完整）
err.print("  尾部砍掉 1 字节      → {s}\n", .{@errorName(decodeErr(Proto.decode(good[0 .. n - 1])))});
err.print("⇒ 解码器**从不做索引前假设**：每步先验长度，再读字节\n", .{});
err.print("   顺序是「上限检查 → 剩余字节检查 → 内容校验」，反过来会漏\n", .{});
end("25.14 恶意输入：篡改字节 → 优雅失败");
```

运行输出（`examples/25_binary/main.zig`）：

```text
==== 25.14 恶意输入：篡改字节 → 优雅失败 开始 ====
逐个篡改/破坏，每种都必须返回**具体的 error**而不是崩溃：
  截断到 3 字节        → Truncated
  翻转 magic 首字节    → BadMagic
  版本改 0x99          → BadVersion
  篡改载荷 1 字节      → ChecksumMismatch（长度仍合法，只能靠校验和抓）
  varint 长度改0x7F    → TooLarge（声明长度超过 max_payload）
  篡改 flags 高字节    → ChecksumMismatch
  encode 载荷 65 字节  → TooLarge（编码器上界检查）
  尾部砍掉 1 字节      → LengthOverrun
⇒ 解码器**从不做索引前假设**：每步先验长度，再读字节
   顺序是「上限检查 → 剩余字节检查 → 内容校验」，反过来会漏
==== 25.14 恶意输入：篡改字节 → 优雅失败 结束 ====
```

八个失败用例，**八个不同的 error**。这就是"每个错误都值得一个具名 error 值"的意义——调用方能根据错误类型做不同决策（重试 / 跳过 / 断开连接 / 上报）。

### ⚠️ 检查顺序不能反

解码器里三步检查的顺序是**硬要求**：

```
① 声明长度 > max_payload ？  → TooLarge      （上界）
② 剩余字节 >= 声明长度 + 2 ？ → LengthOverrun（够不够）
③ 校验和对得上吗？→ ChecksumMismatch      （内容）
```

**为什么 ① 必须在 ② 之前**：如果先查"剩余字节够不够"，攻击者给一个 `length = 0x7FFFFFFF` 的帧，你会在一个 18 字节的缓冲区上做 `buf.len < body + n + 2` 的加法——`body + n + 2` 在 `usize` 上不会溢出（`n` 是从 varint 解出来的，受 `i >= 5` 限制最大约 2^35），所以不会立刻出事；但如果你**先分配 `n` 字节的缓冲区**（很多解码器会），那就是一次 OOM 攻击。**先限上界能挡掉这一整类。**

**为什么 ③ 在最后**：校验和覆盖整个消息体，在长度还没验证对之前算它没有意义（会白算）。

### ⚠️ 一个真实踩到的坑：切片别名

写这个demo 的第一版时，我用的是：

```zig
// ❌ 错误写法：bad 和 frame 共享内存
var bad = frame[0..n];
bad[0] ^= 0xFF;
// ... 后面 6 项也都用 bad
```

结果**八项全部报 `BadMagic`**——因为 `frame[0..n]` 是切片，`var bad = ` 只是复制了指针，`bad[0] ^= 0xFF` 改的就是 `frame` 本身。后面每一项测试拿到的都是**已经被上一项污染过的 `frame`**。

正确写法两种：

```zig
// ✅ 修法一：@memcpy 到独立暂存区（每次都从干净数据开始）
@memcpy(scratch[0..n], good);
scratch[0] ^= 0xFF;
Proto.decode(scratch[0..n]);

// ❌ 修法二：想用 .* 整体拷贝，但 n 是运行时值
var bad: [128]u8 = frame[0..n].*;
```

修法二在 `n` 是 comptime 已知时才好用。本例 `n` 是运行时值，`frame[0..n]` 的类型是 `[]u8`（切片，长度运行时才定），`.*` 解出来的东西没法赋给定长数组，报错原文（探针 `y.zig`）：

```text
y.zig:5:35: error: expected type '[128]u8', found '[8]u8'
    var bad: [128]u8 = frame[0..n].*;
                       ~~~~~~~~~~~^~
y.zig:5:35: note: destination has length 128
y.zig:5:35: note: source has length 8
```

所以**修法一才是通用的**：`@memcpy` 对"长度是编译期常量"和"长度是运行时值"两种情况都成立，不需要分支。

这个坑的教训很一般：**在 Zig 里，数组的切片赋值是指针别名，不是拷贝。** 只要写 `var x = arr[a..b]`，`x` 就和 `arr` 共享内存。要真拷贝，用 `@memcpy` 或 `. *`（且长度必须 comptime 已知）。

### 用测试钉住每一种失败

```zig
// examples/25_binary/main.zig 第 890-952 行（节选，中间用 // ... 省略了 4 项）
test "协议解码器对恶意输入稳健：每种失败都钉住" {
    const flags = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
    var frame: [128]u8 = undefined;
    const n = try Proto.encode(&frame, flags, "hello wire");
    const good = frame[0..n];
    // ⚠️ 别写`var bad = good` —— 那是**切片别名**，改 bad 就是改 good，
    //    后面每一项测的都是被上一项污染过的数据（这个坑真实踩过一次）。
    var bad: [128]u8 = undefined;
    const reset = struct {
        fn f(dst: []u8, src: []const u8) void {
            @memcpy(dst[0..src.len], src);
        }
    }.f;

    // 1) 空输入 / 截断
    try std.testing.expectError(error.Truncated, Proto.decode(&[_]u8{}));
    try std.testing.expectError(error.Truncated, Proto.decode(good[0..3]));
    try std.testing.expectError(error.Truncated, Proto.decode(good[0 .. Proto.header_len - 1]));

    // 2) magic 不匹配（两种改法都试）
    reset(&bad, good);
    bad[0] ^= 0xFF;
    try std.testing.expectError(error.BadMagic, Proto.decode(bad[0..n]));
    // ...
    // 9) 编码器自己也要挡住超长载荷
    var tiny: [16]u8 = undefined;
    try std.testing.expectError(error.TooLarge, Proto.encode(&tiny, flags, &oversized_payload()));
    // 10) 输出缓冲区不够
    try std.testing.expectError(error.NoSpaceLeft, Proto.encode(&tiny, flags, "abc"));
}
```

`expectError` 是这里的重点：**它断言的是"返回了某个具体 error"，不是"没崩溃"**。这比 try/catch 里吞掉错误强得多——吞掉错误的解析器在测试里也是"通过"的。

### 什么时候用整体 view，什么时候用逐字段

25.13 走的是**逐字段 `writeInt`/`readInt`**。什么时候可以直接用 `bytesToValue` 整体 view（25.6）？

| | 逐字段 `readInt` | 整体 `bytesToValue` |
|---|---|---|
| 跨平台| ✅ 完全可控 | ⚠️ 依赖 `@typeInfo` 的布局稳定性 |
| 对齐要求 | ✅ 无 | ❌ 需要对齐，但不报错 |
| 端序控制 | ✅ 逐字段显式 | ❌ 只能是本机序 |
| 性能 | 逐字段 memcpy | 一次指针转换 |
| 代码量 | 多| 少 |

**规则：协议的首选是逐字段。** 整体 view 只在"这块内存的布局我完全确定"（比如一个 `extern` 声明的 C 结构体、或你自己 `align` 标注过的局部数组）时用。本章 25.6 那个反例——`unaligned ok? .{ .magic = 48879, ...}`——就是整体 view 用错地方的下场。

---

## 25.x 坑位清单

1. **`@bitCast` 在 0.17 拒绝裸结构体**：`error: cannot @bitCast from 'main.Record'`。`extern struct` 不行，普通 `struct` 更不行。**唯一例外是 `packed struct`**（内存表示 = 背板整数）。正解是 `std.mem.asBytes(&v)` + `std.mem.readInt` / `writeInt`（**显式端序**）。

2. **`packed struct` 的字段取地址在 0.17 被允许了**（旧教程说"不可取地址"已过时）。但返回类型是**带 bit offset 的指针**（`*align(2:1:2) u2`），传给 `fn(*u2)` 会编译失败：`expected type '*u2', found '*align(2:1:2) u2` + `note: pointer bit offset '1' cannot cast into pointer bit offset '0'`。**报错里含 bit offset 是识别标志**。修法：显式标注 `*align(2:1:2) u2`，或把背板 `@bitCast` 出来做纯整数运算。

3. **`std.meta.fields` 已彻底废弃**：声明处就是 `pub const fields = @compileError("deprecated in favor of @typeInfo")`——不是"调用时报废弃"，是符号本身编译不过。0.16 教程里的 `for (std.meta.fields(T)) |f| @sizeOf(f.type)` 在 0.17 完全跑不了，换成 `@typeInfo(T).@"struct".field_types`。

4. **`field_types` / `field_names` / `field_attrs` 只能用 `inline for` 遍历**。它们是**平行数组**（0.16 是 `{ name, type }` 结构体数组），元素是类型值，普通 `for` 拿不到。三条要一起遍历就写 `inline for (S.field_names, S.field_types, S.field_attrs) |n, t, a| {...}`。

5. **`@typeInfo(T).@"struct".layout` 的类型是 `std.lang.Type.ContainerLayout`**，不是 `std.builtin.Type.Layout`——后者在 0.17 不存在（`std.builtin.Type` 是 union，写全名报 `union 'lang.Type' has no member named 'Layout'`）。取值 `.auto` / `.@"extern"` / `.@"packed"`。

6. **`@bitSizeOf(extern struct)` 是编译错误**：`error: no bit size available for type 'main.Ext'`。有对齐填充时"占多少位"无定义。只有 `packed struct` 和整数类型能用。

7. **`std.mem.valueToBytes` 在 0.17 不存在**（`hasDecl == false`）。替代品是 `std.mem.toBytes(value)`，它**接受值**（不是指针）并返回 `[N]u8` 值拷贝。同样消失的还有 `std.fmt.fmtSliceHexLower` / `fmtSliceHexUpper` / `fmtSliceHex` → 用 `std.fmt.bytesToHex(input, .lower/.upper)`（**只接受 2 个参数**，没有分隔符参数）。

8. **`asBytes` 返回**带对齐**的指针** `*align(N) [N]u8`（0.16 返回不带 align 的 `*[N]u8`），长度就是 `@sizeOf(T)`，切不出越界。⚠️ `@alignOf(@TypeOf(ab))` 拿到的是**指针自身**的对齐（x86_64 上是 8），问被指数组的对齐要用 `@typeInfo(@TypeOf(ab)).pointer.attrs.@"align"`——注意字段名是 `@"align"`（关键字要转义）。

9. **`bytesToValue` 对齐不过关时**不报错**，直接给你一个错读的值。实测 `unaligned ok? .{ .magic = 48879, .v = 1, ... }`（无 `align` 标注的字节数组照样成功）。原因是 `bytesAsValue` 的实现就是 `@ptrCast` + `CopyPtrAttrs`，**只保留不提高**传入指针的对齐。旧文档说"它会当场报错"是错的。→ 协议解析走`readInt`。

10. **`readInt` / `writeInt` 的数组长度 N 必须精确等于 `sizeof(T)`**（由 `@divExact(@typeInfo(T).int.bits, 8)` 推导，你不能自己指定）。给 8 字节读 `u32` → `expected type '*const [4]u8', found '*const [8]u8'`。`u24` 合法但要正好 3 字节。从**切片**读要写 `sl[off..][0..4]`（把长度变成 comptime 已知），直接传 `sl[off..]` 报`coercion from slice to array pointer type requires length to be known at compile-time`。

11. **旋转不是内建函数**：`@rotl` / `@rotr` / `@rotateLeft` / `@bitRotateLeft` 在 0.17 全是 `error: invalid builtin function`。正解是 `std.math.rotl(T, v, n)` / `std.math.rotr(T, v, n)`（**类型参数 `T` 在前**）。

12. **`@popCount` / `@clz` / `@ctz` 的返回类型不是 `usize`**，而是由输入位宽推导的最小宽度（`u8` → `u4`，`u16` → `u5`）。写测试必须 `expectEqual(@as(u4, 4), @ctz(u8_val))`——写成 `@as(usize, 4)` 会类型不匹配。⚠️ 边界值：**`@ctz(0)` 等于位宽**（u8 上是 8），`@popCount(0)` 是 0。

13. **`packed struct(u32) { a: u24, b: u8 }` 合法**，但 `extern struct { a: u24 }` 编译失败：`extern structs cannot contain fields of type 'u24'` / `note: only integers with 0 or power of two bits are extern compatible`。**两个布局的位宽规则正好相反。** 另外 `packed struct(u32) { a: u24 }` 会报`backing integer bit width does not match total bit width of fields`——字段位宽之和必须**恰好**等于背板位宽。

14. **LEB128 的 `shift` 变量类型是 `u6`**（7 位一组，最多 10 组，`7 * 9 = 63` 需要 6 位）。写成 `u5` 在 64 位值上溢出。解码必须两道防线：`i >= 5`（字节数上限）+ `i >= src.len`（数据够不够），**顺序不能反**。⚠️ std 里没有 varint（`@hasDecl(std, "varint") == false`），必须手写。

15. **`var x = arr[a..b]` 是切片别名，不是拷贝**。写 demo 时踩过：`var bad = frame[0..n]; bad[0] ^= 0xFF;` 改的就是 `frame` 本身，导致后面 6 项测试全部基于被污染的数据、全报 `BadMagic`。正解是 `@memcpy(scratch[0..n], good)`。注意 `frame[0..n].*` 在 `n` 是运行时值时也编译不过（`index syntax required to access runtime-known slice`）。

16. **`std.Io.Writer` 在 0.17 没有 `interface` 成员**：`var fbs = std.Io.Writer.fixed(&out); const w = &fbs.interface;` → `error: no field named 'interface' in struct 'Io.Writer'`。`fixed` 返回的 writer **本身就是缓冲区视图**，直接 `var w = std.Io.Writer.fixed(&buf); w.print(...)` 即可，`w.buffered()` 取有效前缀。**函数不要返回"局部数组 + 长度"**——要么让调用方提供缓冲区，要么返回调用方缓冲区的切片。

17. **`{` 在格式串里是占位符**。写协议布局说明时 `readInt(u32, &[_]u8{8字节})` 里的 `{8字节}` 会被当成格式占位符，报 `error: too few arguments` / `error: unused argument`。字面 `{` 要写 `{{`、`}}`。

18. **`@typeInfo(...).pointer.attrs.@"align"` 是 `?usize`，不能直接用 `{d}` 打印**：`err.print("{d}", .{@typeInfo(@TypeOf(ab)).pointer.attrs.@"align"})` 编译失败，报 `error: invalid format string 'd' for type '?usize'`（`lib/std/Io/Writer.zig:1935`）。要么写 `.?` 先解包，要么像示例那样直接打 `@alignOf(T)`（编译期常量，结果相同）。

19. **`{}` 覆盖数组会按元素类型逐个打印**：`err.print("{{{d},{d}}}", .{rev16[0], rev16[1]})` 对 `u16` 数组会打成十进制 `{772, 258}` 而不是 `0x0304, 0x0102`。想看十六进制得显式 `{X:0>4}`。

20. **混合行尾会传染源码**：示例仓库 `.zig` 统一 LF（`.gitattributes` 已钉死）。Windows autocrlf 检出成 CRLF 后 `zig fmt --check` 整文件挂，混合行尾只报部分行，更迷惑（本教程实测踩过：25–34 批次一次终验被 11/21/22 三章的旧 CRLF 绊停）。

---

## 导航

上一章：[24 实战：迷你 grep](24-minigrep.md) ·下一章：[26 编码与流处理](26-encoding.md)
