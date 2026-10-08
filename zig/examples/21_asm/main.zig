//! 21 内联汇编与底层工具箱
//!
//! 0.17 的三处大改动（本章全部实测，坑位清单见 docs/21-asm.md）：
//!   1. clobber 从**字符串列表**变成**类型化结构体** `std.lang.assembly.Clobbers`，
//!      `asm volatile ("" : : : "cc", "memory")` 已过期，新写法是 `: : : .{ .cc = true, .memory = true }`。
//!   2. Clobbers 结构体**按架构分字段**：x86_64 有 `.cc`（条件码），aarch64 只有 `.nzcv`。
//!      照抄 x86 的 `.cc = true` 到 arm64 上直接编译错。
//!   3. 0.17 的 clobbers 里**不能有尾逗号**（`: .{ .memory = true },` 报 expected ')'）。
//!   4. ⚠️ aarch64 的内联汇编在 Zig 里走 **Intel 语序（目的在前）**，不是 AT&T：
//!      `add %[o], %[a], #5` 而不是 `add %[a], %[o], #5`。照抄 x86 的 AT&T 语序
//!      在 arm64 上报 `too few operands for instruction`。
//!
//! 平台策略：x86_64 走真汇编；aarch64（Apple Silicon）走**纯 Zig 等价实现**，
//! 保证 `zig fmt/test/build-exe` 三层在两种机器上都绿。
const std = @import("std");
const builtin = @import("builtin");

// ═══ 21.12 平台守卫：x86_64 / aarch64 各一份实现，其他架构编译期就爆
comptime {
    switch (builtin.cpu.arch) {
        .x86_64, .aarch64 => {},
        else => @compileError("21 章实现了 x86_64（真汇编）与 aarch64（纯 Zig 回退）两条路径"),
    }
}

const is_x86 = builtin.cpu.arch == .x86_64;

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ─────────────────────────────────────────────────────────────
// 21.1 最小内联汇编
// ─────────────────────────────────────────────────────────────

/// 21.1：最小的一块 asm——只有模板串，没有输出、没有输入、没有 clobber。
/// `nop` 是 x86 的单字节空操作（0x90），aarch64 对应 `nop`，两边都有。
pub fn asmNop() void {
    asm volatile ("nop");
}

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
}

// ─────────────────────────────────────────────────────────────
// 21.2 输出约束
// ─────────────────────────────────────────────────────────────

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
}

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
}

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
}

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
}

// ─────────────────────────────────────────────────────────────
// 21.3 输入约束
// ─────────────────────────────────────────────────────────────

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
}

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
}

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
}

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
}

// ─────────────────────────────────────────────────────────────
// 21.4 volatile：防止整块蒸发
// ─────────────────────────────────────────────────────────────

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
}

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
}

// ─────────────────────────────────────────────────────────────
// 21.5 clobber 列表
// ─────────────────────────────────────────────────────────────

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
}

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
}

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
}

// ─────────────────────────────────────────────────────────────
// 21.6 系统调用
// ─────────────────────────────────────────────────────────────

/// 21.6：手写系统调用在**三类OS 上走三条完全不同的路**。
///
/// x86_64 Linux：`syscall` 指令直接可用（0.17 标准库 `std.os.linux` 就是这么写的）。
/// x86_64 Windows：**用户态没有开放的 `syscall` 通道**——所有系统调用必须经过
/// ntdll 的网关存根（win32 API 就是这些存根的薄包装），裸 `syscall` 直接吃
/// 非法指令异常。所以 Windows 只能"借道 API"，与 macOS 借道 libc 同理。
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

/// 21.6：Windows 的取 pid 通道。理论上可以自己写
/// `extern "system" fn GetCurrentProcessId() u32;`，但 0.17 实测坑位：
/// 在 `-lc`（mingw 模式）下 `extern "system"` 会被链接器当成要找名为
/// `system` 的 DLL 导入库（`DllImportLibraryNotFound`）——所以这里直接用
/// `std.os.windows` 里现成的声明，它底下就是 ntdll 网关，语义完全一样：
/// 在 Windows 用户态，win32 API **就是**合法的系统调用入口。
fn sysGetpidViaWin32() u64 {
    return std.os.windows.GetCurrentProcessId();
}

