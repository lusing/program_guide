# 06 · 数组、切片与字符串

> 对应示例：`examples/06_slices/main.zig`
>
> Zig 没有 `string` 类型，也没有 C 那种"数组名即指针"的退化规则。这一章要建立的认知是：
> **Zig 把"一块内存"和"对这块内存的视图"拆成了两套类型**——数组 `[N]T` 是值（长度进类型），
> 切片 `[]T` 是胖指针（指针 + 长度），指针 `*T` 则是"指向一个元素"的最强表达。
> 读完你应该能自己回答：为什么 `sum(arr)` 编译不过而 `sum(&arr)` 行，为什么 `"你好".len` 是 12 而不是 2。

---

## 6.1 数组 `[N]T`：长度是类型的一部分

```zig
// examples/06_slices/main.zig 第 63-87 行
const arr = [_]i32{ 10, 20, 30, 40, 50 }; // [_] 让编译器数个数，等价 [5]i32
var copy = arr; // 数组是**值**：赋值 = 整块拷贝
copy[0] = -1;
std.debug.print("arr={any}  copy={any}  （改 copy 不影响 arr）\n", .{ arr, copy });
std.debug.print("arr.len={d}  @sizeOf={d}  类型={s}\n", .{
    arr.len, @sizeOf(@TypeOf(arr)), @typeName(@TypeOf(arr)),
});
// [5]i32 与 [6]i32 是**两个不同的类型**，不能互换、不能传同一个函数
const six = [_]i32{ 1, 2, 3, 4, 5, 6 };
std.debug.print("arr 与 six 同类型？{}（长度进类型，必然false）\n", .{
    @TypeOf(arr) == @TypeOf(six),
});
// 数组不能直接传给收[]const T 的函数：sum(arr) 编译错（length comptime 6 doesn't match）
// ——但 &arr / arr[0..] 可以。数组 → 数组指针 → 切片是自动的两步。
const as_slice: []const i32 = &arr;
std.debug.print("&arr 退化成切片后类型={s} len={d} sum={d}\n", .{
    @typeName(@TypeOf(as_slice)), as_slice.len, sum(as_slice),
});
// 嵌套数组：数组的数组，仍然是一块连续内存
const mat = [2][3]i32{ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
std.debug.print("mat[1][2]={d}  @sizeOf={d}（[2][3]i32 是 24 字节连续块）\n", .{
    mat[1][2], @sizeOf(@TypeOf(mat)),
});
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.1 开始 ====
arr={ 10, 20, 30, 40, 50 }  copy={ -1, 20, 30, 40, 50 }  （改 copy 不影响 arr）
arr.len=5  @sizeOf=20  类型=[5]i32
arr 与 six 同类型？false（长度进类型，必然false）
&arr 退化成切片后类型=[]const i32 len=5 sum=150
mat[1][2]=6  @sizeOf=24（[2][3]i32 是 24 字节连续块）
==== 6.1 结束 ====
```

**① 数组是值类型，赋值就是整块拷贝。** 这和 C 完全不同——C 里 `int a[5]; int b[5]; b = a;` 连编译都过不了，而 `int b[5]; int *p = a;` 又是另一个意思。Zig 把这三件事分得干干净净：数组是"一个东西"（可以赋值、可以传参、就是内存本身），指针是"指向某物"（另一个东西）。想避免拷贝就显式写 `&arr` 或 `arr[0..]`，**这个决定永远由你做出，不被语言规则隐藏**。

**② 长度进类型，所以 `[5]i32` 和 `[6]i32` 是两个类型。** 输出第 4 行 `arr 与 six 同类型？false` 就是这条规则最直白的证据。它带来一个实际后果：不能写一个"任意长度数组"的函数——`fn f(a: [5]i32)` 收不了 `[6]i32`。Zig 的答案是"用切片"（6.4 节），因为长度的信息量恰好就是切片 `len` 字段携带的东西。

**③ 数组不能直接传给收切片的函数，必须写 `&`。** 这是实测最容易撞的一堵墙：

```text
main.zig:364:56: error: array literal requires address-of operator (&) to coerce to slice type '[]const i32'
    std.debug.print("sum({any}) = {d}\n", .{ nums, sum(nums) });
                                                       ^~~~
```

注意报错措辞里的 **"array literal"** ——编译器把你写的 `nums` 当成"数组字面量"看待。修法就是 `sum(&nums)`。为什么语言要这么设计？因为"传数组"（拷贝 24 字节）和"传切片"（传 16 字节胖指针）是**性能差异巨大**的两个操作，语言不该替你猜。

**④ 嵌套数组仍然是一块连续内存。** `@sizeOf([2][3]i32) = 24`，和 `[6]i32` 一样大，没有每行额外的指针或元数据。这一点在 6.6 节会反过来咬人（多维数组没法一步摊平成 `[]u8`）。

## 6.2 编译期数组：`++` 拼接、`repeat()` 重复、`@splat`

0.17 移除了 `**` 运算符，所以"把值重复 n 份"必须换写法。这是本章第一个必须面对的迁移点：

```text
// 老教程的 "ab" ** 3 在 0.17：
error: binary operator '*' has whitespace on one side, but not the other
```

报错文案有点误导——编译器把 `**` 解析成了两个 `*`，然后抱怨空格不对称。替代品有三种，本节全部实测：

```zig
// examples/06_slices/main.zig 第 90-106 行
const part_one = [_]i32{ 1, 2, 3, 4 };
const part_two = [_]i32{ 5, 6, 7, 8 };
const all = part_one ++ part_two; // 编译期拼接（0.17 保留 ++）
std.debug.print("part_one ++ part_two = {any}  类型={s}\n", .{ all, @typeName(@TypeOf(all)) });
// ⚠️ 0.17 移除了 `**`："ab" ** 3 会报 binary operator '*' has whitespace on one side。
const pattern = "ab" ++ "ab" ++ "ab"; // 等价替代
const sp: [4]u8 = @splat(7); // 数组重复填充：0.17 替代 [_]u8{0} ** 4
std.debug.print("\"ab\"++\"ab\"++\"ab\" = {s}（类型 {s}）\n", .{ pattern, @typeName(@TypeOf(pattern)) });
std.debug.print("@splat(7) : [4]u8 = {any}\n", .{sp});
const zeroes = repeat(u16, 4, 0); // 自己写的 comptime 重复
std.debug.print("repeat(u16, 4, 0) = {any}  类型={s}\n", .{ zeroes, @typeName(@TypeOf(zeroes)) });
const ruled = repeatStr(3, "ab"); // 字符串重复版
std.debug.print("repeatStr(3, \"ab\") = {s}  类型={s}\n", .{ ruled, @typeName(@TypeOf(ruled)) });
const zh2 = repeatStr(2, "中"); // 多字节字符重复也正确（按字节切，s.len 已是字节数）
std.debug.print("repeatStr(2, \"中\") = {s}  .len={d}（字节数，不是字符数）\n", .{ zh2, zh2.len });
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.2 开始 ====
part_one ++ part_two = { 1, 2, 3, 4, 5, 6, 7, 8 }  类型=[8]i32
"ab"++"ab"++"ab" = ababab（类型 *const [6:0]u8）
@splat(7) : [4]u8 = { 7, 7, 7, 7 }
repeat(u16, 4, 0) = { 0, 0, 0, 0 }  类型=[4]u16
repeatStr(3, "ab") = ababab  类型=*const [6:0]u8
repeatStr(2, "中") = 中中  .len=6（字节数，不是字符数）
==== 6.2 结束 ====
```

三种替代方案的分工很清晰：**`++` 拼接两个已有序列**（结果长度是两者之和，`[4]i32 ++ [4]i32 → [8]i32`）；**`@splat(x)` 填充一个标量**（`{ 7, 7, 7, 7 }`，0.17 里 `[_]u8{0} ** 4` 的正确替代）；**`repeat()` 处理任意情况**（尤其"重复一个已经算出来的数组"）。

### `repeat()` 为什么值得写

```zig
// examples/06_slices/main.zig 第 12-20 行
/// 6.2 节的 `repeat()`：0.17 起 `**` 运算符已被移除（`"ab" ** 3` 现在被解析成两个 `*`，
/// 直接编译错；`[_]T{x} ** n` 重复填充语法也没了，改用 `@splat(x)`）。
/// 这个函数是替代方案之一，也是 comptime 最典型的用法：参数全comptime、函数体被编译器
/// 真正执行一遍、结果烘进二进制——运行期没有一行代码。
fn repeat(comptime T: type, comptime n: usize, v: T) [n]T {
    var out: [n]T = undefined;
    for (&out) |*e| e.* = v;
    return out;
}
```

