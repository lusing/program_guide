# FreePascal/Lazarus 开发指南（FPC 3.2.2 / Lazarus 4.8）

面向**会编程（C/C++/Delphi 背景皆可）、初学 Object Pascal + Lazarus** 的读者：从零教到
能写出完整 GUI 应用。语言篇 13 章打透 Object Pascal（含 OOP/泛型/字符串编码深水区），
GUI 篇 9 章吃下 LCL（控件两章 + 布局/菜单/对话框/列表/绘图/多线程），第 24 章实战
**记事本+**（多标签/编码/查找替换/修改跟踪/INI 持久化）。每章"读讲解 → 跑示例 →
改代码再跑"，全部 23 个示例在本机**多层验证**通过：CLI 双通道（检查 `-Cr -Co -Ci -Sa -B`
+ 断言 / 发布 `-O2`，各四条判定 + 输出逐字节比对），GUI 无头 selftest（lazbuild 构建 +
`--selftest` 日志断言）。

> ⚠️ 网上 FreePascal 教程多停留在 Delphi 7 或 Lazarus 1.x 时代：`and then` 运算符
> （objfpc 没有）、无码页的 string 语义（FPC 3.x 全变）、`Extended` 10 字节（win64 是 8）
> 等说法皆过时。本教程所有代码在 **FPC 3.2.2 x86_64-win64 + Lazarus 4.8（win32 控件集）**
> 实测，每章末"坑位清单"收录版本差异——CHEATSheet 汇总 **46 条实测坑位**。

## 目录结构

