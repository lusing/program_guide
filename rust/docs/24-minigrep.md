# 24 · 实战：迷你 grep ⭐

> 对应示例：`examples/24_minigrep/`（独立 cargo 工程：lib + bin + 集成测试）
>
> 24 章知识的合练：所有权/借用（搜索返回）、错误处理（? 全链路）、
> 生命周期（视图）、迭代器管道、模块分层、测试三件套。目标产物是能真用的命令行工具。

## 24.1 需求与用法

```text
minigrep [-i] [-r] <关键词> <文件或目录>...
  -i, --ignore-case   忽略大小写（环境变量 MINIGREP_IGNORE_CASE=1 同效）
  -r, --recursive     目录递归搜索
输出：文件:行号:整行（命中部分 ANSI 标红）；结尾汇总命中数
退出码：0 有命中 / 1 无命中或错误 / 2 用法错误（grep 传统）
```

```bash
# macOS / Linux
cd <仓库>/rust/examples/24_minigrep
cargo run                            # 无参数 → 自包含演示模式（exit 0）
cargo run -- Rust src                # 真实搜索
cargo run -- -i -r "fn main" ../24_minigrep/src   # 递归 + 忽略大小写
```

```powershell
# Windows（PowerShell）
cd G:\code\guide\rust\examples\24_minigrep
cargo run                            # 无参数 → 自包含演示模式（exit 0）
cargo run -- Rust src                # 真实搜索
cargo run -- -i -r "fn main" ..\..\  # 递归 + 忽略大小写
```

## 24.2 分层：lib 承载逻辑，main 只做壳

```text
24_minigrep/
├── Cargo.toml
├── src/
│   ├── lib.rs        # Config 解析、search 核心、run 主流程（全部可测）
│   └── main.rs       # 参数 → Config → run → 退出码；无参时演示模式
└── tests/
    └── integration.rs   # 以用户视角测库 + 直接跑二进制（CARGO_BIN_EXE）
```

**为什么逻辑放 lib**：bin crate 没法被集成测试 use；lib 天然是"被调用方"，测试、文档、复用三得利。main.rs 保持 30 行内——这是 CLI 工具的 Rust 标准分层（21 章）。

## 24.3 Config：参数解析作为纯函数

```rust
#[derive(Debug, Clone)]
pub struct Config {
    pub query: String,
    pub paths: Vec<PathBuf>,
    pub ignore_case: bool,
    pub recursive: bool,
}

impl Config {
    /// 收迭代器不收 &[String]：std::env::args() 直接喂，测试也好造
    pub fn build(mut args: impl Iterator<Item = String>) -> Result<Config, String> {
        let _prog = args.next();                                  // 跳过程序名
        let (mut query, mut paths) = (None, Vec::new());
        let mut ignore_case = env::var("MINIGREP_IGNORE_CASE").is_ok_and(|v| v != "0");
        let mut recursive = false;
        for arg in args {
            match arg.as_str() {
                "-i" | "--ignore-case" => ignore_case = true,
                "-r" | "--recursive" => recursive = true,
                _ if query.is_none() => query = Some(arg),        // 第一个非选项 = 关键词
                _ => paths.push(PathBuf::from(arg)),              // 其余 = 路径
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
```

要点：**签名要 `impl Iterator` 而不是 `env::args()` 的具体类型**——测试传 `["minigrep","-i","q","p"].iter().map(...)` 即可（示例测试实测）。flags 与位置参数分流，环境变量作为配置输入的第二通道。

## 24.4 搜索核心：返回什么类型？

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct Match {          // 一条命中
    pub path: PathBuf,
    pub line_no: usize,
    pub line: String,       // 拥有整行（见下）
}

