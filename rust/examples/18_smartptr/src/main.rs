//! 18 · 智能指针：Box、Rc、RefCell、Weak、Deref/Drop、内部可变性

use std::cell::RefCell;
use std::rc::{Rc, Weak};

// ---- Box 让递归类型成为可能：编译期必须知道大小，Box 是固定大小指针 ----
#[derive(Debug)]
enum List {
    Node(i32, Box<List>),
    Nil,
}

use List::{Nil, Node};

// ---- 自定义智能指针：实现 Deref / Drop 就能像引用一样用 ----
struct MyBox<T>(T);

impl<T> MyBox<T> {
    fn new(v: T) -> Self {
        MyBox(v)
    }
}

impl<T> std::ops::Deref for MyBox<T> {
    type Target = T;
    fn deref(&self) -> &T {
        &self.0
    }
}

impl<T> Drop for MyBox<T> {
    fn drop(&mut self) {
        println!("  [MyBox] 释放");
    }
}

// ---- RefCell：把借用检查从编译期挪到运行期（内部可变性）----
#[derive(Debug)]
struct Logger {
    level: String,
    count: usize,
}

fn main() {
    // ================= Box：堆分配 + 独占所有权 =================
    let b = Box::new(5);
    println!("Box 里的值 = {b}（自动解引用）");

    let list = Node(1, Box::new(Node(2, Box::new(Node(3, Box::new(Nil))))));
    println!("递归链表 = {list:?}");
    println!("链表长度 = {}，总和 = {}", len(&list), sum(&list));

    // Box<dyn Trait>：trait 对象的标准持有方式（12 章见过 Vec<Box<dyn>>）
    let shapes: Vec<Box<dyn std::fmt::Debug>> =
        vec![Box::new(1), Box::new("文本"), Box::new([1, 2])];
    println!("异构集合：{shapes:?}");

    // ================= Deref 链：&String → &str 的秘密 =================
    let s = MyBox::new(String::from(" deref 强转"));
    let view: &str = &s; // &MyBox<String> → &String → &str，逐层 deref
    println!("MyBox 借出：{view}");
    // 方法调用也自动穿透：s.len() 直接可用
    println!("直接调方法 len = {}", s.len());

    // ================= Rc：共享所有权（单线程引用计数）=================
    let a = Rc::new(String::from("共享数据"));
    let b = Rc::clone(&a); // 只增加计数，不复制数据
    let c = Rc::clone(&a);
    println!(
        "Rc 强计数 = {}（Rc::clone 是廉价操作）",
        Rc::strong_count(&a)
    );
    drop(b);
    println!("drop 一个后 = {}", Rc::strong_count(&a));
    println!("a 和 c 都能读：{a} / {c}");
    // 计数归零时（a、c 都 drop）数据才释放。
    // Rc 是只读共享：let mut = a; a.push_str(...) ← 不行
    // Arc 是它的原子版（多线程用，22 章实战）

    // ================= RefCell：运行期借用检查 =================
    let cell = RefCell::new(Logger {
        level: "INFO".into(),
        count: 0,
    });
    // 编译器看 RefCell 是不可变绑定，但通过 borrow_mut 能改内容：
    for i in 0..3 {
        cell.borrow_mut().count += 1; // 运行期独占借用
        let _ = i;
    }
    println!(
        "改了 {} 次，level = {}",
        cell.borrow().count,
        cell.borrow().level
    );
    // 借用规则没消失，只是推迟到运行期强制：
    // let r1 = cell.borrow_mut();
    // let r2 = cell.borrow_mut();   // ← panic: already mutably borrowed
    // println!("{:?}", r1);

    // ================= Rc<RefCell<T>>：共享 + 可变 的经典组合 =================
    let shared = Rc::new(RefCell::new(vec![1, 2]));
    let writer = Rc::clone(&shared);
    writer.borrow_mut().push(3);
    shared.borrow_mut().push(4);
    println!("共享可变向量 = {:?}", shared.borrow());

    // ================= Weak：打破循环引用 =================
    // Rc 环（A→B→A）的计数永不归零 → 内存泄漏。Weak 不增计数、访问需 upgrade：
    #[derive(Debug)]
    struct Node2 {
        name: &'static str,
        parent: RefCell<Weak<Node2>>, // 父节点用弱引用
        children: RefCell<Vec<Rc<Node2>>>,
    }
    let leaf = Rc::new(Node2 {
        name: "leaf",
        parent: RefCell::new(Weak::new()),
        children: RefCell::new(vec![]),
    });
    let root = Rc::new(Node2 {
        name: "root",
        parent: RefCell::new(Weak::new()),
        children: RefCell::new(vec![Rc::clone(&leaf)]),
    });
    *leaf.parent.borrow_mut() = Rc::downgrade(&root); // 建立弱引用
    println!("root 有 {} 个子节点", root.children.borrow().len());
    println!(
        "leaf 的父节点 = {:?}",
        leaf.parent.borrow().upgrade().map(|p| p.name)
    );
    println!("root 强计数 = {}", Rc::strong_count(&root));
    // ↑ children 字段在上面被读取；未被读取的字段会触发 dead_code 警告
    // root 释放后 leaf 的 parent 变 None，而不是悬垂：
    drop(root);
    println!(
        "drop root 后 leaf 的父节点 = {:?}",
        leaf.parent.borrow().upgrade().map(|p| p.name)
    );

    // 选型速记（docs 有全表）：
    // Box 独占 | Rc/Arc 共享只读 | RefCell 单线程内部可变 | Mutex/RwLock 多线程内部可变
    // Rc<RefCell<T>> 共享+可变（单线程）| Arc<Mutex<T>> 共享+可变（多线程）
}