这个函数是**0.17 迁移留下的产物**（原本是为了替代被移除的 `**` 写的），但它同时是 comptime 最该被理解的一个例子，值得逐行拆开看：

- **`comptime T: type`** —— `T` 是"类型本身"作为参数（03 章 3.8 节的 `kindName` 同一手法）。因为它是 comptime，编译器会对`repeat(u16, ...)` 和 `repeat(u8, ...)` **各生成一份专门化的代码**，而不是在运行期做类型判断。
- **`comptime n: usize`** —— 长度在编译期已知，于是 `var out: [n]T` 的栈空间可以静态分配、循环次数可以静态展开。
- **`v: T` 不是 comptime** —— 但无所谓，因为函数整体在编译期求值，`v` 的实参（`0` 或 `7`）也是编译期常量。
- **返回值是 `[n]T` 而不是 `[]T`** —— 类型里带着长度，调用方拿到的仍是数组，能当定长缓冲区用。这是"comptime 计算 + 运行期类型"能同时拿到的最好结果。

一句验证：`repeat(u16, 4, 0)` 在输出里是 `{ 0, 0, 0, 0 }`，**二进制里没有任何循环**。这就是 comptime 的全部意义：把"能提前算的算掉"，而不是"运行时更快一点"。

### `repeatStr()`：字符串重复，以及一个真实的悬空指针陷阱

字符串重复没法用 `++` 表达（次数要动态拼），也没法用 `@splat`（`"ab"` 不是一个 `u8`），所以得自己写：

```zig
// examples/06_slices/main.zig 第 22-38 行
/// 6.2 节的 `repeatStr()`：字符串重复版，返回 `*const [N:0]u8`（哨兵数组指针）。
///
/// ⚠️ 两个实测出来的关键点（0.17.0/x86_64-macos）：
/// 1. 局部 `const buf` 的地址要return 出去，必须让整个初始化块在**编译期**求值
///    （写 `comptime blk: { ... }`）。只写普通 `blk:` 时，`buf` 是运行期栈变量，
///    函数返回后地址悬空——编译器**不报错**，实测打印出乱码。
/// 2. 哨兵槽（第 `n*s.len` 字节）必须真的是 0。用 `@splat(0)` 初始化最省事；
///    若用 `undefined` 再靠循环填，前`n*s.len` 个字节对了、哨兵槽是脏的。
fn repeatStr(comptime n: usize, comptime s: []const u8) *const [n * s.len:0]u8 {
    const buf: [n * s.len:0]u8 = comptime blk: {
        var b: [n * s.len:0]u8 = @splat(0); // 0.17 替代 `[_]u8{0} ** n`
        var k: usize = 0;
        while (k < n * s.len) : (k += 1) b[k] = s[k % s.len];
        break :blk b;
    };
    return &buf;
}
```

**⚠️ 写这一节时实测踩到的最严重的一个坑，值得单独讲。** 函数返回 `&buf`（局部 `const` 的地址）。直觉上这在 Zig 里是合法的——`const` 局部量如果地址被取，编译器通常会把它提升到静态存储。但**这里有个决定性的细节**：提升只发生在"该值是编译期常量"的情况下。

我先写成普通块（`const buf: [...] = blk: { ... };`，块本身不是 comptime），编译**完全通过**，`zig test` 也通过，但运行输出是这样的：

```text
v2 raw={ 207, 179, 184, 247, 127, 0 }      ← 内存是脏的
v2 s  =[ϳ��]                          ← {s} 打印出乱码
```

而同一个文件里，**只要把块标成 `comptime blk:`**，输出立刻正确且连跑 5 次 md5 完全一致：

```text
r1 raw={ 97, 98, 97, 98, 97, 98 }
r1 s  =[ababab]
```

差别在于：普通块里 `b` 是**运行期栈变量**，`&buf` 就是栈地址，函数返回后那块栈已经被复用/回收——**这是静默的 use-after-free，编译器不报错、测试不失败、只有输出是乱的**。标成 `comptime` 之后，`buf` 成了编译期常量，地址指向静态区，才真正安全。

**教训**：在 Zig 里"返回局部 `const` 的地址"不是无条件安全的。判断标准是**这个值是否在编译期完全确定**——不确定时，编译器有时会拦住你（报 `returning address of expired local variable`，例如 6.3 节的哨兵切片例子），有时**不会**。所以本教程的纪律是：**编译期构造 + 返回地址，一律显式写 `comptime` 块**。

**第二个细节是哨兵槽。** `[n * s.len:0]u8` 有 `n*s.len + 1` 个槽，循环只填前 `n*s.len` 个。如果初始化写`undefined`：

```zig
var b: [n * s.len:0]u8 = undefined;   // 哨兵槽是脏的！
inline while (k < n * s.len) : (k += 1) b[k] = s[k % s.len];
```

实测 `{any}` 打印出 `{ 97, 98, 97, 98, 97, 98 }`（前 6 字节都对），但 `b[6]` 是 `170` 而不是 `0`。用 `@splat(0)` 初始化就一步到位——**哨兵类型的数组，初始化就该用 `@splat(0)`**，这是 0.17 没有 `[_]u8{0} ** n` 之后最顺手的写法。

输出第 6 行还顺带印证了 6.8 节的主题：`repeatStr(2, "中")` 的 `.len=6`，两个汉字是6 个**字节**。因为 `s.len` 本身就是字节数，按字节取模天然正确，多字节字符不需要任何特殊处理。

## 6.3 哨兵数组 `[N:0]T` 与哨兵切片 `[:0]T`

"哨兵"就是在类型里写明"末尾还有一个特定值的槽位"。这是与 C 字符串互操作的地基（17 章）。

```zig
// examples/06_slices/main.zig 第 109-139 行
const sent = [_:0]u8{ 1, 2, 3, 4 }; // 声明 4 个元素 + 1 个哨兵槽
std.debug.print("哨兵数组 类型={s}  len={d}  但 @sizeOf={d}（N+1 个槽）\n", .{
    @typeName(@TypeOf(sent)), sent.len, @sizeOf(@TypeOf(sent)),
});
std.debug.print("sent[3]={d}  sent[4]={d}（len 处的哨兵，可以安全读）\n", .{ sent[3], sent[4] });
// 字面量天生就是哨兵数组指针
const lit = "Zig";
std.debug.print("字面量 类型={s}  @sizeOf={d}（3 字节 + 1 哨兵，末尾对齐到 4）\n", .{
    @typeName(@TypeOf(lit)), @sizeOf(@TypeOf(lit)),
});
std.debug.print("lit.len={d}  lit[3]={d}\n", .{ lit.len, lit[3] });
//哨兵切片：长度在运行期，末尾哨兵由类型保证
const cs: [:0]const u8 = "Elixir";
std.debug.print("哨兵切片 类型={s}  len={d}  cs[6]={d}\n", .{
    @typeName(@TypeOf(cs)), cs.len, cs[cs.len],
});
// 运行时构造：切一个带哨兵的子切片`s[a..b :c]`
var buf = [_]u8{ 'h', 'e', 'l', 'l', 'o', 0, 0 };
const sub: [:0]u8 = buf[0..5 :0]; // 第 5 字节确实是 0，才允许这么切
std.debug.print("buf[0..5 :0] = {s}  len={d}  sub[5]={d}\n", .{ sub, sub.len, sub[sub.len] });
// ⚠️ 声称的哨兵位置不是 0 会被抓住：
//   buf[0..3 :0]                  → error: value in memory does not match slice sentinel
//                                   note: expected '0', found '108'
std.debug.print("buf[3]={d}不是0，所以 buf[0..3 :0] 编译期就被拒绝\n", .{buf[3]});
// 哨兵切片 → 哨兵数组指针（长度必须编译期已知）
const sap = sub[0..5 :0];
std.debug.print("哨兵切片再取地址 类型={s}（与哨兵切片不是一回事）\n", .{
    @typeName(@TypeOf(sap)),
});
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.3 开始 ====
哨兵数组 类型=[4:0]u8  len=4  但 @sizeOf=5（N+1 个槽）
sent[3]=4  sent[4]=0（len 处的哨兵，可以安全读）
字面量 类型=*const [3:0]u8  @sizeOf=8（3 字节 + 1 哨兵，末尾对齐到 4）
lit.len=3  lit[3]=0
哨兵切片 类型=[:0]const u8  len=6  cs[6]=0
buf[0..5 :0] = hello  len=5  sub[5]=0
buf[3]=108不是0，所以 buf[0..3 :0] 编译期就被拒绝
哨兵切片再取地址 类型=*[5:0]u8（与哨兵切片不是一回事）
==== 6.3 结束 ====
```