pub fn search(path: &Path, query: &str, contents: &str) -> Vec<Match> {
    contents
        .lines()                                   // 15 章迭代器
        .enumerate()
        .filter(|(_, line)| line.contains(query))
        .map(|(line_no, line)| Match {
            path: path.to_path_buf(),
            line_no: line_no + 1,
            line: line.to_string(),
        })
        .collect()
}
```

TRB 原版返回 `Vec<&str>`（借自 contents，生命周期联动 13 章）；跨多文件汇总时借用链互相纠缠——**返回拥有的数据（String/PathBuf）是工具类程序的务实解**，一次 `to_string` 换全链路简洁。两种取舍都合法，注释里写明理由即可。

大小写不敏感版：`line.to_lowercase().contains(&query.to_lowercase())`——注意 `to_lowercase` 可能变长（土耳其 İ），所以是"造小写副本再比"，不是原地（06 章）。

## 24.5 目录遍历 + 输出

```rust
pub fn collect_files(root: &Path, recursive: bool, out: &mut Vec<PathBuf>)
    -> Result<(), Box<dyn Error>>
{
    if root.is_file() { out.push(root.to_path_buf()); return Ok(()); }
    let mut entries: Vec<PathBuf> = fs::read_dir(root)?
        .filter_map(|e| e.ok())          // 权限错误等：跳过而不是崩
        .map(|e| e.path())
        .collect();
    entries.sort();                       // read_dir 顺序不定（09/20 章坑）→ 排序保稳定
    for p in entries {
        if p.is_dir() {
            if recursive { collect_files(&p, recursive, out)?; }
        } else {
            out.push(p);
        }
    }
    Ok(())
}
```

高亮：ANSI 转义序列（`\x1b[1;31m` 红色加粗）包住命中片段——按**字节区间**切（`find` 返回字节偏移），命中串本身保证边界合法（06 章 UTF-8 切片规则）。

**但只在 stdout 是终端时才上色**（`std::io::IsTerminal`），并且尊重 `NO_COLOR` 环境变量：

```rust
fn palette() -> (&'static str, &'static str, &'static str) {
    let on = env::var_os("NO_COLOR").is_none() && std::io::stdout().is_terminal();
    if on { (RED_ESC, BOLD_ESC, RESET_ESC) } else { ("", "", "") }
}
```

理由：**`cargo run > out.txt` 或管道到 `less`/CI 日志时，ANSI 转义是纯噪声**——
下游拿到一串 `\x1b[1;31m`，还可能被判定成"输出含控制字符"。Windows 上更明显：
旧控制台不支持 VT 时这些转义会原样印成乱码。判据是 `stdout` 而不是"是不是 Windows"。

## 24.6 run：主流程 = 错误处理编排

```rust
pub fn run(config: &Config) -> Result<usize, Box<dyn Error>> {
    let mut files = Vec::new();
    for p in &config.paths { collect_files(p, config.recursive, &mut files)?; }
    let mut total = 0;
    for file in &files {
        let contents = fs::read_to_string(file)?;          // io::Error 上抛
        let matches = if config.ignore_case { /* … */ } else { search(file, &config.query, &contents) };
        for m in &matches { println!(/* 高亮行 */); }
        total += matches.len();
    }
    Ok(total)
}
```

`Box<dyn Error>` 承装 io::Error 与自定义错误（10 章）；调用方拿 `Result<usize>` 决定退出码——**库不 process::exit，退出是 main 的职权**。

## 24.7 测试三件套落地

```rust
// 单元（lib 内）：核心算法表驱动
#[test] fn case_sensitive() { assert_eq!(行号集(&search("Rust", SAMPLE)), [1, 3]); }
#[test] fn config_parses_flags() { … }
#[test] fn collect_files_sorts() { … }        // 临时目录实测

// 集成（tests/）：用户视角
use minigrep::{search, search_case_insensitive};
#[test] fn library_search_end_to_end() { … }

// 系统级：直接执行编译出的二进制
let out = Command::new(env!("CARGO_BIN_EXE_minigrep"))     // cargo 注入的路径
    .args(["不存在的词", path]).output().unwrap();
assert!(!out.status.success());                            // 无命中 → 退出码 1
```

`CARGO_BIN_EXE_*` 是 cargo 的测试期环境变量（21 章）——**测试退出码语义**（0/1/2）只能走这条路，库测试覆盖不了。

## 24.8 无参演示模式：可验证的自足入口

构建脚本要求 `cargo run` 无参数也 exit 0——工具的"演示模式"顺便解决了它：临时目录生成样例文本，依次跑三种配置（敏感/忽略大小写/递归），输出完清理。**可复现、不依赖仓库外文件**——这是教程工程的通用技巧（go/zig 教程同款处理）。

## 24.9 扩展练习（做完才算毕业）

1. `--count`：只输出每文件命中数（改 run 的输出分支）；
2. `--json`：输出 JSON 行（20 章 serde_json；Match 加 Serialize）；
3. 多关键词 `AND/OR`（Config.query 变 Vec，search 谓词泛化）；
4. 并行搜索（22 章：scoped threads 或 23 章 spawn，按文件分片）；
5. `--hidden`/`--glob` 过滤（路径谓词链）；
6. 用 `clap` derive 重写参数解析（对比手写版代码量与帮助信息质量）。

每一项都在既有骨架上加一层——这就是分层与测试先行的回报。

## 24.10 坑位清单

1. **参数解析里的 `mut paths` 忘写**：`paths.push(...)` 编译错 E0596——元组解构绑定的可变性要逐个声明（示例实测第一版就栽了）。
2. **read_dir 顺序不稳定**：Windows/Linux/每次运行都不同——排序后再用（09 章坑的实战版）。
3. **`is_ok_and` vs `map_or`**：`map_or(false, |v| ...)` 被 clippy 建议改 `is_ok_and`（示例实测）。
4. **二进制测试别猜 target 路径**：`env!("CARGO_BIN_EXE_minigrep")` 是唯一稳法（相对路径在 cargo 改布局时全碎）。
5. **搜索含中文文件**：`read_to_string` 遇非 UTF-8（GBK 老文件）报错——工具语义上该跳过+警告而不是中断，练习 5 的好素材。
6. **退出码语义要在 main 定**：库返回 Result，main 映射 0/1/2——把 exit 写进库会让测试无法覆盖。
7. **println! 大量输出性能**：逐行 println 每次锁 stdout；热点用 `BufWriter<Stdout>` 包一层批量 flush（百万行级才显著）。

---

恭喜——24 章全部完成。回到 [README](../README.md) 看全貌，或用 `build.ps1 -All` 复核全部示例。
