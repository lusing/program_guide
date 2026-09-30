# 18 · Slint 状态、绑定与全局单例

> 对应示例：[examples/18_slint_state](../examples/18_slint_state)

## 18.1 属性的三种流向

```slint
// ═══ 18.1 in / out / in-out ═══
in-out property <float> km: 0;     // 双向：Rust 与 .slint 都读写
in property <string> token: "abc"; // 只进：Rust 设给界面（如鉴权令牌）
out property <int> rows: 0;        // 只出：界面报告给 Rust（如选中数）
```

Rust 侧对应生成 `get_/set_` 的子集（in 只有 set、out 只有 get）。**绑定的方向就是数据的方向**——这是 Slint 世界观的地基。

## 18.2 输入事件三件套：TouchArea / LineEdit / FocusScope

```slint
// ═══ 18.2 单位换算器的输入链 ═══
km-input := LineEdit {
    placeholder-text: "输入千米数";
    edited(text) => {              // 每击键回调，载荷就是新文本
        root.km = text.to-float(); // 解析失败得 0
        root.refresh-miles();
    }
}

dark-toggle := TouchArea {        // 万物点击区：clicked/pressed/moved/scroll
    clicked => { Settings.dark = !Settings.dark; }
}
```

- **TouchArea** 是底层点击捕获器（透明覆盖其父元素）：`clicked`、`pressed`/`released`（带 `pointer-event` 参数）、`moved`、`scroll-event`——按钮的"按钮感"全靠它；
- **LineEdit**（std-widgets）是成品输入框：`edited(text)` 每击键触发、`accepted(text)` 回车触发、`text` 属性持有内容。**别把 `text` 绑回业务属性**（`text <=> root.km-string` 之类）：绑定回写会跟用户打字/光标位置打架——输入走 `edited` 回调，显示走旁边的 `Text` 绑定，一进一出两张皮；
- **FocusScope** 管键盘焦点与快捷键：`key-pressed(event) => { if (event.text == Key.Return) { accept } else { reject } }`，配 `forward-focus` 把焦点引给孩子。本例没用到，23 章的待办输入会亮相。

## 18.3 global 单例：跨组件共享状态

```slint
// ═══ 18.3 全局主题开关 ═══
export global Settings {
    in-out property <bool> dark: false;
}

// 任意组件里直接引用（不需要层层传属性）：
Rectangle {
    background: Settings.dark ? #233 : #dee;
    TouchArea { clicked => { Settings.dark = !Settings.dark; } }
}
```

Rust 侧：`Settings::get(&app).get_dark() / set_dark(true)`——单例句柄随组件实例走。global 是"组件树传参"的逃逸口：主题、当前用户、全局配置这类**每层都要用**的状态放这里最省心；但它也削弱了组件的纯度（隐式依赖），业务状态仍建议走属性显式传递——度和 egui 的"全局 ctx"与 iced 的"State 里一切" 都不一样。

## 18.4 无头测试升级：ElementHandle 元素查询

17 章的坐标注入要求"布局可预测"。Slint 其实有官方的**元素查询 API**（`i-slint-backend-testing` 的 `search_api`），两步打开：

```rust
// ═══ 18.4 元素查询 + 几何推导 + a11y 注入 ═══
// ① build.rs 开 debug info（元素 id/类型信息进生成代码）
let config = slint_build::CompilerConfiguration::new().with_debug_info(true);
slint_build::compile_with_config("ui/unit.slint", config)?;

// ② 测试里按 id 查（注意前缀：组件名::元素名）
let input = testing::element_by_id(&app, "UnitConverter::km-input");
let toggle = testing::element_by_id(&app, "UnitConverter::dark-toggle");

// 文本输入走 a11y 通道：set_accessible_value 等价读屏的 set_value，
// LineEdit 内部是 accessible-value <=> text 且 set-value 触发 edited——
// 比"点击聚焦再打字"稳得多
input.set_accessible_value("42");
assert!((app.get_km() - 42.0).abs() < 1e-3);

// 点击走几何推导：absolute_position 给真实布局位置，不再盲猜
let pos = toggle.absolute_position();
testing::send_mouse_click(&app, pos.x + 10.0, pos.y + 10.0);
```

`ElementQuery` 还能按类型/无障碍角色/谓词匹配（`match_type_name("LineEdit")`、`match_accessible_role(...)`），`ElementHandle` 暴露 `accessible_value/label/checked/...` 一整套无障碍读取——**Slint 把无障碍树当成了测试接口**，与 egui_kittest 的思路殊途同归。

## 18.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 18_slint_state
```

实测输出（`build/18_slint_state.run.out`）：

```text
==== 18 slint 状态与绑定 开始 ====
km=42 miles=26.098 dark=false
==== 18 slint 状态与绑定 结束 ====
```

`dark=false` 的可信度来自断言链：第一次点击后断言 `dark_after_one == true`，第二次点击后才落到 false——两跳都真实发生。真窗口里打字看英里数即时跳动、点主题条看背景换色。

## 坑位清单

- **元素 id 带组件前缀**：`find_by_element_id(&app, "km-input")` 找不到——要写 `"UnitConverter::km-input"`（组件名::元素名）。查不到时先怀疑前缀，再怀疑 debug info。
- **with_debug_info 是查询的前提**：没开的话 ElementHandle 系列返回 None/空并打日志"requires debug info"。`compile_with_config` + `with_debug_info(true)` 一次配好。
- **LineEdit 别绑回 text**：`text <=> 业务属性` 会跟光标打架（打一个字符光标跳回开头是典型症状）。输入 `edited` 回调进，显示 `Text` 绑定出。
- **to-float 失败静默得 0**：解析不了不是错误事件——需要校验就在 edited 里查 `text.is-float`（或 Rust 侧重验）。
- **单例隐式依赖**：global 好用但测试隔离性变差（跨测试共享）。本例每个测试重新 `init` + 新组件实例规避；正式项目对 global 的读写集中在少数回调里。

---

上一章：[17 · Slint 最小应用：声明式 DSL](17-slint-hello.md) ｜ 下一章：[19 · Slint 布局系统](19-slint-layout.md) ｜ 返回：[README](../README.md)