**`[N:0]T` 和 `[:0]T` 是两个不同的东西。** 前者长度进类型（`[4:0]u8`，编译期就知道是 4 个元素 + 1 哨兵，占 5 字节）；后者长度在运行期（`[:0]const u8`，`len` 是 `usize`，但类型保证 `s[s.len] == 0`）。输出第 1 行的 `@sizeOf=5` 和第 3 行的 `@sizeOf=8` 也提醒了一件事：哨兵槽是**真实的内存**，而且为了对齐还会被补齐（`"Zig"` 是 3 字节 + 1 哨兵 = 4，但 `u8` 数组对齐是 1，为什么 8？——因为它的类型是 `*const [3:0]u8`，**指针**本身是 8 字节，对齐按指针算）。

**字符串字面量天生就是哨兵数组指针**：`*const [3:0]u8`。这个类型把三件事一次性说清了：指向一个 3 元素的数组、末尾有 0 哨兵、且只读。任何需要 `[]const u8` 的地方它都能自动退化过去。

**`s[a..b :c]` 是哨兵切片的构造语法**，冒号后的 `0` 是"声称第 `b` 字节是哨兵"。编译器会去**实际检查**那个字节：

```text
error: value in memory does not match slice sentinel
note: expected '0', found '108'
```

`108` 是 `'l'`——因为 `buf = "hello"`。这和 03 章 3.8 节 `@typeInfo` 的 `field_names`（`[:0]const u8` 元素）是**同一个报错**，来自同一套 sentinel 校验机制。

⚠️ 但要注意哨兵子切片的结果类型：因为 `0..5` 是编译期字面量，`sub[0..5 :0]` 得到的是 **`*[5:0]u8`（哨兵数组指针）**，不是哨兵切片 `[:0]u8`（输出第 8 行印证）。想拿到哨兵切片，得让长度在运行期才知道。这和 6.5 节讲的是同一条规律。

## 6.4 切片 `[]T`：胖指针（指针 + 长度）

```zig
// examples/06_slices/main.zig 第 142-165 行
std.debug.print("@sizeOf: *u8={d}  [*]u8={d}  []u8={d}  [:0]u8={d}  [5]u8={d}  usize={d}\n", .{
    @sizeOf(*u8), @sizeOf([*]u8), @sizeOf([]u8), @sizeOf([:0]u8), @sizeOf([5]u8), @sizeOf(usize),
});
std.debug.print("→ 切片 {d} 字节 = 指针({d}) + 长度({d})，64 位机器上正好两个机器字\n", .{
    @sizeOf([]u8), @sizeOf(usize), @sizeOf(usize),
});
var stones = [_]u16{ 42, 17, 93, 58, 11, 99 };
const full: []u16 = &stones; // 数组整体退化成切片（不拷贝）
// 不打印 full.ptr 的绝对地址（每次运行都不同，ASLR）——只打印可复现的关系
std.debug.print("full.len={d}  full.ptr 与 &stones 同一地址？{}（切片不拷贝内存）\n", .{
    full.len, full.ptr == &stones,
});
full[0] = 43; // 通过切片改数组
std.debug.print("full[0]=43 后 stones[0]={d}（同一块内存）\n", .{stones[0]});
// 切片只是"视图"：它自己不能被索引到长度之外，也不管底层活多久
const mid = full[1..3];
std.debug.print("full[1..3] = {any}  len={d}  类型={s}\n", .{
    mid, mid.len, @typeName(@TypeOf(mid)),
});
std.debug.print("mid.ptr 偏移量 = {d} 字节（相对 full.ptr）\n", .{
    @intFromPtr(mid.ptr) - @intFromPtr(full.ptr),
});
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.4 开始 ====
@sizeOf: *u8=8  [*]u8=8  []u8=16  [:0]u8=16  [5]u8=5  usize=8
→ 切片 16 字节 = 指针(8) + 长度(8)，64 位机器上正好两个机器字
full.len=6  full.ptr 与 &stones 同一地址？true（切片不拷贝内存）
full[0]=43 后 stones[0]=43（同一块内存）
full[1..3] = { 17, 93 }  len=2  类型=*[2]u16
mid.ptr 偏移量 = 2 字节（相对 full.ptr）
==== 6.4 结束 ====
```

**"胖指针"这个名字来自尺寸对比。** 输出第 1 行把五种类型排在一起：`*u8` 和 `[*]u8` 都是 8 字节（只有一个地址），`[]u8` 和 `[:0]u8` 都是 **16 字节**（地址 + 长度，正好两个 64 位机器字）。多出来的 8 字节就是 `len`——**这份长度信息是安全边界的全部来源**。

**切片是视图，不拥有内存。** `full.ptr == &stones` 为 `true` 证明退化过程零拷贝；`full[0] = 43` 之后 `stones[0]` 也变成 43，证明它们指向同一块内存。这两面合起来就是"借用视图"的完整含义。

⚠️ **由此产生的第一个坑是生命周期**：切片不延长底层内存的寿命。函数里写 `var buf: [10]u8 = ...; return &buf;` 返回的不是堆内存，是**已经被回收的栈**——运行时安全检查通常抓得到，但栈上重用会让它读到别的数据。**要返回就返回堆分配的，或者返回调用方传进来的缓冲**（11 章会系统讲分配器）。

`mid.ptr 偏移量 = 2 字节` 是 `full[1..3]` 的直接后果：`u16` 每个 2 字节，跳 1 个元素就是偏移 2 字节。这也是为什么子切片是O(1) 操作——**只改指针和长度，不动数据**。

⚠️ 注意输出最后一行：`full[1..3]` 的类型是 **`*[2]u16`（数组指针）不是 `[]u16`**。这是 6.5 节的主题，本节先记住这个反常现象。

## 6.5 子切片：编译期边界 vs 运行期边界

```zig
// examples/06_slices/main.zig 第 168-203 行
const stones2 = [_]u16{ 42, 17, 93, 58, 11, 99 };
// 三种写法
const left = stones2[0..2]; // s[a..b]：左闭右开
const right = stones2[4..]; // s[a..]：从a 到尾
const all_of_it = stones2[0..]; // s[a..] 里 a=0
std.debug.print("stones2[0..2] = {any}  类型={s}（编译期已知 → **数组指针**）\n", .{
    left, @typeName(@TypeOf(left)),
});
std.debug.print("stones2[4..]  = {any}  类型={s}（长度 = 6-4 编译期可知，也是数组指针）\n", .{
    right, @typeName(@TypeOf(right)),
});
std.debug.print("stones2[0..]  = {any}  类型={s}\n", .{ all_of_it, @typeName(@TypeOf(all_of_it)) });
// ⚠️ 这是本节最容易踩的坑：边界是编译期字面量时，结果**不是切片而是数组指针**。
//好处是长度进类型、能当定长缓冲区用；坏处是有时不能直接传 []const T。
std.debug.print("注意类型差别：{s} vs {s}\n", .{
    @typeName(@TypeOf(left)), @typeName(@TypeOf(full)),
});
// 运行期边界 → 真切片
var arr_rt = [_]u8{ 10, 20, 30, 40, 50 };
var lo: usize = 1;
var hi: usize = 4;
_ = &lo; // 告诉编译器"我假装不知道这个值"
_ = &hi;
const rt = arr_rt[lo..hi];
std.debug.print("运行期 arr_rt[lo..hi] = {any}  len={d}  类型={s}\n", .{
    rt, rt.len, @typeName(@TypeOf(rt)),
});
// 想在运行期切、但想要数组指针：长度必须写死
const fixed3 = arr_rt[1..4];
std.debug.print("arr_rt[1..4] = {any}  类型={s}\n", .{ fixed3, @typeName(@TypeOf(fixed3)) });
// 越界是运行期 panic，不是静默越界
std.debug.print("rt.len={d}，写 rt[{d}] 会 panic（index out of bounds）——本例不触发\n", .{
    rt.len, rt.len,
});
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.5 开始 ====
stones2[0..2] = { 42, 17 }  类型=*const [2]u16（编译期已知 → **数组指针**）
stones2[4..]  = { 11, 99 }  类型=*const [2]u16（长度 = 6-4 编译期可知，也是数组指针）
stones2[0..]  = { 42, 17, 93, 58, 11, 99 }  类型=*const [6]u16
注意类型差别：*const [2]u16 vs []u16
运行期 arr_rt[lo..hi] = { 20, 30, 40 }  len=3  类型=[]u8
arr_rt[1..4] = { 20, 30, 40 }  类型=*[3]u8
rt.len=3，写 rt[3] 会 panic（index out of bounds）——本例不触发
==== 6.5 结束 ====
```

