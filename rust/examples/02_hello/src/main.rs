//! 02 · 第一个程序：cargo 全流程与格式化输出
//!
//! 本示例对应 docs/02-hello.md。学法：`cargo run` 看输出 →
//! 改代码再跑；`cargo test` 跑断言。

// 演示位置参数/命名参数必须传字面量，clippy 默认建议"内联变量"——此处教学豁免
#[allow(clippy::uninlined_format_args)]
fn main() {
    println!("Hello, world!");

    // ---- println! 占位符全家 ----
    let lang = "Rust";
    let ver = 1.98;
    println!("语言：{}，版本：{}", lang, ver); // 顺序占位
    println!("语言：{lang}，版本：{ver}"); // 内联参数（1.58+，现代默认）
    println!("{0}×{1} = {2}；再来一次 {0}", 2, 3, 6); // 位置参数
    let (name, v) = ("四", 16); // 命名参数：变量名就是占位名
    println!("{name} 的平方是 {v}");

    // 宽度、对齐、补零、精度
    let (l, r, c) = ("左", "右", "中"); // 内联参数同样支持宽度/对齐
    println!("[{l:<8}|{r:>8}|{c:^8}]");
    println!("{:06.2}", 13.37); // 宽度 6、补零、两位小数 → 013.37
    println!("{:#x} {:#o} {:#b}", 255u32, 8u32, 5u32); // 0xff 0o10 0b101
    println!("数字可读性下划线：{}", 1_000_000u32);

    // Debug 格式：{:?} 单行，{:#?} 多行（需要类型实现 Debug）
    let v = vec![1, 2, 3];
    let person = ("李雷", 28);
    println!("单行：{:?} / {:?}", v, person);
    println!("多行：\n{:#?}", v);

    // print! 不换行；eprintln! 写 stderr（调试信息的惯例去处）
    print!("同一行，");
    println!("接着输出");
    eprintln!("这是 stderr：cargo run 2>err.txt 能单独重定向");

    // ---- 表达式语义预演（03 章细讲）----
    let x = 5;
    let y = {
        let x = x * 2; // 内层遮蔽
        x + 1 // 块末无分号 → 块的值
    };
    println!("x = {x}，y = {y}");
}

#[cfg(test)]
mod tests {
    #[test]
    fn format_basics() {
        assert_eq!(format!("{}, {}", 1, 2), "1, 2");
        assert_eq!(format!("{0}{1}{0}", "a", "b"), "aba");
        assert_eq!(format!("{:>5}.", 42), "   42.");
        assert_eq!(format!("{:06.2}", 13.37), "013.37");
        assert_eq!(format!("{0:+}", 7), "+7");
    }

    #[test]
    fn debug_format() {
        assert_eq!(format!("{:?}", vec![1, 2]), "[1, 2]");
    }
}
