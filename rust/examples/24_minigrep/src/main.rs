//! 24 · 实战：迷你 grep ⭐（入口）
//!
//! 分层：main 只做 参数 → 配置 → 调库 → 退出码。
//! 无参数时进入自包含演示模式（build 脚本的 cargo run 需要 exit 0）。

use std::process;
use std::{env, fs};

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        demo();
        return;
    }

    let config = minigrep::Config::build(args.into_iter()).unwrap_or_else(|err| {
        eprintln!("参数错误：{err}");
        process::exit(2); // 2 = 用法错误（区分于 1 = 运行错误）
    });

    match minigrep::run(&config) {
        Ok(n) if n > 0 => process::exit(0),
        Ok(_) => {
            println!("没有命中。");
            process::exit(1) // grep 的传统：没找到也是非零
        }
        Err(e) => {
            eprintln!("运行错误：{e}");
            process::exit(1);
        }
    }
}

/// 演示模式：临时目录里生成样例文本，跑大小写敏感/不敏感/递归三种搜索
fn demo() {
    println!("== minigrep 演示模式（真实用法：minigrep [-i] [-r] <关键词> <路径...>）==\n");

    let dir = std::env::temp_dir().join(format!("minigrep_demo_{}", process::id()));
    fs::create_dir_all(dir.join("sub")).unwrap();
    fs::write(
        dir.join("poem.txt"),
        "Rust 让人又爱又恨\nrust 都是小写\nNothing here\n爱 Rust 的每个字节\n",
    )
    .unwrap();
    fs::write(dir.join("sub/notes.md"), "备注：rustc 是编译器\n普通一行\n").unwrap();

    for (label, cfg) in [
        (
            "大小写敏感，单文件",
            minigrep::Config {
                query: "Rust".into(),
                paths: vec![dir.join("poem.txt")],
                ignore_case: false,
                recursive: false,
            },
        ),
        (
            "忽略大小写（-i），单文件",
            minigrep::Config {
                query: "RUST".into(),
                paths: vec![dir.join("poem.txt")],
                ignore_case: true,
                recursive: false,
            },
        ),
        (
            "递归（-r）+ 忽略大小写，整棵目录",
            minigrep::Config {
                query: "rust".into(),
                paths: vec![dir.clone()],
                ignore_case: true,
                recursive: true,
            },
        ),
    ] {
        println!("-- {label} --");
        let hits = minigrep::run(&cfg).unwrap();
        println!("（{hits} 处命中）\n");
    }

    fs::remove_dir_all(&dir).unwrap();
    println!("演示完毕，已清理临时文件。");
}
