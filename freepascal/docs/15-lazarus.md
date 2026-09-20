# 15 · Lazarus 入门（⭐）

## 1. Lazarus 是什么

一句话：**Lazarus = Lazarus IDE + LCL 类库**，目标是"Write once, compile anywhere"的
原生 GUI 开发——用 Delphi 的 RAD 体验（拖控件、双击写事件），编译出各平台原生程序。

- **LCL**（Lazarus Component Library）是 VCL 的开源复刻：`TForm/TButton/TMemo` 这些类的
  API 与 Delphi VCL 高度同源——学 LCL ≈ 半学 VCL，三十年 Delphi 书籍大体可用。
- 跨平台机制：LCL 把控件操作转发给各平台的**控件集（widgetset）**——win32/gtk2/qt5/cocoa。
  你写的代码一份，控件集按平台编译进去（.lpi 不指定时按宿主默认：Windows→win32，
  macOS→cocoa）。本教程 .lpi 一律不写死控件集，两个平台各取默认。
- IDE 本身就是 LCL 写的（自举）——能拖控件写 Delphi 风格程序的东西，本身就是它写的。

与语言篇的关系：前 14 章的所有东西（类/事件是方法指针/引用计数/泛型）在 GUI 世界
全部用上，一件不少。

## 2. 工程三件套：.lpr / .lpi / .lfm

一个最小 Lazarus 工程是三个（组）文件（本章示例 `15_lazarus_hello` 就是完整标本）：

```text
15_lazarus_hello/
├── 15_lazarus_hello.lpi    工程文件（XML）：单元清单、编译选项、包依赖
├── 15_lazarus_hello.lpr    主程序：uses 顺序 + selftest 分支 + Application.Run
├── uhelloform.pas          窗体单元：TMainForm 类 + {$R *.lfm}
└── uhelloform.lfm          窗体描述：控件树（文本格式，设计器可视化编辑的就是它）
```

### .lpi——工程户口

XML 格式，手写最小版完全可行（本教程全部 GUI 工程都是手写 .lpi，实测 lazbuild 4.8
接受 Version=12 老格式）：

```xml
<RequiredPackages Count="1">
  <Item1><PackageName Value="LCL"/></Item1>       <!-- 依赖 LCL 包 -->
</RequiredPackages>
<Units Count="2">
  <Unit0><Filename Value="15_lazarus_hello.lpr"/> ... </Unit0>
  <Unit1><Filename Value="uhelloform.pas"/> ... </Unit1>
</Units>
...
<UnitOutputDirectory Value="lib/$(TargetCPU)-$(TargetOS)"/>   <!-- 产物目录 -->
```

要加第三方包（如 datetimectrls，17 章的 DateTimePicker）就是在 RequiredPackages 加一项。

### .lpr——主程序

```pascal
uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,                       // Unix（Linux/macOS）多线程才需要（Windows 不用）
  {$ENDIF}{$ENDIF}
  Interfaces,                    // ⚠️ 必须是 LCL 单元之首（cthreads 除外）
  Forms, Classes, SysUtils,
  uhelloform { MainForm };

begin
  Application.Initialize;                          // 初始化控件集
  Application.CreateForm(TMainForm, MainForm);      // 建主窗体（IDE 向导标准形态）
  Application.Run;                                  // 消息循环（不返回直到窗体关）
end.
```

**`Interfaces` 第一**（实测坑）：漏了它链接期报 unit Interfaces missing 类错误——
它把 LCL 绑到具体控件集，必须先于其他 LCL 单元。

**消息循环**：`Application.Run` 就是语言篇里没有的那半——取消息、分发、驱动事件。
你写的所有 OnClick 都是从这里出发被调用的。

### .lfm + 窗体单元——流式 UI

```pascal
// uhelloform.pas
type
  TMainForm = class(TForm)      // 字段写【默认可见性】——TForm 祖先带 {$M+}，
    BtnHello: TButton;          // 默认段即 published，流机制靠 RTTI 找到字段并填充
    LblMessage: TLabel;
    procedure BtnHelloClick(Sender: TObject);
  end;

implementation
{$R *.lfm}                      // 把同名 .lfm 链进来
```

```text
# uhelloform.lfm —— 文本格式，设计器编辑的可视化映射
object MainForm: TMainForm
  Caption = '15 · Lazarus 入门'
  object BtnHello: TButton
    Caption = '问好'
    OnClick = BtnHelloClick      # 按方法名绑定（编译器核对签名）
  end
  object LblMessage: TLabel ...
end
```

`TMainForm.Create` 时：`{$R *.lfm}` 的资源被读出 → 逐个 `object` 建控件 →
按**字段名**塞进 published 字段 → 按方法名挂事件。**字段名/方法名与 .lfm 不匹配 =
运行时控件缺 nil**（不是编译错误！）——这是 lfm 三大坑之一。

## 3. 设计器 vs 手写

Lazarus IDE 的用法（装好就能用，本教程主线是命令行，IDE 当"可视化查看器"用）：

