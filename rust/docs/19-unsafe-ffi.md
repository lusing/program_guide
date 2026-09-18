# 19 · unsafe 与 FFI

> 对应示例：`examples/19_unsafe_ffi/`
>
> unsafe 不是"关闭安全检查"，而是**你向编译器立下的书面承诺**：
> "这里的额外规则我来维护"。目标是把 unsafe 关进最小的盒子，对外只暴露安全 API。

## 19.1 unsafe 能做的五件事（仅此五件）

1. 解引用**裸指针**（`*const T` / `*mut T`）
2. 调用 **unsafe 函数**（含 FFI 外部函数）
3. 访问/修改 **`static mut`**
4. 实现 **unsafe trait**（Send/Sync 手动声明那类）
5. 访问 **union 字段**

注意它**不能**做的：绕过借用检查（`&`/`&mut` 规则照旧）、绕过类型检查、关闭整数溢出检查。unsafe 的边界比 C 程序员的直觉窄得多。

## 19.2 裸指针：不带契约的地址

```rust
let mut y = 7;
let rp: *mut i32 = &mut y;    // 从安全引用造裸指针（安全）
unsafe { *rp += 1; }          // 解引用/写穿 = unsafe（编译器不再管别名/寿命）

let rc: *const i32 = &y;
let same = std::ptr::eq(rc, rp as *const i32);   // 比较/传拷贝不需要 unsafe
```

裸指针三特性：**允许为空、允许别名、不实现 Deref**——前两条正是 `&T`（非空、无别名）排除掉的。指针运算 `ptr.add(n)` / `ptr.offset(n)` 都在 unsafe 内（越界即 UB）。

## 19.3 unsafe 函数与最小作用域

```rust
unsafe fn dangerous() -> i32 { 42 }

let v = unsafe { dangerous() };     // 调用方书面签字
```

**块越小越好**：一行 unsafe 包住真正必要的调用，别把整段逻辑罩进去——出问题时审计面就是那几行。`unsafe fn` 体内的调用不需要再包块（函数整体已是声明），但**新风格**建议体内用显式 `unsafe {}` 提高可读性（2024 edition 引入 `unsafe(op)` 表达式语法，调用处更醒目）。

## 19.4 安全封装：unsafe 的正确归宿

TRB 经典——`split_at_mut`：安全 Rust 无法一次产出两个 `&mut [i32]`，但"前半/后半各借一块"互不重叠、语义正当：

```rust
fn split_at_mut(values: &mut [i32], mid: usize) -> (&mut [i32], &mut [i32]) {
    let len = values.len();
    assert!(mid <= len);                       // 边界先挡住（fail fast，不是 UB）
    let ptr = values.as_mut_ptr();
    unsafe {
        (
            std::slice::from_raw_parts_mut(ptr, mid),
            std::slice::from_raw_parts_mut(ptr.add(mid), len - mid),
        )
    }
}
// 对外签名完全安全——调用方无从得知内部有 unsafe
```

这是 std 的真实实现。**模式：边界检查/不变量在安全代码里完成，unsafe 只做最后一步"编译器不会的原语"**。

## 19.5 FFI：与 C 互操作

**调 C（外部函数导入）**——直接链系统 CRT 里的 `abs`：

```rust
unsafe extern "C" {                 // 2024 edition：extern 块标 unsafe
    fn abs(input: i32) -> i32;      // 你承诺：符号存在、签名正确
}
let n = unsafe { abs(-42) };        // 你承诺：调用约定、参数合法性
```

**给 C 调（导出）**：

```rust
#[unsafe(no_mangle)]                // 2024 edition：no_mangle 挪进 unsafe(...)
pub extern "C" fn rust_add(a: i32, b: i32) -> i32 { a + b }
```

`extern "C"` 指定调用约定（C ABI；也有 "system" = Windows 上随 stdcall/cdecl）。字符串与结构体跨边界要按 C 布局（`#[repr(C)]`），内存谁分配谁释放——FFI 的坑八成在所有权，不在语法。

真实项目不手写 extern 块：**bindgen** 从 C 头文件自动生成声明；**cbindgen** 反向生成给 C 的头。Rust↔C++ 大型互操作有 cxx crate（类型映射 + 安全封装生成）。

## 19.6 static mut（2024 edition 新规）

```rust
static mut COUNTER: u32 = 0;

fn bump() { unsafe { COUNTER += 1; } }       // 整体读写：unsafe 块内允许
// let r = unsafe { &COUNTER };              // ← 2024 直接编译错：禁止取引用
fn read() -> u32 { unsafe { COUNTER } }
```

2024 edition 收紧：对 `static mut` **取引用被拒**（引用绕开同步约束，是数据竞争之源），只许整体读写。**现代替代品**：需要全局可变状态用 `AtomicU32`（22 章，免 unsafe、多线程安全）或 `Mutex`——`static mut` 的适用面已经收得很窄，新代码基本不该出现。

## 19.7 什么时候真的需要 unsafe

| 场景 | 说明 |
|---|---|
| FFI 边界 | 调 C 库 / 被 C 调（本节） |
| 自定义底层数据结构 | Vec 一样的双缓冲、侵入式链表 |
| SIMD/内联汇编 | `std::arch` intrinsics、`asm!` |
| 性能微调 | 编译器不做的指针别名断言（`ptr::read/write` 搬运） |
| unsafe trait 手动 Send/Sync | 你能证明跨线程安全（罕见，慎之又慎） |

写 unsafe 的纪律：每处 unsafe 配 `// SAFETY: 为什么成立` 注释；能 assert 的先 assert；封装成安全函数对外。

## 19.8 坑位清单

1. **edition 2024 语法三连变**：`unsafe extern`、`#[unsafe(no_mangle)]`、static mut 禁取引用——旧教程代码照抄三处全炸（01 章对照表）。
2. **extern 块签名错误 = UB 不是编译错**：C 侧 `int64_t` 你写 i32，链接照过、运行错位——对照头文件逐个核对。
3. **`from_raw_parts` 的三前提**：指针有效、长度正确、别名规则（返回的两个切片不得重叠）——split_at_mut 靠 mid<=len 保证，你的封装也要写明。
4. **assert 挡边界，不要 if-else 补救**：契约破裂就该 panic（10 章边界论），UB 没有补救。
5. **unsafe 块里调 safe 代码照样可能 UB**：`unsafe { vec.get_unchecked(i) }` 越界就是 UB——unsafe 只解锁，不兜底。
6. **SAFETY 注释不是装饰**：回头审计时它是唯一线索；团队 lint（如 `clippy::undocumented_unsafe_blocks`）可强制。
7. **FFI 内存谁分配谁释放**：Rust `String` 给 C 后 free 的必须是 Rust（`drop` from Rust 侧）；跨边界传裸指针 + 明确所有权文档是底线。

---

上一章：[18 智能指针](18-smartptr.md) · 下一章：[20 文件 IO 与序列化](20-files.md)