```text
freepascal/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读；⭐ 为特色重点章）
├── examples/       23 个示例目录（章号 = 目录号；15–24 为 Lazarus GUI 工程）
├── build.ps1       统一验证脚本（pwsh 7 运行）
├── run-all.sh      等价的 Git Bash 验证入口
└── CHEATSheet.md   语法速查 + 46 条实测坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景与工具链](docs/01-overview.md) | 家族史、方言模式、编译模型、fpc 开关总览、验证方法论 | — |
| [02 第一个程序](docs/02-hello.md) | program 结构、WriteLn、**编码纪律三件套（实测矩阵）** | `02_hello` |
| [03 类型与变量](docs/03-types.md) | 尺寸表（Integer 恒 4/Extended=8）、枚举子界、转换三路 | `03_types` |
| [04 运算符与控制流](docs/04-control.md) | / 与 div、case、三循环、for-in、短路求值实测 | `04_control` |
| [05 过程与函数](docs/05-procedures.md) | const/var/out/constref、开放数组、TVarRec、嵌套/递归 | `05_procedures` |
| [06 数组与集合](docs/06-arrays.md) | 动态数组共享语义、多维、set 运算与位图 | `06_arrays` |
| [07 字符串与编码](docs/07-strings.md) ⭐ | 四代字符串、码页标记、**字面量重定型**、Pos/Copy 分裂 | `07_strings` |
| [08 记录与指针](docs/08-records.md) | packed/variant record、指针三件套、回调、**调 DLL**、heaptrc | `08_records` |
| [09 单元与工程](docs/09-units.md) | 两段式、init/final、循环引用、条件编译（多文件工程） | `09_units` |
| [10 异常与资源](docs/10-exceptions.md) | finally/except、类型化捕获、自定义异常族、Assert | `10_exceptions` |
| [11 文件与序列化](docs/11-files.md) | TextFile/typed file/TFileStream/TIniFile、时间与随机纪律 | `11_files` |
| [12 OOP I：类与封装](docs/12-oop1.md) | Create/Free、property 校验、**同单元无隐私**、FreeAndNil | `12_oop1` |
| [13 OOP II：继承与多态](docs/13-oop2.md) | virtual/override、is/as、类引用、接口与引用计数 | `13_oop2` |
| [14 泛型与容器](docs/14-generics.md) | specialize、Generics.Collections、**字典中文键配方** | `14_generics` |
| [15 Lazarus 入门](docs/15-lazarus.md) ⭐ | **.lpr/.lpi/.lfm 三件套逐行讲**、lazbuild、selftest 模式 | `15_lazarus_hello` |
| [16 基础控件与事件](docs/16-controls.md) ⭐ | 事件=方法指针、输入/按钮/选择/容器矩阵、触发矩阵 | `16_controls` |
| [17 更多控件](docs/17-more-controls.md) ⭐ | TrackBar/SpinEdit/Calendar/StringGrid/TabControl/TFrame | `17_more_controls` |
| [18 布局与高 DPI](docs/18-layout.md) | Align/Anchors/Splitter、OnResize 手工布局、DPI | `18_layout` |
| [19 菜单、工具栏与 Action](docs/19-menus.md) | TActionList 统一命令三绑定、OnUpdate、状态栏 | `19_menus_actions` |
| [20 对话框与文件](docs/20-dialogs.md) | Open/Save/Font/Find、ShowModal 与 ModalResult | `20_dialogs` |
| [21 列表与树视图](docs/21-lists.md) | ListView 报表、TreeView（**DFS 序坑**）、Data 所有权 | `21_lists_trees` |
| [22 绘图与自绘](docs/22-canvas.md) ⭐ | TCanvas、双缓冲、鼠标画板、像素级验证 | `22_paint` |
| [23 多线程](docs/23-threads.md) ⭐ | TThread、Synchronize vs Queue、锁、取消、CheckSynchronize | `23_threads` |
| [24 实战：记事本+](docs/24-notepad.md) ⭐ | 多标签/编码/查找替换/修改跟踪/INI/uchecks 测试框架 | `24_notepad_plus` |

## 构建工具链

- **FPC 3.2.2**（主线 = Lazarus 自带 x86_64-win64）：
  `G:\scoop\apps\lazarus\current\fpc\3.2.2\bin\x86_64-win64\fpc.exe`
- **Lazarus 4.8 / lazbuild**：`G:\scoop\apps\lazarus\current\lazbuild.exe`（LCL，win32 控件集）
- 源码一律 **UTF-8 无 BOM + `{$codepage utf8}`**；脚本运行前自动 `chcp 65001`
  （WriteLn 跟随控制台码页，见 02 章实测矩阵）。
- 脚本按 **环境变量 FPC/LAZBUILD → 固定路径 → PATH** 顺序探测（scoop 独立 freepascal
  包只有 i386 目标，PATH 优先会静默编出 32 位——实测坑）。

## 验证命令

```powershell
cd G:\code\guide\freepascal
pwsh -File build.ps1 -All              # 全部 23 示例：CLI 双通道 + GUI selftest
pwsh -File build.ps1 -Example 07_strings   # 单个示例（07_strings / 07 / 07_strings.pas）
pwsh -File build.ps1 -Gui              # 只验证 GUI 工程
pwsh -File build.ps1 -Clean            # 清理 build/ 与产物
```

```bash
./run-all.sh            # Git Bash 等价入口（02 / --gui / -v / --clean）
```

**判定标准**：CLI 每通道四条（exit 0 / stderr 空 / 无控制字符 / 含 `==== NN 结束 ====`
标记）+ 双通道输出 SHA256 一致；GUI 每工程四条（lazbuild exit 0 + exe 存在 +
`--selftest` exit 0 + 日志含 `==== NN selftest OK ====`），selftest 运行带 60 秒超时
（GUI 未捕获异常会弹 LCL 框，无头环境挂死——实测坑，双保险）。

## 学习路线

- **语言篇（02–14）**：顺序读；07（字符串编码）是 FPC 特有深水区，值得两遍。
- **GUI 篇（15–23）**：15 是地基；16/17 控件两章是用户点名加强的重点。
- **实战（24）**：跟着源码读，`selftest` 的 29 条断言就是功能清单。
- **速查**：[CHEATSheet.md](CHEATSheet.md)（语法 + 46 条坑位）。

## 相关教程

- [MFC 开发指南](../mfc/README.md)——同为"老牌桌面框架"的 C++ 视角；本教程收官项目
  与其同为记事本+（结构可对照）。
- [Win32](../win32/README.md)——LCL 背后的原生世界（win32 控件集的底层）。
- [FreeBASIC](../freebasic/README.md)——另一门带方言模式的经典语言，验证方法论同源。
