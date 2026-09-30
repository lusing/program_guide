# 17 · Slint 最小应用：声明式 DSL

> 对应示例：[examples/17_slint_hello](../examples/17_slint_hello)

## 17.1 第三种范式：界面是一门语言

egui 把界面写在 Rust 函数里（即时模式），iced 把界面写成 Rust 值的树（Elm 架构），Slint 干脆发明了一门**界面语言**——`.slint` 文件编译期生成 Rust 代码，Rust 侧只拿组件句柄：

```text
.slint 源文件 ──build.rs(slint_build 编译)──▶ 生成的 Rust 组件类型 ──▶ Rust 侧读写属性/调回调
```

这个设计换来三样别家没有的东西：**热重载预览**（VS Code Slint 插件/lsp 实时预览 .slint 改动）、**设计师可协作**（DSL 比 Rust 友好）、**多语言宿主**（同一份 .slint 也能给 C++/Python 用）。代价是多一层间接——调试要跨语言边界。

```slint
// ═══ 17.1 声明式最小界面（ui/app.slint）═══
export component AppWindow inherits Window {
    title: "17 slint hello";
    preferred-width: 320px;
    preferred-height: 200px;

    in-out property <int> click-count;      // 属性 = 状态
    callback increment();                    // 回调 = 出口
    increment() => {
        root.click-count += 1;               // 命令式回调体（slint 语言）
    }

    VerticalLayout {
        padding: 16px;
        spacing: 12px;
        Rectangle {
            height: 40px;
            background: touch.pressed ? #4a9eff : #2b6cb0;
            touch := TouchArea {
                clicked => { root.increment(); }   // 事件入口
            }
            Text { text: "Increment"; color: white; }
        }
        Text { text: "count: " + root.click-count; }  // 绑定 = 反应式显示
    }
}
```

读法：**属性声明状态、绑定声明显示、回调声明行为**。`Text { text: "count: " + root.click-count }` 是一条永真的等式——click-count 变，text 自动跟着变，没有任何"刷新"代码。这与 egui 的"每帧重算"、iced 的"消息重算 view"是第三种更新机制：**依赖跟踪的反应式**。

## 17.2 工程接线：build.rs + include_modules

```rust
// ═══ 17.2 三处接线 ═══
// build.rs —— 编译 .slint 为 Rust 代码
fn main() {
    slint_build::compile("ui/app.slint").expect("slint 编译失败");
}

// Cargo.toml
[dependencies]
slint = "1.18"
[build-dependencies]
slint-build = "1.18"

// src/main.rs —— 引入生成的组件
slint::include_modules!();

fn main() -> Result<(), slint::PlatformError> {
    let app = AppWindow::new()?;   // 组件类型名 = export component 名
    app.run()                      // 事件循环（真窗口）
}
```

生成代码给的句柄面（记住这一张表就够了）：

| .slint 侧 | Rust 侧 |
|---|---|
| `in-out property <int> click-count` | `app.get_click_count() / set_click_count(3)` |
| `callback increment()` | `app.invoke_increment() / on_increment(closure)` |
| `in property`（只进） | 只生成 `set_` |
| `out property`（只出） | 只生成 `get_` |
| `export global Settings` | `Settings::get(&app)` 单例句柄 |

## 17.3 无头测试：testing backend + ffi 注入

**断代警告**：旧教程里的 `slint::testing` 模块（`send_mouse_click(&handle, x, y)` 那套）在 1.18 已**移除**。现行通道是官方的 `i-slint-backend-testing` crate（slint 自己的 doctest 也这么用）：

```rust
// ═══ 17.3 无头三件套 ═══
// Cargo.toml:
i-slint-backend-testing = { version = "1.18", default-features = false, features = ["ffi"] }
// ffi 是纯门控 feature：打开 testing_backend 模块的注入函数

// 测试体：
fn selftest_body() -> i32 {
    i_slint_backend_testing::init_no_event_loop();  // ① 安装测试 backend（每进程一次）

    let app = AppWindow::new().unwrap();

    // ② 注入事件（testing_backend 模块，参数是内部 WindowAdapter——
    //    4 行官方同款 shim 桥接，见示例 src/testing.rs）
    testing::send_mouse_click(&app, 50.0, 35.0);
    testing::send_mouse_click(&app, 50.0, 35.0);
    testing::send_mouse_click(&app, 50.0, 35.0);

    app.get_click_count()                          // ③ 读属性断言
}
```

- `init_no_event_loop()` 直接 `set_platform`——**不需要** SLINT_BACKEND 环境变量，普通 `cargo run` 照旧开真窗口；
- 注入函数收 `&WindowAdapterRc`（内部类型），`src/testing.rs` 里 4 行 shim 从公开的 `component.window()` 桥过去——照抄官方 internal_tests.rs；
- **每进程只能 init 一次**：一个示例只留一个 `#[test]`（多个测试并发会二次 set_platform 直接 panic）。

坐标注入依赖可预测布局：测试窗口默认 **800×600**，本例把点击条带放在布局第一个子元素（padding 16 + 高 40 → (50,35) 稳定命中）。18 章升级为元素查询，告别盲猜坐标。

## 17.4 与前两家的第一眼对照

| | egui（02） | iced（10） | Slint（本章） |
|---|---|---|---|
| 界面定义 | Rust 函数每帧重跑 | Rust 构造的组件值 | 独立 DSL，编译期生成 |
| 状态 | Rust 结构体字段 | State + update 消息 | 属性（+ global） |
| 事件 | 返回值 | Message | 回调 |
| 显示更新 | 整帧重算 | 消息触发 view 重算 | 依赖跟踪的反应式绑定 |
| 无头通道 | egui_kittest | iced_test | i-slint-backend-testing(ffi) + shim |

## 17.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 17_slint_hello
```

实测输出（`build/17_slint_hello.run.out`）：

```text
==== 17 slint 最小应用 开始 ====
count after 3 clicks = 3
==== 17 slint 最小应用 结束 ====
```

真窗口外还有个开发期福利：装 VS Code 的 Slint 扩展（或跑 `slint-viewer ui/app.slint`），改 .slint 即时预览——live-preview 不参与本仓库的自动验证（属人工工具），但写界面时极香。

## 坑位清单

- **`slint::testing` 已移除（1.18）**：网上旧文的三行测试法全部失效。现行通道 = `i-slint-backend-testing`（`ffi` feature 开注入函数），官方 doctest 同款。
- **`internal` feature 编译不过**：官方人体工学封装在 1.18.1 发布包里因缺字体文件（`tests/screenshots/fonts/*.ttf` 未随包发布）编译失败——打包 bug。用 `ffi` + 4 行 shim 绕开（本例）。
- **init_no_event_loop 每进程一次**：多 `#[test]` 并发必炸；每示例单测试或合并进 selftest_body。
- **坐标注入要布局可预测**：测试窗口固定 800×600，点击目标给固定尺寸、放布局可推算位置；不然升级到 18 章的元素查询法。
- **属性类型严格**：`text` 只吃 string，`"count: " + int` 能隐式拼接（重载过的 +），但 `text: some-float` 直接编译错——转字符串用拼接或 `@tr`。

---

上一章：[16 · iced 综合实战：待办管理器](16-iced-app.md) ｜ 下一章：[18 · Slint 状态、绑定与全局单例](18-slint-state.md) ｜ 返回：[README](../README.md)
