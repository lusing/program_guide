# 20 · 文件 IO 与序列化

> 对应示例：`examples/20_files/`（依赖 serde + serde_json——第一个用第三方 crate 的示例）
>
> std 的 fs/Path 够写工具；serde 是 Rust 生态的"事实标准序列化层"，
> JSON 学会后 YAML/TOML/bincode 只是换个后端。

## 20.1 快速上手：一行读写

```rust
use std::fs;

fs::write("hello.txt", "第一行\n")?;            // 整文件写（覆盖）
let content = fs::read_to_string("hello.txt")?; // 整文件读（UTF-8 校验，失败返回 io::Error）
let bytes = fs::read("data.bin")?;              // 二进制：Vec<u8>
fs::copy("a", "b")?;  fs::rename("a", "b")?;  fs::remove_file("a")?;
```

工具脚本这就够用了。注意返回值全是 `Result`（10 章）——`?` 一路向上抛。

## 20.2 追加与精细控制：OpenOptions

```rust
use std::fs::OpenOptions;
use std::io::Write;

let mut f = OpenOptions::new().append(true).open("log.txt")?;   // 追加模式
f.write_all("第二行\n".as_bytes())?;    // 注意：字节串 b"" 只允许 ASCII，
                                        // 中文内容用 "...".as_bytes()
drop(f);                                 // 显式落锁/释放（也可等 Drop）
```

builder 风格：`.read(true).write(true).create(true).truncate(true)` 任意组合——对应 C 的 fopen 模式字符串，但类型安全。

## 20.3 目录与元数据

```rust
fs::create_dir_all("a/b/c")?;                  // 递归建目录（mkdir -p）

for entry in fs::read_dir("some/dir")? {       // 只列一层
    let entry = entry?;                         // 每项也是 Result（权限等）
    println!("{} 目录={}", entry.path().display(), entry.file_type()?.is_dir());
}

let meta = fs::metadata("hello.txt")?;         // 元数据
meta.len() / meta.is_file() / meta.is_dir() / meta.modified()?
```

递归遍历要自己写（或用 `walkdir` crate）——24 章实战手写一个：

```rust
fn collect(root: &Path, out: &mut Vec<PathBuf>) -> std::io::Result<()> {
    if root.is_file() { out.push(root.to_path_buf()); return Ok(()); }
    for entry in fs::read_dir(root)? {
        let p = entry?.path();
        if p.is_dir() { collect(&p, out)?; } else { out.push(p); }
    }
    Ok(())
}
```

## 20.4 Path 与 PathBuf：跨平台的路径类型

```rust
use std::path::{Path, PathBuf};

let p: PathBuf = dir.join("logs").join("app.log");  // 拼接（自动处理分隔符）
p.parent() / p.file_name() / p.extension()           // 全是 Option<&OsStr>
Path::new("x.txt").exists()
p.display()                                          // 打印用（处理非 UTF-8 路径）
```

`Path` 是 `str` 的路径版（借用视图），`PathBuf` 是 `String` 版（拥有）——与 06 章的二元结构完全同构。Windows 路径 `\` 与 `/` 都接受；`Path::new("a/b").join("c")` 在 Windows 产 `a\b\c`。

## 20.5 serde：序列化的普通话

```toml
[dependencies]
serde = { version = "1", features = ["derive"] }   # derive 宏在 feature 里
serde_json = "1"
```

```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, PartialEq)]
#[serde(rename_all = "camelCase")]     // Rust snake_case ↔ JSON camelCase
struct Config {
    app_name: String,
    max_retries: u32,
    tags: Vec<String>,
    #[serde(default)]                  // 字段缺失 → Default，而不是报错
    verbose: bool,
}
```

`Serialize`/`Deserialize` 两个 derive 把结构体接进 serde 的数据模型，**换后端不用改结构体**：`serde_json`、`toml`、`serde_yaml`、`bincode`（二进制）、`serde_urlencoded`……前端 API 与后端格式解耦，这是 serde 成为生态基石的原因。

## 20.6 serde_json 全流程

```rust
// 序列化
let compact = serde_json::to_string(&cfg)?;          // {"appName":"guide",...}
let pretty = serde_json::to_string_pretty(&cfg)?;    // 缩进版

