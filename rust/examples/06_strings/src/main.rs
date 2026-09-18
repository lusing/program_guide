//! 06 · 切片与字符串：String vs &str、UTF-8、索引为什么不存在

fn main() {
    // ---- 两种字符串 ----
    let lit: &str = "字面量"; // &'static str：指向二进制里的 UTF-8 字节，固定大小
    let owned: String = String::from("堆上字符串"); // 拥有堆缓冲，可增长
    println!("{lit} / {owned}");

    // String → &str：自动 deref（切片视图）
    let view: &str = &owned;
    println!("视图：{view}");

    // &str → String：三种常见方式
    let s1 = lit.to_string(); // 或 lit.to_owned()
    let s2 = String::from(lit);
    let s3 = format!("{lit}+拼接");
    println!("{} / {} / {}", s1, s2, s3);

    // ---- 增删改（全部要求 &mut String）----
    let mut s = String::from("Rust");
    s.push('!');
    s.push_str(" 语言");
    let louder = s.replace('!', "!!"); // replace 返回新串，原串不变
    println!("{louder}");
    s.insert(0, '【'); // 单字符插入用 insert（clippy 提示）
    s.push('】');
    println!("{s}");
    println!("len = {}（字节数，不是字符数）", s.len());
    println!("chars().count() = {}", s.chars().count());

    // ---- 拼接：+ 会吃掉左操作数（move），format! 不会 ----
    let a = String::from("左");
    let b = String::from("右");
    let c = a + "+" + &b; // a 被 move；&b 是 &str 强转
    println!("c = {c}");
    // format! 借用一切，谁也不动：
    let d = format!("{}&{}", c, b);
    println!("d = {d}");

    // ---- UTF-8：字节 ≠ 字符 ----
    let zh = "你好";
    println!("'你好'.len() = {} 字节", zh.len()); // 6
    println!("chars().count() = {}", zh.chars().count()); // 2
    for (i, ch) in zh.char_indices() {
        println!("  字节偏移 {i}: {ch}（{} 字节）", ch.len_utf8());
    }
    for b in zh.bytes() {
        print!("{b:02x} "); // e4 bd a0 e5 a5 bd
    }
    println!();

    // ---- 索引不存在：s[0] 没有这个语法 ----
    // zh[0];          // ← 编译错：String 不能用整数索引
    //                   // 原因：字节索引会切出半个字符（UTF-8 变长）
    // &zh[0..1];      // ← 能编译但运行时 panic：字节边界落在字符中间
    // 安全做法——Option 语义：
    let seg = zh.get(0..3); // 恰好是完整"你"
    println!("get(0..3) = {seg:?}");
    let bad = zh.get(0..1); // 半个字符 → None，不 panic
    println!("get(0..1) = {bad:?}");

    // ---- 按字符取第 n 个：chars().nth() ----
    let second = zh.chars().nth(1);
    println!("第 2 个字符 = {second:?}");

    // ---- API 参数惯例：要只读就收 &str，要拥有/修改才收 String ----
    println!("greet(&String) = {}", greet(&owned));
    println!("greet(&str)    = {}", greet(lit)); // 同一个函数两种入参都行
}

fn greet(name: &str) -> String {
    format!("你好，{name}！")
}

#[cfg(test)]
mod tests {
    #[test]
    fn str_literals_are_static() {
        let s: &'static str = "静态";
        assert_eq!(s.len(), 6); // UTF-8 字节数
    }

    #[test]
    fn ownership_between_kinds() {
        let lit = "guide";
        let mut owned = lit.to_string();
        owned.push('!');
        assert_eq!(owned, "guide!");
        let view: &str = &owned; // String → &str 无损
        assert_eq!(view.len(), 6);
    }

    #[test]
    fn plus_moves_left_operand() {
        let a = String::from("x");
        let b = String::from("y");
        let c = a + &b; // a move 进 c；b 完好
        assert_eq!(c, "xy");
        assert_eq!(b, "y");
        // 此处再使用 a 就是编译错：value borrowed here after move
    }

    #[test]
    fn utf8_boundaries() {
        let s = "你好";
        assert_eq!(s.len(), 6);
        assert_eq!(s.chars().count(), 2);
        assert_eq!(s.get(0..3), Some("你"));
        assert_eq!(s.get(0..1), None); // 不完整边界 → None
        assert_eq!(s.chars().nth(1), Some('好'));
        assert_eq!(s.bytes().next(), Some(0xe4));
    }

    #[test]
    fn format_borrows_everything() {
        let a = String::from("A");
        let b = String::from("B");
        let c = format!("{a}-{b}");
        assert_eq!(c, "A-B");
        assert_eq!(a, "A"); // format! 只借用——两个都还活着
        assert_eq!(b, "B");
    }
}
