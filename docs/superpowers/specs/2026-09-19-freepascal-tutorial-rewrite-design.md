# FreePascal/Lazarus 教程重写设计（2026-09-19）

## 1. 背景与问题

`freepascal/` 目录现状：单个 `Free Pascal编程指南.md`（607 行，特性手册式）+ 15 个平铺示例
（12 个 CLI 单文件 5–29 行 + 3 个 Lazarus 工程）+ `build.ps1`/`run-all.sh`。无 docs/ 分章、
无章号=示例号对应、无坑位清单、无 CHEATSheet；示例只跑不改错、无断言；旧脚本的工具链定位
还指向 i386 的独立 FPC。Object Pascal + Lazarus 内容小众，现有篇幅远讲不透。

与 cpp20/zig/julia/freebasic 教程标准（docs/ 24 章分章 + 章号=示例目录号 + 递进讲解 +
坑位清单 + 多层验证 + CHEATSheet）差距大。

## 2. 目标与非目标

**目标**：重写为 24 章独立文档（每章 200–350 行，特色章不压缩）、章号 = 示例目录号
（02–24 共 23 个示例，其中 GUI 10 个）；定位"会编程（C/C++/Delphi 背景皆可）、初学
Object Pascal + Lazarus，从零教到能写完整 GUI 应用"；主线 **FPC 3.2.2 + Lazarus 4.8
（LCL，win32 控件集，x86_64-win64）**；全部示例在本机实测多层验证通过；第 24 章实战
项目为**记事本+**（多标签文本编辑器，对齐 MFC/WPF 收官标准）。

