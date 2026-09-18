//! 05 · 借用与引用 ⭐：& 与 &mut、借用规则、NLL、切片
//!
//! 两条铁律（编译器同时强制）：
//!   任意时刻，对同一数据：要么 N 个共享引用 &T，要么恰好 1 个可变引用 &mut T。
//!   引用的生存期绝不超过被指数据（悬垂引用直接编译错）。

fn main() {
    // ---- 共享引用 &：只读，可以同时有很多个 ----
    let s = String::from("共享");
    let r1 = &s;
    let r2 = &s;
    println!("r1={r1} r2={r2}，多个共享引用相安无事");

    // ---- 可变引用 &mut：独占写权限 ----
    let mut m = String::from("可变");
    change(&mut m);
    println!("改写后：{m}");

    // ---- 冲突场景 1：共享引用存活期间开可变引用 ----
    let mut t = String::from("冲突");
    let r = &t;
    // let w = &mut t;      // ← 编译错：cannot borrow `t` as mutable
    //                       //   because it is also borrowed as immutable
    println!("读 {r}"); // r 的最后一次使用在这里（NLL）
    let w = &mut t; // ← r 已不再使用，此处借可变引用 OK！
    w.push('!');
    println!("写 {w}");

    // ---- 冲突场景 2：两个可变引用 ----
    let mut u = String::from("两把写锁");
    let w1 = &mut u;
    w1.push('1');
    // let w2 = &mut u;     // ← 编译错：second mutable borrow
    println!("{w1}");

    // ---- NLL（非词法生命周期）：按"最后使用"而非"作用域结束"判定 ----
    let mut v = vec![1, 2, 3];
    let first = &v[0];
    println!("first = {first}"); // 共享借用到此为止
    v.push(4); // 此处重新可变借用，合法（旧引用已死）
    println!("v = {v:?}");

    // ---- 悬垂引用：编译器直接拒绝 ----
    // fn dangle() -> &String { let s = String::from("x"); &s }
    // ↑ 编译错：cannot return reference to local variable（s 在函数结束已释放）

    // ---- 切片：借用一段连续数据的视图（不拥有）----
    let arr = [1, 2, 3, 4, 5];
    let mid: &[i32] = &arr[1..4]; // [2, 3, 4]
    println!("切片 {mid:?} 长度 {} 首元素 {}", mid.len(), mid[0]);

    let words = String::from("the quick brown fox");
    let first = first_word(&words); // &String 自动 deref 为 &str
    println!("第一个单词：{first}");
    // words.clear();  // ← 编译错：first 还持有共享借用（悬垂防线）
    println!("words 完整内容仍可用：{words}");

    // ---- 典型 API 形态：函数要只读文本就用 &str（06 章细讲）----
    println!("byte_len(&str) = {}", "你好".len()); // 6：UTF-8 三个字节/汉字
}

fn change(s: &mut String) {
    s.push_str("（被函数改写）");
}

/// TRB 经典：返回第一个单词的切片。
/// 输入 &str（而不是 &String）→ 同时接受 &String 与 &str（deref 强制转换）。
fn first_word(s: &str) -> &str {
    match s.find(' ') {
        Some(i) => &s[..i],
        None => s,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn shared_refs_coexist() {
        let s = String::from("abc");
        let a = &s;
        let b = &s;
        assert_eq!(a, b);
    }

    #[test]
    fn mutable_ref_allows_change() {
        let mut n = 1;
        add_one(&mut n);
        assert_eq!(n, 2);
    }

    fn add_one(n: &mut i32) {
        *n += 1; // 解引用写入
    }

    #[test]
    fn nll_reborrow_after_last_use() {
        let mut v = vec![10];
        let r = &v[0];
        assert_eq!(*r, 10); // r 最后一次使用
        v.push(20); // 新的借用阶段开始
        assert_eq!(v.len(), 2);
    }

    #[test]
    fn first_word_slices() {
        assert_eq!(first_word("hello world"), "hello");
        assert_eq!(first_word("solo"), "solo");
        assert_eq!(first_word(""), "");
    }

    #[test]
    fn slice_is_a_fat_pointer() {
        let a = [1, 2, 3, 4, 5];
        let s = &a[1..3];
        assert_eq!(s, &[2, 3]);
        assert_eq!(s.len(), 2);
        let full: &[i32] = &a; // 整个数组也是一个切片
        assert_eq!(full.len(), 5);
    }
}
