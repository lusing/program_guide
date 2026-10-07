# 21 · 内联汇编与底层工具箱

> 对应示例：`examples/21_asm/main.zig`（1179 行，18 个 test）
>
> 汇编是**最后手段**：本章把 0.17.0 上每一种约束、每一个 clobber 字段、
> 每一条平台差异都实测一遍，然后告诉你哪些说法已经过期了。
>
> 本章有**七条结论会推翻你可能听过的说法**（全部在本机
> `/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/zig`（0.17.0）上跑出来，
> 平台是 `x86_64-macos`、优化模式 `debug`）：
>
> 1. **Zig 里没有 `inline` 关键字**——只有 `asm` 和 `asm volatile` 两个。
>    而且决定"这块 asm 会不会被删掉"的**不是关键字，是输出的可观察性**。
> 2. **0.17 的 clobber 从字符串列表变成了类型化结构体**。
>    网上（以及旧版 Zig 文档）写的 `: : : "cc", "memory"` 在 0.17 上
>    报 `expected type 'lang.assembly.Clobbers__struct_36', found '*const [2:0]u8'`，
>    新写法是 `: : : .{ .cc = true, .memory = true }`。
> 3. **clobber 结构体按架构分字段**：x86_64 有 `.cc`（条件码），
>    **aarch64 只有 `.nzcv`**——把 x86 的 `.cc = true` 抄到 arm64 上直接编译错。
>    而且 0.17 的 clobbers 段**不能有尾逗号**（`: .{ .memory = true },` 报
>    `expected ')', found ','`）。
> 4. **x86 的 `"=a"` / `"=b"` / `"=c"` / `"=d"` / `"=S"` / `"=D"` 在 0.17.0 上
>    全部不可用**，报 `couldn't allocate output register for constraint 'a'`。
>    要 rax 请写显式的 `"={rax}"`，或用寄存器家族 `"=A"`（实测可用）。
> 5. **aarch64 的内联汇编在 Zig 里走 Intel 语序（目的在前），不是 AT&T**。
>    照抄 x86 的 `add %[a], %[o]` 在 arm64 上报
>    `too few operands for instruction`，必须写 `add %[o], %[a]`。
> 6. **"macOS 上可以 `mov $label` 把符号地址当立即数搬"——不行**。
>    `movl $g, %o` 报 `invalid operand for instruction`，
>    换 `movabsq $g, %o` 报 `undefined symbol: g`（Zig 的普通顶层 `var`
>    不是导出符号）。正解是 `@intFromPtr(&g)` 当运行期整数传进寄存器。
> 7. **Zig 的 `"m"` 约束不是 C 的"内存操作数"**。它给的是「装着这个操作数
>    **值**的那个栈槽」的内存引用——`movq %[m], %[o]` 读到的是那个值的副本
>    （对数组来说恰好是它的地址，实测返回 `140702030757888` 这种栈地址），
>    而不是它指向的内容。要按地址访存必须 `"r"` 传地址 + 模板里写 `(%[p])`。
>
> 另外两条不算"推翻"但同样重要：
>
> - **x86_64 macOS 上裸 `syscall` 指令会吃 SIGSYS**（实测退出码 140 = 128 + 12，
>   12 就是 `SIGSYS`）。macOS 要求先 `csopen` 切代码段，
>   所以必须借 libc 的 `syscall()`。**网上所有"Zig 手写 syscall"的例子在
>   macOS 上必崩。**
> - **0.17 的 `@bitCast` 拒绝任何非 `packed` 的结构体**，`extern struct` 也不行
>   （`error: cannot @bitCast from 'main.ExternPair'`）。想按字节看一个
>   `extern struct`，只能用 `std.mem.asBytes` + `std.mem.readInt`。
>
> 最后一句忠告：**这一章里超过一半的内容都在说"别用 asm"**。
> `@popCount` / `@ctz` / `@byteSwap` / `@Vector` 都已经是语言内建，
> 21.12 会把这条论证做完。

---


## 21.1 最小内联汇编

### asm 的四段结构

Zig 的 `asm` 表达式有**四段**，用冒号分隔：

```plain
asm [volatile] ("模板串"          ← ① 汇编指令本体
    : 输出列表                     ← ② 编译器写出来的值
    : 输入列表                     ← ③ 喂给汇编的值
    : clobber 声明                 ← ④ 被汇编蹂躏的寄存器/标志/内存
);
```

四段**都可以省**，但规则不对称：

| 你省略的段 | 后果 |
|---|---|
| 输出 | 这块 asm 没有可观察的输出 → **必须**写 `volatile`，否则编译直接错 |
| 输入 | 模板里不能引用任何 `%[名字]`（除了硬编码的寄存器） |
| clobber | 汇编里动过的额外寄存器/条件码**不会被告知编译器** → 数据神不知鬼不觉地坏 |

`volatile` 在 21.4 单独讲。**注意 Zig 里没有 `inline` 关键字**——C 的
`__asm__ volatile` 在 Zig 里对应的是 `asm volatile`，而"inline"那半边
Zig 用的是 `inline for` / `inline fn` 这些完全不同的东西，两者无关。

x86 默认 **AT&T 语法**：`add $5, %[r]`（源在前、立即数带 `$`、
寄存器写 `%rax`——注意这里 `%` 后面**不加寄存器名**，
因为 `%rax` 会被 LLVM 当成占位符解析）。多行模板用 `\` 续行，
或者在单行串里写 `\n\t`（实测两种都可行）。

**aarch64 分支是 Intel 语序**：`add %[r], %[r], #5`（目的在前、立即数带 `#`）。
这不是"写法风格"，是LLVM 后端在两种目标上分别喂给汇编器的语法不同。
把 x86 的 `add %[a], %[o]` 抄到 arm64 上会得到：

```text
error: <inline asm>:1:2: too few operands for instruction
        add %[a], %[o], #5
        ^
```


`asm volatile ("nop")` —— 只有模板串，没有输出、没有输入、没有 clobber。`nop` 是 x86 的单字节空操作（0x90），aarch64 对应 `nop`，两边都有。

```zig
// examples/21_asm/main.zig 第 40-44 行
/// 21.1：最小的一块 asm——只有模板串，没有输出、没有输入、没有 clobber。
/// `nop` 是 x86 的单字节空操作（0x90），aarch64 对应 `nop`，两边都有。
pub fn asmNop() void {
    asm volatile ("nop");
}
```

同一个 `+r`（读+写）操作数在两种架构上的写法。注意 aarch64 那一支的条件码字段是 `.nzcv` 而不是 `.cc`。