> 改版记录（2026-09-19）：按用户反馈"控件再多讲一讲"——原 16 控件单章拆为
> **16 基础控件与事件模型** + **17 更多控件**（数值/日期/颜色/**TStringGrid 表格**/
> TTabControl vs TPageControl/TImage/**TFrame 组件复用**），GUI 篇扩为 15–23 共 9 章；
> 原 23 工具链与测试章取消，内容分散吸收（编译开关总览→01、heaptrc 实操→08、
> 条件编译→09、自制测试与 CI 思路→24 末节以 `--selftest`+uchecks 为载体）。
> 章数 24、示例数 23 均不变。

**非目标**：
- 不做 Delphi→FPC 迁移专题（差异在 01 章给对照表，坑位清单点到即止）
- 不教数据库（SQLdb/DBGrid）——对齐 MFC/WPF（均无 DB 章）；24 章末"可以继续做的事"给方向
- 不教交叉编译实操（01 章讲机制与旗标一瞥）
- Web 框架（fpweb）、fpcupdeluxe 等生态工具不展开
- 多控件集（gtk2/qt5/cocoa）实测只做 win32，其余讲原理

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 章节规模 | 24 章完整版（语言 14 + Lazarus 9（控件 2 章）+ 实战 1） |
| 读者定位 | 会编程、初学 Object Pascal + Lazarus，FPC 3.2.2 / Lazarus 4.8 现代写法 |
| 实战项目 | 第 24 章记事本+（多标签 TMemo + 查找替换 + 编码保存 + 修改跟踪 + 统计 + INI 配置） |
| 工具链 | `G:\scoop\apps\lazarus\current\fpc\3.2.2\bin\x86_64-win64\fpc.exe`（与 lazbuild 同套）；scoop 独立 i386 FPC 在 01 章说明差异 |
| 示例形态 | 每章一个目录 `examples/NN_topic/`，章号=目录号；CLI 为 `NN_topic.pas`（09 为多文件），GUI 为手写最小 .lpi+.lpr(+.lfm) 工程 |
| 验证策略 | CLI（02–14）双通道（检查 `-Cr -Co -Ci -Sa` / 发布 `-O2`）×四条判定 + 双通道输出 SHA256 对比；GUI（15–24）lazbuild 构建 + `--selftest` 无头自检（写 selftest.log，四条判定） |
| 旧文件 | 删 `Free Pascal编程指南.md`、旧 examples 15 项；`build.ps1`/`run-all.sh`/`README.md` 原地重写 |
| 新增 | `docs/` 24 章、新 `examples/` 23 目录、`CHEATSheet.md`、根 README 条目更新 |
| 目录名 | 保留 `freepascal`（外部引用不破坏） |

## 4. 环境实测结论（2026-09-19，FPC 3.2.2 x86_64-win64 + Lazarus 4.8 @ scoop）

| 项 | 结论 |
|---|---|
| **编码纪律** | 源码 **UTF-8 无 BOM + `{$codepage utf8}`**（放 `{$mode objfpc}` 旁）+ 脚本设 `chcp 65001`。三变体实测：无指令源码字面量按系统码页（936）标记、字节实为 UTF-8 → `u := s` 转 UTF8String 双重编码乱码；`{$codepage utf8}` 下转换/输出全对 |
| **WriteLn 码页** | FPC 3.2.2 文本输出跟随**活动控制台代码页**（重定向也一样）：GBK 控制台下 utf8 标记串自动转 GBK 正确显示；chcp 65001 下直通 UTF-8 字节。旧"裸字节直通"路数在 65001 下反而乱码——坑位必收录 |
| 断言 | `-Sa` 开启断言（或源码 `{$C+}`）；检查通道 `-Cr -Co -Ci -Sa` 实测可用 |
| heaptrc | `-gh` 报告**走 stderr 且 0 泄漏也打印** → 不进 CI 通道，08 章教学项 |
| 尺寸表（win64） | Integer=4（恒定）、Int64/Pointer/NativeInt/PtrUInt=8、**Extended=8**（win64 精简为 Double；Delphi 32 位是 10 字节——教学点）、Single=4/Double=8、Char=1、String=8（AnsiString 是指针）、ShortString=256、enum 默认 4、子界 0..9 自动收缩为 1 字节、Variant=24、UnicodeString=8 |
| lazbuild | 只认 `.lpi`（直接喂 `.lpr` 报 File not found）；**手写最小 .lpi 可行**（RequiredPackages=LCL + Units + lib 输出目录，Version=12 老格式 4.8 接受）；exe 与 .o 同落 `lib/<cpu>-<os>/` |
| GUI selftest | **可行**：`Application.Initialize` 后 `TForm.Create(nil)` 不 Show 也能建控件、读 Caption/ControlCount、写日志 `Halt(0)` exit 0；日志为 UTF-8 字节（LCL 内部即 UTF-8，与 `{$codepage utf8}` 纪律衔接） |
| 探针顺手坑 | ① with 块内 `Close` 解析到 System 的文件过程而非窗体方法；② `mrClose` 在 Controls 单元；③ LCL 工程 `Interfaces` 必须最先 uses（ctheads 除外） |
| scoop 布局 | 独立 `freepascal` 包只有 i386-win32 目标；Lazarus 包自带完整 x86_64 FPC——统一用后者 |

其余坑位（UTF8String 转换族、open array、set 实现、TThread/CheckSynchronize、.lfm 手写格式等）实施中边写边实测累积。

## 5. 章节结构（docs/，24 章，⭐ = 特色重点细讲）

| # | 文件 | 主题 | 示例 |
|---|---|---|---|
| 01 | `01-overview.md` | 全景：Pascal 家族史（Wirth→TP→Delphi→FPC/Lazarus）、FPC 与 Delphi 关系、方言模式（-Mfpc/objfpc/delphi/tp）、编译模型（先声明后用/单元两段式）、工具链安装（Windows+scoop 与 Lazarus 自带）、fpc 开关总览 | — |
| 02 | `02-hello.md` | 第一个程序：program 结构、begin/end、WriteLn、注释、fpc 编译运行、**编码纪律（实测三变体故事）**、结束标记约定 | `02_hello` |
| 03 | `03-types.md` | 类型与变量：整型家族尺寸表（Integer 恒 32 位/Extended=8 教学点）、实型、布尔四兄弟、枚举与子界（尺寸收缩）、typed const、类型转换（硬转 vs Val/Str） | `03_types` |
| 04 | `04-control.md` | 运算符与控制流：`/` vs `div`、运算符表、类型提升、if/case（子界列表）、repeat/while/for（downto）、for-in、Break/Continue/Exit/Halt、短路布尔 | `04_control` |
| 05 | `05-procedures.md` | 过程与函数：procedure/function、Result、const/value/var/out/constref、默认参数、开放数组、函数重载、嵌套过程、前向声明、递归 | `05_procedures` |
| 06 | `06-arrays.md` | 数组与集合：静态/动态数组、SetLength、Length/High/Low、多维、array of const、**set 类型与运算**（位图实现一瞥） | `06_arrays` |
| 07 | `07-strings.md` ⭐ | 字符串与编码：String=AnsiString（引用计数/COW/码页标记）、ShortString/PChar/RawByteString/UTF8String/UnicodeString、Pos/Copy/Delete/Insert、Format、字符串数字互转、**码页转换实测**（§4 结论展开） | `07_strings` |
| 08 | `08-records.md` | 记录与指针：record、with、packed、variant record、record 方法/运算符（FPC 扩展）、@ 与 ^、New/Dispose、GetMem/FreeMem、指针算术（`{$POINTERMATH}`）、过程类型与回调、**调 DLL 小节**（`external 'msvcrt'`/cdecl）、**heaptrc 泄漏排查小节**（-gh 实操，吸收原工具链章） | `08_records` |
| 09 | `09-units.md` | 单元与工程：interface/implementation 两段式、uses 顺序、initialization/finalization、循环引用解法、多文件命令行工程、.ppu/.o 与增量编译、**条件编译小节**（`{$MODE}`/`{$IFDEF}`/`{$DEFINE}`，吸收原工具链章） | `09_units`（多文件） |
| 10 | `10-exceptions.md` | 异常与资源：try/except/finally、`on E: 类型 do`、raise 与 re-raise、Exception 家族、自定义异常、Assert 与 `{$C+}`、资源保护惯例（try-finally/FreeAndNil） | `10_exceptions` |
| 11 | `11-files.md` | 文件与序列化：TextFile 全家（Assign/Reset/Rewrite/Append/ReadLn）、`{$I-}`+IOResult、typed file（定长记录）、TFileStream 二进制、TIniFile、目录/文件操作、时间（Now/FormatDateTime）与随机（Randomize）小节 | `11_files` |
| 12 | `12-oop1.md` | OOP I：class vs record、字段/方法/属性、constructor/destructor、private/protected/public/published、Self、TObject 万物之祖、Create/Free/FreeAndNil 与所有权 | `12_oop1` |
| 13 | `13-oop2.md` | OOP II：继承、virtual/override/abstract、inherited、多态、is/as、类引用（class of）、类方法/类变量、**接口**（IInterface/引用计数/implements） | `13_oop2` |
| 14 | `14-generics.md` | 泛型与容器：generic 声明与 specialize（objfpc 语法）、约束、Generics.Collections（TList\<T\>/TObjectList\<T\>/TDictionary\<K,V\>）、与 Classes.TList/TFPGList 对照 | `14_generics` |
| 15 | `15-lazarus.md` ⭐ | Lazarus 入门：是什么（LCL 跨平台、与 VCL 血缘）、IDE 布局（窗体设计器/对象查看器）、**工程三件套 .lpr/.lpi/.lfm 逐行讲**（手写最小工程=探针版）、Interfaces 先行、lazbuild 命令行、控件集（win32/gtk2/qt5/cocoa）、设计器 vs 纯代码 | `15_lazarus_hello` |
| 16 | `16-controls.md` ⭐ | **基础控件与事件模型**：事件是方法指针（赋值 @）、OnClick/OnChange/OnKeyDown/OnKeyPress/OnEnter/OnExit、Sender、文本类（TLabel/TEdit/TMemo/TLabeledEdit/TStaticText）、按钮类（TButton/TBitBtn/TSpeedButton/TToggleBox）、选择类（TCheckBox/TRadioButton/TRadioGroup）、列表入门（TComboBox/TListBox）、容器（TGroupBox/TPanel/TScrollBox）、Tab 顺序与 SetFocus、Enabled/Visible、Caption vs Text | `16_controls` |
| 17 | `17-more-controls.md` ⭐ | **更多控件**：数值（TTrackBar/TUpDown/TSpinEdit/TProgressBar）、日期（TDateTimePicker/TCalendar）、颜色（TColorBox/TColorListBox）、**TStringGrid 表格**（单元格读写/编辑事件/固定行列/动态行列/ownerdraw 一瞥）、TTabControl vs TPageControl、TImage（加载/拉伸/透明）、**TFrame 组件复用**（设计+挂接） | `17_more_controls` |
| 18 | `18-layout.md` | 布局与高 DPI：Left/Top/Width/Height、Align 家族（alClient/alTop/...）、Anchors 四向组合、BorderSpacing、TPanel/TSplitter、TPageControl/TTabSheet 作布局、OnResize 手工布局、DPI 缩放（AutoAdjustLayout/PixelsPerInch） | `18_layout` |
| 19 | `19-menus.md` | 菜单、工具栏与 Action：TMainMenu/TMenuItem、TPopupMenu、快捷键/加速键、**TActionList/TAction 统一命令**（菜单/工具栏/快捷键三绑定、OnUpdate 状态同步）、TToolBar/TToolButton、TStatusBar 窗格 | `19_menus_actions` |
| 20 | `20-dialogs.md` | 对话框与文件：TOpenDialog/TSaveDialog（过滤器/选项）、ShowModal 与 ModalResult、MessageDlg/ShowMessage 家族、InputBox/InputQuery、TFontDialog/TColorDialog、TFindDialog/TReplaceDialog（24 章复用）、LoadFromFile/SaveToFile | `20_dialogs` |
| 21 | `21-lists.md` | 列表与树：TListBox（风格/多选/自绘）、TComboBox 深入、TListView（vsReport 列/排序/图标/选中）、TTreeView/TTreeNode、Items 与 Data 对象持有、内存所有权 | `21_lists_trees` |
| 22 | `22-canvas.md` ⭐ | 绘图与自绘：TCanvas（Pen/Brush/Font）、线/形/填充/文字、OnPaint 与无效区（Invalidate）、**双缓冲**（TBitmap 离屏）、鼠标事件画板、TPaintBox vs TImage、像素操作 | `22_paint` |
| 23 | `23-threads.md` ⭐ | 多线程与后台任务：TThread（CreateSuspended/FreeOnTerminate/Execute）、**Synchronize vs Queue**、TCriticalSection、TProgressBar 回传、取消与 WaitFor、**LCL 非线程安全铁律**、CheckSynchronize（selftest 用） | `23_threads` |
| 24 | `24-notepad.md` ⭐ | 实战：记事本+——TPageControl 动态多标签（每页 TMemo）、打开/保存/另存（编码选择 UTF-8/ANSI）、查找/替换对话框、修改跟踪（标签 `*` + 关闭确认）、状态栏（行列/字数/编码）、字体/只读/换行选项（INI 持久化）、About、**--selftest 全功能自检**（临时文件开-改-存-比对；uchecks.pas 迷你断言单元——测试思想与 CI/lazbuild 收官一节） | `24_notepad_plus`（工程） |

吸收旧内容：旧指南的安装说明压缩进 01/02；Lazarus 三章（12–14 节内容）重组进 15–20；
示例代码全部重写（旧的只跑不改错、无断言）。

## 6. 示例与验证

- CLI 示例 `NN_topic.pas`：`{$mode objfpc}{$codepage utf8}{$H+}` 头、`uses SysUtils`、
  按 `# ═══ N.M 标题` 分节（与正文小节一致）、关键路径 Assert 自检、末行 `==== NN 结束 ====`。
- GUI 示例：手写最小 `.lpi`（探针模板：LCL 包 + `lib/$(TargetCPU)-$(TargetOS)` 输出）+ `.lpr`
  （`--selftest` 分支：Initialize → 建窗体/控件不 Show → 跑逻辑 → 写 `selftest.log`
  （UTF-8，含 `==== NN selftest OK ====`）→ Halt(0)）；正常分支 `Application.Run`。
  涉及 .lfm 的章（15 教语法）用文本 .lfm，其余尽量纯代码创建（"每个文件都看得懂"）。
- `build.ps1`（pwsh 7，UTF-8 无 BOM，参数 `-All/-Example NN_topic/-Gui/-Clean`）：
  - CLI 双通道：检查 `-MObjFPC -Cr -Co -Ci -Sa -B`，发布 `-MObjFPC -O2`；通道分目录
    `build/check|release/`；每通道四条判定（exit 0 / stderr 空 / 无控制字符 / 含结束标记）；
    双通道 stdout SHA256 对比（差异 → warn 不算 fail）
  - GUI：`lazbuild xx.lpi` exit 0 + exe 存在 → 运行 `--selftest`（cwd=示例目录）→ log 四条判定
  - 运行 CLI 前设 `chcp 65001`（编码纪律，实测依据见 §4）
- `run-all.sh`（Git Bash）等价实现；任一示例失败退出码 1。

## 7. 交付物清单

1. `freepascal/docs/01-overview.md` … `24-notepad.md`（24 章）
2. `freepascal/examples/02_hello/` … `24_notepad_plus/`（23 个示例目录；09 多文件，15–24 GUI 工程，24 含 uchecks.pas 迷你断言单元）
3. `freepascal/build.ps1`（重写）+ `freepascal/run-all.sh`（重写）
4. `freepascal/CHEATSheet.md`（语法速查 + 3.2.2/4.8 坑位索引）
5. `freepascal/README.md`（重写：定位、目录结构、章节索引表、工具链、验证命令、学习路线）
6. 删除：`Free Pascal编程指南.md`、旧 `examples/` 15 项、旧 `build/`
7. 根 `README.md` freepascal 条目更新
8. 记忆文件：`freepascal-tutorial-build.md`（实测坑位 + 结构）

## 8. 风险与对策

| 风险 | 对策 |
|---|---|
| 网上资料多 Delphi 7 / Lazarus 1.x 时代，API 说法过时 | 一切以 3.2.2/4.8 实测为准；坑位即素材（编码三变体、Extended 尺寸、Interfaces 顺序均已实测） |
| 手写 .lpi/.lfm 与 IDE 生成格式差异 | 探针已验证手写最小 .lpi 可构建；.lfm 用文本语法（lazbuild 自动编译），15 章讲格式 |
| GUI 无头验证稳定性 | selftest 不依赖窗口可见性（已实测）；线程章 selftest 用 CheckSynchronize 手动泵 |
| 双通道输出不一致的误报 | 断言/检查只影响错误路径，正常输出必须逐字节一致；不一致时 warn + 人工看 diff |
| 24 章 × 200–350 行 + 23 示例的写作量 | 分批交付分批提交（语言篇 → GUI 篇 → 收官），每批跑 build.ps1 全绿再 commit |
| 旧文件删除不可逆 | git 历史保留；删除与新结构同批提交，diff 清晰可审 |
