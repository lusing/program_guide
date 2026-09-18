//! 16 · 宏系统：macro_rules! 声明宏、匹配分支、重复模式、导出与卫生性
//!
//! 过程宏（derive/属性/函数式）见 docs/16-macros.md——
//! 它们是独立的 proc-macro crate，本示例聚焦声明宏。

/// 规则 1：空输入 → 0
/// 规则 2：一个 expr
/// 规则 3：逗号分隔的多个 expr
/// `$()`...`*` 表示"重复片段"，$(,)? 表示"可选的尾逗号"
macro_rules! my_sum {
    () => { 0 };
    ($last:expr) => { $last };
    ($first:expr $(, $rest:expr)* $(,)?) => {
        $first $(+ $rest)*
    };
}

/// 打印每个表达式的"源码 = 值"（stringify! 拿到 token 的文本形态）
macro_rules! dbg_vars {
    ($($name:expr),* $(,)?) => {
        $(println!("  {} = {:?}", stringify!($name), $name);)*
    };
}

/// 造一个 vec!-like 宏：重复展开 push
/// （clippy 会建议"直接用 vec![]"，但展开原理正是本宏要教的东西，
///   在宏定义上豁免；空参数展开的 unused_mut 在宏体内豁免）
#[allow(clippy::vec_init_then_push)]
macro_rules! my_vec {
    ($($item:expr),* $(,)?) => {{
        #[allow(unused_mut, clippy::vec_init_then_push)]
        let mut v = Vec::new();
        $(v.push($item);)*
        v
    }};
}

/// 生成结构体 + 构造函数（宏做代码生成）
macro_rules! make_point {
    ($name:ident, $($field:ident : $ty:ty),* $(,)?) => {
        #[derive(Debug, Clone, Copy)]
        struct $name {
            $($field: $ty,)*
        }
        impl $name {
            fn new($($field: $ty),*) -> Self {
                Self { $($field,)* }
            }
        }
    };
}

make_point!(Point2, x: f64, y: f64);
make_point!(Point3, x: f64, y: f64, z: f64);

// 想让宏在其他模块/ crate 可用：#[macro_export] 把它挂到 crate 根。
#[macro_export]
macro_rules! shout {
    ($s:expr) => {
        println!("{}！", $s.to_uppercase())
    };
}

// crate 内部随处可用；跨 crate 则由 #[macro_export] 挂到 crate 根导出。
// 也可以用 pub(crate) use 把导出宏重新导入本地名下（docs/16-macros.md 有展开）。

// my_vec! 的展开是"新建 + 循环 push"，clippy 会建议直接用 vec![]——
// 教学宏故意保留最朴素的形态
#[allow(clippy::vec_init_then_push)]
fn main() {
    // ---- 多分支匹配：自上而下尝试 ----
    println!("my_sum!()       = {}", my_sum!());
    println!("my_sum!(5)      = {}", my_sum!(5));
    println!("my_sum!(1,2,3)  = {}", my_sum!(1, 2, 3));
    println!("my_sum!(1,2,3,) = {}", my_sum!(1, 2, 3,)); // 尾逗号也行

    // ---- stringify：编译期文本化 ----
    let a = 10;
    let b = "文本";
    dbg_vars!(a, b, a * 2);

    // ---- 代码生成 ----
    let v = my_vec![1, 2, 3, 4];
    println!("my_vec! = {v:?}");
    let p2 = Point2::new(1.0, 2.0);
    let p3 = Point3::new(1.0, 2.0, 3.0);
    println!("{p2:?}（x={} y={}）", p2.x, p2.y);
    println!("{p3:?}（x={} y={} z={}）", p3.x, p3.y, p3.z);

    // ---- 宏卫生（hygiene）：宏内部引入的变量不会污染调用处 ----
    let v = 999; // 与 my_vec! 内部的 v 同名——互不干扰
    let made = my_vec![1];
    println!("调用处 v = {v}，宏造的 = {made:?}");

    shout!("宏已导出");

    // ---- 片段类型速览（docs 有全表）----
    // expr 表达式 | ident 标识符 | ty 类型 | pat 模式 | stmt 语句
    // literal 字面量 | tt 单个 token 树 | block 块表达式 | path 路径
    // 匹配后捕获的类型在展开处受限：比如 ident 只能当名字用
}

#[cfg(test)]
mod tests {
    #![allow(clippy::vec_init_then_push)] // my_vec! 宏展开的固有形态（内部属性作用于整个模块）
    use super::*; // 宏生成的 Point2/Point3 在父模块

    #[test]
    fn sum_branches() {
        assert_eq!(my_sum!(), 0);
        assert_eq!(my_sum!(7), 7);
        assert_eq!(my_sum!(1, 2, 3), 6);
        assert_eq!(my_sum!(1, 2, 3,), 6);
    }

    #[test]
    fn vec_macro_builds() {
        let v: Vec<i32> = my_vec![];
        assert!(v.is_empty());
        assert_eq!(my_vec![1, 1, 1], vec![1, 1, 1]);
    }

    #[test]
    fn generated_types_work() {
        let p = Point2::new(3.0, 4.0);
        assert_eq!((p.x, p.y), (3.0, 4.0));
        let q = Point3::new(0.0, 0.0, 1.0);
        assert_eq!(q.z, 1.0);
    }

    #[test]
    fn hygiene_no_capture_confusion() {
        let v = 1; //宏体里的 v 不会与这里冲突
        let m = my_vec![5];
        assert_eq!(v, 1);
        assert_eq!(m, vec![5]);
    }
}
