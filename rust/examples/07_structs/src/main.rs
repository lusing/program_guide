//! 07 · 结构体：字段语法、impl 方法、关联函数、派生宏

#[derive(Debug, Clone, PartialEq)]
struct Rect {
    width: f64,
    height: f64,
}

#[derive(Debug)]
struct Color(u8, u8, u8); // 元组结构体：字段无名，按位置访问

#[derive(Debug)]
struct Marker; // 单元结构体：无字段（常用作类型级标签/占位）

impl Rect {
    // ---- 关联函数：无 self，通过 Type::name() 调用（构造器惯例 new）----
    fn new(width: f64, height: f64) -> Self {
        Self { width, height } // 字段初始化简写：同名变量免写 `width: width`
    }

    fn square(size: f64) -> Self {
        Self::new(size, size)
    }

    // ---- 方法：第一个参数 self 形态决定权限 ----
    fn area(&self) -> f64 {
        // &self：只读借用，最常用
        self.width * self.height
    }

    fn scale(&mut self, k: f64) -> &mut Self {
        // &mut self：独占可变借用；返回自身引用以支持链式调用
        self.width *= k;
        self.height *= k;
        self
    }

    fn into_parts(self) -> (f64, f64) {
        // self：拿走所有权，调用后原值不可用
        (self.width, self.height)
    }

    fn can_hold(&self, other: &Rect) -> bool {
        self.width >= other.width && self.height >= other.height
    }
}

// 同一个类型可以有多个 impl 块（按主题组织代码）
impl Rect {
    const NAME: &str = "矩形";

    fn name() -> &'static str {
        Self::NAME // 关联常量
    }
}

// ---- 手写 Display（println! 的 {} 走它）----
impl std::fmt::Display for Rect {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:.1}×{:.1}", self.width, self.height)
    }
}

fn main() {
    let mut r = Rect::new(3.0, 4.0);
    println!("{r:?}"); // Debug 派生 → {:?} 可用
    println!("{r}"); // 手写 Display → {} 可用
    println!("面积 = {:.2}", r.area());

    // 方法调用是自动引用/解引用的：r.area() 等价 Rect::area(&r)
    r.scale(2.0).scale(0.5); // 链式
    println!("缩放后 {r}，面积 {}", r.area());

    let big = Rect::square(10.0);
    println!("big 能装下 r？{}", big.can_hold(&r));
    println!("类型名 = {}", Rect::name());

    // 结构体更新语法：..base 从旧值搬走未列出的字段（move！）
    let base = Rect::new(1.0, 9.9);
    let widened = Rect {
        width: 5.0,
        ..base // height 来自 base（被 move；Rect 的 f64 是 Copy，故 base 仍可用）
    };
    println!("widened = {widened:?}");

    // 元组结构体与单元结构体
    let red = Color(255, 0, 0);
    println!("R={} G={} B={}", red.0, red.1, red.2);
    let _tag = Marker;
    println!("{_tag:?} {red:?}");

    // 解构
    let Rect {
        width: w,
        height: h,
    } = widened;
    println!("解构 w={w} h={h}");

    // 拥有权限的方法消耗值
    let (w, h) = Rect::square(2.0).into_parts();
    println!("拆成 parts：{w} {h}");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn methods_and_assoc_fn() {
        let r = Rect::new(3.0, 4.0);
        assert_eq!(r.area(), 12.0);
        assert_eq!(Rect::square(5.0).area(), 25.0);
    }

    #[test]
    fn chaining_returns_self_ref() {
        let mut r = Rect::new(1.0, 1.0);
        r.scale(3.0).scale(2.0);
        assert_eq!(r, Rect::new(6.0, 6.0));
    }

    #[test]
    fn can_hold_compares() {
        let big = Rect::square(10.0);
        let small = Rect::new(2.0, 30.0); // 高度放不下
        assert!(big.can_hold(&Rect::new(1.0, 1.0)));
        assert!(!big.can_hold(&small));
    }

    #[test]
    fn derive_gives_you_comparison() {
        // PartialEq 派生 → == 可用；Clone 派生 → .clone() 可用
        assert_eq!(Rect::new(1.0, 2.0), Rect::new(1.0, 2.0).clone());
        assert_ne!(Rect::new(1.0, 2.0), Rect::new(2.0, 1.0));
    }

    #[test]
    fn struct_update_moves_unlisted() {
        let base = Rect::new(1.0, 9.9);
        let w = Rect { width: 5.0, ..base };
        // f64 是 Copy，base 字段被复制，base 仍可用；
        // 换成 String 字段则 base 整体被 move（部分移动），后续不可用。
        assert_eq!((w.width, w.height), (5.0, 9.9));
        assert_eq!(base.width, 1.0);
    }
}
