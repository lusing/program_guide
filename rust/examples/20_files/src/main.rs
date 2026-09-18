//! 20 · 文件 IO 与序列化：fs/Path/OpenOptions、serde 派生、serde_json 全流程

use serde::{Deserialize, Serialize};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};

#[derive(Serialize, Deserialize, Debug, PartialEq)]
#[serde(rename_all = "camelCase")] // Rust 字段 snake_case ↔ JSON camelCase
struct Config {
    app_name: String,
    max_retries: u32,
    tags: Vec<String>,
    #[serde(default)] // 字段缺失时用 Default::default()，而不是报错
    verbose: bool,
}

fn main() {
    // 用系统临时目录做沙箱（Windows: %TEMP%，macOS/Linux: /tmp）
    let dir = std::env::temp_dir().join(format!("guide_files_{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    println!("工作目录：{}", dir.display());

    // ============ 文本文件：写、读、追加 ============
    let hello = dir.join("hello.txt");
    fs::write(&hello, "第一行\n").unwrap(); // 整文件覆写
    let content = fs::read_to_string(&hello).unwrap();
    println!("读到：{content:?}");

    // OpenOptions：精细控制（追加模式）
    let mut f = OpenOptions::new().append(true).open(&hello).unwrap();
    f.write_all("第二行（追加）\n".as_bytes()).unwrap(); // b"" 字节串只允许 ASCII，中文用 as_bytes()
    drop(f);
    println!("追加后：{:?}", fs::read_to_string(&hello).unwrap());

    // ============ 二进制文件 ============
    let bin = dir.join("data.bin");
    fs::write(&bin, [0x52u8, 0x53, 0x54]).unwrap(); // "RST"
    let bytes = fs::read(&bin).unwrap();
    println!("二进制：{bytes:?}（{} 字节）", bytes.len());

    // ============ 目录：创建、遍历、元数据 ============
    let sub = dir.join("a").join("b"); // 嵌套路径
    fs::create_dir_all(&sub).unwrap();
    fs::write(sub.join("deep.txt"), "深处").unwrap();

    println!("目录遍历（read_dir 只看一层）：");
    for entry in fs::read_dir(&dir).unwrap() {
        let entry = entry.unwrap();
        let ft = entry.file_type().unwrap();
        let kind = if ft.is_dir() { "目录" } else { "文件" };
        println!("  [{kind}] {}", entry.path().display());
    }

    let meta = fs::metadata(&hello).unwrap();
    println!("hello.txt：{} 字节，is_file={}", meta.len(), meta.is_file());

    // ============ Path / PathBuf：跨平台路径操作 ============
    let p: PathBuf = dir.join("logs").join("app.log");
    println!("join 后：{}", p.display());
    println!(
        "parent={:?} file_name={:?} extension={:?}",
        p.parent(),
        p.file_name(),
        p.extension()
    );
    println!("logs 存在吗？{}", Path::new(&dir).join("logs").exists());

    // ============ serde_json：结构体 ⇄ JSON ============
    let cfg = Config {
        app_name: "guide".into(),
        max_retries: 3,
        tags: vec!["rust".into(), "教程".into()],
        verbose: false,
    };

    // 序列化：紧凑 / 美化
    let compact = serde_json::to_string(&cfg).unwrap();
    let pretty = serde_json::to_string_pretty(&cfg).unwrap();
    println!("紧凑：{compact}");
    println!("美化：\n{pretty}");

    // 反序列化：camelCase 字段映射回 snake_case
    let back: Config = serde_json::from_str(&compact).unwrap();
    println!("往返一致：{}", back == cfg);

    // #[serde(default)]：verbose 缺失也不报错
    let partial = r#"{"appName":"x","maxRetries":1,"tags":[]}"#;
    let c2: Config = serde_json::from_str(partial).unwrap();
    println!("缺省字段 verbose = {}", c2.verbose);

    // 常见错误：类型不匹配 / 字段缺失（无 default 时）
    let bad = r#"{"appName":42}"#;
    let err = serde_json::from_str::<Config>(bad).unwrap_err();
    println!("错误信息：{err}");

    // JSON 落盘（serde_json::to_writer 直接写文件，不整串进内存）
    let cfg_path = dir.join("config.json");
    let wf = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .open(&cfg_path)
        .unwrap();
    serde_json::to_writer_pretty(wf, &cfg).unwrap();

    // 从文件反序列化（from_reader 流式读取）
    let rf = fs::File::open(&cfg_path).unwrap();
    let from_disk: Config = serde_json::from_reader(rf).unwrap();
    println!("从磁盘读回：{from_disk:?}");

    // ============ 清理沙箱 ============
    fs::remove_dir_all(&dir).unwrap();
    println!("已清理 {}", dir.display());
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn json_round_trip() {
        let cfg = Config {
            app_name: "t".into(),
            max_retries: 1,
            tags: vec!["a".into()],
            verbose: true,
        };
        let s = serde_json::to_string(&cfg).unwrap();
        let back: Config = serde_json::from_str(&s).unwrap();
        assert_eq!(cfg, back);
    }

    #[test]
    fn rename_all_camel_case() {
        let cfg = Config {
            app_name: "n".into(),
            max_retries: 0,
            tags: vec![],
            verbose: false,
        };
        let s = serde_json::to_string(&cfg).unwrap();
        assert!(s.contains("\"appName\""));
        assert!(!s.contains("app_name"));
    }

    #[test]
    fn serde_default_fills_missing() {
        let c: Config =
            serde_json::from_str(r#"{"appName":"x","maxRetries":2,"tags":[]}"#).unwrap();
        assert!(!c.verbose);
    }

    #[test]
    fn type_mismatch_is_an_error() {
        let r: Result<Config, _> = serde_json::from_str(r#"{"appName":42}"#);
        assert!(r.is_err());
    }

    #[test]
    fn file_round_trip_in_sandbox() {
        let dir = std::env::temp_dir().join(format!("guide_files_test_{}", std::process::id()));
        fs::create_dir_all(&dir).unwrap();
        let path = dir.join("t.json");
        fs::write(&path, r#"{"appName":"a","maxRetries":9,"tags":["x"]}"#).unwrap();
        let c: Config = serde_json::from_reader(fs::File::open(&path).unwrap()).unwrap();
        assert_eq!(c.max_retries, 9);
        assert_eq!(c.tags, vec!["x".to_string()]);
        fs::remove_dir_all(&dir).unwrap();
    }
}