**本章最反直觉的一条规则**：**切片的编译结果取决于边界是否编译期已知。**

| 写法 | 边界 | 结果类型 |
|---|---|---|
| `stones2[0..2]` | 都是字面量 | `*const [2]u16` 数组指针 |
| `stones2[4..]` | 字面量（长度 6-4 也能算） | `*const [2]u16` 数组指针 |
| `stones2[0..]` | 同上 | `*const [6]u16` 数组指针 |
| `arr_rt[lo..hi]` | 运行期 `var` | `[]u8` **切片** |
| `arr_rt[1..4]` | 字面量 | `*[3]u8` 数组指针 |

C 里根本没有这个区别（`arr[0..2]` 语法都不一样）。Zig 的逻辑是：**能用编译期信息换更强的类型，就用**。知道长度是 2，那 `*const [2]u16` 显然比 `[]u16` 更有用——它能当 `fn f(x: [2]u16)` 的参数、长度进类型不会被改坏。所以语言自动选了它。

**这个"自动"有时会碍事**：`expectEqualStrings(got, ct)` 要求 `[]const u8`，传 `*const [5]u8` 会报 `expected type '[]const u8', found '*const *[5:0]u8'`（实测踩到）。这时写 `ct[0..ct.len]` 显式转成切片即可。

**`_ = &lo;` 这个小技巧值得记住。** `var lo: usize = 1;` 虽然写了 `var`，但编译器知道它从没被改过，值是编译期已知的。要让边界真正在运行期，必须"骗"编译器——取它的地址（`_ = &lo;`）迫使它落到内存里。实测加上这两行之后，`arr_rt[lo..hi]` 的类型就是 `[]u8`。

**越界是 panic 不是静默**：`rt[3]` 在 Debug/ReleaseSafe 下报 `index out of bounds` 并带上源码行号。C里同样的越界是未定义行为——可能安静地改坏别的变量。这条安全网是 Zig 默认开启的（02 章 2.5 节的 `runtime_safety`）。

## 6.6 切片 ↔ 数组 ↔ 数组指针 互转

```zig
// examples/06_slices/main.zig 第 206-239 行
var nums = [_]i32{ 1, 2, 3, 4, 5, 6 };
// 数组 → 数组指针
const ap: *[6]i32 = &nums;
// 数组指针 → 切片（长度从指针类型里来，自动）
const ap_to_slice: []i32 = ap;
std.debug.print("&nums : *[6]i32（{d} 字节）→ 切片 []i32（{d} 字节），len={d}\n", .{
    @sizeOf(@TypeOf(ap)), @sizeOf([]i32), ap_to_slice.len,
});
// 数组指针切出更小的数组指针（长度编译期已知）
const head3: *[3]i32 = ap[0..3];
std.debug.print("ap[0..3] = {any}  类型={s}\n", .{ head3.*, @typeName(@TypeOf(head3)) });
// 切片 → 数组指针：长度必须对得上
const back: *[3]i32 = ap_to_slice[0..3];
std.debug.print("切片也能拿回数组指针：{any}\n", .{back.*});
// 数组 → 切片（一步到位，不需要先取地址）
const direct: []const i32 = &nums;
std.debug.print("直接 &nums 给切片：len={d} sum={d}\n", .{ direct.len, sum(direct) });
// const 数组也能取切片（只读）
const carr = [_]i32{ 9, 8, 7 };
const csl: []const i32 = &carr;
std.debug.print("const 数组 → []const i32：len={d} sum={d}\n", .{ csl.len, sum(csl) });
// 多维数组不能一步摊平成 []u8：内层元素是 [3]u8 不是 u8
//   const flat: []const u8 = &mat;  → error: pointer type child '[3]u8' cannot cast into 'u8'
const mat2 = [2][3]u8{ .{ 1, 2, 3 }, .{ 4, 5, 6 } };
const row = mat2[0]; // 先取内层，得到 [3]u8（值拷贝）
const row_slice: []const u8 = &mat2[0]; // 或直接 &mat2[0]
std.debug.print("mat2[0] 类型={s} len={d}；&mat2[0] 切片 len={d} {any}\n", .{
    @typeName(@TypeOf(row)), row.len, row_slice.len, row_slice,
});
std.debug.print("整块按字节看：std.mem.sliceAsBytes(&mat2).len={d}\n", .{
    std.mem.sliceAsBytes(&mat2).len,
});
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.6 开始 ====
&nums : *[6]i32（8 字节）→ 切片 []i32（16 字节），len=6
ap[0..3] = { 1, 2, 3 }  类型=*[3]i32
切片也能拿回数组指针：{ 1, 2, 3 }
直接 &nums 给切片：len=6 sum=21
const 数组 → []const i32：len=3 sum=24
mat2[0] 类型=[3]u8 len=3；&mat2[0] 切片 len=3 { 1, 2, 3 }
整块按字节看：std.mem.sliceAsBytes(&mat2).len=6
==== 6.6 结束 ====
```

四条转换路径汇总：

| 转换 | 写法 | 结果 |
|---|---|---|
| 数组 → 数组指针 | `&arr` | `*[N]T`（8 字节） |
| 数组 → 切片 | `const s: []T = &arr;` | `[]T`（16 字节） |
| 数组指针 → 切片 | `const s: []T = ap;` | 长度从 `*[N]T` 自动取 |
| 切片 → 数组指针 | `const ap: *[M]T = s[0..M];` | **M 必须编译期已知** |
| 数组指针 → 更小数组指针 | `ap[0..M]` | `*[M]T` |

**切片 → 数组指针是这组转换里唯一有约束的**：长度必须对得上，否则报错`coercion from slice to array pointer type requires length to be known at compile-time`（实测踩到）。这是"长度进类型"这条规则的必然推论——`[]T` 不知道长度，没法凭空造出 `*[M]T`。

**`const` 数组照样能取切片**（输出第 6 行：`const 数组 → []const i32`），得到只读切片。`const` 修饰的是**绑定**，数组本身是值，值可以取地址。

⚠️ **多维数组不能一步摊平成 `[]u8`**：

```text
error: expected type '[]const u8', found '*const [2][3]u8'
note: pointer type child '[3]u8' cannot cast into 'u8'
```

原因很直白：`[2][3]u8` 的元素类型是 `[3]u8` 而不是 `u8`，指针的 child 类型不匹配。两种解法：**取内层** `&mat2[0]` 拿到某一行的切片（输出第 7 行，len=3），或者**按字节看整块** `std.mem.sliceAsBytes(&mat2)`（输出第 8 行，len=6——2 行 × 3 字节，运行时连续性由此得到保证）。这和 03 章 3.7 节"结构体要按字节看"是同一个思路。

## 6.7 指针三兄弟 `*T` / `[*]T` / `[]T`

```zig
// examples/06_slices/main.zig 第 242-268 行
var x: u32 = 42;
const single: *u32 = &x; // 单项指针：天生指向 1 个元素
single.* += 1; // 解引用写回
std.debug.print("*T：single.*={d}（改了 x，x={d}）\n", .{ single.*, x });
// 多项指针：只有起点，没有长度
var quad = [_]u32{ 10, 20, 30, 40 };
const many: [*]u32 = &quad;
std.debug.print("[*]T：many[3]={d}  @sizeOf={d}（只有一个地址，长度全靠你记）\n", .{
    many[3], @sizeOf(@TypeOf(many)),
});
std.debug.print("[*]T 能做指针算术：(many+2)[0]={d}\n", .{(many + 2)[0]});
// ⚠️ 单项指针与切片都**不允许**指针算术：
//   const bad = single + 1;  → error: pointer arithmetic not allowed on single-item pointers
//   const bad2 = slice + 1;  → error: pointer arithmetic not allowed on slice
std.debug.print("只有 [*]T 允许 + / -；*T 和 []T 都不允许（编译器直接拒绝）\n", .{});
// 哨兵多项指针：靠末尾 0 找尾，就是C 的 char*
var zbuf: [4:0]u8 = .{ 1, 2, 0, 0 };
const cptr: [*:0]u8 = &zbuf;
std.debug.print("[*:0]u8：std.mem.len={d}  std.mem.span 读到={d} 个字节\n", .{
    std.mem.len(cptr), std.mem.span(cptr).len,
});
// ⚠️ std.mem.span 只吃**哨兵指针**，不吃哨兵切片：
//   std.mem.span(cs)   → error: invalid type given to std.mem.span: [:0]const u8
// 要写 std.mem.span(cs.ptr)。
std.debug.print("span 的参数必须是哨兵**指针**（切片要写 .ptr）\n", .{});
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.7 开始 ====
*T：single.*=43（改了 x，x=43）
[*]T：many[3]=40  @sizeOf=8（只有一个地址，长度全靠你记）
[*]T 能做指针算术：(many+2)[0]=30
只有 [*]T 允许 + / -；*T 和 []T 都不允许（编译器直接拒绝）
[*:0]u8：std.mem.len=2  std.mem.span 读到=2 个字节
span 的参数必须是哨兵**指针**（切片要写 .ptr）
==== 6.7 结束 ====
```

