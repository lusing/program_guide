# 37 · Ratatui 综合实战：待办管理器

> 对应示例：[examples/37_ratatui_app](../examples/37_ratatui_app)

## 37.1 第五份答卷

与 09（egui）/16（iced）/23（Slint）/30（GTK4）同一张考卷——六条共同
规格（列表/输入添加/勾选完成/删除/滚动/特色亮点）。TUI 的答卷特色：
**键位状态机**（`Mode::{Normal, Insert}`——同键双义：Normal 里 `a` 是
进输入模式的命令、Insert 里 `a` 是文本字符）与**ANSI 样式完成态**
（CROSSED_OUT + dim + 绿，34 章手法）加**完成趋势 Sparkline**（35 章
手法）——全部由 33–35 章的积木拼装：

```rust
// ═══ 37.1 键位状态机：match (&app.mode, key.code) 双维度分发 ═══
match (&app.mode, key.code) {
    (Mode::Insert, KeyCode::Char(c)) => app.input.push(c),
    (Mode::Insert, KeyCode::Enter) => { /* 提交 + 回 Normal */ }
    (Mode::Normal, KeyCode::Char(' ')) => { /* 勾选当前 + 记趋势 */ }
    (Mode::Normal, KeyCode::Char('d')) => { /* 删除 + clamp */ }
    (Mode::Normal, KeyCode::Char('a')) => app.mode = Mode::Insert,
    _ => {}
}
```

删除后 `clamp_select`（选中索引 clamp 到剩余范围——`select` 越界是渲染
异常的源头）；边界上 j/k 不越出首尾（`saturating` + `min` 双向 clamp）。

## 37.2 无头剧本：与四份前卷同构

```
种子 2 条 → j+空格勾选（done 2、趋势记一笔）→ a 进 Insert 逐字符输入
"对照五框架" → Enter 提交（3 条）→ d 删第 3 条（clamp 回第 2 条）→
k 到底再 k / j 到顶再 j（边界 clamp）→ 渲染断言（统计行 + 完成行
CROSSED_OUT+绿 + "> " 高亮符）→ q 退出
```

全程 `KeyEvent::from(KeyCode::Char(c))` 直喂 `handle_key`（32 章定下的
纯函数纪律），断言打在 App 状态与 buffer 扫描上。样式断言用**扫描法**：
不赌具体坐标，全屏找 CROSSED_OUT+Green 的 cell 存在即可——布局行数
变化时断言不碎。

## 37.3 immediate mode 的两端：ratatui ↔ egui

五份待办写完，最后把镜头拉远——**ratatui 与 egui 是同一范式的两种投影**：

| | egui（09 章） | ratatui（37 章） |
|---|---|---|
| 显示设备 | GPU 像素帧 | 终端字符网格 |
| 每帧 | `App::ui` 每帧重跑 | `terminal.draw(render)` 每帧重画 |
| 渲染纯函数 | `fn ui(&mut self, ui)` | `fn render(frame, &app)` |
| diff 优化 | 全量重布局（重用少） | Backend 双 buffer diff，只发变化 cell |
| 输入 | 控件返回值即事件（拉） | poll 事件队列 + handle_key（推） |
| 状态 | 全在 App 结构体 | 全在 App 结构体 |
| 无头验证 | kittest 无障碍树断言 | TestBackend buffer 断言 |
| 帧驱动 | request_repaint | poll 超时兜底帧 |

代码并排读最有感：09 章的 `Todos::add()` 与 37 章 `handle_key(Enter)`
分支几乎逐行同构——**状态在外、UI 是状态的纯函数、帧循环负责投影**。
差别只在显示端：一个把状态画成像素（布局引擎、样式系统都为此而生），
一个把状态写成字符（布局退化为矩形切分、样式退化为 ANSI 属性）。
选型时把这两个当作同一棵树的两根枝——工具类 HUD/终端场景选 TUI
（零依赖、ssh 友好），图形密集选 GUI。

## 37.4 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 37_ratatui_app
```

实测输出（`build/37_ratatui_app.run.out`）：

```text
==== 37 ratatui 待办管理器 开始 ====
items=2 done=2 trend=4 clamp=ok crossed-out=ok
==== 37 ratatui 待办管理器 结束 ====
```

数字对账：种子 2 条 → 勾选 1 → 趋势 [1,2]；Insert 加 1 删 1 → 趋势
[1,2,2,2]（trend=4）；全程 clamp 与完成态样式机器判定。真终端：
j/k/space/d/a 键位操作、输入框蓝框高亮、趋势条随勾选爬升。

## 坑位清单

- **同键双义漏模式判断**：`Char('a')` 在 Normal 是命令、在 Insert 是文本——`match (&app.mode, key.code)` 双维度分发一次写对；单 match key.code 的写法迟早出"打字触发命令"的怪 bug。
- **删除后 select 不 clamp**：删掉选中项后 `selected()` 可能 ≥ len——渲染异常或空指针式 panic；`clamp_select` 在每次增删后调用（本例 clamp 到末项，清空时 `select(None)`）。
- **`is_none_or` 是 1.82+ API**：`selected().is_none_or(|i| i >= len)` 的写法在老 MSRV 编不过——用 `map_or(true, ..)` 等价替换（本教程 MSRV 1.88 无碍，读者降版注意）。
- **样式断言别赌坐标**：布局行数一变坐标全漂（本章第一版 (2,2) 断言翻车实录）——扫描法找"存在 CROSSED_OUT+Green 的 cell"与坐标解耦。
- **`Mode` 上 `#[derive(Debug, PartialEq)]`**：assert_eq!/match 双需求——裸 enum 会缺 Debug，测试里 E0277。

---

上一章：[36 · Ratatui 异步事件流](36-ratatui-async.md) ｜ 返回：[README](../README.md)（本教程终章——横评见 [31 章](31-comparison.md)）


