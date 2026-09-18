# 21 · 测试 ⭐

> 对应示例：`examples/21_testing/`（lib + bin + tests/ 三层齐装）
>
> cargo test 一条命令跑三种测试：单元、集成、文档。
> 测试代码是 Rust 代码——所有权、借用、Result 全部适用。

## 21.1 三种测试的位置与身份

| 种类 | 位置 | 看得见什么 | 编译成 |
|---|---|---|---|
| 单元测试 | `#[cfg(test)] mod tests`（与被测代码同文件） | **私有**函数/字段 | 每个目标内嵌 |
| 集成测试 | `tests/*.rs`（每个文件一个） | 只有 **pub API** | 独立二进制 |
| 文档测试 | `///` 注释里的 ```rust 块 | pub API | doctest 二进制 |

```rust
/// 加法。
///
/// # Examples
///
/// ```
/// use testing_demo::add;        // doctest 是独立 crate，要显式 use
/// assert_eq!(add(2, 3), 5);
/// ```
pub fn add(a: i32, b: i32) -> i32 { a + b }
```

**doctest 是 Rust 的独门武器**：文档里的每个示例都被编译、运行——文档永远不会烂掉。README 的代码块都能测，谁还敢说文档过时。

## 21.2 单元测试解剖

```rust
#[cfg(test)]                          // 不进正式构建（零运行时成本）
mod tests {
    use super::*;                     // 拉进被测模块的一切（含私有项）

    #[test]
    fn add_works() {
        assert_eq!(add(2, 2), 4);
        assert!(cond, "失败时附加信息 {x}");
        assert_ne!(a, b);
    }

    #[test]
    #[should_panic(expected = "除数为零")]   // panic 即通过（精确匹配子串）
    fn div_by_zero() { div(1, 0); }

    #[test]
    fn result_style() -> Result<(), String> {   // 测试也能 ? 传播
        let q = checked_div(10, 2)?;
        assert_eq!(q, 5);
        Ok(())       // Err 即测试失败
    }

    #[test]
    #[ignore = "需要外部数据库"]        // 默认跳过；cargo test -- --ignored 单独跑
    fn slow() { /* ... */ }
}
```

私有函数直接测（同模块可见性）——`#[cfg_attr(not(test), allow(dead_code))]` 处理"仅测试使用"的私有项（示例实测）。

## 21.3 集成测试

```rust
// tests/integration.rs —— 像真实用户一样 use 这个库
use testing_demo::{add, checked_div};

#[test]
fn integration_add() { assert_eq!(add(20, 22), 42); }
```

- 每个文件独立编译成二进制（链接的是库 crate）——测试多时拆文件避免全量重编；
- 共用工具放 `tests/common/mod.rs`（旧惯例 `tests/common/mod.rs` 而非 `tests/common.rs`，后者会被当成测试跑）；
- 测**二进制行为**（CLI 退出码/输出）用 `env!("CARGO_BIN_EXE_名字")` 拿可执行文件路径 + `std::process::Command`（24 章实战用法）。

## 21.4 运行与过滤

```powershell
cargo test                      # 全部
cargo test add_works            # 名字含 add_works 的
cargo test --test integration   # 只跑集成测试文件
cargo test -- --nocapture       # 显示测试内的 stdout（默认只在失败时打印）
cargo test -- --ignored         # 只跑被 ignore 的
cargo test -p 包名              # workspace 里限定包
```

`--` 之后是传给测试二进行的参数（libtest 惯例）。

## 21.5 该测什么、怎么组织

- **业务规则与边界**：空输入、极值、错误路径（自定义错误 enum 的每个变体配一条测试，10 章示例风格）；
- **表驱动**：Rust 没有内建参数化，用数组+循环（配 `#[should_panic]` 场景单独拆函数）：

```rust
#[test]
fn classify_all() {
    for (input, want) in [(0, "零"), (42, "中"), (-1, "负")] {
        assert_eq!(classify(input), want, "输入 {input}");
    }
}
```

- 文件/网络依赖：小而自足的临时数据（`std::env::temp_dir()` + 进程号唯一化，或 tempfile crate）；不碰真实网络；
- 时间敏感逻辑：注入时钟/用假实现，别 sleep 硬等。

## 21.6 断言与比较工具箱

```rust
assert_eq! / assert_ne!                 // 需要 PartialEq + Debug
assert!(matches!(x, Some(3)))           // 模式断言（08 章 matches!）
assert_eq!(v, vec![1, 2])               // Vec/数组直接比（元素 PartialEq）
pretty_assertions crate                 // 失败时彩色多行 diff（生态增强）
proptest / quickcheck                   // 属性测试（生成随机输入）
```

## 21.7 覆盖率与基准（生态一瞥）

| 工具 | 用途 |
|---|---|
| `cargo-llvm-cov` | 覆盖率（合并 unit/integration/doctest 三路） |
| `criterion` | 统计学基准（bench 文件 + HTML 报告） |
| `cargo-mutants` | 变异测试：验证测试真的能抓住 bug |
| `nextest` | 更快更严格的测试运行器（失败即停、隔离重试） |

 nightly 的 `#[bench]` 基本被 criterion 取代；CI 里 nextest + llvm-cov 是当前主流搭配。

## 21.8 坑位清单

1. **doctest 找不到你的函数**：doctest 是独立 crate——`use your_crate::item` 必写，且只测 pub 项。
2. **`#[cfg(test)]` 的死代码警告**：仅测试使用的私有函数在正式构建触发 dead_code——`#[cfg_attr(not(test), allow(dead_code))]`（示例实测）。
3. **should_panic 太宽**：不写 `expected` 时任何 panic 都算过——精确到消息子串才是有效测试。
4. **并行执行是默认**：测试函数间无顺序保证——共享文件/全局状态要设计成每测试独立（临时目录唯一化），或 `-- --test-threads=1` 退守。
5. **stdout 默认被吞**：`-- --nocapture` 才看得到 println——失败时自动放行打印。
6. **集成测试编译慢**：每个 tests/*.rs 一个二进制；工具代码共享用 mod 引入而非复制。
7. **测试里 unwrap 是惯例**：unwrap 的 panic 恰好是"测试失败"，无需层层 match——这和产码纪律相反，别别扭。

---

上一章：[20 文件 IO 与序列化](20-files.md) · 下一章：[22 并发](22-threads.md)