| 形态 | 类型 | `@sizeOf` | 长度 | 指针算术 | 用途 |
|---|---|---|---|---|---|
| 单项指针 | `*T` | 8 | 天然1 个 | ❌ | 表达"指向这一个元素"、方法 self |
| 多项指针 | `[*]T` | 8 | **无** | ✅ | C 边界、底层缓冲 |
| 哨兵多项 | `[*:0]T` | 8 | 末尾 0 | ✅ | C 的 `char*` |
| 切片 | `[]T` | **16** | 有（`len` 字段） | ❌ | 日常序列操作 |

**单项指针 `*T` 的语义最强**——`*u32` 明确表示"指向一个 u32"，所以它**不允许** `+ 1`（那会指向哪？）。切片同理：切片有 `len`，做指针算术绕过 `len` 就破坏了安全边界。只有 `[*]T` 敢开放算术，因为它**本来就没有边界概念**，越界与否是你的责任。

**输出第 2、3 行对照着看**：`many` 是 `[*]u32`，`@sizeOf=8`（只有地址，没有长度），所以能算 `(many+2)[0]=30`。代价是第 2 行那个 `many[3]=40`——编译器**不会**检查 `3 < 4`，因为它不知道数组多长。

⚠️ **新踩到的坑：`std.mem.span` 只吃哨兵指针，不吃哨兵切片。** 写 `std.mem.span(cs)`（`cs: [:0]const u8`）直接编译失败：

```text
error: invalid type given to std.mem.span: [:0]const u8
note: called at comptime here
pub fn span(ptr: anytype) Span(@TypeOf(ptr)) {
```

必须写 `std.mem.span(cs.ptr)`——哨兵切片的 `.ptr` 字段类型正是 `[*:0]const u8`，这才是 C 的 `const char*`。这个报错**有点反直觉**：哨兵切片明明自带哨兵信息，`span` 却要"退回去"要指针。原因是 `span` 的实现必须靠**读内存**找尾（`return ptr[0..l :s]`），而它要遍历的对象是"指针指向的一段内存"——切片的 `len` 反而帮不上忙（它已经知道长度了）。

顺带一个实测细节：输出第 5 行 `std.mem.len=2` 而 `zbuf = { 1, 2, 0, 0 }`——`len` 在第一个 0 处停止，所以是 2。这个函数正是 C 的 `strlen`。

## 6.8 字符串的真相：没有 `string` 类型

```zig
// examples/06_slices/main.zig 第 271-297 行
const msg = "你好，Zig";
std.debug.print("字面量 类型={s}  @sizeOf={d}\n", .{
    @typeName(@TypeOf(msg)), @sizeOf(@TypeOf(msg)),
});
const s: []const u8 = msg; // 退化成普通切片
std.debug.print("退化后 类型={s}  len={d}（**字节数**：你好 6 字节 + 逗号 3 + Zig 3 = 12）\n", .{
    @typeName(@TypeOf(s)), s.len,
});
std.debug.print("std.unicode 数出来的字符数 = {d}\n", .{try codepointCount(s)});
// 逐字节看 UTF-8
std.debug.print("字节展开：", .{});
for (s) |b| std.debug.print("{x:0>2} ", .{b});
std.debug.print("\n", .{});
// {s} 与 {any} 的分工
std.debug.print("{{s}}（当字符串直出）= {s}\n", .{s});
std.debug.print("{{any}}（当字节序列打印）= {any}\n", .{s});
// 纯 ASCII 的"巧合"：字节数 == 字符数
const en = "hello";
std.debug.print("纯 ASCII \"hello\"：len={d}，字符数也是 {d}，第 0 字节是 '{c}'\n", .{
    en.len, try codepointCount(en), en[0],
});
// Zig 字符串**没有** NUL 终止概念
std.debug.print("en.len={d}，读 en[5] 是越界访问（不是读到 0）——本例不触发\n", .{en.len});
// 字符串字面量是只读的
std.debug.print("msg 的元素类型是 const u8：写 msg[0]='x' 编译错（cannot assign to constant）\n", .{});
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.8 开始 ====
字面量 类型=*const [12:0]u8  @sizeOf=8
退化后 类型=[]const u8  len=12（**字节数**：你好 6 字节 + 逗号 3 + Zig 3 = 12）
std.unicode 数出来的字符数 = 6
字节展开：e4 bd a0 e5 a5 bd ef bc 8c 5a 69 67 
{s}（当字符串直出）= 你好，Zig
{any}（当字节序列打印）= { 228, 189, 160, 229, 165, 189, 239, 188, 140, 90, 105, 103 }
纯 ASCII "hello"：len=5，字符数也是 5，第 0 字节是 'h'
en.len=5，读 en[5] 是越界访问（不是读到 0）——本例不触发
msg 的元素类型是 const u8：写 msg[0]='x' 编译错（cannot assign to constant）
==== 6.8 结束 ====
```

**`"你好，Zig".len` 是 12，不是 6也不是 2。** 这是本节唯一需要记住的事实。输出第 4 行把真相摊开成字节：`e4 bd a0`（"你"，U+4F60）、`e5 a5 bd`（"好"，U+597D）、`ef bc 8c`（"，"，U+FF0C 全角逗号）、`5a 69 67`（`Zig` 三个 ASCII）。**Zig 的字符串就是字节序列，`len` 是字节数**——没有"字符"这个一等概念。

字符数得自己数，本章用一个专门的函数（示例第 53-59 行）：

```zig
/// 6.10 节：统计 UTF-8 字符数——必须走 std.unicode，不能用 `s.len`。
fn codepointCount(s: []const u8) !usize {
    const view = try std.unicode.Utf8View.init(s);
    var it = view.iterator();
    var n: usize = 0;
    while (it.nextCodepoint()) |_| n += 1;
    return n;
}
```

`Utf8View.init` 返回错误（`error{InvalidUtf8}`），因为**它会先验证整个字节串是合法 UTF-8**——非法输入立刻暴露，而不是让你在后面某处读到乱码。想跳过验证可以用 `initUnchecked`。

**`{s}` 与 `{any}` 的分工**：输出第 5、6 行是同一个 `s` 的两种打印方式。`{s}` 把它当字符串直出（遇到 `0xFFFD` 之类的非法字节就替换成替换字符），`{any}` 把底层字节当数字数组打印（`{ 228, 189, ... }`）。**调试字符串的字节构成时用 `{any}`，正常显示用 `{s}`。**

⚠️ **`@sizeOf(msg) = 8`**，不是 13。因为 `msg` 是 `*const [12:0]u8`——一个**指针**，8 字节；它指向的数组在别处。想知道"这段字节占多少内存"要写 `@sizeOf(@TypeOf(msg.*))`。

⚠️ **Zig 字符串没有 NUL 终止保证。** 字面量碰巧有哨兵（类型里的 `:0`），但你从数组 `&buf` 拿到的切片**没有**。读 `en[5]`（`"hello"` 的长度是 5）是**越界访问**，Debug 下 panic——不是"读到 0"。要传给 C 函数必须用 `[:0]const u8` 或 `[*:0]const u8`（见 6.7 节）。

⚠️ **字面量改不了**：`msg` 的元素类型是 `const u8`，写 `msg[0] = 'x'` 报 `cannot assign to constant`。要可变字符串得先拷一份：`alloc.dupe(u8, "literal")`（11 章）。

## 6.9 UTF-8 边界：不要按字节切断多字节字符

上一节说"`len` 是字节数"。这一节处理它的后果：**按字节随便切，会切出半个汉字**。