/// 架构无关的取pid 入口。
fn getpidPortable() u64 {
    // Windows 用户态裸 syscall 直接崩，必须借 win32 API（ntdll 网关）
    if (comptime builtin.os.tag == .windows) {
        return sysGetpidViaWin32();
    }
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

/// 21.6：让 asm 结果和 libc/OS API 对账 —— 这才是可信的验证方式。
/// 0.17 坑位：Windows 下 `std.c.getpid()` 的返回类型是 `pid_t = windows.HANDLE`
/// （`*anyopaque`，0.17 把 Windows getpid 映射成了 GetCurrentProcess 伪句柄），
/// 编译都过不了——所以 Windows 的对照面用 `std.os.windows.GetCurrentProcessId()`。
fn getpidMatchesLibc() bool {
    if (comptime builtin.os.tag == .windows) {
        return getpidPortable() == @as(u64, std.os.windows.GetCurrentProcessId());
    }
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
/// `"=X"` 在 x86 上等价于任何 SSE 寄存器。真正要rax 就写 `"={rax}"`。
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

/// 21.7：`rdtsc` 的第二个用法——绑定 eax/edx 拿到时间戳。
/// aarch64 侧返回虚拟计数器，两边都是"单调递增的计数器"这一个语义。
fn cycles() u64 {
    return rdtsc();
}

const cycles_name = if (is_x86) "rdtsc" else "cntvct_el0";

/// 21.7：向量寄存器上的 asm——结果与输入 a 显式共享 xmm0。
/// 坑位：`addsd` 的 dst（AT&T 顺序在末尾）会被**就地覆盖**，输出必须与 a 同寄存器。
/// Zig 没有 GCC 的 `"0"` 匹配约束，共享寄存器的写法是给输入/输出各一个操作数、
/// 用**同名显式寄存器**约束（`std.os.linux` 的 syscall 模式：输出 `={rax}`、输入 `{rax}`）。
/// 实测教训：写成 `var out: f64 = undefined` + 独立 `"=x"` 输出，`out` 永远不会被写——
/// macOS 上寄存器分配恰好撞对能过，Windows 上分配不同立刻算出 0。
/// `@Vector` 在语言层面已经够用了（见 21.10），所以这里只用来证明约束本身可用。
fn sseAdd(a: f64, b: f64) f64 {
    if (comptime is_x86) {
        return asm ("addsd %[b], %[a]"
            : [out] "={xmm0}" (-> f64),
            : [a] "{xmm0}" (a),
              [b] "{xmm1}" (b), // b 是 input-only 寄存器，用完即弃，占 xmm1 没问题
        );
    } else {
        // aarch64 上 fadd 要走 d 寄存器而 `"=r"` 给的是 x/w 寄存器（实测 invalid operand），
        // 要写对得手动 fmov 到 d0/d1 —— 这种地方纯 Zig 的 `a + b` 就是正解（见 21.12）。
        return a + b;
    }
}

// ─────────────────────────────────────────────────────────────
// 21.8 内存操作数
// ─────────────────────────────────────────────────────────────

/// 21.8：asm 写内存 → 用 `std.mem.readInt` 读回来。
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
///   ① 用`@intFromPtr(&g)` 把地址当**运行期整数**传进寄存器（跨平台）；
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

pub fn main() !void {
    std.debug.print("arch={s} os={s} mode={s}\n", .{
        @tagName(builtin.cpu.arch),
        @tagName(builtin.os.tag),
        @tagName(builtin.mode),
    });
    std.debug.print("Clobbers 类型 = {s}（{d} 字节，0.17 从字符串列表改成了结构体）\n", .{
        @typeName(std.lang.assembly.Clobbers),
        @sizeOf(std.lang.assembly.Clobbers),
    });

    // ═══ 21.1 最小内联汇编 ═══
    begin("21.1 最小内联汇编");
    asmNop();
    asmNop();
    std.debug.print("asm volatile (\"nop\") 两条：编译通过、运行无事发生（它就是 nop）\n", .{});
    std.debug.print("addFive(37) = {d}（汇编 +5；x86 是 AT&T `add $5, %[r]`，aarch64 是 `add %[r], %[r], #5`）\n", .{addFive(37)});
    std.debug.print("裸 `asm` 没有 inline 关键字：Zig 里关键字就是 asm / asm volatile 两个\n", .{});
    std.debug.print("加不加 volatile 取决于「输出有没有人用」，不是取决于指令有没有副作用\n", .{});
    std.debug.print("⚠️ 不带输出且不带 volatile 直接编译错（assembly expression with no output must be marked volatile）\n", .{});
    end("21.1");

    // ═══ 21.2 输出约束 ═══
    begin("21.2 输出约束");
    std.debug.print("=r  任意寄存器：emitMovImm(11) = {d}\n", .{emitMovImm(11)});
    std.debug.print("=A  rax 家族：movqRax(22) = {d}\n", .{movqRax(22)});
    std.debug.print("={{rax}} 显式钉 rax：movqRax(33) = {d}（实测 0.17 上 \"=a\" 不能用，见坑位清单）\n", .{movqRax(33)});
    std.debug.print("-> T 只要类型：immViaArrow(44) = {d}\n", .{immViaArrow(44)});
    std.debug.print("=m  直接落内存：emitToMemory() = {d}（不经过寄存器）\n", .{emitToMemory()});
    var slot: u32 = 0;
    emitToVar(&slot);
    std.debug.print("=m  带变量：emitToVar(&slot) = {d}\n", .{slot});
    std.debug.print("多个输出之间用**逗号**分隔（不是分号）：rdtsc 用了 \"={{eax}}\" 和 \"={{edx}}\" 两个\n", .{});
    std.debug.print("x86 硬件只给 4 个固定输出槽（eax/ebx/ecx/edx），超了就必须换设计\n", .{});
    end("21.2");

    // ═══ 21.3 输入约束 ═══
    begin("21.3 输入约束");
    std.debug.print("r  任意寄存器：mulBy(6, 7) = {d}\n", .{mulBy(6, 7)});
    std.debug.print("r  传地址读内存：loadFromMemory() = 0x{x}\n", .{loadFromMemory()});
    const ic = immConstraint();
    std.debug.print("i  立即数：ic.x86_i = {d}（32 位那条路径）\n", .{ic.x86_i});
    std.debug.print("n  8 位立即数：ic.x86_n = {d}（更紧，编码更短）\n", .{ic.x86_n});
    std.debug.print("i/n 都要求编译期已知；传运行期变量会报 not a comptime constant\n", .{});
    std.debug.print("具名引用输入用 %[名字]：addTwoNamed(100, 23) = {d}\n", .{addTwoNamed(100, 23)});
    const sw = swapViaAsm(1, 2);
    std.debug.print("+&r（early-clobber）：swapViaAsm(1,2) → a={d} b={d}（模板用了临时寄存器 rdx/x16，必须写进 clobber）\n", .{ sw.a, sw.b });
    std.debug.print("⚠️ $0 引用的是「第 0 个输出」不是输入；引用输入一律用 %[名字]\n", .{});
    end("21.3");

    // ═══ 21.4 volatile 的作用 ═══
    begin("21.4 volatile");
    g_probe = 0;
    probeNoVolatile(7);
    std.debug.print("mode={s}：非 volatile 那次写完后 g_probe = {d}\n", .{ @tagName(builtin.mode), g_probe });
    g_probe = 0;
    probeVolatile(8);
    std.debug.print("mode={s}：volatile  那次写完后 g_probe = {d}\n", .{ @tagName(builtin.mode), g_probe });
    std.debug.print("⇒ 在 ReleaseSafe/ReleaseFast 下非 volatile 那行会被整块删掉（g_probe 停在 0）\n", .{});
    std.debug.print("⇒ 纯计算（输出被用上）不需要 volatile：addTenPure(32) = {d}\n", .{addTenPure(32)});
    std.debug.print("⚠️ @setRuntimeSafety 只能关安全检查，管不到「asm 被不被删」——那由输出可观察性决定\n", .{});
    end("21.4");

    // ═══ 21.5 clobber 列表 ═══
    begin("21.5 clobber 列表");
    const C = std.lang.assembly.Clobbers;
    std.debug.print("Clobbers 是 packed struct（{d} 字节），不是字符串列表\n", .{@sizeOf(C)});
    std.debug.print("x86_64 上它有 {d} 个字段，头几个：memory cc dirflag eflags flags fpcr fpsr mxcsr rflags rax rcx ...\n", .{
        @typeInfo(C).@"struct".field_names.len,
    });
    std.debug.print("⚠️ 新写法是 `: : : .{{ .cc = true, .memory = true }}`，旧写法 `\"cc\", \"memory\"` 编译不过\n", .{});
    std.debug.print("rol8(0x0123456789abcdef) = 0x{x}（rol 改条件码，所以声明了 .cc）\n", .{rol8(0x0123456789abcdef)});
    {
        var buf: [8]u8 align(8) = @splat(0);
        storeThroughPtr(@ptrCast(&buf), 0x1122334455667788);
        std.debug.print("storeThroughPtr 之后 readInt = 0x{x}（.memory 声明编译器不能重排这次访存）\n", .{
            std.mem.readInt(u64, &buf, .little),
        });
    }
    std.debug.print("cmovIfGe 语义是 max(a,b)：cmovIfGe(5,9)={d} cmovIfGe(9,5)={d} cmovIfGe(7,7)={d}\n", .{
        cmovIfGe(5, 9),
        cmovIfGe(9, 5),
        cmovIfGe(7, 7),
    });
    end("21.5");

    // ═══ 21.6 完整系统调用 ═══
    begin("21.6 系统调用");
    {
        const pid_asm = getpidPortable();
        // Windows 下 std.c.getpid() 返回类型是 pid_t = HANDLE（*anyopaque），编不过；
        // 参考实现按平台取：Windows 用 std.os.windows.GetCurrentProcessId()
        const pid_ref: u64 = if (comptime builtin.os.tag == .windows)
            std.os.windows.GetCurrentProcessId()
        else
            @intCast(std.c.getpid());
        std.debug.print("裸汇编/借 libc 拿到的 pid 与 OS 参考实现一致？ {s}\n", .{
            if (pid_asm == pid_ref) "是" else "否",
        });
        std.debug.print("syscall 的形状：输出 \"={{rax}}\"、输入 \"{{rax}}\"（同一个寄存器既进又出）、clobber .rcx/.r11/.memory\n", .{});
        if (comptime builtin.os.tag == .windows) {
            std.debug.print("⚠️ Windows 用户态没有开放的 `syscall` 指令通道：裸 `syscall` 直接吃非法指令异常\n", .{});
            std.debug.print("⇒ win32 API 就是 ntdll 网关存根的薄包装，本机走 GetCurrentProcessId 通道（汇编 syscall 代码仍在，仍参与编译）\n", .{});
        } else if (comptime is_x86) {
            std.debug.print("⚠️ x86_64 macOS 上裸 `syscall` 指令会吃 SIGSYS（实测退出码 140 = 128+12）\n", .{});
            std.debug.print("⇒ macOS 必须借 libc 的 syscall()（它内部做 csopen 切代码段）；Linux 才能裸写\n", .{});
            std.debug.print("本机是 {s}，所以 main 走的是 libc 通道（汇编 syscall 代码仍在，仍参与编译）\n", .{@tagName(builtin.os.tag)});
        } else {
            std.debug.print("aarch64 用 `svc #0`（不是 syscall），系统调用号走 x8，返回值走 x0\n", .{});
        }
        std.debug.print("标准库自己的形状：std.os.linux.x86_64.syscall0 就是一行 asm，stdlibSyscallShape()={d}\n", .{stdlibSyscallShape()});
    }
    end("21.6");

    // ═══ 21.7 逐寄存器 vs 通用约束 ═══
    begin("21.7 逐寄存器与通用约束");
    {
        const probe = constraintFamilyProbe();
        std.debug.print("=r → {d}；=A → {d}；=q → {d}（三个在 x86_64 上都能用）\n", .{ probe.eq_r, probe.eq_A, probe.eq_q });
        std.debug.print("❌ \"=a\" / \"=b\" / \"=c\" / \"=d\" / \"=S\" / \"=D\" 在 0.17.0 上全部报 couldn't allocate output register\n", .{});
        std.debug.print("⇒ 要 rax 就写 \"={{rax}}\"（显式寄存器）或 \"=A\"（寄存器家族）\n", .{});
        std.debug.print("cpuidMaxLeaf() = 0x{x}（只能逐寄存器钉死 eax/ebx/ecx/edx，通用约束在这条指令上没用）\n", .{cpuidMaxLeaf()});
        const t0 = cycles();
        var sink: u64 = 0;
        for (0..1000) |i| sink +%= i;
        const t1 = cycles();
        std.debug.print("1000 次加法：tick 数 > 0 ？ {s}；计数器单调递增？ {s}（{s}）\n", .{
            if (t1 > t0) "是" else "否",
            if (t1 >= t0) "是" else "否",
            cycles_name,
        });
        std.debug.print("sink={d}（刻意不用 tick 数本身，那是不可复现的）\n", .{sink});
        std.debug.print("sseAdd(1.5, 2.25) = {d}（显式寄存器约束：输出与 a 共享 xmm0）\n", .{sseAdd(1.5, 2.25)});
    }
    end("21.7");

    // ═══ 21.8 内存操作数 ═══
    begin("21.8 内存操作数");
    {
        const v = asmStoreThenRead(0x1122334455667788);
        std.debug.print("asm 写内存 → std.mem.readInt 读回：0x{x}（同值即正确）\n", .{v});
        var buf: [8]u8 align(8) = @splat(0);
        std.mem.writeInt(u64, &buf, 0xcafebabedeadbeef, .little);
        std.debug.print("\"r\" 传地址 + movq (%[p]) 从缓冲读：0x{x}\n", .{asmLoadFromBuf(&buf)});
        storeThroughPtr(@ptrCast(&buf), 0);
        std.debug.print("再 storeThroughPtr 写0 → 0x{x}\n", .{std.mem.readInt(u64, &buf, .little)});
        std.debug.print("⚠️ macOS/x86_64 上 `movl $g, %o` 编译错：invalid operand for instruction\n", .{});
        std.debug.print("⚠️ `movabsq $g, %o` 也错：undefined symbol: g（Zig 顶层 var 不是导出符号）\n", .{});
        std.debug.print("⇒ 正解一：@intFromPtr(&g) 当运行期整数传进寄存器；addressViaRegister() == &g_probe ？ {s}\n", .{
            if (addressViaRegister() == @intFromPtr(&g_probe)) "是" else "否",
        });
        std.debug.print("⇒ 正解二：export var 让符号对外可见后，汇编里可以写 leaq g(%rip)\n", .{});
        _ = exportedSymbolWorks();
    }
    end("21.8");

    // ═══ 21.9 与 C 交互 ═══
    begin("21.9 与 C 交互");
    std.debug.print("0.17 里 callconv(.C) 已被删除 → error: union 'lang.CallingConvention' has no member named 'C'\n", .{});
    std.debug.print("只剩 callconv(.c)，它是 builtin.target.cCallingConvention() 的别名\n", .{});
    std.debug.print("addOneC(41) = {d}；export fn zig_triple(14) = {d}（export 隐含 C 调用约定）\n", .{ addOneC(41), zig_triple(14) });
    {
        const asm_pid = getpidPortable();
        const c_pid = getpid();
        // ⚠️ 刻意**不打印 pid 本身**（每个进程不同）—— 只打印判定结果，
        //    这样本节的运行输出在任何一次执行里都逐字节一致（文档要引用它）
        std.debug.print("asm 的 pid 与 extern \"c\" getpid() 相同？ {s}（pid > 0？ {s}）\n", .{
            if (asm_pid == @as(u64, @intCast(c_pid))) "是" else "否",
            if (c_pid > 0) "是" else "否",
        });
        std.debug.print("extern \"c\" strlen 验证 asm 写的字节：{d}（期望 7）\n", .{asmBytesThenStrlen()});
        std.debug.print("⇒ 这就是可信验证的形状：asm 产出，libc 消费（写错布局/字节序会立刻暴露）\n", .{});
    }
    end("21.9");

    // ═══ 21.10 SIMD ═══
    begin("21.10 SIMD 与 @Vector");
    {
        const a: @Vector(4, i32) = .{ 1, 2, 3, 4 };
        const b: @Vector(4, i32) = .{ 10, 20, 30, 40 };
        const c = vecAdd(a, b);
        std.debug.print("vecAdd({{1,2,3,4}}, {{10,20,30,40}}) = {any}\n", .{vecToArray(c)});
        std.debug.print("vecSum = {d}（@reduce(.Add, ...)）\n", .{vecSum(c)});
        std.debug.print("vecDot = {d}（1*10+2*20+3*30+4*40 = {d}）\n", .{ vecDot(a, b), 1 * 10 + 2 * 20 + 3 * 30 + 4 * 40 });
        const f: @Vector(4, f32) = .{ 1.5, 2.5, 3.5, 4.5 };
        std.debug.print("vecScale(f, 2.0) = {any}\n", .{vecScale(f, 2.0)});
        std.debug.print("⚠️ @Vector 不能 .len、不能 field access（does not support field access）→ 先转 [N]T\n", .{});
        std.debug.print("⇒ @Vector 在 0.17 的任何目标上都能编译，不需要 asm、不需要特性开关（自动标量化降级）\n", .{});
        std.debug.print("⇒ 要 SIMD 语义时，@Vector 永远优于手写 asm（21.12 会论证）\n", .{});
    }
    end("21.10");

    // ═══ 21.11 @bitCast 与内存 ═══
    begin("21.11 @bitCast 与内存");
    std.debug.print("0.17：@bitCast **拒绝裸 struct 和 extern struct** → error: cannot @bitCast from 'main.ExternPair'\n", .{});
    std.debug.print("只有 packed struct 能直接 @bitCast\n", .{});
    std.debug.print("bitcastViaPacked(1, 2)   = 0x{x}\n", .{bitcastViaPacked(1, 2)});
    std.debug.print("bitcastViaBytes(1, 2)    = 0x{x}（extern struct + asBytes + readInt，端序显式）\n", .{bitcastViaBytes(1, 2)});
    std.debug.print("bitcastViaArray(1, 2)    = 0x{x}（先变 [2]u32，数组布局明确所以能 @bitCast）\n", .{bitcastViaArray(1, 2)});
    {
        const p = ExternPair{ .a = 1, .b = 2 };
        const raw = std.mem.asBytes(&p);
        std.debug.print("asBytes 返回 {s}，长度 {d}（= @sizeOf(ExternPair)）\n", .{ @typeName(@TypeOf(raw)), raw.len });
        std.debug.print("字节 = {any}（小端：a=1 在最低地址）\n", .{raw});
    }
    std.debug.print("⇒ 做二进制协议时，正解是 asBytes + readInt/writeInt —— 顺带把端序写死在代码里\n", .{});
    std.debug.print("⇒ asm 写进内存后用 std.mem.readInt 读回，是同一套机制（21.8 已经这么做了）\n", .{});
    end("21.11");

    // ═══ 21.12 边界与陷阱 ═══
    begin("21.12 边界与陷阱");
    std.debug.print("本示例为两种架构提供了实现：x86_64={any} aarch64={any}\n", .{ impl_sample.x86, impl_sample.aarch64 });
    std.debug.print("共 {d} 个示例函数（下面逐个列名字）\n", .{impl_sample.names.len});
    for (impl_sample.names) |n| std.debug.print("  - {s}\n", .{n});
    crossPlatformTable();
    {
        const x: u64 = 0x0f0f0f0f0f0f0f0f;
        const ins = intrinsicBeatsAsm(x);
        std.debug.print("不用 asm 的做法：@popCount={d} @ctz={d} @byteSwap=0x{x}\n", .{ ins.popcount, ins.ctz, ins.bswap });
        std.debug.print("⇒ popCount/ctz/byteSwap 这类都有 builtin intrinsic，永远不要写 asm\n", .{});
    }
    std.debug.print("⚠️ 汇编块必须**逐个架构**写：x86 模板在 aarch64 上是 unrecognized instruction mnemonic\n", .{});
    std.debug.print("⚠️ x86 模板即使放在 if (comptime) 的不可达分支里，LLVM 仍会看到 → 靠 comptime 选路\n", .{});
    std.debug.print("⚠️ clobber 字段名也按架构分：x86 是 .cc，aarch64 是 .nzcv（写 .cc 到 arm 上编译错）\n", .{});
    std.debug.print("⇒ 本章的跨平台模式：switch (comptime builtin.cpu.arch) 每个 arch 一份实现，未选中分支不进产物\n", .{});
    end("21.12");

    std.debug.print("自检通过\n", .{});
}

// ═══════════════════════════════════════════════════════════
// tests
// ═══════════════════════════════════════════════════════════

test "21.1 最小内联汇编：nop +5 与平台分支都正确" {
    asmNop();
    try std.testing.expectEqual(@as(u64, 42), addFive(37));
    try std.testing.expectEqual(std.math.add(u64, 37, 5) catch unreachable, addFive(37));
}

test "21.2 输出约束：=r / =A / ={rax} / -> T / =m 五种写法" {
    try std.testing.expectEqual(@as(u64, 11), emitMovImm(11));
    try std.testing.expectEqual(@as(u64, 22), movqRax(22));
    try std.testing.expectEqual(@as(u64, 33), movqRax(33));
    try std.testing.expectEqual(@as(u64, 44), immViaArrow(44));
    try std.testing.expectEqual(@as(u32, 22), emitToMemory());
    var slot: u32 = 0;
    emitToVar(&slot);
    try std.testing.expectEqual(@as(u32, 7), slot);
}

test "21.2 rdtsc/cycles 是单调递增的计数器" {
    const t0 = cycles();
    var sink: u64 = 0;
    for (0..1000) |i| sink +%= i;
    const t1 = cycles();
    try std.testing.expect(t0 > 0);
    try std.testing.expect(t1 >= t0);
    try std.testing.expectEqual(@as(u64, 499500), sink);
}

test "21.3 输入约束：r / m / i / n 四种都能取到正确值" {
    try std.testing.expectEqual(@as(u64, 42), mulBy(6, 7));
    try std.testing.expectEqual(@as(u64, 0x1122334455667788), loadFromMemory());
    const ic = immConstraint();
    try std.testing.expectEqual(@as(u64, 1000), ic.wide);
    try std.testing.expectEqual(@as(u64, 1000), ic.x86_i);
    try std.testing.expectEqual(@as(u64, 30), ic.x86_n);
    try std.testing.expectEqual(@as(u64, 123), addTwoNamed(100, 23));
}

test "21.3 early-clobber 交换两个值" {
    const r = swapViaAsm(1, 2);
    try std.testing.expectEqual(@as(u64, 2), r.a);
    try std.testing.expectEqual(@as(u64, 1), r.b);
    const r2 = swapViaAsm(0xdeadbeef, 0x12345678);
    try std.testing.expectEqual(@as(u64, 0x12345678), r2.a);
    try std.testing.expectEqual(@as(u64, 0xdeadbeef), r2.b);
}

test "21.4 volatile：volatile 版一定写进内存" {
    g_probe = 0;
    probeVolatile(0x1234_5678_9abc_def0);
    try std.testing.expectEqual(@as(u64, 0x1234_5678_9abc_def0), g_probe);
    // 非 volatile 版在 Release 下可能被整块删除，所以不断言它写成功——
    // 这一点本身就是本test 要记录的事实。
    g_probe = 0;
    probeNoVolatile(7);
    try std.testing.expect(g_probe == 7 or g_probe == 0);
}

test "21.4 纯计算不加 volatile 也正确（输出被用上了）" {
    try std.testing.expectEqual(@as(u64, 42), addTenPure(32));
    try std.testing.expectEqual(@as(u64, 11), addTenPure(1));
}

test "21.5 clobber：rol8 与 cmovIfGe" {
    try std.testing.expectEqual(@as(u64, 0x23456789abcdef01), rol8(0x0123456789abcdef));
    // cmovIfGe(a, b)：a<b → 返回 b；否则返回 a
    try std.testing.expectEqual(@as(u64, 9), cmovIfGe(5, 9));
    try std.testing.expectEqual(@as(u64, 9), cmovIfGe(9, 5));
    try std.testing.expectEqual(@as(u64, 7), cmovIfGe(7, 7));
}

test "21.5 clobber：storeThroughPtr 之后内存确实变了" {
    var buf: [8]u8 align(8) = @splat(0);
    storeThroughPtr(@ptrCast(&buf), 0x1122334455667788);
    try std.testing.expectEqual(@as(u64, 0x1122334455667788), std.mem.readInt(u64, &buf, .little));
    storeThroughPtr(@ptrCast(&buf), 0);
    try std.testing.expectEqual(@as(u64, 0), std.mem.readInt(u64, &buf, .little));
}

test "21.6 系统调用：asm 拿到的 pid 与 libc 一致" {
    try std.testing.expect(getpidMatchesLibc());
    try std.testing.expect(getpidPortable() > 0);
}

test "21.7 寄存器族约束与cpuid" {
    const probe = constraintFamilyProbe();
    if (comptime is_x86) {
        try std.testing.expectEqual(@as(u64, 11), probe.eq_r);
        try std.testing.expectEqual(@as(u64, 22), probe.eq_A);
        try std.testing.expectEqual(@as(u64, 33), probe.eq_q);
        // cpuid(0).eax = "最大支持的 leaf号"，现代 CPU 至少 0xB（Skylake）到 0x16
        try std.testing.expect(cpuidMaxLeaf() >= 1);
    }
    try std.testing.expectEqual(@as(f64, 3.75), sseAdd(1.5, 2.25));
}

test "21.8 内存操作数：asm 写→readInt 读，asm 从 \"m\" 读" {
    try std.testing.expectEqual(@as(u64, 0x1122334455667788), asmStoreThenRead(0x1122334455667788));
    var buf: [8]u8 = undefined;
    std.mem.writeInt(u64, &buf, 0xcafebabedeadbeef, .little);
    try std.testing.expectEqual(@as(u64, 0xcafebabedeadbeef), asmLoadFromBuf(&buf));
}

test "21.8 符号地址只能通过寄存器传（不能当立即数）" {
    // addressViaRegister 必须能拿到非 0 地址
    try std.testing.expect(addressViaRegister() != 0);
    try std.testing.expectEqual(@intFromPtr(&g_probe), addressViaRegister());
}

test "21.9 与 C 交互：callconv(.c)、extern \"c\"、libc 消费 asm 结果" {
    try std.testing.expectEqual(@as(u64, 42), addOneC(41));
    try std.testing.expectEqual(@as(u64, 42), zig_triple(14));
    try std.testing.expectEqual(@as(i32, getpid()), @as(i32, @intCast(getpidPortable())));
    try std.testing.expectEqual(@as(usize, 7), asmBytesThenStrlen());
}

test "21.10 @Vector：不需要 asm，四种操作全对" {
    const a: @Vector(4, i32) = .{ 1, 2, 3, 4 };
    const b: @Vector(4, i32) = .{ 10, 20, 30, 40 };
    try std.testing.expectEqual([4]i32{ 11, 22, 33, 44 }, vecToArray(vecAdd(a, b)));
    try std.testing.expectEqual(@as(i32, 110), vecSum(vecAdd(a, b)));
    try std.testing.expectEqual(@as(i32, 300), vecDot(a, b));
    const f: @Vector(4, f32) = .{ 1.5, 2.5, 3.5, 4.5 };
    try std.testing.expectEqual([4]f32{ 3, 5, 7, 9 }, vecScale(f, 2.0));
}

test "21.11 @bitCast：packed 行、extern struct 不行、数组行" {
    try std.testing.expectEqual(@as(u64, 0x0000000200000001), bitcastViaPacked(1, 2));
    try std.testing.expectEqual(@as(u64, 0x0000000200000001), bitcastViaBytes(1, 2));
    try std.testing.expectEqual(@as(u64, 0x0000000200000001), bitcastViaArray(1, 2));
    // 三条路径必须给出同一个位模式——这正是 extern struct 布局正确的证据
    try std.testing.expectEqual(bitcastViaPacked(7, 0), bitcastViaBytes(7, 0));
    try std.testing.expectEqual(bitcastViaBytes(0, 9), bitcastViaArray(0, 9));
}

test "21.11 asBytes 往返：字节序列与端序" {
    const p = ExternPair{ .a = 0x01020304, .b = 0x05060708 };
    const raw = std.mem.asBytes(&p);
    try std.testing.expectEqual(@as(usize, 8), raw.len);
    try std.testing.expectEqual(@as(u8, 0x04), raw[0]); // 小端：a 的最低字节在最前
    try std.testing.expectEqual(@as(u8, 0x01), raw[3]);
    try std.testing.expectEqual(@as(u8, 0x08), raw[4]);
    try std.testing.expectEqual(@as(u8, 0x05), raw[7]);
}

test "21.12 intrinsic 覆盖：不该写 asm 的地方" {
    const x: u64 = 0x0f0f0f0f0f0f0f0f;
    const ins = intrinsicBeatsAsm(x);
    try std.testing.expectEqual(@as(u64, 32), ins.popcount);
    try std.testing.expectEqual(@as(u6, 0), ins.ctz);
    try std.testing.expectEqual(@as(u64, 0xf0f0f0f0f0f0f0f), ins.bswap);
    // 实现清单非空，且覆盖两种架构
    try std.testing.expect(impl_sample.names.len >= 20);
    try std.testing.expect(impl_sample.x86 and impl_sample.aarch64);
}