// 反序列化
let back: Config = serde_json::from_str(&compact)?;
let partial: Config = serde_json::from_str(r#"{"appName":"x","maxRetries":1,"tags":[]}"#)?;
// verbose 缺失 → false（#[serde(default] 的功劳）

// 流式：大文件不整串进内存
serde_json::to_writer_pretty(File::create("config.json")?, &cfg)?;
let cfg: Config = serde_json::from_reader(File::open("config.json")?)?;

// 泛型 JSON（无类型时）
let v: serde_json::Value = serde_json::from_str(r#"{"a":[1,2]}"#)?;
v["a"][0].as_i64()      // Some(1)
```

常用属性速查：`rename_all`、`default`、`skip_serializing_if = "Option::is_none"`、`flatten`（合并结构）、`deny_unknown_fields`（严格模式）。

### RON：Rust 原生风格的配置格式

JSON 是跨语言通用格式，但语法和 Rust 差异大（引号、逗号、null）。**RON（Rusty Object Notation）** 是 Rust 生态的替代方案——语法贴近 Rust 结构体字面量，特别适合游戏配置、实体模板等"Rust 程序读 Rust 风格数据"的场景：

```rust
// resources/template.ron —— 游戏实体模板
Templates(
    entities: [
        Template(
            entity_type: Item,
            name: "Healing Potion",
            glyph: '!',
            levels: [0, 1, 2],
            provides: Some([("Healing", 6)]),
            frequency: 2,
        ),
        Template(
            entity_type: Enemy,
            name: "Goblin",
            glyph: 'g',
            levels: [0, 1, 2],
            hp: Some(1),
            frequency: 3,
        ),
    ],
)
```

对应的数据结构用 serde derive 直接映射——`Option` 字段在 RON 里写 `Some(...)` 或省略，`HashSet` 用 `[...]` 初始化：

```rust
use serde::Deserialize;
use std::collections::HashSet;

#[derive(Clone, Deserialize, Debug)]
pub struct Template {
    pub entity_type: EntityType,
    pub levels: HashSet<usize>,          // RON 的 [0, 1, 2] → HashSet
    pub frequency: i32,
    pub name: String,
    pub glyph: char,
    pub provides: Option<Vec<(String, i32)>>,  // RON 的 Some([...]) → Option
    pub hp: Option<i32>,
}

#[derive(Clone, Deserialize, Debug, PartialEq)]
pub enum EntityType { Enemy, Item }

#[derive(Clone, Deserialize, Debug)]
pub struct Templates {
    pub entities: Vec<Template>,
}
```

加载只需两行——`ron::de::from_reader` 把文件直接反序列化成结构体：

```rust
use ron::de::from_reader;
use std::fs::File;

impl Templates {
    pub fn load() -> Self {
        let file = File::open("resources/template.ron")
            .expect("Failed opening template file");
        from_reader(file).expect("Unable to parse templates")
    }
}
```

**数据驱动设计的价值**：游戏实体（怪兽、物品、武器）的定义从代码中抽离到数据文件——添加新怪物只需改 RON 文件，无需重新编译。这让游戏设计师（非程序员）也能调整数值，也缩短了"试玩 → 调数值 → 再试玩"的迭代周期。

```toml
[dependencies]
serde = { version = "1", features = ["derive"] }
ron = "0.8"    # 0.6 是旧版，0.8+ 改进了错误报告和性能
```

RON vs JSON 选型：纯 Rust 项目、配置文件手写维护 → RON（语法亲切、支持注释、char/元组原生）；跨语言 API、前端配置 → JSON（生态通用性不可替代）。

## 20.7 错误处理配合（10 章落地）

```rust
fn load(path: &Path) -> Result<Config, Box<dyn std::error::Error>> {
    let text = std::fs::read_to_string(path)?;   // io::Error 自动装箱
    Ok(serde_json::from_str(&text)?)             // serde_json::Error 同箱
}
```

`Box<dyn Error>` 把 io 与 serde 两种错误装同一容器（From 自动转换）；要细分就自定义 enum + thiserror（10 章）。

## 20.8 坑位清单

1. **`b"中文"` 编译错**（non-ASCII byte string）：`write_all("中文".as_bytes())`——实测示例第一版就踩了。
2. **`read_to_string` 遇非 UTF-8 直接 Err**：二进制/未知编码文件用 `fs::read` 拿 Vec<u8>，再决定怎么解码。
3. **`file_type()` 与 `metadata()`**：前者轻（不 stat 平台差异），后者全；判目录两者都行。
4. **read_dir 顺序不定**（与 HashMap 同理）：跨平台/测试要排序（24 章实战 sort 过）。
5. **Windows 路径显示**：`println!("{}", p)` 对非 UTF-8 路径 panic 风险——用 `p.display()`。
6. **serde 的 derive feature 忘开**：`features = ["derive"]` 不写，`#[derive(Serialize)]` 直接编译错——报错信息会提醒。
7. **枚举序列化的默认形态**：externally tagged（`{"Move":{"x":1}}`）——跨语言对接时确认 `#[serde(tag = "type")]` 等内部标签形态。
8. **临时目录冲突**：测试写临时文件用 `std::env::temp_dir().join(带进程号/唯一串)`，或 `tempfile` crate（自动清理）——本教程示例用前者（无额外依赖）。

---

上一章：[19 unsafe 与 FFI](19-unsafe-ffi.md) · 下一章：[21 测试](21-testing.md)
