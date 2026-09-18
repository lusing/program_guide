//! 24 · 实战：迷你 grep ⭐（库部分）
//!
//! 综合演练：所有权/借用（切片搜索）、错误处理（Result + ? + Box<dyn Error>）、
//! 生命周期（返回借自 contents 的数据）、迭代器管道、模块拆分与测试。
//! 逻辑放 lib（可测试），main 只做参数处理——这是 Rust CLI 的标准分层。

use std::env;
use std::error::Error;
use std::fs;
use std::path::{Path, PathBuf};

// ============================ 配置 ============================

#[derive(Debug, Clone)]
pub struct Config {
    pub query: String,
    pub paths: Vec<PathBuf>,
    pub ignore_case: bool,
    pub recursive: bool,
}

impl Config {
    /// 从参数迭代器构造（跳过程序名）；环境变量 MINIGREP_IGNORE_CASE=1 也开忽略大小写。
    /// 用迭代器而不是 &[String] —— std::env::args() 直接喂进来，测试也好造。
    pub fn build(mut args: impl Iterator<Item = String>) -> Result<Config, String> {
        let _prog = args.next(); // 程序名
        let (mut query, mut paths) = (None, Vec::new());
        let mut ignore_case = env::var("MINIGREP_IGNORE_CASE").is_ok_and(|v| v != "0");
        let mut recursive = false;
        for arg in args {
            match arg.as_str() {
                "-i" | "--ignore-case" => ignore_case = true,
                "-r" | "--recursive" => recursive = true,
                _ if query.is_none() => query = Some(arg),
                _ => paths.push(PathBuf::from(arg)),
            }
        }
        Ok(Config {
            query: query.ok_or("用法：minigrep [-i] [-r] <关键词> <文件或目录>...")?,
            paths,
            ignore_case,
            recursive,
        })
    }
}

// ============================ 搜索核心 ============================

/// 一条命中：文件、行号、整行内容。
/// line 拥有数据（String）——跨文件汇总时借用生命周期会互相纠缠，拥有更简单。
#[derive(Debug, Clone, PartialEq)]
pub struct Match {
    pub path: PathBuf,
    pub line_no: usize,
    pub line: String,
}

/// 大小写敏感搜索
pub fn search(path: &Path, query: &str, contents: &str) -> Vec<Match> {
    contents
        .lines()
        .enumerate()
        .filter(|(_, line)| line.contains(query))
        .map(|(line_no, line)| Match {
            path: path.to_path_buf(),
            line_no: line_no + 1,
            line: line.to_string(),
        })
        .collect()
}

/// 大小写不敏感搜索（同一份代码，两个实现——统一成闭包参数见 docs）
pub fn search_case_insensitive(path: &Path, query: &str, contents: &str) -> Vec<Match> {
    let q = query.to_lowercase();
    contents
        .lines()
        .enumerate()
        .filter(|(_, line)| line.to_lowercase().contains(&q))
        .map(|(line_no, line)| Match {
            path: path.to_path_buf(),
            line_no: line_no + 1,
            line: line.to_string(),
        })
        .collect()
}

/// 递归收集文件：目录 → 展开子目录；文件 → 原样保留。
/// 排序保证输出稳定（read_dir 顺序依平台/时间而变，测试需要确定性）。
pub fn collect_files(
    root: &Path,
    recursive: bool,
    out: &mut Vec<PathBuf>,
) -> Result<(), Box<dyn Error>> {
    let meta = fs::metadata(root)?;
    if meta.is_file() {
        out.push(root.to_path_buf());
        return Ok(());
    }
    let mut entries: Vec<PathBuf> = fs::read_dir(root)?
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .collect();
    entries.sort();
    for p in entries {
        if p.is_dir() {
            if recursive {
                collect_files(&p, recursive, out)?;
            }
        } else {
            out.push(p);
        }
    }
    Ok(())
}

// ============================ 运行 ============================

const RED: &str = "\x1b[1;31m";
const BOLD: &str = "\x1b[1m";
const RESET: &str = "\x1b[0m";