fn len(list: &List) -> i32 {
    match list {
        Node(_, rest) => 1 + len(rest),
        Nil => 0,
    }
}

fn sum(list: &List) -> i32 {
    match list {
        Node(v, rest) => v + sum(rest), // 读取字段 0（负载）
        Nil => 0,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn box_enables_recursion() {
        let l = Node(1, Box::new(Node(2, Box::new(Nil))));
        assert_eq!(len(&l), 2);
    }

    #[test]
    fn deref_gives_method_access() {
        let m = MyBox::new(String::from("abc"));
        assert_eq!(m.len(), 3); // String::len 穿透 MyBox
        let s: &str = &m; // deref 强转到 &str
        assert_eq!(s, "abc");
    }

    #[test]
    fn rc_shares_without_copying() {
        let a = Rc::new(vec![1, 2]);
        let b = Rc::clone(&a);
        assert_eq!(Rc::strong_count(&a), 2);
        assert_eq!(*b, vec![1, 2]); // 同一份数据
        drop(a);
        assert_eq!(Rc::strong_count(&b), 1);
        assert_eq!(*b, vec![1, 2]); // 数据仍在
    }

    #[test]
    fn refcell_runtime_borrow() {
        let c = RefCell::new(0);
        *c.borrow_mut() += 1;
        *c.borrow_mut() += 1;
        assert_eq!(*c.borrow(), 2);
    }

    #[test]
    #[should_panic(expected = "already borrowed")]
    fn refcell_double_borrow_panics_at_runtime() {
        let c = RefCell::new(1);
        let _r1 = c.borrow();
        let _r2 = c.borrow_mut(); // 共享借用存活期间开独占 → 运行时 panic
    }

    #[test]
    fn rc_refcell_combo() {
        let shared = Rc::new(RefCell::new(String::from("a")));
        for _ in 0..3 {
            shared.borrow_mut().push('b');
        }
        assert_eq!(shared.borrow().as_str(), "abbb");
        assert_eq!(Rc::strong_count(&shared), 1);
    }

    #[test]
    fn weak_upgrade_or_none() {
        let strong = Rc::new(1);
        let weak: Weak<i32> = Rc::downgrade(&strong);
        assert_eq!(weak.upgrade().as_deref(), Some(&1)); // upgrade 返回 Option<Rc<T>>
        drop(strong);
        assert!(weak.upgrade().is_none()); // 强引用没了 → None，不悬垂
    }
}