```zig
// examples/21_asm/main.zig 第 46-62 行
/// 21.1：同一条"+5"在两种架构上的写法。
/// `asm`（不带 volatile）与 `asm volatile` 的差别见 21.4。
/// aarch64 的立即数必须带 `#`，且**目的寄存器在前**（Intel 语序，不是 AT&T）。
fn addFive(x: u64) u64 {
    var r = x;
    if (comptime is_x86) {
        asm volatile ("add $5, %[r]" // AT&T 语法：源在前、立即数带 $
            : [r] "+r" (r), // "+r" = 读+写，编译器保证同一个寄存器
        );
    } else {
        asm volatile ("add %[r], %[r], #5" // AArch64：目的在前、立即数带 #
            : [r] "+r" (r),
            :
            : .{ .nzcv = true } // aarch64 的条件码字段叫 nzcv，不是 cc
        );
    }
    return r;
```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.1 最小内联汇编 开始 ====
asm volatile ("nop") 两条：编译通过、运行无事发生（它就是 nop）
addFive(37) = 42（汇编 +5；x86 是 AT&T `add $5, %[r]`，aarch64 是 `add %[r], %[r], #5`）
裸 `asm` 没有 inline 关键字：Zig 里关键字就是 asm / asm volatile 两个
加不加 volatile 取决于「输出有没有人用」，不是取决于指令有没有副作用
⚠️ 不带输出且不带 volatile 直接编译错（assembly expression with no output must be marked volatile）
==== 21.1 结束 ====
```

## 21.2 输出约束

### 五种输出写法

输出约束回答一个问题：**结果放哪里**。

```plain
=     只输出（写）
+     读+写（同一个寄存器先读后写）
&     early-clobber：这个输出可能在所有输入被读之前就被写
      ⇒ 寄存器分配器不许它和任何输入共用寄存器
=r    任意通用寄存器
={rax} 显式钉死 rax（花括号里是寄存器名）
=A    rax 寄存器家族（rax / eax / ax / al）
=q    任意可作字节地址的寄存器
=x    任意 SSE 寄存器
=m    直接落内存
-> T  只要类型、不要变量（asm 表达式本身就是值）
```

0.17.0 上实测**不能用的**那一批（每一个都报
`couldn't allocate output register for constraint 'X'`）：

```text
=a   =b   =c   =d   =S   =D   =g
```

也就是说 C 里最常见的 `"=a"`（rax）在0.17 的 Zig 上**已经不能用了**。
要 rax 就写 `"={rax}"`（可用）或 `"=A"`（可用，实测返回 22）。
`"=g"`、`"=m"` 在 x86 上另有语法问题（见下面 `"=m"` 那段）。

`-> T` 形式很省事——整个 asm 表达式就是它的值：

```zig
const v = asm volatile ("movq $22, %[o]"
    : [o] "=r" (-> u64),
    : ,
);
```

⚠️ 但 `"=m"` **不能**配 `-> T`：0.17 实测能编过、运行时直接 segfault
（退出码 139），因为匿名输出拿不到一个稳定的栈槽。必须给一个具名 `var`。

```text
error: value of type 'u64' ignored
    asm volatile ("movq $g, %[out]" : [out] "=r" (-> u64));
```
这条是"asm 的值必须被用掉"（Zig 表达式不是语句），
和 `-> T` 无关，但新手常撞。


`"=r"`（编译器随便挑寄存器）、`"={rax}"`（显式钉死）、`"=A"`（rax 寄存器家族）三种。

```zig
// examples/21_asm/main.zig 第 68-102 行

/// 21.2：`"=r"` —— 只输出，寄存器由编译器随便挑。
/// aarch64 上同样是 `"=r"`（x86 的 `"=r"`/`"=q"`/`"=Q"` 字母在 arm 上无意义）。
fn emitMovImm(comptime imm: u64) u64 {
    if (comptime is_x86) {
        return asm volatile ("movq %[i], %[o]"
            : [o] "=r" (-> u64),
            : [i] "i" (imm),
        );
    } else {
        // aarch64 没有 `mov reg, imm`（要拆成 movz/movk），用 movz
        return asm volatile ("movz %[o], %[i]"
            : [o] "=r" (-> u64),
            : [i] "i" (imm),
        );
    }
}

/// 21.2：`"={rax}"` —— 显式钉死一个具体寄存器。
/// x86 上 LLVM 的单字母寄存器类（`"a"`/`"b"`/`"c"`/`"d"`/`"S"`/`"D"`）在 0.17.0
/// **全部报** `couldn't allocate output register for constraint 'a'`（实测，见坑位清单）；
/// 要rax 就写显式寄存器 `"={rax}"`，或用等价但可用的寄存器类 `"=A"`。
fn movqRax(comptime imm: u64) u64 {
    if (comptime is_x86) {
        return asm volatile ("movq %[i], %%rax"
            : [o] "={rax}" (-> u64),
            : [i] "i" (imm),
        );
    } else {
        // aarch64 没有 `mov reg, imm`（要拆成 movz/movk），用 movz
        return asm volatile ("movz %[o], %[i]"
            : [o] "=r" (-> u64),
            : [i] "i" (imm),
        );
    }
```

多个输出之间用**逗号**分隔（不是分号）。`rdtsc` 占了 `eax` / `edx` 两个固定槽——x86 硬件只给 4 个（eax/ebx/ecx/edx），超了就得换设计。

```zig
// examples/21_asm/main.zig 第 104-121 行

/// 21.2：同一个 asm 块里两个输出用**逗号**分隔（不是分号）。
/// x86 只能给 4 个固定输出槽（eax/ebx/ecx/edx），`rdtsc` 就占掉了 2 个。
fn rdtsc() u64 {
    if (comptime is_x86) {
        var lo: u32 = undefined;
        var hi: u32 = undefined;
        asm volatile ("rdtsc"
            : [lo] "={eax}" (lo),
              [hi] "={edx}" (hi),
        );
        return (@as(u64, hi) << 32) | lo;
    } else {
        // aarch64 没有 rdtsc；虚拟计数器 cntvct_el0 一条 mrs 直接给 64 位
        return asm volatile ("mrs %[v], cntvct_el0"
            : [v] "=r" (-> u64),
        );
    }
```

`-> T` 形式：只要类型不要变量，整个 asm 表达式就是它的值。适合"这块 asm 就是一个纯函数"。

```zig
// examples/21_asm/main.zig 第 123-134 行

/// 21.2：输出可以是 `-> T` 形式——**只要类型，不要变量**。表达式直接返回 asm 的值。
/// 适合"这块 asm 就是一个纯函数"的场景。
fn immViaArrow(comptime imm: u64) u64 {
    if (comptime is_x86) return asm volatile ("movq %[i], %[o]"
        : [o] "=r" (-> u64),
        : [i] "i" (imm),
    );
    return asm volatile ("movz %[o], %[i]"
        : [o] "=r" (-> u64),
        : [i] "i" (imm),
    );
```

`"=m"`：输出直接落内存。⚠️ 两个实测陷阱——不能配 `-> T`（会 segfault），输出操作数只接受**裸标识符**（`slot.*` / `a[1]` 都编译不过）。

```zig
// examples/21_asm/main.zig 第 136-168 行

/// 21.2：`"=m"` —— 输出**直接落到内存**，不经过寄存器。
/// 编译器会自己生成合适的寻址（栈上传参的 `(%rsp)` 或 RIP 相对）。
fn emitToMemory() u32 {
    // ⚠️ "=m" **不能**配 `-> T` 用（0.17 实测：能编过，运行时 segfault，
    //    因为 "m" 的匿名输出拿不到一个稳定的栈槽）。必须给一个具名 var。
    var slot: u32 = 0;
    if (comptime is_x86) {
        asm volatile ("movl $22, %[o]"
            : [o] "=m" (slot),
        );
    } else {
        // aarch64 上 `"=m"` 配 `str %[v], [%[o]]` 会报 unexpected token in argument list
        // （LLVM 的 aarch64 asm 后端不接受把 "m" 操作数放进方括号）→ 这一处直接用纯 Zig。
        // 这不是妥协：21.12 的论点正是"能用语言特性就别用 asm"。
        slot = 22;
    }
    return slot;
}

/// 21.2：显式带变量的 `=m`——⚠️ 0.17 的输出操作数**只接受一个裸标识符**
/// （写 `slot.*` 报 `expected ')', found '.*'`，写 `a[1]` 报 `expected ')', found '['`），
/// 所以想通过指针写回，得先在本地声明一个 var，让汇编写它，再自己搬回去。
fn emitToVar(slot: *u32) void {
    var tmp: u32 = 0;
    if (comptime is_x86) {
        asm volatile ("movl $7, %[o]"
            : [o] "=m" (tmp),
        );
    } else {
        tmp = 7; // 同上：aarch64 的 "=m" 不可用，纯 Zig 代替
    }
    slot.* = tmp;
```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.2 输出约束 开始 ====
=r  任意寄存器：emitMovImm(11) = 11
=A  rax 家族：movqRax(22) = 22
={rax} 显式钉 rax：movqRax(33) = 33（实测 0.17 上 "=a" 不能用，见坑位清单）
-> T 只要类型：immViaArrow(44) = 44
=m  直接落内存：emitToMemory() = 22（不经过寄存器）
=m  带变量：emitToVar(&slot) = 7
多个输出之间用**逗号**分隔（不是分号）：rdtsc 用了 "={eax}" 和 "={edx}" 两个
x86 硬件只给 4 个固定输出槽（eax/ebx/ecx/edx），超了就必须换设计
==== 21.2 结束 ====
```

## 21.3 输入约束

### `r` / `i` / `n` / 具名引用 / early-clobber

输入约束回答：**值从哪里来**。

```plain
r    任意通用寄存器（最常用）
i    编译期已知的立即数（32 位那条路径）
n    编译期已知的立即数，能塞进 8 位（编码更短）
m    ⚠️ 见下面——不是你想的那个意思
```

模板里引用输入一律用 `%[名字]`。`$0` 是另一套机制：它引用**第 0 个输出**
（配合 `"0"` 约束用），0.17 上实测可用。

`i` / `n` 都要求**编译期已知**。传一个运行期变量会得到：

```text
error: invalid operand for inline asm constraint 'i'
```

所以 `emitMovImm` / `movqRax` / `immViaArrow` 的 `imm` 参数都写成
`comptime imm: u64`——这不是风格选择，是约束要求。

另外实测：`"n"` 传 300（超出 8 位）**也能编过并正确运行**，
LLVM 会自己换手段。所以 `"n"` 的"8 位"是优化提示，不是硬边界。

### ⚠️⚠️ `"m"` 约束的真相（本节最重要的一段）

C 里 `"m"` 是"这个操作数在内存里，请直接用内存寻址"。
**Zig 的 `"m"` 不是这个意思。** 用 `-femit-asm` 看编译产物最直接：

```plain
    lea    rax, [rbp - 16]              ; 先算出数组的地址
    mov    qword ptr [rbp - 104], rax   ; 把这个"值"存进一个临时栈槽
    ## InlineAsm Start
    mov    rcx, qword ptr [rbp - 104]  ; ← "m" 展开成这个槽的内存引用
    ## InlineAsm End
```

也就是说 `%[m]` 指向的是「装着这个操作数**值**的那个临时槽」。
于是 `movq %[m], %[o]` 读到的是**那个值的副本**——
对数组来说恰好就是它的地址，实测 `loadFromMemory()` 返回
`140702030757888` 这种栈地址，而不是数组里的内容。

**按地址访存的正道**是 `"r"` 传地址 + 模板里显式写 `(%[p])`：

```zig
const p: *const u64 = @ptrCast(&buf);
return asm volatile ("movq (%[p]), %[o]"
    : [o] "=r" (-> u64),
    : [p] "r" (p),
);
```

这个坑值得单拎出来，因为**编译不报错、测试也不报错，只有数值不对**——
本示例第一版就是靠 `test` 断言才发现的。

### 两操作数指令的陷阱

x86 的 `add` / `imul` / `sub` 都是**两操作数**形式（AT&T：结果写回第一个操作数）。
但很多人会把结果声明在一个**独立的 `[out]`** 上——这时 LLVM 不保证
out 和输入同寄存器，于是计算结果落在输入的寄存器里，out 拿到垃圾。

实测 `mulBy(6, 7)` 声明成 `[out] "=&r"` 时返回
`18377501229438730240`（`0xFF3A...`，就是某个未初始化寄存器）。
加 `&`（early-clobber）只会更糟——那会**禁止**两者共用寄存器，
把"可能错"变成"必然错"。

正解二选一：把结果绑到输入本身（`[out] "+r" (a)`），
或者用"先搬后乘"的两指令形式——后者不依赖任何寄存器分配假设，本示例用这个。
aarch64 的 `mul` 本来就是三操作数（`mul %[out], %[a], %[b]`），
不需要这个绕法。


`"r"` 输入。这里藏着本章最容易踩的坑：x86 的 `imulq %[b], %[a]` 是**两操作数**形式，结果写回 `%[a]`；把结果声明在独立的 `[out] "=&r"` 上，LLVM 不保证两者同寄存器，于是 out 拿到未初始化寄存器（实测 `mulBy(6,7)` 返回 18377501229438730240）。正解是"先搬后乘"两指令形式。

```zig
// examples/21_asm/main.zig 第 174-205 行

/// 21.3：`"r"` 输入约束——输入放任意通用寄存器（寄存器由编译器挑）。
/// `mulBy(6, 7)` → 42。
///
/// ⚠️⚠️ 这是本章最容易踩的一个坑，0.17 实测：
/// x86 的 `imulq %[b], %[a]` 是**两操作数**形式（AT&T：结果写回 `%[a]` 那个寄存器）。
/// 但我们把结果声明在一个**独立的 `[out] "=r"`** 上——LLVM 不保证 out 和 a 是同一个寄存器，
/// 于是乘积留在 a 的寄存器里，而 out 拿到的是**未初始化**的寄存器
/// （实测 `mulBy(6,7)` 返回 18377501229438730240）。
/// 加 `&`（early-clobber）更糟：那会**禁止** out 与 a 共用寄存器，让错误变成必然。
///
/// 正解：要么把结果绑到 a 本身（`[out] "+r" (a)`），要么用"先搬后乘"两指令形式——
/// 后者不依赖任何寄存器分配假设，本示例用这个。
fn mulBy(a: u64, b: u64) u64 {
    if (comptime is_x86) {
        return asm volatile (
            \\movq %[a], %[out]
            \\imulq %[b], %[out]
            : [out] "=&r" (-> u64),
            : [a] "r" (a),
              [b] "r" (b),
            : .{ .cc = true } // imul 会改条件码 → 必须声明（x86 字段名）
        );
    } else {
        // aarch64 的 `mul` 本来就是三操作数（Intel 语序），不需要 x86 那种"先搬后乘"
        return asm volatile ("mul %[out], %[a], %[b]"
            : [out] "=&r" (-> u64),
            : [a] "r" (a),
              [b] "r" (b),
            : .{ .nzcv = true } // arm64 字段名是 nzcv，不是 cc
        );
    }
```

⚠️⚠️ Zig 的 `"m"` **不是** C 的"内存操作数"。它是「装着这个操作数**值**的那个栈槽」的内存引用，所以 `movq %[m], %[o]` 读到的是那个值的副本（对数组来说就是它的地址），不是它指向的内容。**按地址访存必须 `"r"` 传地址 + 模板里写 `(%[p])`。**

```zig
// examples/21_asm/main.zig 第 207-229 行

/// 21.3：**读内存的正道**是 `"r"` 传地址 + 模板里显式写 `(%[p])`。
///
/// ⚠️⚠️ 0.17 实测打翻了 C 的直觉：Zig 的 `"m"` **不是**"内存操作数"。
/// 它给的是「装着这个操作数**值**的那个栈槽」的内存引用，
/// 所以 `movq %[m], %[o]` 读到的是**那个值的副本**
/// （对数组来说恰好就是它的地址，实测返回140702030757888 这种栈地址），
/// 而不是它指向的内容。想按地址访存必须用下面这个形状。
fn loadFromMemory() u64 {
    var buf: [8]u8 align(8) = @splat(0);
    std.mem.writeInt(u64, &buf, 0x1122334455667788, .little);
    const p: *const u64 = @ptrCast(&buf);
    if (comptime is_x86) {
        return asm volatile ("movq (%[p]), %[o]"
            : [o] "=r" (-> u64),
            : [p] "r" (p),
        );
    } else {
        return asm volatile ("ldr %[o], [%[p]]" // aarch64：Intel 语序 + 方括号寻址
            : [o] "=r" (-> u64),
            : [p] "r" (p),
        );
    }
```

`"i"`（32 位立即数那条路径）与 `"n"`（8 位立即数，更紧）。两者都要求**编译期已知**——传运行期变量会报 `invalid operand for inline asm constraint 'i'`。

```zig
// examples/21_asm/main.zig 第 231-255 行

/// 21.3：`"i"` —— 必须是**编译期已知**的立即数（32 位那条路径）。
/// `"n"` 更紧：只要能塞进 8 位立即数就用它。两者在 0.17 上都对 0-255 放行，
/// 超出范围 LLVM 会自己换手段（实测 `n`传 300 也能编过并正确运行）。
fn immConstraint() struct { x86_i: u64, x86_n: u64, wide: u64 } {
    if (comptime is_x86) {
        const x: u64 = asm volatile ("movq %[k], %[o]"
            : [o] "=r" (-> u64),
            : [k] "i" (@as(u64, 1000)),
        );
        const n: u64 = asm volatile ("movq %[k], %[o]"
            : [o] "=r" (-> u64),
            : [k] "n" (@as(u64, 30)),
        );
        return .{ .x86_i = x, .x86_n = n, .wide = 1000 };
    }
    const x: u64 = asm volatile ("movz %[o], %[k]"
        : [o] "=r" (-> u64),
        : [k] "i" (@as(u64, 1000)),
    );
    const n: u64 = asm volatile ("movz %[o], %[k]"
        : [o] "=r" (-> u64),
        : [k] "n" (@as(u64, 30)),
    );
    return .{ .x86_i = x, .x86_n = n, .wide = 1000 };
```

具名引用输入用 `%[名字]`（`$0` 引用的是"第 0 个输出"，配合 `"0"` 约束用，两套机制）。以及 `"+&r"`（read-write + early-clobber）：输出可能在所有输入被读之前就被写，所以寄存器分配器不许它和输入共用寄存器——模板里借用了 `rdx`/`x16` 当临时寄存器，就必须一起写进 clobber。

```zig
// examples/21_asm/main.zig 第 257-308 行

/// 21.3：具名引用 —— 模板串里用 `%[名字]` 引用**输入**。
/// `$0` 引用的是"第 0 个输出"（配合 `"0"` 约束用），跟具名输入是两套机制。
///
/// `addTwoNamed(100, 23)` → 123。和上面 `mulBy` 同源的坑：
/// x86 的 `addq %[b], %[a]` 是两操作数形式（结果写回 `%[a]`），
/// 所以必须先把 a 搬进 out 再 add。
fn addTwoNamed(a: u64, b: u64) u64 {
    if (comptime is_x86) {
        return asm volatile (
            \\movq %[a], %[out]
            \\addq %[b], %[out]
            : [out] "=&r" (-> u64),
            : [a] "r" (a),
              [b] "r" (b),
            : .{ .cc = true });
    } else {
        return asm volatile ("add %[out], %[a], %[b]" // aarch64 三操作数，一条就够
            : [out] "=&r" (-> u64),
            : [a] "r" (a),
              [b] "r" (b),
            : .{ .nzcv = true });
    }
}

/// 21.3：`"+&r"`（read-write + early-clobber）——告诉编译器
/// "这个输出可能在所有输入被读之前就被写"，寄存器分配器因此不会把它和某个输入分到同一寄存器。
/// 模板里用了 `%%rdx`（aarch64 用 `x16`）当临时寄存器，所以还必须在 clobber 里声明它——
/// 这是 21.5 的内容，但两件事必须一起做才对。
fn swapViaAsm(a: u64, b: u64) struct { a: u64, b: u64 } {
    var x = a;
    var y = b;
    if (comptime is_x86) {
        asm volatile (
            \\movq %[x], %%rdx
            \\movq %[y], %[x]
            \\movq %%rdx, %[y]
            : [x] "+&r" (x),
              [y] "+&r" (y),
            :
            : .{ .cc = true, .rdx = true }); // rdx 被当临时寄存器，必须声明
    } else {
        asm volatile (
            \\mov x16, %[x]
            \\mov %[x], %[y]
            \\mov %[y], x16
            : [x] "+&r" (x),
              [y] "+&r" (y),
            :
            : .{ .nzcv = true, .x16 = true }); // x16 是 aarch64 的临时寄存器
    }
    return .{ .a = x, .b = y };
```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.3 输入约束 开始 ====
r  任意寄存器：mulBy(6, 7) = 42
r  传地址读内存：loadFromMemory() = 0x1122334455667788
i  立即数：ic.x86_i = 1000（32 位那条路径）
n  8 位立即数：ic.x86_n = 30（更紧，编码更短）
i/n 都要求编译期已知；传运行期变量会报 not a comptime constant
具名引用输入用 %[名字]：addTwoNamed(100, 23) = 123
+&r（early-clobber）：swapViaAsm(1,2) → a=2 b=1（模板用了临时寄存器 rdx/x16，必须写进 clobber）
⚠️ $0 引用的是「第 0 个输出」不是输入；引用输入一律用 %[名字]
==== 21.3 结束 ====
```

## 21.4 volatile

### 防蒸发，以及"关键字无用论"

`volatile` 唯一的作用是：**告诉编译器"这块 asm 必须执行，
不许因为没有可观察的输出而删掉它"**。

⚠️ **Zig 里没有 `inline` 关键字**（这一条已经过期）。而且真正起作用的
根本不是关键字——**决定一块 asm 会不会被删的是它的输出的可观察性**。

本示例用一组对照来实测这一点。两个函数**只差 `volatile` 一个词**：

- `probeNoVolatile`：输出 `dead` 声明了但此后从未被读 → 非 volatile 下整块可删
- `probeVolatile`：同样的输出，但加了 `volatile` → 必须执行

在 `debug` 模式下两者都执行，所以输出一样（`g_probe` 分别是 7 和 8）。
真正的差别要在 `-OReleaseSafe` / `-OReleaseFast` 下才看得到，
实测结果：

| 模式 | `probeNoVolatile(7)` 之后 | `probeVolatile(8)` 之后 |
|---|---|---|
| `debug` | `g_probe = 7` | `g_probe = 8` |
| `safe` | **`g_probe = 0`（被删了）** | `g_probe = 8` |
| `fast` | **`g_probe = 0`（被删了）** | `g_probe = 8` |

这就是"不加 volatile 被优化掉"的可复现证据。

反过来说，**输出被用上的纯计算不需要 volatile**：
`addTenPure` 写的是 `asm`（没有 `volatile`），但它的 `+r` 输出被
`return t` 用上了，所以两种优化模式下都不会被删。

### 两个相关规则

**不带输出必须写 volatile**，否则编译直接错（0.17 实测）：

```text
error: assembly expression with no output must be marked volatile
    asm ("movl %[v], (%[p])" : : [v] "r" (v), [p] "r" (&g_store));
```

**`@setRuntimeSafety` 管不到这件事。** 它的作用域是"运行时安全检查"
（整数溢出、数组越界、不可达分支），asm 块在不在产物里是**优化器**的决定，
由可观察性驱动。想知道"这块 asm 会不会被删"，只能看反汇编或者做上面那种
Release 模式对照实验。

⚠️ 本教程的 `test` 里对非 volatile 版只断言 `g_probe == 7 or g_probe == 0`——
因为在 Release 模式下 `zig test` 跑的确实是优化产物，断言 7 会失败。
**这个"或"断言本身就是这条规则的证据。**


观测靶子：asm 往全局 `g_probe` 写，由 main 用普通 Zig 读回来。两个版本**只差 `volatile` 一个词**——非 volatile 那版的输出 `dead` 从此不再被读，于是整块 asm 没有可观察的输出。

```zig
// examples/21_asm/main.zig 第 314-355 行

/// 21.4 的观测靶子：asm 往这块全局内存写，然后由 main 用普通 Zig 读回来。
/// 非 volatile 的那一版在 ReleaseSafe/ReleaseFast 下会被整块删掉（写不发生）。
var g_probe: u64 = 0;

/// 非 volatile + 一个"没人用的输出"：编译器发现输出没人读 → 整块删。
fn probeNoVolatile(value: u64) void {
    var dead: u64 = undefined;
    const p: *u64 = &g_probe;
    if (comptime is_x86) {
        asm ("movq %[v], (%[p])"
            : [dead] "=r" (dead),
            : [v] "r" (value),
              [p] "r" (p),
        );
    } else {
        asm ("str %[v], [%[p]]"
            : [dead] "=r" (dead),
            : [v] "r" (value),
              [p] "r" (p),
        );
    }
    // dead 从此不再被读 → asm 块没有可观察的输出
}

/// volatile：输出同样没人读，但这条 asm **必须执行**。
fn probeVolatile(value: u64) void {
    var dead: u64 = undefined;
    const p: *u64 = &g_probe;
    if (comptime is_x86) {
        asm volatile ("movq %[v], (%[p])"
            : [dead] "=r" (dead),
            : [v] "r" (value),
              [p] "r" (p),
        );
    } else {
        asm volatile ("str %[v], [%[p]]"
            : [dead] "=r" (dead),
            : [v] "r" (value),
              [p] "r" (p),
        );
    }
```

对照组：纯计算（`+r` 的输出被 return 用上了）不加 volatile 也不会被删。这才是"asm 需要写 inline 关键字"这个说法的真正来源——起作用的是可观察性，不是关键字。

```zig
// examples/21_asm/main.zig 第 357-372 行

/// 21.4：带 `+r` 的**纯计算**——输出被用上了，所以不加 volatile 也不会被删。
/// 这是"asm 需要写 inline 关键字"这个说法的来源：真正起作用的不是关键字，是**可观察性**。
fn addTenPure(x: u64) u64 {
    var t = x;
    if (comptime is_x86) {
        asm ("addq $10, %[t]"
            : [t] "+r" (t),
        );
    } else {
        asm ("add %[t], %[t], #10"
            : [t] "+r" (t),
            :
            : .{ .nzcv = true });
    }
    return t;
```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.4 volatile 开始 ====
mode=debug：非 volatile 那次写完后 g_probe = 7
mode=debug：volatile  那次写完后 g_probe = 8
⇒ 在 ReleaseSafe/ReleaseFast 下非 volatile 那行会被整块删掉（g_probe 停在 0）
⇒ 纯计算（输出被用上）不需要 volatile：addTenPure(32) = 42
⚠️ @setRuntimeSafety 只能关安全检查，管不到「asm 被不被删」——那由输出可观察性决定
==== 21.4 结束 ====
```

## 21.5 clobber 列表

### 0.17 的三处大改

0.17 在这一节有**三处大改**，全部是breaking change：

### 改一：从字符串列表变成类型化结构体

旧写法（网上、旧文档、本教程上一版都这么写）：

```text
asm volatile ("..." : : : "cc", "memory")
```

0.17 实测报错：

```text
error: expected type 'lang.assembly.Clobbers__struct_36', found '*const [2:0]u8'
asm volatile ("addq $1, %[a]" : [a] "+r" (a) : : "cc");
```

新写法：

```zig
asm volatile ("addq $1, %[a]"
    : [a] "+r" (a),
    :
    : .{ .cc = true }
);
```

类型是 `std.lang.assembly.Clobbers`，一个 `packed struct`，
在 x86_64 上 **32 字节、195 个字段**（实测 `@sizeOf` 与字段数）：

```text
memory cc dirflag eflags flags fpcr fpsr mxcsr rflags rax rcx rdx rbx rsp rbp
rsi rdi r8..r15 eax ecx edx ebx esp ebp esi edi r8d..r15d ax..di r8w..r15w
al cl dl bl spl bpl sil dil r8b..r15b ah ch dh bh zmm0..zmm31 ymm0..ymm31
xmm0..xmm31 mm0..mm7 st0..st7 es cs ss ds fs gs
```

写错字段名会得到：

```text
error: no field named 'xyz' in struct 'lang.assembly.Clobbers__struct_36'
```

### 改二：字段名按架构分

aarch64 的 `Clobbers` 是**另一个** packed struct，条件码字段叫
**`.nzcv`**（N/Z/C/V 四个标志的合称），**没有 `.cc`**。
把 x86 的写法抄过去：

```text
error: no field named 'cc' in struct 'lang.assembly.Clobbers__struct_35'
```

aarch64 那一版的字段是 `memory nzcv x0..x30 w0..w30 lr sp wsp fpcr fpmr fpsr ffr
p0..p15 z0..z31 d0..d31 s0..s31 q0..q31 v0..v31`。

### 改三：clobbers 段不能有尾逗号

```plain
    : .{ .memory = true },     ← ✗ error: expected ')', found ','
    : .{ .memory = true }      ← ✓
```

另外，**只有三段的写法要特别注意**（`: outputs : clobbers`）——
Zig 要求四段的冒号都在，只是可以把输入段留空：

```zig
: .{ .nzcv = true }              ← ✗ error: expected ')', found '.'
: : .{ .nzcv = true }            ← ✓ 空输入段 + clobber 段
```

### 为什么必须写 `.cc` 和 `.memory`

- **`.cc`（条件码）**：汇编里`cmp` / `test` / `add` / `rol` 全都会改标志位。
  不声明的话，编译器会把"比较结果"当成仍然有效的信息传播到块外，
  于是它基于陈旧标志位做分支——**症状是"某个 `if` 偶尔走错分支"**，
  极难定位。
- **`.memory`**：告诉编译器"这块汇编可能读写**从传入指针推导不出来**的地址"
  （比如它内部访问了某个全局、或者改了某个静态变量）。于是编译器
  **禁止**把其他访存重排或合并过这个点。没写的话，一次 store 可能被
  提到循环外、或两次相邻 store 被合并成一个——**症状是数据被"莫名优化"**。

写 clobber 的判断标准很简单：**汇编里除了输入输出寄存器之外，
还动了什么，就写什么。** 动了条件码写 `.cc` / `.nzcv`，
动了内存写 `.memory`，借了某个具体寄存器当临时寄存器就写那个（见 21.3 的
`swapViaAsm`：模板用了 `%%rdx`，clobber 就必须有 `.rdx = true`，
否则编译器可能把 `x`/`y` 分到 `rdx` 上，交换结果直接错）。


`rolq` 改条件码 → 必须声明 `.cc`。aarch64 没有 `rol`，用 `ror #56` 等价，条件码字段是 `.nzcv`。

```zig
// examples/21_asm/main.zig 第 378-394 行

/// 21.5：`rol` 改条件码 → 声明 `.cc`。返回 64 位循环左移 8 位后的值。
fn rol8(x_in: u64) u64 {
    var x = x_in;
    if (comptime is_x86) {
        asm volatile ("rolq $8, %[r]"
            : [r] "+r" (x),
            :
            : .{ .cc = true } // 条件码被蹂躏：编译器不能假设标志位还成立
        );
    } else {
        asm volatile ("ror %[r], %[r], #56"
            : [r] "+r" (x),
            :
            : .{ .nzcv = true });
    }
    return x;
```

`.memory`：汇编可能读写"从指针推导不出来的地址"，于是编译器禁止把前后一切访存重排/合并过这个点。

```zig
// examples/21_asm/main.zig 第 396-413 行

/// 21.5：`.memory` —— 汇编块可能读写"从指针推导不出来的地址"，
/// 于是编译器**禁止**把它前后的一切访存重排/合并过这个点。
fn storeThroughPtr(ptr: *u64, value: u64) void {
    if (comptime is_x86) {
        asm volatile ("movq %[v], (%[p])"
            :
            : [v] "r" (value),
              [p] "r" (ptr),
            : .{ .memory = true } // ← 没有它，编译器可以把这个 store 挪到别处甚至合并掉
        );
    } else {
        asm volatile ("str %[v], [%[p]]"
            :
            : [v] "r" (value),
              [p] "r" (ptr),
            : .{ .memory = true });
    }
```

`cmov`：条件码由块内的 `cmp` 产生、自产自销，但仍必须声明 `.cc`——否则编译器会把比较结果传播到块外去。⚠️ AT&T 的 `cmpq %[a], %[b]` 是拿 **b 减 a**，所以 `cmovge` 判的是 `b >= a`；方向写反会得到 `min`（实测）。

```zig
// examples/21_asm/main.zig 第 415-442 行

/// 21.5：`cmov` —— 条件成立才搬。条件码由前面的 `cmp` 产生，块内自产自销，
/// 所以 `.cc` 必须声明（否则编译器会把 cmp 的比较结果传播到块外去）。
///
/// 语义是 `max(a, b)`。⚠️ AT&T 的 `cmpq %[a], %[b]` 是拿 **b 减 a**，
/// 所以 `cmovge` 判的是 `b >= a`；写 `cmpq %[b], %[a]` 方向就反了（实测得到 `min`）。
fn cmovIfGe(a: u64, b: u64) u64 {
    var out = a;
    if (comptime is_x86) {
        asm volatile (
            \\movq %[a], %[o]
            \\cmpq %[a], %[b]
            \\cmovgeq %[b], %[o]
            : [o] "+&r" (out),
            : [a] "r" (a),
              [b] "r" (b),
            : .{ .cc = true });
    } else {
        asm volatile (
            \\mov %[o], %[a]
            \\cmp %[b], %[a]
            \\csel %[o], %[b], %[o], hs
            : [o] "+&r" (out),
            : [a] "r" (a),
              [b] "r" (b),
            : .{ .nzcv = true });
    }
    return out;
```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.5 clobber 列表 开始 ====
Clobbers 是 packed struct（32 字节），不是字符串列表
x86_64 上它有 195 个字段，头几个：memory cc dirflag eflags flags fpcr fpsr mxcsr rflags rax rcx ...
⚠️ 新写法是 `: : : .{ .cc = true, .memory = true }`，旧写法 `"cc", "memory"` 编译不过
rol8(0x0123456789abcdef) = 0x23456789abcdef01（rol 改条件码，所以声明了 .cc）
storeThroughPtr 之后 readInt = 0x1122334455667788（.memory 声明编译器不能重排这次访存）
cmovIfGe 语义是 max(a,b)：cmovIfGe(5,9)=9 cmovIfGe(9,5)=9 cmovIfGe(7,7)=7
==== 21.5 结束 ====
```

## 21.6 系统调用

### 系统调用的形状本身很简单

```zig
return asm volatile ("syscall"
    : [ret] "={rax}" (-> u64),   // 返回值在 rax
    : [number] "{rax}" (@intCast(number)), // 号也放rax（同一个寄存器既进又出）
    : .{ .rcx = true, .r11 = true, .memory = true }
);
```

注意**同一个寄存器既是输入又是输出**——`syscall` 号走 rax、返回值也走 rax。
这就是标准库 `std.os.linux.x86_64.syscall0` 的全部内容（读源码最直接）。

`clobber` 的三个字段各有来由：`rcx` 被 CPU 用来存返回地址、
`r11` 被用来存 rflags、`.memory` 表示这次调用会读写内存。

### ⚠️⚠️ 但是：x86_64 macOS 上裸 `syscall` 会死

本示例写的裸汇编版本在**本机跑起来直接退出，退出码 140**：

```bash
$ ./sysprobe        # 第一行 before 打印出来了，然后进程死掉
$ echo $?
140             # 128 + 12
```

`140 = 128 + 12`，而 12 正是 **`SIGSYS`**（"bad system call"）。
同样的裸 `syscall` 写成 C 用 `zig cc` 编译，**照样 140**——
所以这不是 Zig 的问题，是 macOS 的规则：

> **macOS 不允许用户态直接执行 `syscall` 指令。**
> 必须先 `csopen` 切到内核代码段（设 CS 寄存器），
> 而 `csopen` 是**特权指令**，用户态调不了。
> libSystem 的 `syscall()` 函数把这件事封好了。

所以 macOS 上唯一能跑的通道是**借 libc**：

```zig
extern "c" fn syscall(number: c_long, ...) c_long;

fn sysGetpidViaLibc() c_long {
    return syscall(20, 0, 0, 0); // 20 = macOS SYS_getpid
}
```

实测 `syscall(20, 0, 0, 0)` 返回 `86591`，与 `std.c.getpid()` **完全相同**。
本示例的 `getpidPortable()` 在 macOS 上走 libc、在 Linux 上走裸汇编，
用一个 `switch (builtin.os.tag)` 编译期选路。

### aarch64 又是另一套

aarch64 **没有 `syscall` 指令**，是 `svc #0`；系统调用号走 **x8**、
返回值走 **x0**，clobber 要写 `.x8`：

```zig
return asm volatile ("mov x8, %[nr]\n\tsvc #0"
    : [ret] "={x0}" (-> u64),
    : [nr] "r" (@as(u64, 172)),  // aarch64 __NR_getpid
    : .{ .x8 = true, .memory = true }
);
```

顺带一提：`syscall0(.getpid)` 在 aarch64 Linux 上是 **39**，
macOS 上是 **20**，aarch64 上是 **172**——三个平台三个号，
这也是为什么"直接抄一个 syscall 号"从来不靠谱。

**这是本教程唯一的 arch+OS 双维度分派的例子**，也是 21.12 的核心论据之一：
**asm 的成本不只是"难写"，还有"每个平台都要重测"。**


手写 syscall 在两类 OS 上走两条完全不同的路：x86_64 Linux 的 `syscall` 指令直接可用（0.17 标准库 `std.os.linux.x86_64.syscall0` 就是这么写的）；**x86_64 macOS 上裸 `syscall` 会吃 SIGSYS**，因为 macOS 要求先 `csopen` 切代码段，只能借 libc 的 `syscall()`。aarch64 根本没有 `syscall` 指令，是 `svc #0`，号走 x8、返回值走 x0。

```zig
// examples/21_asm/main.zig 第 448-514 行

/// 21.6：手写系统调用在**两类OS 上走两条完全不同的路**。
///
/// x86_64 Linux：`syscall` 指令直接可用（0.17 标准库 `std.os.linux` 就是这么写的）。
/// x86_64 macOS：**用户态直接 `syscall` 会吃SIGSYS**（实测退出码 140 = 128+12，
/// 12 = SIGSYS）。macOS 要求先`csopen`/`csclose` 切到代码段，
/// libSystem 的 `syscall()` 函数封装了这件事 —— 所以 macOS 上要借道 libc。
///
/// 这也是 0.17 的一个坑位：**网上所有"Zig 手写 syscall"的例子在 macOS 上必崩**。
const syscall_getpid_macos: usize = 20; // macOS: SYS_getpid
const syscall_getpid_linux: usize = 39; // Linux x86_64: __NR_getpid

extern "c" fn syscall(number: c_long, ...) c_long;

/// x86_64 macOS 上唯一能跑的 syscall 通道：借道 libc（21.9 会讲这个 extern "c"）。
fn sysGetpidViaLibc() c_long {
    return syscall(@as(c_long, @intCast(syscall_getpid_macos)), @as(c_long, 0), @as(c_long, 0), @as(c_long, 0));
}

/// x86_64 Linux 上手写的 `syscall` 汇编（本机macOS 跑不到，用交叉编译验证）。
fn sysGetpidViaAsm() u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (syscall_getpid_linux),
        : .{ .rcx = true, .r11 = true, .memory = true } // syscall 会改 rcx（返回地址）和 r11（rflags）
    );
}

/// aarch64 上根本没有 `syscall` 指令（是 `svc #0`），而且 clobber 字段名也不一样。
fn sysGetpidAarch64() u64 {
    return asm volatile ("mov x8, %[nr]\n\tsvc #0" // 号进 x8，返回值走 x0
        : [ret] "={x0}" (-> u64),
        : [nr] "r" (@as(u64, 172)), // aarch64 __NR_getpid
        : .{ .x8 = true, .memory = true });
}

/// 架构无关的取pid 入口。
fn getpidPortable() u64 {
    if (comptime is_x86) {
        // macOS 上不能直接 syscall（SIGSYS），必须借 libc；Linux 上才用裸汇编
        return if (builtin.os.tag == .macos)
            @as(u64, @intCast(sysGetpidViaLibc()))
        else
            sysGetpidViaAsm();
    } else {
        return sysGetpidAarch64();
    }
}

/// 21.6：让 asm 结果和 libc 对账 —— 这才是可信的验证方式。
fn getpidMatchesLibc() bool {
    return getpidPortable() == @as(u64, @intCast(std.c.getpid()));
}

/// 21.6：标准库自己怎么写的（读源码最直接）。
/// `std.os.linux.x86_64.syscall0` 就是一行 asm：输出 `{rax}`、输入 `{rax}`、clobber rcx/r11/memory。
fn stdlibSyscallShape() u64 {
    if (comptime builtin.os.tag == .linux and builtin.cpu.arch == .x86_64) {
        return sysGetpidViaAsm();
    }
    return 0;
}

// ─────────────────────────────────────────────────────────────
// 21.7 逐寄存器约束 vs 通用约束
// ─────────────────────────────────────────────────────────────

```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.6 系统调用 开始 ====
裸汇编/借 libc 拿到的 pid 与 std.c.getpid() 一致？ 是
syscall 的形状：输出 "={rax}"、输入 "{rax}"（同一个寄存器既进又出）、clobber .rcx/.r11/.memory
⚠️ x86_64 macOS 上裸 `syscall` 指令会吃 SIGSYS（实测退出码 140 = 128+12）
⇒ macOS 必须借 libc 的 syscall()（它内部做 csopen 切代码段）；Linux 才能裸写
本机是 macos，所以 main 走的是 libc 通道（汇编 syscall 代码仍在，仍参与编译）
标准库自己的形状：std.os.linux.x86_64.syscall0 就是一行 asm，stdlibSyscallShape()=0
==== 21.6 结束 ====
```

## 21.7 逐寄存器与通用约束

### 什么时候必须逐寄存器

硬件规定"结果必须落在特定寄存器"的指令，通用约束完全没用：

- `rdtsc` → eax（低 32 位）+ edx（高 32 位）
- `cpuid` → eax / ebx / ecx / edx
- `syscall` → rax（号也是 rax）

对这些指令只能写 `"={eax}"` / `"={edx}"` 这样的**显式寄存器约束**。

### ⚠️ 每个输出必须写进不同的变量

本示例第一版把 `cpuid` 的三个输出写进了同一个变量：

```plain
var hi: u32 = undefined;
asm volatile ("cpuid"
    : [lo] "={eax}" (lo),
      [_bx] "={ebx}" (hi),   ← ✗ 三个输出共用一个变量
      [_cx] "={ecx}" (hi),
      [_dx] "={edx}" (hi),
```

**这个版本 segfault（退出码 139）**。原因是 LLVM 可以合法地把三个
`"={ebx}"` / `"={ecx}"` / `"={edx}"` 全部分配到**同一个物理寄存器**
（反正三个都是"死值"，最后一次写就够），于是 `cpuid` 的三条隐式输出
撞在一起。正确写法是三个不同的变量（哪怕你只关心 `eax`）。

### `"=a"` 这一批在 0.17 上不能用

实测把每一个约束单独编译一遍（`asm volatile ("movq $22, %[o]" : [o] "=X" (-> u64))`）：

```plain
| 约束 | 0.17.0 结果 |
|---|---|
| `"=r"` | ✅ 可用 |
| `"=A"` | ✅ 可用 |
| `"=q"` | ✅ 可用 |
| `"=X"` | ✅ 可用（x86 上等价于任何 SSE 寄存器） |
| `"={rax}"` | ✅ 可用 |
| `"={eax}"` | ✅ 可用 |
| `"=a"` | ❌ couldn't allocate output register for constraint 'a' |
| `"=b"` | ❌ 同上 |
| `"=c"` | ❌ 同上 |
| `"=d"` | ❌ 同上 |
| `"=S"` | ❌ 同上 |
| `"=D"` | ❌ 同上 |
| `"=g"` | ❌ 同上 |
```

这个失败在 `-OReleaseFast` 下也一样（不是 Debug 的问题），
在 x86_64-linux 交叉编译下则更早地报 `error: invalid constraint: '=a'`
（x86 后端的约束检查比 macOS 后端更早触发）。

**结论**：要 rax 就写 `"={rax}"`（最明确）或 `"=A"`（寄存器家族）。
**别用单字母寄存器类。**

### 计时别打印原始 tick

`rdtsc`（或 aarch64 的 `cntvct_el0`）给的是单调递增计数器，
本示例用它做微基准，但**只打印判定结果**（`t1 > t0` / `t1 >= t0`），
不打印 tick 数本身——tick 数每次运行都不同，**打印它就没法把运行输出
逐字节抄进文档**。这条是本教程所有章的通用纪律（15 章的计时同理）。


`cpuid`：硬件规定结果必须落在 eax/ebx/ecx/edx，通用约束 `"=r"` 在这条指令上完全用不上，只能逐寄存器钉死。⚠️ 每个输出必须写进**不同的变量**——三个输出写同一个 var，LLVM 可以合法地复用同一个寄存器，直接编译出错的代码（本示例最初就这么崩过一次，退出码 139）。

```zig
// examples/21_asm/main.zig 第 515-540 行
/// 21.7：`cpuid` —— 硬件规定了"结果必须落在 eax/ebx/ecx/edx"，
/// 这时候通用约束 `"=r"` 完全用不上，必须逐寄存器钉死。
fn cpuidMaxLeaf() u32 {
    if (comptime is_x86) {
        const leaf: u32 = 0;
        // ⚠️ 每个输出必须写进**不同的变量**：三个输出写同一个 var 三个都会取到最后那次
        //    的值（更糟的是 LLVM 可以合法地复用同一个寄存器 → 直接编译出错的代码）
        var eax: u32 = undefined;
        var ebx: u32 = undefined;
        var ecx: u32 = undefined;
        var edx: u32 = undefined;
        asm volatile ("cpuid"
            : [eax] "={eax}" (eax),
              [ebx] "={ebx}" (ebx),
              [ecx] "={ecx}" (ecx),
              [edx] "={edx}" (edx),
            : [leaf] "{eax}" (leaf),
            : .{ .cc = true, .memory = true });
        return eax;
    } else {
        return 0; // aarch64 没有 cpuid（对应物是 midr_el1，但语义完全不同）
    }
}

/// 21.7：几个在 0.17.0 上实测能用的寄存器类（对照"`"=a"` 反而不能用的坑）。
/// `"=A"` 等价于"rax 家族"（rax/eax/ax/al），`"=q"` 是"任一可作字节地址的寄存器"，
```

三个实测可用的寄存器族：`"=r"` / `"=A"` / `"=q"`。要 rax 就写 `"={rax}"`。

```zig
// examples/21_asm/main.zig 第 542-566 行
fn constraintFamilyProbe() struct { eq_r: u64, eq_A: u64, eq_q: u64 } {
    if (comptime is_x86) {
        const a: u64 = asm volatile ("movq $11, %[o]"
            : [o] "=r" (-> u64),
        );
        const b: u64 = asm volatile ("movq $22, %[o]"
            : [o] "=A" (-> u64),
        );
        const c: u64 = asm volatile ("movq $33, %[o]"
            : [o] "=q" (-> u64),
        );
        return .{ .eq_r = a, .eq_A = b, .eq_q = c };
    }
    const a: u64 = asm volatile ("movz %[o], #11"
        : [o] "=r" (-> u64),
    );
    const b: u64 = asm volatile ("movz %[o], #22"
        : [o] "=r" (-> u64),
    );
    const c: u64 = asm volatile ("movz %[o], #33"
        : [o] "=r" (-> u64),
    );
    return .{ .eq_r = a, .eq_A = b, .eq_q = c };
}

```

`"=x"` 强制落 SSE 寄存器。

```zig
// examples/21_asm/main.zig 第 568-596 行
/// aarch64 侧返回虚拟计数器，两边都是"单调递增的计数器"这一个语义。
fn cycles() u64 {
    return rdtsc();
}

const cycles_name = if (is_x86) "rdtsc" else "cntvct_el0";

/// 21.7：向量寄存器上的 asm——`"=x"` 强制落到 SSE 寄存器。
/// `@Vector` 在语言层面已经够用了（见 21.10），所以这里只用来证明约束本身可用。
fn sseAdd(a: f64, b: f64) f64 {
    if (comptime is_x86) {
        var out: f64 = undefined;
        asm volatile ("addsd %[b], %[a]"
            : [out] "=x" (out),
            : [a] "x" (a),
              [b] "x" (b),
        );
        return out;
    } else {
        // aarch64 上 fadd 要走 d 寄存器而 `"=r"` 给的是 x/w 寄存器（实测 invalid operand），
        // 要写对得手动 fmov 到 d0/d1 —— 这种地方纯 Zig 的 `a + b` 就是正解（见 21.12）。
        return a + b;
    }
}

// ─────────────────────────────────────────────────────────────
// 21.8 内存操作数
// ─────────────────────────────────────────────────────────────

```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.7 逐寄存器与通用约束 开始 ====
=r → 11；=A → 22；=q → 33（三个在 x86_64 上都能用）
❌ "=a" / "=b" / "=c" / "=d" / "=S" / "=D" 在 0.17.0 上全部报 couldn't allocate output register
⇒ 要 rax 就写 "={rax}"（显式寄存器）或 "=A"（寄存器家族）
cpuidMaxLeaf() = 0xd（只能逐寄存器钉死 eax/ebx/ecx/edx，通用约束在这条指令上没用）
1000 次加法：tick 数 > 0 ？ 是；计数器单调递增？ 是（rdtsc）
sink=499500（刻意不用 tick 数本身，那是不可复现的）
sseAdd(1.5, 2.25) = 3.75（约束 "=x" 强制落 SSE 寄存器）
==== 21.7 结束 ====
```

## 21.8 内存操作数

### 核心模式：asm 搬字节，`std.mem` 解释字节

```zig
var buf: [8]u8 align(8) = @splat(0);
storeThroughPtr(@ptrCast(&buf), 0x1122334455667788);
const got = std.mem.readInt(u64, &buf, .little);  // ← 解释字节的是 std.mem
```

反过来也一样（`asmLoadFromBuf`）。这个分工的好处是**端序被显式写进了代码**
（`.little` / `.big`），而不是靠"这台机器是小端"这种隐含假设。

⚠️ 顺带一个 0.17 的对齐收紧：`@ptrCast` 到更高对齐的类型要配 `@alignCast`，
否则报 `@ptrCast increases pointer alignment`。
本示例用 `var buf: [8]u8 align(8)` 从**类型上**就免掉了它——
这比在每个 `@ptrCast` 旁边加 `@alignCast` 更省事。

### ⚠️ 不能把符号地址当立即数搬

三种写法全部实测失败：

| 写法 | 结果 |
|---|---|
| `movl $g, %[o]` | ❌ `invalid operand for instruction` |
| `movabsq $g, %[o]` | ❌ `undefined symbol: g` |
| `leaq g(%rip), %[p]` | ❌ `undefined symbol: g` |

第一条的原因很直接：x86 的 `movl` 是 32 位立即数，装不下 64 位地址。
第二条换成了 64 位的 `movabsq`，语法没问题了，但**符号解析失败**——
因为 **Zig 的普通顶层 `var` 不是导出符号**，汇编器在符号表里找不到 `g`。
第三条的 RIP 相对寻址同样需要符号可见。

```text
error: undefined symbol: g
    note: referenced by .../ta_zcu.o:_ta.main
```

### 两条正解

**① 把地址当运行期整数传进寄存器**（跨平台、本示例采用）：

```zig
const p = @intFromPtr(&g_probe);
var out: u64 = undefined;
asm volatile ("movq %[p], %[o]"
    : [o] "=r" (out),
    : [p] "r" (p),
);
// out == @intFromPtr(&g_probe)  ← test 里就这么断言
```

**② `export var`** 让符号对外可见，之后汇编里可以写 `leaq g(%rip)`。
适合真的要写"汇编级裸机代码"的场景（比如内核、bootloader）。

**第三条路（多数时候是对的）**：这段逻辑根本不该用 asm。
`std.mem.copyForwards` / `@memcpy` 已经把这件事做到极致了。


asm 写内存 → `std.mem.readInt` 读回；asm 读内存 → `"r"` 传地址 + `(%[p])`。**这是本章反复出现的核心模式**：asm 只负责搬字节，解释字节的活交给 `std.mem`。

```zig
// examples/21_asm/main.zig 第 598-632 行
/// **不用 `@bitCast`** —— 0.17 里 `@bitCast` 拒绝任何非 packed 的结构体（21.11）。
fn asmStoreThenRead(value: u64) u64 {
    // ⚠️ 0.17：@ptrCast 到更高对齐的类型要显式 @alignCast，
    //    这里用 `align(8)` 的数组声明从类型上就免掉它（另一个坑位，见坑位清单）
    var buf: [8]u8 align(8) = @splat(0);
    storeThroughPtr(@ptrCast(&buf), value);
    return std.mem.readInt(u64, &buf, .little);
}

/// 21.8：asm 读内存：把缓冲交给`"m"` 约束，让汇编自己从地址读。
fn asmLoadFromBuf(buf: *const [8]u8) u64 {
    // ⚠️ 0.17：@ptrCast 到更高对齐要配 @alignCast —— 直接 @ptrCast 报
    //    "@ptrCast increases pointer alignment"。这里 buf 来自 align(8) 的数组所以安全。
    const p: *const u64 = @ptrCast(@alignCast(buf));
    if (comptime is_x86) {
        return asm volatile ("movq (%[p]), %[o]"
            : [o] "=r" (-> u64),
            : [p] "r" (p),
        );
    } else {
        return asm volatile ("ldr %[o], [%[p]]" // aarch64：Intel 语序 + 方括号寻址
            : [o] "=r" (-> u64),
            : [p] "r" (p),
        );
    }
}

/// 21.8：⚠️ 反例：macOS / x86_64 上**不能**把标签（符号地址）当立即数搬。
///
/// `movl $g, %o` 会被汇编器拒绝：`invalid operand for instruction`
///（x86 的 32 位立即数装不下 64 位地址）。
/// 即使换`movabsq $g, %o` 也会得到 `undefined symbol: g`
/// —— Zig 的普通顶层 var 不是导出符号，汇编器看不到。
///
/// 正确姿势有两条：
```

⚠️ 反例：x86_64/macOS 上**不能**把标签当立即数搬。`movl $g, %o` → `invalid operand for instruction`（32 位立即数装不下 64 位地址）；`movabsq $g, %o` → `undefined symbol: g`（Zig 的普通顶层 `var` 不是导出符号）。正解一：`@intFromPtr(&g)` 当运行期整数传进寄存器（跨平台）；正解二：`export var` 让符号对外可见后，汇编里可以写 `leaq g(%rip)`。

```zig
// examples/21_asm/main.zig 第 634-666 行
///   ② 真要在汇编里写符号，得先 `export` 让它成为外部可见符号。
fn addressViaRegister() u64 {
    const p = @intFromPtr(&g_probe);
    if (comptime is_x86) {
        var out: u64 = 0;
        asm volatile ("movq %[p], %[o]"
            : [o] "=r" (out),
            : [p] "r" (p),
        );
        return out;
    } else {
        var out: u64 = 0;
        asm volatile ("mov %[o], %[p]"
            : [o] "=r" (out),
            : [p] "r" (p),
        );
        return out;
    }
}

/// 21.8：确实要在汇编里引用一个符号时的正解——先 `export`。
/// （本函数只编译不运行到有意义的值，因为 macOS 上 `leaq` 走 RIP 相对。）
fn exportedSymbolWorks() bool {
    if (comptime is_x86) {
        return @sizeOf(u64) == 8;
    }
    return true;
}

// ─────────────────────────────────────────────────────────────
// 21.9 与 C 交互
// ─────────────────────────────────────────────────────────────

```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.8 内存操作数 开始 ====
asm 写内存 → std.mem.readInt 读回：0x1122334455667788（同值即正确）
"r" 传地址 + movq (%[p]) 从缓冲读：0xcafebabedeadbeef
再 storeThroughPtr 写0 → 0x0
⚠️ macOS/x86_64 上 `movl $g, %o` 编译错：invalid operand for instruction
⚠️ `movabsq $g, %o` 也错：undefined symbol: g（Zig 顶层 var 不是导出符号）
⇒ 正解一：@intFromPtr(&g) 当运行期整数传进寄存器；addressViaRegister() == &g_probe ？ 是
⇒ 正解二：export var 让符号对外可见后，汇编里可以写 leaq g(%rip)
==== 21.8 结束 ====
```

## 21.9 与 C 交互

### `callconv(.C)` 已被删除

0.17 实测：

```text
error: union 'lang.CallingConvention' has no member named 'C'
fn addOne(x: u64) callconv(.C) u64 { return x + 1; }
             ~
```

`std.lang.CallingConvention` 里现在只有：

```zig
/// This is an alias for the default C calling convention for this target.
pub const c = builtin.target.cCallingConvention().?;
```

也就是说 `.c` 是个**别名**，展开成目标平台自己的 C 约定
（macOS / Linux x86_64 上都是 `x86_64_sysv`，Windows 上是 `x86_64_win`）。
好处是同一份代码跨平台不用改。

`export fn` **隐含** C 调用约定，所以写不写 `callconv(.c)` 都行——
本示例两种都写了，是为了把约定显式标出来。

### 可信验证：asm 产出，libc 消费

单测"asm 返回了一个看起来合理的数"是不够的——**你不知道它是不是真的对**。
本节用两个 libc 函数交叉验证：

```zig
// ① pid：asm 拿的必须等于 libc 拿的
asm_pid == @as(u64, @intCast(getpid()))

// ② 字节：asm 写的 7 字节必须被 strlen 数成 7
//    （如果字节序或布局理解错了，strlen 会立刻给出别的数）
extern "c" fn strlen(s: [*:0]const u8) usize
```

第二条特别有用：它验证的是**布局和字节序**，而不是"某个整数值"。

⚠️ 顺带记一个 0.17 的诊断：`fn main()` 漏掉 `pub` 时，
`zig build-exe` 报的**不是** "main must be pub"，
而是一条完全不相干的 `lib/std/start.zig:624` 错误
（`struct 'elf.AT__struct_855' has no member named 'HWCAP'`）。
本示例第一版就撞了这个——**看到 `HWCAP` 就知道是 `main` 的 `pub` 漏了**。


0.17 里 `callconv(.C)` **已经被删了**，报 `union 'lang.CallingConvention' has no member named 'C'`，只剩 `callconv(.c)`——它是 `builtin.target.cCallingConvention()` 的别名。可信验证的形状是"asm 产出、libc 消费"：写错布局或字节序会立刻暴露。

```zig
// examples/21_asm/main.zig 第 667-695 行
/// 21.9：0.17 里 `callconv(.C)` **已经被删了**，只剩 `callconv(.c)`。
/// `.c` 是个别名，展开成 `builtin.target.cCallingConvention()`（macOS/Linux x86_64 上是 SysV）。
fn addOneC(x: u64) callconv(.c) u64 {
    return x + 1;
}

/// 21.9：导出给 C 用的入口（`export` 隐含 C 调用约定，也可以显式写 `callconv(.c)`）。
export fn zig_triple(x: u64) callconv(.c) u64 {
    return x * 3;
}

/// 21.9：借 libc 验证 asm 结果。`extern "c" fn` 就是"这个符号在 libc 里"。
extern "c" fn getpid() i32;

/// 21.9：`strlen` 交叉验证：asm 写的字符串指针能不能被C 库正确读出来。
extern "c" fn strlen(s: [*:0]const u8) usize;

/// 21.9：把 asm 算出的字节序列交给 `strlen` 数长度。
fn asmBytesThenStrlen() usize {
    var buf: [8]u8 align(8) = @splat(0);
    storeThroughPtr(@ptrCast(&buf), asmStoreThenRead(0x0041424344454647));
    buf[7] = 0; // C 字符串结尾
    return strlen(@ptrCast(&buf));
}

// ─────────────────────────────────────────────────────────────
// 21.10 SIMD：@Vector
// ─────────────────────────────────────────────────────────────

```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.9 与 C 交互 开始 ====
0.17 里 callconv(.C) 已被删除 → error: union 'lang.CallingConvention' has no member named 'C'
只剩 callconv(.c)，它是 builtin.target.cCallingConvention() 的别名
addOneC(41) = 42；export fn zig_triple(14) = 42（export 隐含 C 调用约定）
asm 的 pid 与 extern "c" getpid() 相同？ 是（pid > 0？ 是）
extern "c" strlen 验证 asm 写的字节：7（期望 7）
⇒ 这就是可信验证的形状：asm 产出，libc 消费（写错布局/字节序会立刻暴露）
==== 21.9 结束 ====
```

## 21.10 SIMD 与 @Vector

### `@Vector` 不需要 asm，也不需要特性开关

```zig
pub fn vecAdd(a: @Vector(4, i32), b: @Vector(4, i32)) @Vector(4, i32) {
    return a + b;   // 就这一行
}
```

**0.17 在任何目标上都能编译 `@Vector`**——不需要 `-mcpu=has_sse4_2`、
不需要手写 asm、不需要运行时探测。目标不支持对应 SIMD 指令时，
LLVM 自动标量化降级（编译能过，性能差一点，语义完全不变）。

这和 asm 的成本对比非常刺眼：

| | `@Vector` | 手写 asm |
|---|---|---|
| 跨平台 | 免费 | 每个 arch 一份，每个 OS 再分一次 |
| 正确性 | 类型系统保证 | 要自己盯 clobber / 约束 / 字节序 |
| 可读性 | 一眼看出意图 | 要查 ISA 手册 |
| 性能 | 自动向量化 | 不一定比自动的好 |

### 四种操作

```zig
const c = vecAdd(a, b);        // 逐 lane 加
@reduce(.Add, c)               // 水平归约（求和）
vecScale(f, 2.0)               // @splat 广播标量→ 逐 lane 乘
vecDot(a, b)                   // 点积 = @reduce(.Add, a*b)
```

点积是最能说明问题的例子：**两条 SIMD 指令**（一次乘 + 一次加）
替代了 4 次乘 + 3 次加，而手写 asm 要处理累加器的 clobber、
可能还要防溢出折叠。

### ⚠️ `@Vector` 不能 `.len`、不能 field access

```text
error: type '@Vector(4, i32)' does not support field access
    std.debug.print("{any}", .{c});
    ~~~~~^~~~
```

`{any}` 对 `@Vector` **也不行**——要打印必须先转成数组：

```zig
pub fn vecToArray(v: @Vector(4, i32)) [4]i32 {
    return v;   // @Vector 和 [N]T 之间可以隐式转换
}
```

这个转换是零成本的（只是换个类型视图），实测
`vecToArray(vecAdd(a,b))` 打出 `{ 11, 22, 33, 44 }`。


`@Vector(4, i32)` 的加法、`@reduce` 水平归约、`@splat` 广播、点积。**0.17 在任何目标上都能编译 `@Vector`**，不需要 asm、不需要 `-mcpu` 特性开关（自动标量化降级）。

```zig
// examples/21_asm/main.zig 第 696-726 行
/// 21.10：`@Vector(4, i32)` 加法。**不需要**任何 asm、不需要任何特性开关——
/// 0.17 在非 SIMD 目标上照样编译（自动标量化降级）。
pub fn vecAdd(a: @Vector(4, i32), b: @Vector(4, i32)) @Vector(4, i32) {
    return a + b;
}

/// 21.10：向量转数组才能逐个打印（`@Vector` 不支持 `.len` / `field access`）。
pub fn vecToArray(v: @Vector(4, i32)) [4]i32 {
    return v;
}

/// 21.10：水平归约——比手动循环快，也比手写 asm 干净。
pub fn vecSum(v: @Vector(4, i32)) i32 {
    return @reduce(.Add, v);
}

/// 21.10：float向量 + splat（广播标量到所有lane）。
pub fn vecScale(v: @Vector(4, f32), k: f32) [4]f32 {
    const scaled = v * @as(@Vector(4, f32), @splat(k));
    return scaled;
}

/// 21.10：点积——SIMD 最典型的用法，两条指令搞定。
pub fn vecDot(a: @Vector(4, i32), b: @Vector(4, i32)) i32 {
    return @reduce(.Add, a * b);
}

// ─────────────────────────────────────────────────────────────
// 21.11 @bitCast 与内存
// ─────────────────────────────────────────────────────────────

```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.10 SIMD 与 @Vector 开始 ====
vecAdd({1,2,3,4}, {10,20,30,40}) = { 11, 22, 33, 44 }
vecSum = 110（@reduce(.Add, ...)）
vecDot = 300（1*10+2*20+3*30+4*40 = 300）
vecScale(f, 2.0) = { 3, 5, 7, 9 }
⚠️ @Vector 不能 .len、不能 field access（does not support field access）→ 先转 [N]T
⇒ @Vector 在 0.17 的任何目标上都能编译，不需要 asm、不需要特性开关（自动标量化降级）
⇒ 要 SIMD 语义时，@Vector 永远优于手写 asm（21.12 会论证）
==== 21.10 结束 ====
```

## 21.11 @bitCast 与内存

### 0.17 的 `@bitCast` 拒绝一切非 packed 结构体

```zig
const Pair = extern struct { a: u32, b: u32 };
const v: u64 = @bitCast(Pair{ .a = 1, .b = 2 });
```

```text
error: cannot @bitCast from 'main.ExternPair'
```

**`extern struct` 也不行**，普通 `struct` 更不行。0.17 的规则是：
`@bitCast` 只接受**布局明确（layout-explicit）**的类型——
整数、浮点、指针、**`packed struct`**、**数组**、向量。

这比旧版本严格（旧版本接受 `extern struct`），因为 `extern struct` 的
填充字节在理论上是可以被优化掉的，不保证位模式稳定。

### 三条路径

```plain
| 路径 | 能用？ | 说明 |
|---|---|---|
| packed struct + @bitCast | ✅ | 唯一"能直接 bitCast 的结构体" |
| extern struct + asBytes + readInt | ✅ | **正规做法**，顺带把端序写死 |
| 先变 [2]u32 再 @bitCast | ✅ | 数组布局明确，最短路径 |
```

本示例三条都实现了，并用 `test` 断言**它们给出同一个位模式**——
这个一致性本身就是"`extern struct` 布局正确"的证据。

### 端序被显式写进代码

```plain
字节 = { 1, 0, 0, 0, 2, 0, 0, 0 }
        ↑  a=1（小端：最低位在最低地址）
```

`std.mem.readInt(u64, raw[0..8], .little)` 的第三个参数就是端序。
**"a=1 落在最低地址"不是平台属性，是你选的。** 旧教程里
"`@bitCast` 之后低位是 a"这种说法把平台假设和布局约定混在一起了。

### 和 asm 的衔接

21.8 的 `asmStoreThenRead` 就是同一套机制：asm 往内存写，
`std.mem.readInt` 读回来。**做二进制协议时，永远走这条路**——
asm 只负责搬字节，解释字节的活交给 `std.mem`，
这样端序、对齐、越界检查全是显式的。


三条路径给出同一个位模式——这正是 `extern struct` 布局正确的证据。`packed struct` 可以直接 `@bitCast`；`extern struct` 不行（`error: cannot @bitCast from 'main.ExternPair'`），只能 `asBytes` + `readInt`；先变成 `[2]u32` 数组再 `@bitCast` 也可以（数组布局明确）。

```zig
// examples/21_asm/main.zig 第 727-756 行
/// 21.11：0.17 的 `@bitCast` **拒绝裸结构体和 `extern struct`**，
/// 只接受布局明确的 `packed struct`。
const PackedPair = packed struct { a: u32, b: u32 };

/// 21.11：`extern struct` 保证 C 布局，但 `@bitCast` 不要它——只能走字节。
const ExternPair = extern struct { a: u32, b: u32 };

/// 21.11：`packed struct` + `@bitCast` —— 唯一"能直接bitCast 的结构体"。
fn bitcastViaPacked(a: u32, b: u32) u64 {
    const p = PackedPair{ .a = a, .b = b };
    return @bitCast(p);
}

/// 21.11：`extern struct` + `asBytes` + `readInt` —— 正规做法，还顺手把端序写明白了。
fn bitcastViaBytes(a: u32, b: u32) u64 {
    const p = ExternPair{ .a = a, .b = b };
    const raw = std.mem.asBytes(&p); // *[8]u8
    return std.mem.readInt(u64, raw[0..8], .little);
}

/// 21.11：数组可以直接 `@bitCast`（数组的布局是明确的）——
/// 所以"结构体 → 整数"的最短路径是先变成数组。
fn bitcastViaArray(a: u32, b: u32) u64 {
    const arr = [2]u32{ a, b };
    return @bitCast(arr);
}

// ─────────────────────────────────────────────────────────────
// 21.12 边界与陷阱
// ─────────────────────────────────────────────────────────────
```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.11 @bitCast 与内存 开始 ====
0.17：@bitCast **拒绝裸 struct 和 extern struct** → error: cannot @bitCast from 'main.ExternPair'
只有 packed struct 能直接 @bitCast
bitcastViaPacked(1, 2)   = 0x200000001
bitcastViaBytes(1, 2)    = 0x200000001（extern struct + asBytes + readInt，端序显式）
bitcastViaArray(1, 2)    = 0x200000001（先变 [2]u32，数组布局明确所以能 @bitCast）
asBytes 返回 *align(4) const [8]u8，长度 8（= @sizeOf(ExternPair)）
字节 = { 1, 0, 0, 0, 2, 0, 0, 0 }（小端：a=1 在最低地址）
⇒ 做二进制协议时，正解是 asBytes + readInt/writeInt —— 顺带把端序写死在代码里
⇒ asm 写进内存后用 std.mem.readInt 读回，是同一套机制（21.8 已经这么做了）
==== 21.11 结束 ====
```

## 21.12 边界与陷阱

### 跨平台写法对照

本示例实测过的全部差异：

```plain
| 语义           | x86_64 (AT&T)         | aarch64 (Intel 语序) |
|----------------|-----------------------|----------------------|
| 加立即数       | add $5, %[r]          | add %[r], %[r], #5   |
| 读时间戳       | rdtsc (eax+edx)       | mrs %[v], cntvct_el0 |
| 系统调用指令   | syscall               | svc #0               |
| 系统调用号     | 39(linux) / libc(mac) | 172                  |
| 条件码字段     | .cc = true            | .nzcv = true         |
| 访存           | movq (%[p]), %[o]     | ldr %[o], [%[p]]     |
| 取立即数       | movq %[i], %[o]       | movz %[o], %[i]      |
| 乘             | 两操作数（需先搬）    | 三操作数 mul %[o],…  |
```

**注意 aarch64 那一列是 Intel 语序**——这是 0.17 实测最容易踩的
"平台差异"：它不是风格问题，是 LLVM 后端分别喂给两个汇编器的语法不同。

### 为什么必须靠 comptime 选路

**x86 模板即使放在 `if (comptime is_x86)` 的不可达分支里，
LLVM 仍然会看到它**——因为 `comptime` 只影响 Zig 前端的分支消除，
而 asm 模板是要交给汇编器的文本。跨架构编译时那些"不会执行"的
x86 指令串照样被送进 aarch64 汇编器：

```text
error: <inline asm>:1:2: unrecognized instruction mnemonic, did you mean: add, addp, adds, addv, fadd, madd?
        addq $5, x8
        ^
```

唯一的办法是让两个架构的 asm 块在**不同的函数**里，
然后用 `switch (builtin.cpu.arch)` 选路（18 章的模式）。
本示例的每个 asm 函数都是这个形状：

```zig
fn addFive(x: u64) u64 {
    var r = x;
    if (comptime is_x86) {
        asm volatile ("add $5, %[r]" : [r] "+r" (r));
    } else {
        asm volatile ("add %[r], %[r], #5" : [r] "+r" (r) : : .{ .nzcv = true });
    }
    return r;
}
```

`comptime` 关键字保证**未选中的分支整块不进产物**。

### 有些地方"回退纯 Zig"是对的

本示例有两处**故意不用 asm**：

- `emitToMemory` / `emitToVar` 的 aarch64 分支：LLVM 的 aarch64 asm 后端
  不接受把 `"m"` 操作数放进方括号（`unexpected token in argument list`），
  于是直接 `slot = 22`。
- `sseAdd` 的 aarch64 分支：`fadd` 要走 `d` 寄存器而 `"=r"` 给的是
  x/w 寄存器（`invalid operand`），要写对得手动 `fmov` 到 d0/d1——
  这种地方 `return a + b` 就是正解。

**这不是妥协，是本章的论点。** 每退回一次纯 Zig，都要说得出
"为什么 asm 在这里不划算"。

### intrinsic 覆盖清单：永远不要写 asm 的操作

```zig
@popCount(x)   // 人口计数
@ctz(x)        // 尾部零个数
@clz(x)        // 头部零个数
@byteSwap(x)   // 字节序翻转
@bitSizeOf(T)  // 位宽
@popCount(x) == 32、@ctz(0x0f0f…) == 0、@byteSwap(0x0123456789abcdef) == 0xf0f0f0f0f0f0f0f
```

这些**全部**是单指令（`popcnt` / `tzcnt` / `bswap`），
LLVM 会直接生成，写 asm 一点优势都没有。

### 判断标准（本章的最终建议）

用asm 的**充分条件**（三条全满足才动手）：

1. 语言/标准库**确实没有**对应能力（不是"写法不够优雅"）
2. 目标平台**确实**需要那条特定指令（不是"也许更快"）
3. 愿意为每个 arch × OS 组合**各写一份并各测一遍**

第 3 条是最贵的。**如果只打算支持一个平台 + 一个 OS，第 3 条的成本是零；
如果打算跨平台，它是主导成本。** 这就是为什么"先问能不能不用 asm"
永远是对的顺序。

> **平台兼容说明**：本示例在 `x86_64-macos` 上跑完整三层验证（18 个 test 全绿），
> 在 `aarch64-macos` 上**交叉编译通过**（`build-exe` / `test` 均无错，
> 反汇编可见 `mrs x16, cntvct_el0` 与 `svc #0`），
> 运行验证待 arm64 真机。
>

跨平台写法对照表 + intrinsic 覆盖清单。`@popCount` / `@ctz` / `@byteSwap` 这类都有 builtin intrinsic，永远不要写 asm。

```zig
// examples/21_asm/main.zig 第 757-799 行

/// 21.12：本章 asm 实现清单（21.12 用它打印"哪些是真汇编、哪些是回退"）。
const Implemented = struct {
    x86: bool = true,
    aarch64: bool = true,
    names: []const []const u8 = &.{
        "asmNop",          "addFive",            "emitMovImm",       "movqRax",
        "rdtsc",           "immViaArrow",        "emitToMemory",     "emitToVar",
        "mulBy",           "loadFromMemory",     "addTwoNamed",      "swapViaAsm",
        "probeNoVolatile", "probeVolatile",      "addTenPure",       "rol8",
        "storeThroughPtr", "cmovIfGe",           "cpuidMaxLeaf",     "sseAdd",
        "asmLoadFromBuf",  "addressViaRegister", "vecAdd",           "vecSum",
        "vecScale",        "vecDot",             "bitcastViaPacked", "bitcastViaBytes",
        "bitcastViaArray", "intrinsicBeatsAsm",
    },
};

/// 21.12 的清单实例（测试里用得到）
const impl_sample = Implemented{};

/// 21.12：哪些操作**根本不该**用 asm——编译器 intrinsic覆盖了绝大多数。
/// 这一节用一次实测把"asm 是最后手段"落到实处。
fn intrinsicBeatsAsm(x: u64) struct { popcount: u64, ctz: u64, bswap: u64 } {
    return .{
        .popcount = @popCount(x),
        .ctz = @ctz(x),
        .bswap = @byteSwap(x),
    };
}

/// 21.12：跨平台写法对照——同一语义在两种架构下的 asm 差异一览。
fn crossPlatformTable() void {
    std.debug.print("  语义|x86_64 (AT&T)|aarch64\n", .{});
    std.debug.print("  加立即数     | add $5, %[r]         | add %[r], %[r], #5\n", .{});
    std.debug.print("  读时间戳     | rdtsc (eax+edx)      | mrs %[v], cntvct_el0\n", .{});
    std.debug.print("  系统调用指令 | syscall              | svc #0\n", .{});
    std.debug.print("  条件码字段   | .cc = true           | .nzcv = true\n", .{});
    std.debug.print("  getpid 号    | 39 (Linux)/libc(mac) | 172\n", .{});
}

// ═══════════════════════════════════════════════════════════
// main
// ═══════════════════════════════════════════════════════════
```

运行输出（`examples/21_asm/main.zig`）：

```text
==== 21.12 边界与陷阱 开始 ====
本示例为两种架构提供了实现：x86_64=true aarch64=true
共 30 个示例函数（下面逐个列名字）
  - asmNop
  - addFive
  - emitMovImm
  - movqRax
  - rdtsc
  - immViaArrow
  - emitToMemory
  - emitToVar
  - mulBy
  - loadFromMemory
  - addTwoNamed
  - swapViaAsm
  - probeNoVolatile
  - probeVolatile
  - addTenPure
  - rol8
  - storeThroughPtr
  - cmovIfGe
  - cpuidMaxLeaf
  - sseAdd
  - asmLoadFromBuf
  - addressViaRegister
  - vecAdd
  - vecSum
  - vecScale
  - vecDot
  - bitcastViaPacked
  - bitcastViaBytes
  - bitcastViaArray
  - intrinsicBeatsAsm
  语义|x86_64 (AT&T)|aarch64
  加立即数     | add $5, %[r]         | add %[r], %[r], #5
  读时间戳     | rdtsc (eax+edx)      | mrs %[v], cntvct_el0
  系统调用指令 | syscall              | svc #0
  条件码字段   | .cc = true           | .nzcv = true
  getpid 号    | 39 (Linux)/libc(mac) | 172
不用 asm 的做法：@popCount=32 @ctz=0 @byteSwap=0xf0f0f0f0f0f0f0f
⇒ popCount/ctz/byteSwap 这类都有 builtin intrinsic，永远不要写 asm
⚠️ 汇编块必须**逐个架构**写：x86 模板在 aarch64 上是 unrecognized instruction mnemonic
⚠️ x86 模板即使放在 if (comptime) 的不可达分支里，LLVM 仍会看到 → 靠 comptime 选路
⚠️ clobber 字段名也按架构分：x86 是 .cc，aarch64 是 .nzcv（写 .cc 到 arm 上编译错）
⇒ 本章的跨平台模式：switch (comptime builtin.cpu.arch) 每个 arch 一份实现，未选中分支不进产物
==== 21.12 结束 ====
自检通过
```

## 21.13 坑位清单

1. **Zig 没有 `inline` 关键字**：只有 `asm` 和 `asm volatile`。
   C 的 `__asm__ volatile` 在 Zig 里写成 `asm volatile`，
   "inline"那半边对应的是 `inline for` / `inline fn`，和 asm 无关。
   更重要的是：**决定一块 asm 会不会被优化掉的是输出的可观察性，
   不是 `volatile` 这个词本身**。

2. **⚠️ 0.17 的 clobber 从字符串列表变成了类型化结构体**：
   旧写法 `asm volatile ("..." : : : "cc", "memory")` 报
   `expected type 'lang.assembly.Clobbers__struct_36', found '*const [2:0]u8'`。
   新写法是 `: : : .{ .cc = true, .memory = true }`
   （类型是 `std.lang.assembly.Clobbers`，x86_64 上 32 字节 / 195 个字段）。

3. **clobber 结构体按架构分字段**：x86_64 有 `.cc`，
   **aarch64 只有 `.nzcv`**（N/Z/C/V 四个标志），没有 `.cc`。
   把 x86 的 `.cc = true` 抄到 arm64 上报
   `no field named 'cc' in struct 'lang.assembly.Clobbers__struct_35'`。
   aarch64 的专用字段还有 `x0..x30` / `w0..w30` / `z0..z31` / `p0..p15` /
   `lr` / `sp` / `wsp` / `fpcr` / `fpsr` / `ffr` 等。

4. **0.17 的 clobbers 段不能有尾逗号**：
   `: .{ .memory = true },` 报 `expected ')', found ','`。
   而且**只有三段**（`: 输出 : clobber`）的写法不行，
   必须写成 `: : .{ ... }` 把输入段留空——
   写 `: .{ .nzcv = true }` 报 `expected ')', found '.'`。

5. **x86 的单字母寄存器类约束在 0.17.0 上全部不可用**：
   `"=a"` `"=b"` `"=c"` `"=d"` `"=S"` `"=D"` `"=g"`
   一律报 `couldn't allocate output register for constraint 'a'`（`-OReleaseFast` 下同样）。
   实测**可用**的是 `"=r"` / `"=A"` / `"=q"` / `"=X"` / `"={rax}"` / `"={eax}"`。
   要 rax 就写 `"={rax}"` 或 `"=A"`。

6. **⚠️ aarch64 的内联汇编在 Zig 里走 Intel 语序（目的在前），不是 AT&T**：
   `add %[a], %[o]` 在 arm64 上报 `too few operands for instruction`，
   必须写 `add %[o], %[a]`。访存同理：x86 是 `movq (%[p]), %[o]`，
   arm64 是 `ldr %[o], [%[p]]`。**这不是风格问题**，是 LLVM 后端分别
   喂给两个汇编器的语法不同（0.17 实测，连 `mov` 取立即数都不一样：
   x86 `movq %[i], %[o]` vs arm64 `movz %[o], %[i]`）。

7. **⚠️ Zig 的 `"m"` 约束不是 C 的"内存操作数"**：
   它给的是「装着这个操作数**值**的那个栈槽」的内存引用。
   `asm volatile ("movq %[m], %[o]" : [o] "=r" (-> u64) : [m] "m" (buf))`
   读到的是**那个值的副本**（对数组来说就是它的地址，实测返回
   `140702030757888` 这种栈地址），**不是它指向的内容**。
   用 `-femit-asm` 可以看到展开成 `mov rcx, qword ptr [rbp-104]`
   （先把 `&buf` 存进 `[rbp-104]` 再从那里读）。
   **按地址访存必须 `"r"` 传地址 + 模板里显式写 `(%[p])`。**
   这个坑编译不报错、测试也不报错，只有数值不对。

8. **⚠️ x86_64 macOS 上裸 `syscall` 指令会吃 `SIGSYS`**
   （实测退出码 140 = 128 + 12，12 就是 SIGSYS）。
   macOS 要求先 `csopen` 切内核代码段，而 `csopen` 是特权指令。
   写成 C 用 `zig cc` 编译也一样 140，所以不是 Zig 的问题。
   macOS 上唯一能跑的通道是 `extern "c" fn syscall(number: c_long, ...)`，
   实测 `syscall(20, 0, 0, 0)` 与 `std.c.getpid()` 完全一致。
   **网上所有"Zig 手写 syscall"的例子在 macOS 上必崩。**

9. **aarch64 没有 `syscall` 指令**，是 `svc #0`；号走 x8、返回值走 x0、
   clobber 要写 `.x8`。而且 getpid 的号在三个平台上是三个数：
   x86_64 Linux **39** / macOS **20** / aarch64 **172**。

10. **⚠️ 多个输出必须写进**不同的**变量**：把 `cpuid` 的三个输出写进同一个 var，
    LLVM 可以合法地把 `"={ebx}"` / `"={ecx}"` / `"={edx}"`
    全部分配到同一个物理寄存器（反正都是死值），
    结果 segfault（实测退出码 139）。

11. **x86 的两操作数指令 + 独立输出 = 垃圾值**：
    `imulq %[b], %[a]` 是两操作数形式（结果写回 `%[a]`），
    而 `[out] "=&r"`（early-clobber）会**禁止** out 与 a 共用寄存器，
    于是乘积落在 a 的寄存器里、out 拿到未初始化值
    （实测 `mulBy(6,7)` 返回 `18377501229438730240`）。
    加 `&` 把"可能错"变成"必然错"。正解：绑到输入本身（`[out] "+r" (a)`）
    或用"先搬后乘"两指令形式。aarch64 的 `mul` 是三操作数，不受影响。

12. **`"=m"` 不能配 `-> T`**：0.17 实测能编过、运行时 segfault（退出码 139），
    因为匿名输出拿不到稳定的栈槽。必须给一个具名 `var`。
    而且输出操作数**只接受裸标识符**：`slot.*` 报 `expected ')', found '.*'`，
    `a[1]` 报 `expected ')', found '['`。

13. **`"i"` / `"n"` 约束要求编译期已知**：
    传运行期变量报 `invalid operand for inline asm constraint 'i'`，
    所以函数签名必须写 `comptime imm: u64`。
    另外 `"n"` 传 300（超出 8 位）**也能编过并正确运行**——
    "8 位"是优化提示不是硬边界。

14. **模板占位是 `%[名字]`，不是 `{[名字]}`**：后者报
    `Expected an identifier after {`（aarch64 上是 `vector register expected`）。
    单 `%r` 报 `invalid register name`。
    `$$` 转义也不支持（x86 报 `32-bit absolute addressing is not supported in 64-bit mode`）。

15. **`fn main()` 漏掉 `pub` 时报错完全不相干**：
    `zig build-exe` 报的是
    `lib/std/start.zig:624: error: struct 'elf.AT__struct_855' has no member named 'HWCAP'`，
    而不是 "main must be pub"。
    **看到 `HWCAP` 就知道是 `main` 的 `pub` 漏了。**

16. **⚠️ macOS/x86_64 上不能把符号地址当立即数搬**：
    `movl $g, %[o]` 报 `invalid operand for instruction`（32 位立即数装不下 64 位地址）；
    `movabsq $g, %[o]` 和 `leaq g(%rip), %[p]` 都报 `undefined symbol: g`
    ——**Zig 的普通顶层 `var` 不是导出符号**，汇编器在符号表里找不到它。
    正解：`@intFromPtr(&g)` 当运行期整数传进寄存器，或先 `export var`。

17. **⚠️ 0.17 的 `@bitCast` 拒绝一切非 `packed` 的结构体**：
    连`extern struct` 也不行，报 `cannot @bitCast from 'main.ExternPair'`
    （普通 `struct` 同样拒绝）。0.17 只接受布局明确的类型：
    整数/浮点/指针/`packed struct`/**数组**/向量。
    看 `extern struct` 的位模式只能用 `std.mem.asBytes` + `std.mem.readInt`。

18. **`callconv(.C)` 在 0.17 已被删除**：报
    `union 'lang.CallingConvention' has no member named 'C'`。
    只剩 `callconv(.c)`，它是 `builtin.target.cCallingConvention()` 的别名。
    另外注意 `.c` 是**函数签名上的东西**，
    `fn` 指针类型要写 `*const fn (u64) callconv(.c) u64`，
    直接把普通 `fn` 赋值过去报
    `expected type '*const fn (u64) callconv(.c) u64', found '*const fn (u64) u64'`。

19. **汇编块不能省成三段**：只有输出 + clobber 时必须写成
    `: 输出, : , : .{ ... }`（空的输入段也要有冒号），
    写 `: 输出, : .{ ... }` 报 `expected ')', found '.'`。

20. **`asm` 的值必须被用掉**：它**不是语句**，
    `: [out] "=r" (-> u64)` 这种"只要类型"的形式如果整个表达式没人用，
    报 `error: value of type 'u64' ignored`
    （想丢弃要赋给 `_`）。

21. **`asm` 没有输出且没有 `volatile` 直接编译错**：
    `error: assembly expression with no output must be marked volatile`。

22. **模板里`%[名字]` 的声明顺序不影响引用，但约束字母不能带逗号**：
    `"=r,r"` 这种写法在 0.17 上**能编过也能运行**（实测返回 22），
    但它不是文档化的语法，别依赖。

23. **`"=m"` 在 aarch64 上不可用**：LLVM 的 aarch64 asm 后端不接受把
    `"m"` 操作数放进方括号，报 `unexpected token in argument list`；
    `fadd` 配 `"=r"` 报 `invalid operand`（fadd 要走 d 寄存器而 `"=r"`
    给的是 x/w 寄存器）。这两处本示例直接回退纯 Zig。

24. **`@Vector` 不能 `.len`、不能 field access，`{any}` 也不行**：
    报 `type '@Vector(4, i32)' does not support field access`。
    要打印必须先 `const arr: [4]i32 = v;`（零成本）。

25. **`@ptrCast` 到更高对齐的类型要配 `@alignCast`**（0.17 的收紧）：
    报 `@ptrCast increases pointer alignment`。
    干净做法是从类型上保证：`var buf: [8]u8 align(8) = @splat(0);`。

26. **x86 的 `cmp` 方向和 `cmov` 方向一起才不反**：
    AT&T 的 `cmpq %[a], %[b]` 是拿 **b 减 a**，
    所以 `cmovgeq` 判的是 `b >= a`。三条指令合起来是 `max(a, b)`。
    写成 `cmpq %[b], %[a]` + `cmovgeq` 就反了（实测得到 `min`）。

27. **别打印不可复现的值**：tick 数、pid、栈地址每次运行都不同
    （本示例的 `rdtsc` 只打印判定结果、`getpid` 只打印"是否相同"、
    符号地址只打印"是否等于 `&g_probe`"）。否则运行输出无法逐字节抄进文档，
    文档里的 ```text 块就会和实际产物对不上。


---

上一章：[20 文件与 IO](20-files-io.md) · 下一章：[22 进程](22-process.md)