/// 把行中命中的部分标红（按字节区间切，命中串本身按字符对齐处理）
fn highlight(line: &str, query: &str, ignore_case: bool) -> String {
    let (hay, needle) = if ignore_case {
        (line.to_lowercase(), query.to_lowercase())
    } else {
        (line.to_string(), query.to_string())
    };
    match hay.find(&needle) {
        Some(byte_start) => {
            // 字节边界安全切片：contains 命中保证边界完整
            let byte_end = byte_start + needle.len();
            format!(
                "{BOLD}{}{RESET}{RED}{}{RESET}{BOLD}{}{RESET}",
                &line[..byte_start],
                &line[byte_start..byte_end],
                &line[byte_end..]
            )
        }
        None => line.to_string(), // 不可能：调用前已过滤
    }
}

/// 主流程：读文件 → 搜文件 → 高亮打印。错误全部 ? 上抛。
pub fn run(config: &Config) -> Result<usize, Box<dyn Error>> {
    let mut files = Vec::new();
    for p in &config.paths {
        collect_files(p, config.recursive, &mut files)?;
    }
    let mut total = 0;
    for file in &files {
        let contents = fs::read_to_string(file)?;
        let matches = if config.ignore_case {
            search_case_insensitive(file, &config.query, &contents)
        } else {
            search(file, &config.query, &contents)
        };
        for m in &matches {
            println!(
                "{}:{RED}{}{RESET}:{}",
                file.display(),
                m.line_no,
                highlight(&m.line, &config.query, config.ignore_case)
            );
        }
        if !matches.is_empty() {
            println!(
                "{BOLD}-- {}：{} 处命中{RESET}",
                file.display(),
                matches.len()
            );
        }
        total += matches.len();
    }
    println!("{BOLD}共 {total} 处命中（{} 个文件）", files.len());
    Ok(total)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> &'static str {
        "Rust 是安全的\nrust 是快的\n大家都爱 Rust\n最后一行没有关键词\n"
    }

    #[test]
    fn case_sensitive() {
        let m = search(Path::new("t.txt"), "Rust", sample());
        let lines: Vec<usize> = m.iter().map(|x| x.line_no).collect();
        assert_eq!(lines, vec![1, 3]);
    }

    #[test]
    fn case_insensitive() {
        let m = search_case_insensitive(Path::new("t.txt"), "RUST", sample());
        let lines: Vec<usize> = m.iter().map(|x| x.line_no).collect();
        assert_eq!(lines, vec![1, 2, 3]);
    }

    #[test]
    fn no_hit_is_empty_vec() {
        assert!(search(Path::new("t"), "不存在", sample()).is_empty());
    }

    #[test]
    fn config_parses_flags() {
        let c = Config::build(
            ["minigrep", "-i", "-r", "query", "dir1", "dir2"]
                .iter()
                .map(|s| s.to_string()),
        )
        .unwrap();
        assert_eq!(c.query, "query");
        assert_eq!(c.paths.len(), 2);
        assert!(c.ignore_case && c.recursive);
    }

    #[test]
    fn config_rejects_empty() {
        assert!(Config::build(std::iter::empty()).is_err());
    }

    #[test]
    fn collect_files_sorts() {
        let dir = std::env::temp_dir().join(format!("mg_sort_{}", std::process::id()));
        fs::create_dir_all(dir.join("b")).unwrap();
        fs::write(dir.join("b/2.txt"), "x").unwrap();
        fs::write(dir.join("1.txt"), "x").unwrap();
        let mut out = vec![];
        collect_files(&dir, true, &mut out).unwrap();
        assert_eq!(out.len(), 2);
        assert!(out[0].ends_with("1.txt")); // 排序后稳定
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn run_counts_hits() {
        let dir = std::env::temp_dir().join(format!("mg_run_{}", std::process::id()));
        fs::create_dir_all(&dir).unwrap();
        fs::write(dir.join("poem.txt"), "one\ntwo rust\nthree\n").unwrap();
        let cfg = Config {
            query: "rust".into(),
            paths: vec![dir.clone()],
            ignore_case: false,
            recursive: false,
        };
        let n = run(&cfg).unwrap();
        assert_eq!(n, 1);
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn highlight_keeps_line_intact() {
        assert!(highlight("abc", "b", false).contains("b"));
    }
}