```zig
// examples/06_slices/main.zig 第 300-331 行
const zh = "中文abc";
std.debug.print("zh=\"{s}\"  .len={d}  字符数={d}\n", .{ zh, zh.len, try codepointCount(zh) });
//按字节随便切，会切出半个汉字
const cut4 = zh[0..4]; // "中" 是 3 字节，"文" 是 3 字节 —— 第 4 字节是"文"的第 1 字节
std.debug.print("zh[0..4] 切在多字节字符中间，合法吗={}\n", .{std.unicode.utf8ValidateSlice(cut4)});
const cut6 = zh[0..6]; // 正好两个完整汉字
std.debug.print("zh[0..6] 切在字符边界上，合法吗={} 内容=\"{s}\"\n", .{
    std.unicode.utf8ValidateSlice(cut6), cut6,
});
// ⚠️ 打印非法 UTF-8 不会 panic，但会输出替换字符 U+FFFD——静默的数据损坏
std.debug.print("直接打印切坏的字节：\"{s}\"（非法字节被替换成 U+FFFD，不报错）\n", .{cut4});
// 正确做法 1：按码点迭代
const view = try std.unicode.Utf8View.init(zh);
var it = view.iterator();
std.debug.print("按码点迭代：", .{});
while (it.nextCodepoint()) |cp| {
    std.debug.print("[U+{X:0>4} {d}字节] ", .{ cp, std.unicode.utf8CodepointSequenceLength(cp) catch 1 });
}
std.debug.print("\n", .{});
// 正确做法 2：单个码点的字节长度由首字节决定（同一段字节，两个不同切法）
const mixed = "中a"; // 3 字节 + 1 字节
const lead_cn = mixed[0];
const lead_ascii = mixed[3];
std.debug.print("mixed=\"{s}\"：首字节 0x{x:0>2} → {d} 字节；0x{x:0>2} → {d} 字节\n", .{
mixed,      lead_cn,                                            try std.unicode.utf8ByteSequenceLength(lead_cn),
    lead_ascii, try std.unicode.utf8ByteSequenceLength(lead_ascii),
});
// 正确做法 3：解码单个码点
const you = try std.unicode.utf8Decode("你");
std.debug.print("utf8Decode(\"你\") = U+{X:0>4}（占 {d} 字节）\n", .{ you, try std.unicode.utf8CodepointSequenceLength(you) });
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.9 开始 ====
zh="中文abc"  .len=9  字符数=5
zh[0..4] 切在多字节字符中间，合法吗=false
zh[0..6] 切在字符边界上，合法吗=true 内容="中文"
直接打印切坏的字节："中�"（非法字节被替换成 U+FFFD，不报错）
按码点迭代：[U+4E2D 3字节] [U+6587 3字节] [U+0061 1字节] [U+0062 1字节] [U+0063 1字节] 
mixed="中a"：首字节 0xe4 → 3 字节；0x61 → 1 字节
utf8Decode("你") = U+4F60（占 3 字节）
==== 6.9 结束 ====
```

**"中文abc" 的 `.len=9`、字符数 5** ——9 = 3+3+1+1+1，两个汉字各占 3 字节，`abc` 各 1 字节。所有UTF-8 字符的第一个字节落在特定区间（0x00-0x7F 是 1 字节，0xC0-0xDF 是 2 字节，0xE0-0xEF 是 3 字节，0xF0-0xF7 是 4 字节），后续字节都是 `10xxxxxx`。

**`zh[0..4]` 切坏了**：第 4 字节是"文"的第1 字节 `e6`，后面两字节被砍掉了。`utf8ValidateSlice` 返回 `false` 抓住了它。

⚠️ **但最危险的情况是这种**——输出第 4 行：把 `cut4` 直接 `{s}` 打印，**不报错、不 panic**，只是输出 `"中�"`。那个 `�` 是 `U+FFFD`替换字符。**这意味着"切坏的字符串会静默地流进你的程序**`，在日志里、在文件里、在网络包里都看不出异常，等到某天下游解码器报错才发现。** 这是本章最值得记住的坑：**验证要在切片产生的那一刻做，不能等到打印时**。

三种正确做法都在代码里：

- **按码点迭代**（输出第 5 行）：`Utf8View` + `nextCodepoint()`，每个码点连它的字节长度一起给你（`utf8CodepointSequenceLength` 返回 `u3`，注意 4 字节的 emoji 要小心 `u3` 装不下 4——实测 `.catch 1` 是保守兜底，真要处理 4 字节场景应该显式处理那个错误）。
- **看首字节**（输出第 6 行）：`utf8ByteSequenceLength(0xe4) = 3`，`utf8ByteSequenceLength(0x61) = 1`。这是UTF-8 的自同步特性——**首字节自己就说出了自己的长度**，不需要看后面的字节。
- **解码单个码点**（输出第 7 行）：`utf8Decode("你") = U+4F60`，反向操作。

## 6.10 可变 vs 只读：`[]T` vs `[]const T`

```zig
// examples/06_slices/main.zig 第 334-360 行
var letters = [_]u8{ 'a', 'b', 'c', 'd' };
const mutable: []u8 = letters[0..]; // 可写
mutable[0] = 'A';
const readonly: []const u8 = mutable; // 只读视图（free，随时可要）
std.debug.print("改 mutable[0]='A' 后 letters={any}；readonly={s}（同一个内存）\n", .{ letters, readonly });
// readonly 视图不能写
//   readonly[1] = 'X';  → error: cannot store into const slice
std.debug.print("readonly[1]='X' 编译错（cannot store into const slice）\n", .{});
// const 切片变量 ≠ 元素只读：const 修饰的是**绑定**，不是元素
const still_mutable: []u8 = letters[0..];
still_mutable[1] = 'B'; // 合法：元素类型是 u8，没有 const
std.debug.print("const 绑定的切片仍能改元素：letters={any}\n", .{letters});
// 可变切片可以隐式转只读切片（[]u8 → []const u8 是宽化，放行）
const as_ro: []const u8 = letters[0..];
std.debug.print("[]u8 隐式转 []const u8：len={d} 首字节='{c}'\n", .{ as_ro.len, as_ro[0] });
// 遍历：值拷贝 vs 指针捕获
var walk = [_]i32{ 1, 2, 3 };
for (walk) |v| std.debug.print("{d} ", .{v}); // v 是拷贝
std.debug.print("（值拷贝）\n", .{});
// ⚠️ 对**数组**用 |*v| 要先取地址：for (walk) |*p| → error: pointer capture of non pointer type '[3]i32'
for (&walk) |*p| p.* *= 100;
std.debug.print("for (&walk) |*p| p.* *= 100 后 walk={any}\n", .{walk});
// 对**切片**可以直接指针捕获
for (walk[0..]) |*p| p.* += 1;
std.debug.print("for (walk[0..]) |*p| p.* += 1 后 walk={any}\n", .{walk});
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.10 开始 ====
改 mutable[0]='A' 后 letters={ 65, 98, 99, 100 }；readonly=Abcd（同一个内存）
readonly[1]='X' 编译错（cannot store into const slice）
const 绑定的切片仍能改元素：letters={ 65, 66, 99, 100 }
[]u8 隐式转 []const u8：len=4 首字节='A'
1 2 3 （值拷贝）
for (&walk) |*p| p.* *= 100 后 walk={ 100, 200, 300 }
for (walk[0..]) |*p| p.* += 1 后 walk={ 101, 201, 301 }
==== 6.10 结束 ====
```

**可变性分两层，各管各的。** 第一层是**绑定**能不能重新指向别处（`const` 管这个，03 章 3.1 节）；第二层是**元素**能不能写（`[]T` 里的 `const` 管这个）。输出第 1、3 行合起来说明：`const still_mutable: []u8` 的绑定不能改指向，但它的元素**能**写——因为元素类型 `u8` 没有 `const`。这个区分正是"把'我不改你的数据'写进签名"的基础：`fn sum(items: []const i32)` 明确承诺不碰你的数据，调用方可以放心传 `[]i32` 进来。

**`[]u8` → `[]const u8` 是隐式允许的**（输出第 4 行）。这是 03 章 3.5 节"宽化放行"的直接应用：只读切片能表示的所有值，可变切片都能表示，反过来不行。所以**可变切片可以随便传给只读参数，只读切片不能传给可变参数**（后者报 `cannot store into const slice`）。

⚠️ **遍历改元素：`for (arr) |*p|` 对数组不行，必须写 `for (&arr) |*p|`**：

```text
error: pointer capture of non pointer type '[3]i32'
note: consider using '&' here
```

`for (x)` 遍历时，捕获到的 `|*p|` 里的 `p` 指向的是**元素**，不是数组本身，所以要先 `&`。这个报错很友好（直接告诉你加 `&`），但初学时容易以为是"数组不能指针捕获"。**记忆口诀：数组要 `for (&arr) |*p|`，切片可以直接 `for (slice) |*p|`**——因为切片本身就是指针。

