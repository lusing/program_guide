# 19 · Slint 布局系统

> 对应示例：[examples/19_slint_layout](../examples/19_slint_layout)

## 19.1 三种布局盒

Slint 的布局是**约束式**的：你不摆坐标，只声明"怎么分"：

| 布局 | 分配方向 | 子元素参与方式 |
|---|---|---|
| `VerticalLayout` | 纵向切 | `height`/`vertical-stretch` |
| `HorizontalLayout` | 横向切 | `width`/`horizontal-stretch` |
| `GridLayout` | 行列网格（Row/Column 嵌套） | 自动取行列最宽/最高 |

```slint
// ═══ 19.1 三栏：定宽 + 弹性 2:1 ═══
HorizontalLayout {
    spacing: 8px;
    left-pane := Rectangle {
        width: 120px;          // 定宽：直接拿走 120
        background: #253;
        Text { text: "定宽 120"; color: white; }
    }
    center-pane := Rectangle {
        horizontal-stretch: 2; // 弹性权重：剩余空间按 2:1 分
        background: #345;
    }
    right-pane := Rectangle {
        horizontal-stretch: 1;
        background: #456;
    }
}
```

`horizontal-stretch` 与 egui/iced 的 `Length::FillPortion(n)` 同族：多个弹性子项按权重分剩余空间；没有 stretch 的定值子项先拿走自己的份。`alignment: center/start/end/space-between` 控制整组在富余空间里的摆法。

```slint
// ═══ 19.2 网格：表单两列自动对齐 ═══
GridLayout {
    spacing: 8px;
    Row { Text { text: "姓名："; } Rectangle { height: 32px; /* ... */ } }
    Row { Text { text: "城市："; } Rectangle { height: 32px; /* ... */ } }
}
```

Grid 的列宽取该列最宽者——两行的输入框天然左对齐，不用算一个像素。

## 19.2 布局是数字：几何断言

egui 04 章用 `Node::rect()` 断言面板切分，iced 12 章用锚点 bounds 推导坐标——Slint 的对应物是 `ElementHandle::absolute_position()`：

```rust
// ═══ 19.3 三栏递增 + Grid 对齐的机器判定 ═══
let (lx, cx, rx) = (left.absolute_position().x, center./*...*/.x, right./*...*/.x);
assert!(lx < cx && cx < rx, "三栏应水平递增");

assert!((lax - lbx).abs() < 0.5, "Grid 两行 label 应同列");
assert!((fax - fbx).abs() < 0.5, "Grid 两行 field 应同列");
```

元素查询还能按**类型名**搜（连 std Button 都能找到）：

```rust
use i_slint_backend_testing::ElementRoot;
let button = app
    .root_element()
    .query_descendants()
    .match_type_name(String::from("Button"))
    .find_first()
    .expect("按类型名查 Button");
let pos = button.absolute_position(); // 拿真实几何，点击不再盲猜
```

`ElementQuery` 的匹配器族：`match_id` / `match_type_name` / `match_accessible_role` / `match_predicate`（自定义谓词），配 `find_first/find_all`——组合拳足以定位树里任何元素。

## 19.3 与前两家布局对读

| | egui | iced | Slint |
|---|---|---|---|
| 模型 | 每帧布局流（panel 谈判） | 弹性盒（Length） | 约束式布局盒 |
| 弹性 | `Length::FillPortion` / 面板 default_size | `Length::Fill/FillPortion` | `horizontal-stretch: n` |
| 网格 | `egui::Grid` | 无内建（row/column 拼） | `GridLayout`（Row/Column） |
| 布局断言 | `Node::rect()` | find 的 bounds Debug | `absolute_position()` |

三家都把"布局正确"变成了可断言的数字——这是 GUI 自动化测试的通用钥匙。

## 19.4 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 19_slint_layout
```

实测输出（`build/19_slint_layout.run.out`）：

```text
==== 19 slint 布局系统 开始 ====
panes x: 16.0 < 144.0 < 561.7
grid label x: 16.0 vs 16.0 (dx=0.0)
callback clicks = 1
==== 19 slint 布局系统 结束 ====
```

`16 < 144 < 561.7`：定宽栏吃掉 120（16→136+8 间距），剩余按 2:1 分（窗口 800 宽的测试环境）。真窗口里拖大窗口看弹性栏按比例长。

## 坑位清单

- **length 数值必须带单位**：`stroke-width: 10` 编译错（"Cannot convert float to length"），写 `10px`；`width: 120px` 同理。纯数只留给 float/int 属性。
- **match_type_name 参数要具体类型**（`String::from("Button")`），`"Button".into()` 推断不出目标类型（E0283）。
- **ElementQuery trait 是否要导入看调用形态**：`query_descendants()` 挂在 `ElementHandle`（经 `ElementRoot::root_element` 拿到）上时通常不必显式导入——clippy 的 unused-import 会提醒你。
- **`for x[i] in` 循环渲染的元素**：19 章没展开（数据驱动见 22 章），循环里给元素命名 id 会被复制多份——查询会命中多个，用 `find_all` 再按几何区分。
- **preferred-size 只是"偏好"**：测试窗口 800×600 下内容会被拉伸/居中，元素真实位置以 `absolute_position()` 为准——别手算布局。

---

上一章：[18 · Slint 状态、绑定与全局单例](18-slint-state.md) ｜ 下一章：[20 · Slint 状态动画与声明式自绘](20-slint-animations.md) ｜ 返回：[README](../README.md)
