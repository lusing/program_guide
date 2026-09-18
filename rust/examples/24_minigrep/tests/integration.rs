//! 集成测试：以最终用户视角驱动二进制行为背后的库 API。

use std::fs;
use std::path::Path;
use std::process::Command;

const SAMPLE: &str = "Rust 安全\nrust 快\n无关行\n";

#[test]
fn library_search_end_to_end() {
    let hits = minigrep::search(Path::new("sample"), "Rust", SAMPLE);
    assert_eq!(hits.len(), 1); // 大小写敏感："rust 快" 不命中
    assert_eq!(hits[0].line_no, 1);

    let ci = minigrep::search_case_insensitive(Path::new("sample"), "RUST", SAMPLE);
    assert_eq!(ci.len(), 2);
    assert_eq!(ci[1].line_no, 2);
}

#[test]
fn binary_exits_nonzero_when_no_match() {
    // cargo 编译出的可执行文件直接跑（不依赖 target 布局的稳健做法：
    // 用 env!("CARGO_BIN_EXE_minigrep")，cargo 会注入路径）
    let dir = std::env::temp_dir().join(format!("mg_int_{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    let f = dir.join("x.txt");
    fs::write(&f, "aaa\n").unwrap();

    let out = Command::new(env!("CARGO_BIN_EXE_minigrep"))
        .args(["不存在的词", f.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(!out.status.success()); // 无命中 → 退出码 1

    let out = Command::new(env!("CARGO_BIN_EXE_minigrep"))
        .args(["aaa", f.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(out.status.success());
    let stdout = String::from_utf8(out.stdout).unwrap();
    assert!(stdout.contains("aaa"));

    fs::remove_dir_all(&dir).unwrap();
}