输出第 7、8 行的对照说明了两种写法都能改到原内存（`* 100` 后 `+1`，两次都是真改）。

## 6.11 切片作为函数参数 + `std.mem` 工具箱

```zig
// examples/06_slices/main.zig 第 41-50 行
/// 6.9 节：函数参数默认收切片。`[]const T` 同时接受数组、切片、哨兵切片。
fn sum(items: []const i32) i32 {
    var total: i32 = 0;
    for (items) |v| total += v;
    return total;
}

/// 6.9 节：只想"读一个元素"时用单项指针，语义最明确（调用方必须保证它指向一个合法元素）。
fn first(items: []const i32) i32 {
    return items[0];
}
```

```zig
// examples/06_slices/main.zig 第 363-400 行
std.debug.print("规则：参数默认收 []const T；跨 C 边界才用 [*]T / [*:0]const T\n", .{});
// ⚠️ 必须写 &nums：数组**不能**直接传给收 []const T 的函数
//   sum(nums)→ error: array literal requires address-of operator (&)
std.debug.print("nums={any}\n", .{nums});
std.debug.print("sum(&nums) = {d}   first(&nums) = {d}\n", .{ sum(&nums), first(&nums) });
// std.mem：字符串处理的工具箱
const csv = "zig,python,rust,go";
var it_csv = std.mem.splitScalar(u8, csv, ',');
std.debug.print("splitScalar: ", .{});
while (it_csv.next()) |part| std.debug.print("[{s}] ", .{part});
std.debug.print("\n", .{});
var it_tok = std.mem.tokenizeScalar(u8, "  a   bbccc  ", ' ');
std.debug.print("tokenizeScalar（跳过空字段）: ", .{});
while (it_tok.next()) |tok| std.debug.print("<{s}> ", .{tok});
std.debug.print("\n", .{});
var it_seq = std.mem.splitSequence(u8, "a::b::c", "::");
std.debug.print("splitSequence（多字符分隔符）: ", .{});
while (it_seq.next()) |part| std.debug.print("[{s}] ", .{part});
std.debug.print("\n", .{});
std.debug.print("find(u8,\"hello zig\",\"zig\") = {?}  findScalar(u8,\"hello\",'l') = {?}\n", .{
    std.mem.find(u8, "hello zig", "zig"),
    std.mem.findScalar(u8, "hello", 'l'),
});
if (std.mem.cut(u8, "key=value", "=")) |kv| { // 一刀两断
    std.debug.print("cut: 左=\"{s}\" 右=\"{s}\"\n", .{ kv[0], kv[1] });
}
std.debug.print("trim=\"{s}\"  startsWith={}  endsWith={}  eql={}\n", .{
    std.mem.trim(u8, "  pad  ", " "),
    std.mem.startsWith(u8, "foobar", "foo"),
    std.mem.endsWith(u8, "foobar", "bar"),
    std.mem.eql(u8, "zig", "zig"),
});
// 固定缓冲格式化：不分配堆内存（`{s}` 与 `{any}` 的选择见 6.8）
var fbuf: [64]u8 = undefined;
const formatted = try std.fmt.bufPrint(&fbuf, "{s}={d}", .{ "n", 42 });
std.debug.print("bufPrint 无分配：\"{s}\" len={d}（缓冲在栈上）\n", .{ formatted, formatted.len });
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.11 开始 ====
规则：参数默认收 []const T；跨 C 边界才用 [*]T / [*:0]const T
nums={ 1, 2, 3, 4, 5, 6 }
sum(&nums) = 21   first(&nums) = 1
splitScalar: [zig] [python] [rust] [go] 
tokenizeScalar（跳过空字段）: <a> <bbccc> 
splitSequence（多字符分隔符）: [a] [b] [c] 
find(u8,"hello zig","zig") = 6  findScalar(u8,"hello",'l') = 2
cut: 左="key" 右="value"
trim="pad"  startsWith=true  endsWith=true  eql=true
bufPrint 无分配："n=42" len=4（缓冲在栈上）
==== 6.11 结束 ====
```

**为什么参数默认收切片**：数组进类型意味着 `fn f(a: [5]i32)` 只能收5 个元素的数组（6.1 节），太僵硬。切片的 `len` 在运行期，正好对应"任意长度"的需求，而且传参只拷 16 字节而不是整个数组。**代价是调用方要写 `&`**（6.1 节那个 `array literal requires address-of operator` 报错）——一次显式的取舍。

**`[]const T` 是最省的参数类型**：它同时接受 `[]T`、`[]const T`、`const [N]T`、`[N]T` 的地址、哨兵切片（6.12 节的 `[:0]const u8` 就能直接传）。所以除非真的需要修改元素，否则**永远写 `[]const T`**。

**`std.mem` 是字符串处理的工具箱**，本节用到的主要成员（0.16 起改了名，老代码里的 `split` / `tokenize` / `indexOf` 要换）：

| 函数 | 作用 | 备注 |
|---|---|---|
| `splitScalar(T, s, c)` | 按单字符切分 | **保留**空字段 |
| `tokenizeScalar(T, s, c)` | 按单字符切分 | **跳过**空字段 |
| `splitSequence(T, s, sub)` | 按多字符子串切分 | `"::"` 这种 |
| `find` / `findScalar` | 查找子串/字节 | 旧名 `indexOf`/`indexOfScalar` |
| `cut` | 一刀两断成 `[2][]const u8` | 找不到返回 `null` |
| `trim` | 去首尾空白 | 第三个参数是"要切的字符集" |
| `startsWith` / `endsWith` / `eql` | 比较 | `eql` **不限长度**，是切片的正确比较方式 |

⚠️ **`splitScalar` 和 `tokenizeScalar` 的区别是"空字段"**：输出第 4 行 `"  a   bbccc  "` 两者结果不同（`tokenizeScalar` 给出 `<a> <bbccc>`，两个字段）——`tokenizeScalar` 把连续的多个分隔符当成一个。反过来 `"a,,b"` 用 `splitScalar` 会得到 `[a] [] [b]`（**中间那个空字段保留**），用 `tokenizeScalar` 只得到 `<a> <b>`。**处理CSV/空白分隔的数据选 `tokenize`，要保留空字段选 `split`。**

⚠️ **比较字符串用 `std.mem.eql` 不要用 `==`。** 切片比较 `==` 在 Zig 里是**逐元素比较**（能工作但先比指针优化失败就退化成全量比对），而 `std.mem.eql` 是专门优化过的。输出第 7 行的 `eql=true` 就是它。

**`std.fmt.bufPrint` 是本章最后一个实用工具**：往调用方提供的固定缓冲里格式化，**不分配堆内存**。它返回的切片指向 `fbuf`（栈上），所以只能活到函数结束——这正是"不要返回局部内存"（6.4 节坑①）的另一种正确用法：借用而非拥有。

## 6.12 命令行参数：真实的 `[:0]const u8`

```zig
// examples/06_slices/main.zig 第 61 行（签名）
pub fn main(init: std.process.Init) !void {

// examples/06_slices/main.zig 第 402-419 行
// ═══ 6.12 命令行参数：真实的 []const u8 ═══
begin("6.12");
var args = init.minimal.args.iterate();
const argv0 = args.next(); // [:0]const u8 —— 哨兵切片
if (argv0) |a0| {
    // argv[0] 是可执行文件路径（长度随安装位置变化），所以只演示类型与哨兵性质
    std.debug.print("argv[0] 类型={s} 末字节={d}（哨兵保证；.len 是路径长度，不固定）\n", .{
        @typeName(@TypeOf(a0)), a0[a0.len],
    });
}
var arg_no: usize = 1;
while (args.next()) |arg| : (arg_no += 1) {
    // 参数是 [:0]const u8，能直接传给收 []const u8 的函数
    std.debug.print("argv[{d}] 类型={s} len={d} 字符数={d} 首字节=0x{x:0>2}\n", .{
        arg_no, @typeName(@TypeOf(arg)), arg.len, try codepointCount(arg), arg[0],
    });
}
std.debug.print("（本例没传额外参数，所以只有 argv[0]）\n", .{});
end("6.12");
```

运行输出（`examples/06_slices/main.zig`）：

```text
==== 6.12 开始 ====
argv[0] 类型=[:0]const u8 末字节=0（哨兵保证；.len 是路径长度，不固定）
（本例没传额外参数，所以只有 argv[0]）
==== 6.12 结束 ====
```

