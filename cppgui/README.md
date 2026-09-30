# cppgui —— C++ GUI 编程指南（四框架四范式 24 章）

一个仓库，四种 C++ 界面框架，四种编程范式。同一批"建窗口/按钮事件/布局/输入/自绘/综合应用"
的任务在四个框架里各写一遍，范式差异不是听来的、是手上写出来的。

| 部分 | 框架 | 范式 | 章 |
|---|---|---|---|
| 一 | wxWidgets 3.3.4 | 保留模式（常驻控件树 + 事件回调） | 01–07 |
| 二 | Dear ImGui 1.93 WIP | 即时模式（每帧重跑，返回值即事件） | 08–13 |
| 三 | FTXUI master | 声明式组件树（不可变元素每帧重建 diff） | 14–19 |
| 四 | tvision master | 经典桌面隐喻 TUI（Borland Turbo Vision 复刻） | 20–24 |

## 目录

```text
cppgui/
├── CMakeLists.txt          # 四框架装配 + 每章示例登记（章号=示例号）
├── CMakePresets.json        # msvc-x64（Ninja）
├── build.ps1                # Windows/MSVC 验证入口（-All / -Example NN）
├── run-all.sh               # macOS/Linux 入口（缺依赖声明式跳过）
├── CHEATSheet.md            # 四框架横向速查 + 134 条实测坑位索引
├── docs/                    # 24 章正文（NN-slug.md）
├── examples/                # 25 个单文件示例（08 章 win32+dx11 主线 + SDL2 变体）
│   ├── imgui_dx11_app.h     # imgui 部分共享骨架（09–13 复用）
│   └── app.rc               # wx 示例共用资源（manifest）
└── tools/
    ├── build-wx.ps1         # wxWidgets 静态库预构建（产物 build/dep-wx）
    ├── check_docs.py        # 文档五关机器核查（build.ps1 -All 末尾自动跑）
    └── reconcile-nav.py     # 章末导航统稿工具
```

## 工具链

| 件 | 版本/路径 | 说明 |
|---|---|---|
| 编译器 | MSVC 14.51（VS 18 Community，vswhere 自动探测） | `/std:c++20 /EHsc /utf-8 /W3`，自家代码零告警 |
| CMake / Ninja | 4.4.3 / 1.13.2（scoop） | preset `msvc-x64` |
| wxWidgets | 3.3.4 源码 `G:/github/cpp/wxWidgets`（可覆盖） | `tools/build-wx.ps1` 预构建静态库到 `build/dep-wx` |
| Dear ImGui | master（1.93.0 WIP，无 docking/多视口）`G:/github/cpp/imgui` | 源码直接编入；win32+D3D11 零第三方依赖；SDL2 变体用 scoop SDL2 |
| FTXUI | master `G:/github/cpp/FTXUI` | add_subdirectory，链 `ftxui` |
| tvision | master `G:/github/cpp/tvision` | add_subdirectory，链 `tvision`（`TV_BUILD_EXAMPLES=OFF`） |

## 构建与验证

```bash
cd cppgui
pwsh build.ps1 -All                  # 首次自动预构建 wx（实测全量从零 5m10s）
pwsh build.ps1 -Example 01_wx_hello  # 单例
python tools/check_docs.py           # 文档五关（-All 会自动追加）
```

判定协议（与全仓库教程一致）：构建 exit 0 + `--selftest` exit 0（60s 超时）+ 输出含
`==== NN ` 起/` 结束 ====` 止 + stderr 空 + 两跑 stdout 逐字节一致。控制台子系统
（imgui/FTXUI）走 stdout；GUI/直写控制台（wx/tvision）走 sidecar `build/selftest-<名>.txt`。

### 验证状态（2026-09-30 终验）

- `build.ps1 -Clean` 清空后 `-All` **从零全绿：25/25**（含 wx 静态库重建，全程 5m10s）
- 四框架 selftest 通路各不相同（详见各章）：wx=wxTimer+Close；imgui=40 帧计数；
  FTXUI=无头 Post 事件；tvision=setTimer 广播+cmQuit
- `tools/check_docs.py` 五关全绿：章号↔示例对齐 / 25 个 ```text 输出块对**当前二进制**
  的顺序敏感子序列命中（现场重跑对账，反假绿）/ 每章坑位 ≥3 / docs 链接有效 / 本 README 导航含 24 章

### macOS / Linux

主线在 Windows/MSVC 实测。`./run-all.sh` 对缺失的框架依赖**声明式跳过**（打印缺失项后该部分
不参与验证，不假装通过）：imgui 非 Windows 需 `CPPGUI_IMGUI_SDL2=1` 且装 SDL2 才可验 08 变体；
wx 需先有 `build/dep-wx` 预构建（本脚本不自建）。

## 分章导航

**第一部分 wxWidgets（保留模式）**

1. [wxWidgets 最小应用：保留模式与事件循环](docs/01-wx-hello.md)
2. [菜单、工具栏与命令](docs/02-wx-menus.md)
3. [Sizer 布局：盒子、网格与弹性](docs/03-wx-sizers.md)
4. [常用控件与事件绑定](docs/04-wx-controls.md)
5. [对话框与数据校验](docs/05-wx-dialogs.md)
6. [DC 绘图：双缓冲与抗锯齿](docs/06-wx-drawing.md)
7. [文档/视图与线程](docs/07-wx-docview-thread.md)

**第二部分 Dear ImGui（即时模式）**

8. [Dear ImGui 骨架：即时模式与双后端](docs/08-imgui-hello.md)
9. [控件全集与 ID 机制：返回值即事件](docs/09-imgui-widgets.md)
10. [窗口系统：Begin/End、标志与子窗口](docs/10-imgui-windows.md)
11. [表格与曲线：Tables API 实战](docs/11-imgui-tables.md)
12. [DrawList 自绘与字体图集：中文渲染](docs/12-imgui-drawlist-fonts.md)
13. [综合实战：迷你系统监视器](docs/13-imgui-app.md)

**第三部分 FTXUI（声明式）**

14. [FTXUI 元素树：声明式范式与渲染到字符串](docs/14-ftxui-dom.md)
15. [FTXUI 组件体系与事件循环](docs/15-ftxui-components.md)
16. [FTXUI 布局进阶：约束、弹性与网格](docs/16-ftxui-layout.md)
17. [FTXUI 样式系统与 Canvas 画布](docs/17-ftxui-style-canvas.md)
18. [FTXUI 组合子代数与自定义组件](docs/18-ftxui-composition.md)
19. [FTXUI 综合实战：交互式待办管理器](docs/19-ftxui-app.md)

**第四部分 tvision（桌面隐喻 TUI）**

20. [tvision 应用骨架：桌面隐喻与事件循环](docs/20-tv-hello.md)
21. [菜单树、命令分发与模态对话框](docs/21-tv-menus-dialogs.md)
22. [窗口体系：TWindow、TScroller 与自绘视图](docs/22-tv-views.md)
23. [三级间接调色板、表单校验与滑块拼图](docs/23-tv-colors-forms.md)
24. [迷你文本编辑器：TEditWindow 与 gap buffer](docs/24-tv-editor.md)

速查与坑位总索引：[CHEATSheet.md](CHEATSheet.md)