1. `lazarus` 启动 → 打开 .lpi → 窗体设计器拖控件、对象查看器（Object Inspector）
   改属性、双击控件生成事件骨架。
2. IDE 会替你维护 .lfm/.pas/.lpr 的同步——所见即所得。
3. **坑**：IDE 会顺手改 .lpi（加它的会话状态）——提交前 diff 看一眼。

本教程的立场与 MFC 篇一致：**示例全部手写**（.lpi/.lfm 都是文本，"每个文件都看得懂"），
但你应当会用 IDE——真实项目里拖控件效率碾压手写坐标。

## 4. lazbuild：命令行构建

IDE 之外，工程用一行命令构建（CI/脚本场景的主力）：

```powershell
lazbuild 15_lazarus_hello.lpi          # Windows: lib/x86_64-win64/15_lazarus_hello.exe
                                       # macOS  : lib/x86_64-darwin/15_lazarus_hello（+ 同名 .app 包）
```

- **lazbuild 只认 .lpi**（直接喂 .lpr 报 File not found——实测坑）。
- 产物与 .o 一起落在 `lib/<CPU>-<OS>/`（.lpi 里 UnitOutputDirectory 控制）。
- **macOS 上产物是两份**：`lib/x86_64-darwin/<名>` 这个裸可执行文件，外加同目录的
  `<名>.app` 包（包里还有一份同名可执行文件）。脚本定位 exe 只查 `lib/*/` 一层，
  用 `-Recurse` 会把两份一起捞回来，取哪个随文件系统返回顺序变——两个入口必须
  用同一套定位规则（`build.ps1` 与 `run-all.sh` 现在都是"只查一层"）。
- **macOS 首次 lazbuild 会编 LCL 本身**：系统的 `/opt/local/share/lazarus` 通常不可写，
  lazbuild 自动改写到 `~/.lazarus/lib/`（日志里能看到 `Fallback output directory`）。
  第一个工程约 5 分钟，之后增量就快了——CI 里别被这个耗时吓到。
- 本教程 `build.ps1 -Gui` 对 15–24 每个工程执行：lazbuild → 跑 `exe --selftest` →
  校验日志。**GUI 程序的自动化验证就这么简单**：窗体不 Show 也能创建、流加载、
  调事件方法（本章示例的 selftest 分支逐行演示）。

## 5. selftest 模式：GUI 也能无头验证

每个 GUI 示例的 .lpr 都有这个分支（本教程的核心工程约定）：

```pascal
if ParamStr(1) = '--selftest' then
begin
  try
    RunSelfTest;               // 建窗体（不 Show）→ 验控件/调事件 → 写 selftest.log
  except
    on E: Exception do begin   // ⚠️ 必须自捕获
      ...写日志...; Halt(1);
    end;
  end;
  Halt(0);
end;
```

**坑（实测，花了一个挂死进程换来的）**：GUI 程序里未捕获异常会弹 **LCL 消息框**等人点
——无头/CI 环境直接挂死。所以 selftest 必须自己 try-except：错误写日志、exit 1。
验证脚本也带 60 秒超时击杀双保险。

## 6. 第一个窗口（代码导读）

本章示例运行后的样子：一个窗口，"问好"按钮，下方标签。点击 → 标签变"你好，Lazarus！"。

- 控件从哪来：.lfm 流加载（BtnHello/LblMessage 字段被填充）
- 点击怎么流转：Application.Run 的消息循环 → 按钮的 OnClick（lfm 里绑的 BtnHelloClick）
  → 你的方法改 LblMessage.Caption → LCL 失效重绘
- **LCL 内部全是 UTF-8**：Caption 是 UTF-8 字节，与语言篇 `{$codepage utf8}` 纪律无缝衔接
  （selftest 断言中文字面量 Caption 全通过）。

## 7. 坑位清单（实测）

1. `Interfaces` 必须是 uses 里第一个 LCL 单元（ctheads 除外）。
2. lazbuild 只认 .lpi；exe 落 `lib/<CPU>-<OS>/`，别在工程根目录找（macOS 还会多一个
   `.app` 包，脚本要只查一层才不会捞错）。
3. 窗体字段必须放默认可见性（=published）才能被 lfm 流填充；放 private 里字段就是 nil。
4. .lfm 的 OnClick 方法名拼错 = 运行时"方法不存在"类错误，不是编译期。
5. GUI 程序未捕获异常弹 LCL 对话框——selftest/后台逻辑必须 try-except 自捕获。
6. 纯代码建窗体用 `TForm.CreateNew(nil)`（跳过 lfm）；但 **TFrame 没有 CreateNew**——
   Frame 天生与 .lfm 配对，缺资源报 `Resource THeaderFrame not found`（17 章）。

---
上一章：[14 泛型与容器](14-generics.md) ｜ 下一章：[16 基础控件与事件模型](16-controls.md) ｜ 返回：[README](../README.md)