**0.17 的 `main` 签名是 `pub fn main(init: std.process.Init) !void`**，`std.process.Init` 里打包了 `gpa`（默认分配器）、`arena`、`io`、`environ_map` 等。`init.minimal.args.iterate()` 拿到参数迭代器——注意 0.17 是 `.iterate()` 不是 `.next()`（`Args` 本身没有 `next` 方法，直接写 `args.next()` 报 `no field or member function named 'next' in 'process.Args'`）。

**每个参数的类型是 `[:0]const u8`——哨兵切片。** 这是本节最漂亮的收尾：它同时集齐了本章所有的概念——**切片**（有 `len`）、**哨兵**（`a0[a0.len] == 0` 实测成立）、**`const`**（只读）、**字节序列**（`len` 是字节数）。而且因为它是哨兵切片，**可以直接 `&arg[arg.len]` 拿到 `[*:0]const u8` 丢给 C 函数**（6.7 节）。

> ⚠️ **Windows 上 `iterate()` 是编译错误**（0.17 实测：`@compileError("In Windows, use initAllocator instead.")`）——WTF-16 → WTF-8 转码需要缓冲，Windows 必须 `iterateAllocator(分配器)` 且用完 `deinit()`；产物是普通 `[]const u8`，**没有哨兵**。上面的哨兵演示是 POSIX 分支，示例源码里用 `if (builtin.os.tag == .windows)` 分了平台两支，跨平台代码照那个写法来（22 章有更完整的参数专题）。

顺带印证了 6.6 节的规律：`arg_no` 是 `var` 但被 `: (arg_no += 1)` 修改，所以循环是运行期的，参数个数编译期未知——**这也意味着 `while (args.next())` 里拿到的东西在运行期才确定**，任何切片操作都要考虑这一点。

### 测试：把语义钉住

本章行为全靠测试守着（`main.zig` 第 424-613 行，11 个 `test` 块）：

```text
$ zig test main.zig
1/11 main.test.数组是值类型：赋值与传参都是整块拷贝...OK
2/11 main.test.0.17 没有 **：++ 拼接与 repeat 重复...OK
3/11 main.test.哨兵数组与哨兵切片：len 处可以安全读...OK
4/11 main.test.切片是胖指针：两个机器字...OK
5/11 main.test.编译期边界得数组指针，运行期边界得切片...OK
6/11 main.test.切片与数组指针互相转...OK
7/11 main.test.字符串没有 string 类型：len 是字节数...OK
8/11 main.test.UTF-8 边界：按字节切会切坏多字节字符...OK
9/11 main.test.可变切片与只读切片...OK
10/11 main.test.std.mem 字符串工具...OK
11/11 main.test.std.mem.span 只吃哨兵指针...OK
All 11 tests passed.
```

几个值得注意的断言：

- **第 4 个测试**把"胖指针"量化了：`@sizeOf([]u8) == @sizeOf(usize) * 2`、而 `@sizeOf([*]u8) == @sizeOf(usize)`——多出来的正是长度字段。
- **第 5 个测试**断言 `ct` 的类型是 `*const [2]u16`（编译期边界 → 数组指针）、`rt` 的类型是 `[]u16`（运行期边界 → 切片），把6.5 节那条反直觉规则钉死。
- **第 7 个测试**逐字节断言 `"你好，Zig"` 的前6 个字节是 `e4 bd a0 e5 a5 bd`（"你" = U+4F60，"好" = U+597D）。写这个断言时我一开始按 `中`（`e4 b8 ad`）写错了，被测试当场抓住——**这就是测试的价值：把"你以为的字节序"和"真的字节序"分开**。
- **第 11 个测试**是6.7 节那个坑的守卫：断言 `std.mem.span(cs.ptr)` 工作（哨兵切片要写 `.ptr`）。

## 6.13 坑位清单

1. **`s.len` 是字节数，不是字符数**：`"你好，Zig".len == 12`。数字符必须走 `std.unicode`（`utf8CountCodepoints` 或 `Utf8View` 迭代）。纯ASCII 时两者恰好相等，这是最容易被掩盖的 bug（6.8）。
2. **按字节切会切坏多字节字符，而且静默**：`zh[0..4]` 打印出 `"中�"`（`U+FFFD` 替换字符），**不报错、不 panic**。必须用 `utf8ValidateSlice` 在切片产生处验证，或用 `Utf8View` 按码点迭代（6.9）。
3. **编译期边界的子切片得到的是数组指针不是切片**：`stones2[0..2]` 是 `*const [2]u16`。要真切片写 `ct[0..ct.len]`，要运行期边界就用 `_ = &var;` 迫使它落到内存（6.5）。
4. **数组不能直接传给收切片的函数**：`sum(nums)` → `error: array literal requires address-of operator (&) to coerce to slice type`。写 `sum(&nums)`（6.1）。
5. **`std.mem.span` 只吃哨兵指针，不吃哨兵切片**：`std.mem.span(cs)`（`cs: [:0]const u8`）→ `error: invalid type given to std.mem.span: [:0]const u8`，报的是 `@compileError`。写 `std.mem.span(cs.ptr)`（6.7）。
6. **⚠️ 编译期构造 + 返回局部地址 = 静默 use-after-free**：函数返回 `&buf`，若 `buf` 是运行期栈变量（`const buf = blk: {...}` 但块不是 `comptime`），**编译器不报错、测试不失败，只有输出是乱码**。必须写 `comptime blk:` 让值成为编译期常量。同类的 `return &buf`（无blk）会被拦成 `returning address of expired local variable`，但带 `blk:` 的这版**逃过了检查**（6.2）。
7. **哨兵数组用 `undefined` 初始化会漏掉哨兵槽**：`var b: [n*len:0]u8 = undefined;` + 循环填前`n*len` 个 → 元素全对但 `b[n*len]` 是脏的。用 `@splat(0)` 初始化（6.2）。
8. **0.17 移除了 `**` 运算符**：`"ab" ** 3` 报 `binary operator '*' has whitespace on one side`（误导性文案）；`[_]u8{0} ** 4` 也没了。替代：`++` 拼接、`@splat(x)` 填充、自己的 `repeat()`（6.2）。
9. **多维数组不能一步摊平成 `[]u8`**：`const flat: []const u8 = &mat2;`（`mat2: [2][3]u8`）→ `pointer type child '[3]u8' cannot cast into 'u8'`。先取内层 `&mat2[0]`，或用 `std.mem.sliceAsBytes(&mat2)`（6.6）。
10. **对数组用 `|*v|` 指针捕获要写 `for (&arr) |*p|`**：`for (arr) |*p|` → `error: pointer capture of non pointer type '[3]i32'` + `note: consider using '&' here`。切片可以直接捕获（6.10）。
11. **切片不延长底层内存寿命**：`var buf: [10]u8 = ...; return &buf;` 返回的是已回收的栈。切片只是借用视图（6.4）。另外 `*const [N]u8` 传给要 `[]const u8` 的参数（如 `expectEqualStrings`）会报类型不匹配，要写 `p[0..p.len]`（6.5）。
12. **字符串没有 NUL 终止保证**：字面量碰巧有哨兵（类型带 `:0`），但 `&buf` 拿到的切片**没有**。读 `s[s.len]` 是**越界访问**（panic），不是"读到 0"。要传给 C 用 `[:0]const u8` / `[*:0]const u8`（6.3、6.8）。
13. **字面量是只读的**：`msg[0] = 'x'` → `cannot assign to constant`（元素类型是 `const u8`）。要可变先`alloc.dupe`。另外 `@sizeOf(msg)` 是 8（指针大小）不是 13（数据大小），后者要写 `@sizeOf(@TypeOf(msg.*))`（6.8）。
14. **`splitScalar` 保留空字段，`tokenizeScalar` 跳过**：`"a,,b"` 前者给 `[a] [] [b]` 三个，后者给 `<a> <b>` 两个（6.11）。
15. **`&arr` 在不同语境下退化成不同类型**：`const s: []const T = &arr;` 是切片；`const p: [*]T = &arr;` 是多项指针；`a[0..2]` 是 `*const [2]T` 数组指针。三个语境别混——**默认写切片，多项指针只在 C 边界出现**（6.4、6.5、6.7）。
16. **只有 `[*]T` 允许指针算术**：`single + 1`（`single: *u32`）→ `pointer arithmetic not allowed on single-item pointers`；切片同样禁止。`[*]T` 开放算术的代价是它**没有长度**，越界全靠你自己（6.7）。

---

上一章：[05 函数](05-functions.md) · 下一章：[07 结构体](07-structs.md)
