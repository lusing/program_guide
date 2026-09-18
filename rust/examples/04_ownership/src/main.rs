//! 04 · 所有权 ⭐：move、Copy/Clone、Drop、值传递的全景
//!
//! 每个值有唯一 owner；owner 离开作用域值被释放。三个经典后果：
//! 1) 赋值/传参会 move（非 Copy 类型）；2) clone 才是深拷贝；
//! 3) 释放时机确定（RAII，无 GC）。

fn main() {
    // ---- move：String 的内容在堆上，赋值 = 所有权转移 ----
    let s1 = String::from("hello");
    let s2 = s1; // s1 被 move，此后 s1 不可用
    // println!("{s1}"); // ← 取消注释：borrow of moved value 编译错
    println!("s2 = {s2}");

    // ---- Copy：栈上小类型赋值即复制，原值仍可用 ----
    let x = 5;
    let y = x; // i32 是 Copy
    println!("x = {x}，y = {y}（都活着）");

    // Copy 的判定：纯标量/纯栈类型（整数、浮点、bool、char、
    // 只含 Copy 字段且未实现 Drop 的定长类型、共享引用 &T）。
    let p1 = (1, 2.0);
    let _p2 = p1; // 命名以 _ 开头：故意不用，消除告警
    println!("tuple p1 = {p1:?} 仍可用（字段全 Copy）");

    // ---- Clone：显式深拷贝 ----
    let a = String::from("深拷贝");
    let b = a.clone();
    println!("a = {a}，b = {b}（两份独立堆内存）");

    // ---- 作用域结束即释放（drop 顺序与声明相反）----
    {
        let _guard = Tracer::new("内层");
        let _guard2 = Tracer::new("更内层");
    } // 先释放 _guard2，再 _guard
    println!("--- 作用域已结束，drop 日志在上面 ---");

    // ---- 函数传参 = move（非 Copy）----
    let s = String::from("交给函数");
    takes_ownership(s);
    // println!("{s}"); // ← 编译错：值已 move 进函数并在其中释放

    let n = 42;
    makes_copy(n);
    println!("n = {n} 仍可用（i32 是 Copy）");

    // ---- 返回值 = move 出来 ----
    let s = gives_ownership();
    println!("拿到返回值：{s}");

    // ---- move 进 + move 出：经典接力 ----
    let s = String::from("接力");
    let s = take_and_give_back(s);
    println!("接回来：{s}");

    // ---- 手动提前 drop ----
    let early = String::from("提前释放");
    drop(early);
    // println!("{early}"); // ← 编译错：已 drop

    // ---- 容器整体 move，元素跟着走 ----
    let mut v = vec![String::from("a"), String::from("b")];
    let first = v.remove(0); // remove 是 move out（元素所有权出容器）
    let _v2 = v; // 容器本身也 move
    println!("first = {first}，v 整体已转移");

    // ---- 借用预演（05 章细讲）：不拿走所有权也能用 ----
    let s = String::from("最后演示借用");
    let len = byte_len(&s); // 传引用，s 不受影响
    println!("{s} 长度 {len}（s 仍然可用）");
}

fn takes_ownership(s: String) {
    println!("函数接管了：{s}");
} // s 在此 drop

fn makes_copy(n: i32) {
    println!("函数收到副本：{n}");
}

fn gives_ownership() -> String {
    String::from("工厂造一个新值")
}

fn take_and_give_back(s: String) -> String {
    s // move 出来交还调用者
}

#[allow(clippy::ptr_arg)] // 教学演示：&String 能编译，但惯用 &str（06 章讲清原因）
fn byte_len(s: &String) -> usize {
    s.len()
}

/// 演示 Drop：释放时自动调用（RAII 析构）
struct Tracer(&'static str);

impl Tracer {
    fn new(name: &'static str) -> Self {
        println!("  [Tracer] 构造 {name}");
        Tracer(name)
    }
}

impl Drop for Tracer {
    fn drop(&mut self) {
        println!("  [Tracer] 释放 {}", self.0);
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn copy_types_survive_assignment() {
        let a = [1u8, 2, 3];
        let b = a; // [u8; 3] 是 Copy
        assert_eq!(a, b);
    }

    #[test]
    fn clone_makes_independent_copy() {
        let a = String::from("abc");
        let mut b = a.clone();
        b.push('!');
        assert_eq!(a, "abc");
        assert_eq!(b, "abc!");
    }

    #[test]
    fn move_chain_via_function() {
        let s = String::from("42");
        let s = take_and_give_back(s); // 测试里直接复用示例函数
        assert_eq!(s, "42");

        fn take_and_give_back(s: String) -> String {
            s
        }
    }
}
