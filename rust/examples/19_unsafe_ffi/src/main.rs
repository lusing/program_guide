//! 19 · unsafe 与 FFI：裸指针、unsafe 块/函数、extern "C"、安全封装
//!
//! unsafe 的正确理解：不是"关闭安全检查的免死金牌"，而是
//! "程序员向编译器承诺维护住的额外不变量（invariant）"。
//! 目标永远是把 unsafe 关进小盒子里，对外提供安全 API。

use std::slice;

// ---- extern 块：声明外来（C）函数，链接器去系统 CRT 里找符号 ----
unsafe extern "C" {
    // 2024 edition：extern 块本身要标 unsafe（承诺符号真的存在且签名正确）
    fn abs(input: i32) -> i32;
}

// ---- 导出给 C 调用：符号名不做 name mangling ----
#[unsafe(no_mangle)] // 2024 edition：no_mangle 属性挪进 unsafe(...)
pub extern "C" fn rust_add(a: i32, b: i32) -> i32 {
    a + b
}

// ---- unsafe 函数：调用方必须用 unsafe 块包起来 ----
unsafe fn dangerous() -> i32 {
    42
}

// ---- 经典安全封装：用裸指针实现"一分为二"的两个可变借用 ----
// 安全写法 &mut [i32] 只能有一个，但"前半/后半各借一块"互不重叠，是合法语义。
/// # Safety（约定）
/// mid <= values.len()（内部已 assert，实际无需调用方维护）
fn split_at_mut(values: &mut [i32], mid: usize) -> (&mut [i32], &mut [i32]) {
    let len = values.len();
    assert!(mid <= len);
    let ptr = values.as_mut_ptr();
    unsafe {
        (
            slice::from_raw_parts_mut(ptr, mid),
            slice::from_raw_parts_mut(ptr.add(mid), len - mid),
        )
    }
}

// ---- 2024 edition 的 static mut：只允许 unsafe 块内整体读写，禁止取引用 ----
static mut COUNTER: u32 = 0;

fn bump_counter() {
    unsafe {
        COUNTER += 1; // 位置表达式整体读写 OK；&COUNTER 会被 2024 edition 拒绝
    }
}

fn read_counter() -> u32 {
    unsafe { COUNTER }
}

fn main() {
    // ---- 裸指针：*const / *mut，允许为空、允许别名、不算借用 ----
    let mut y = 7;
    let rp: *mut i32 = &mut y; // 从安全引用造裸指针
    unsafe {
        *rp += 1; // 解引用/写穿裸指针必须 unsafe（编译器不再管别名与生命周期）
    }
    println!("裸指针改写后 y = {y}");
    let rc: *const i32 = &y;
    unsafe {
        println!("*rc = {}", *rc);
    }
    // 裸指针本身可以拷贝/传递/比较（不 deref 就不需要 unsafe）：
    println!("指针相等：{}", std::ptr::eq(rc, rp as *const i32));

    // ---- unsafe 块越窄越好 ----
    let v = unsafe { dangerous() };
    println!("unsafe 函数返回 {v}");

    // ---- 调 C 函数（CRT 的 abs）----
    let n = unsafe { abs(-42) };
    println!("C 的 abs(-42) = {n}");

    // ---- 导出的 C ABI 函数，Rust 自己也能直接调 ----
    println!("rust_add(3, 4) = {}", rust_add(3, 4));

    // ---- 安全封装的对外表现：签名全安全，内部 unsafe 不外溢 ----
    let mut data = [1, 2, 3, 4, 5, 6];
    let (front, back) = split_at_mut(&mut data, 2);
    println!("split → {front:?} + {back:?}");
    front[0] *= 100;
    back[1] *= 100;
    println!("改写后 data = {data:?}");

    // ---- static mut ----
    bump_counter();
    bump_counter();
    println!("COUNTER = {}", read_counter());

    // 现代替代：需要可变全局状态请用原子（22 章）或 Mutex，
    // static mut 的适用面已收得很窄。
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ffi_abs_works() {
        assert_eq!(unsafe { abs(-5) }, 5);
        assert_eq!(unsafe { abs(7) }, 7);
    }

    #[test]
    fn exported_symbol_is_callable() {
        assert_eq!(rust_add(2, 3), 5);
    }

    #[test]
    fn safe_wrapper_splits_correctly() {
        let mut v = [1, 2, 3, 4, 5];
        let (a, b) = split_at_mut(&mut v, 3);
        assert_eq!(a, &mut [1, 2, 3]);
        assert_eq!(b, &mut [4, 5]);
        a[0] = 9;
        b[1] = 8;
        assert_eq!(v, [9, 2, 3, 4, 8]);
    }

    #[test]
    #[should_panic]
    fn split_bounds_checked() {
        let mut v = [1, 2, 3];
        let _ = split_at_mut(&mut v, 99); // assert 拦截越界，而不是 UB
    }

    #[test]
    fn static_mut_counter() {
        bump_counter();
        assert!(read_counter() >= 1);
    }
}
