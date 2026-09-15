# Free Pascal 编程教程

Free Pascal（FPC）是一种现代、跨平台的 Pascal 实现。它继承了 Pascal 的结构化设计思想，同时支持过程式编程、面向对象编程以及丰富的运行库。

本教程的目标是帮助读者在本地工具链中快速建立起 Pascal 代码的编写与验证能力，并把示例整理为独立文件，以便逐步练习。

## 1. Pascal 与 Free Pascal 简介

Pascal 是一种强调清晰结构和强类型语法的语言，最早由 Niklaus Wirth 设计。Free Pascal 则把它扩展为更现代的编程语言，适合：

- 命令行工具开发
- 学习算法和数据结构
- 面向对象编程
- 经典教学场景
- 跨平台编译

## 2. 编译与运行模型

Free Pascal 使用最常见的编译流程。Windows 上（scoop 安装）：

```powershell
G:\scoop\apps\freepascal\current\bin\i386-win32\fpc.exe -MObjFPC -Sc hello.pas
.\hello.exe
```

macOS / Linux 上编译器直接在 PATH 里（macOS 可用 `sudo port install fpc lazarus`）：

```bash
fpc -MObjFPC -Sc hello.pas
./hello
```

两个平台的差异只有两点：**编译器路径**，以及**可执行文件后缀**（Windows 是 `hello.exe`，
macOS/Linux 是 `hello`，无扩展名）。编译参数和源码本身完全一致。

本仓库的 `build.ps1`（PowerShell）与 `run-all.sh`（shell）是等价的双入口，都会自动探测
工具链、按平台决定产物后缀，并对每个示例执行最小运行验证。

## 3. 基础语法：程序结构

最小 Pascal 程序如下：

```pascal
program Hello;

begin
  WriteLn('Hello, Free Pascal!');
end.
```

关键点：

- `program` 语句声明程序名
- `begin ... end.` 代表程序体
- `WriteLn` 输出文本
- `.` 是程序结束符

## 4. 变量、类型与算术

Pascal 中变量需要先声明：

```pascal
var
  a, b, c: Integer;
  name: String;
begin
  a := 10;
  b := 20;
  c := a + b;
  name := 'guide';
  WriteLn(name, ' = ', c);
end.
```

常见类型包括：

- Integer
- Real
- Boolean
- Char
- String
- Array
- Record

## 5. 条件分支与选择结构

Pascal 中使用 `if`、`case` 来进行分支处理：

```pascal
if score >= 90 then
  WriteLn('A')
else if score >= 80 then
  WriteLn('B')
else
  WriteLn('C');
```

`case` 更适合对离散值进行判断：

```pascal
case ch of
  'a': WriteLn('A');
  'b': WriteLn('B');
  else WriteLn('Other');
end;
```

## 6. 循环结构

常见循环包括：

- `for ... to ... do`
- `for ... downto ... do`
- `while ... do`
- `repeat ... until`

例如：

```pascal
for i := 1 to 5 do
  WriteLn(i);
```

## 7. 过程、函数与模块化

Pascal 非常适合结构化拆分：

```pascal
procedure PrintMessage(msg: String);
begin
  WriteLn(msg);
end;

function Square(x: Integer): Integer;
begin
  Square := x * x;
end;
```

模块化思维在 Pascal 中尤其重要，因为它天然鼓励清晰的程序结构。

## 8. Array、Record 与集合

数组和记录是数据组织的基本手段：

```pascal
type
  TPoint = record
    X, Y: Integer;
  end;

var p: TPoint;
begin
  p.X := 3;
  p.Y := 4;
  WriteLn(p.X, ',', p.Y);
end.
```

数组则用于同类元素的批量处理：

```pascal
var nums: array[0..4] of Integer;
```

## 9. 字符串、集合与指针

Free Pascal 同样支持：

- 字符串拼接
- 字符索引访问
- 集合类型
- 指针和动态分配

例如：

```pascal
var p: ^Integer;
New(p);
p^ := 42;
WriteLn(p^);
Dispose(p);
```

## 10. 文件 I/O 与数据保存

基础的文件读写非常适合学习：

```pascal
var f: TextFile;
begin
  AssignFile(f, 'demo.txt');
  Rewrite(f);
  WriteLn(f, 'hello from Pascal');
  CloseFile(f);
end.
```

这样可以帮助读者理解程序与外部数据的交互。

## 11. 面向对象编程

Free Pascal 完整支持类和对象：

```pascal
type
  TPerson = class
  private
    FName: String;
  public
    constructor Create(name: String);
    procedure Show;
  end;
```

这一部分让学生对传统 Pascal 和面向对象范式之间的衔接更加容易理解。

## 12. Lazarus 图形界面开发

Lazarus 是 Free Pascal 的 IDE，它不仅能用于命令行程序，也非常适合桌面 GUI 开发。与传统命令行脚本相比，Lazarus 的工作流更偏向：

- 视觉化设计窗体（Form）
- 拖放组件（Button、Label、Edit、Memo 等）
- 通过事件处理器响应点击和输入
- 使用 `LCL`（Lazarus Component Library）组织界面逻辑

一个典型的 Lazarus 窗体程序会包含：

- `*.lpr`：程序入口
- `*.lpi`：Lazarus 项目配置
- `*.pas`：窗体代码
- `*.lfm`：界面布局描述

最小示例：

```pascal
program LazarusGuiDemo;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,
  Unit1;

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
```

对应的窗体代码：

```pascal
unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TMainForm = class(TForm)
    BtnHello: TButton;
    LblMessage: TLabel;
    procedure BtnHelloClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

procedure TMainForm.BtnHelloClick(Sender: TObject);
begin
  LblMessage.Caption := 'Lazarus GUI works!';
end;

end.
```

GUI 编程的核心思想：

- 窗体是 `TForm`
- 按钮等控件继承自 `TControl`
- 事件由 `OnClick`、`OnChange` 等回调驱动
- 组件属性在 IDE 中可以非常直观地修改

### 12.1 Lazarus 的常见组件

Lazarus 中最常用的基础组件包括：

- `TButton`：按钮
- `TLabel`：文本标签
- `TEdit`：单行输入框
- `TMemo`：多行文本框
- `TListBox`：列表
- `TRadioButton` / `TCheckBox`：选择控件
- `TPanel`：容器面板

### 12.2 GUI 开发步骤

1. 创建新项目：`File -> New Project -> Application`
2. 拖入控件到 Form 上
3. 设置 `Caption`、`Name`、`Width`、`Height` 等属性
4. 双击按钮创建事件处理函数
5. 绑定逻辑并进行本地编译与调试

### 12.3 推荐的学习顺序

- 先做最小窗体：标题 + 按钮 + 标签
- 再做输入/输出交互：`TEdit` + `TLabel`
- 再学习布局：`TPanel`、`TGroupBox`
- 最后进阶到列表、对话框、菜单和多窗体程序

## 13. Lazarus 窗体控件进阶篇

在掌握最小窗体之后，可以继续学习 Lazarus 中的常用高级控件，这些控件让一个桌面应用具备更完整的交互能力。

### 13.1 `TEdit` 与输入框

`TEdit` 是最常用的输入控件，可以接收用户文本：

```pascal
var
  EdName: TEdit;

procedure TMainForm.BtnAddClick(Sender: TObject);
begin
  if Trim(EdName.Text) = '' then
    Exit;

  ListBox1.Items.Add(EdName.Text);
  EdName.Clear;
end;
```

其典型用途包括：

- 用户姓名、编号输入
- 搜索框
- 参数输入
- 配置编辑

### 13.2 `TListBox` 与 `TMemo`

`TListBox` 适合展示一组选择项，而 `TMemo` 适合多行日志或输出。组合起来可以做出：

- 任务列表
- 日志面板
- 历史记录
- 用户消息显示

### 13.3 `TComboBox` 与选项选择

`TComboBox` 常用于选择模式、主题、配置项等：

```pascal
ComboBox1.Items.Add('Classic');
ComboBox1.Items.Add('Dark');
ComboBox1.Items.Add('Modern');
ComboBox1.ItemIndex := 0;
```

### 13.4 `TRadioGroup` 与 `TCheckBox`

- `TCheckBox`：单个布尔选择项
- `TRadioGroup`：多个互斥选项

这类控件非常适合做：

- 功能开关
- 过滤条件
- 风格选择
- 用户偏好设置

### 13.5 组合交互案例

一个成熟的窗口通常会组合这些组件：

- 输入框：收集数据
- 按钮：触发操作
- 列表框：展示结果
- 复选框：控制状态
- 下拉框：切换配置
- 单选组：选择模式
- 日志框：记录操作

这个组合正是桌面程序开发最典型的模式。

### 13.6 高级控件演示项目

本目录中的 `14_lazarus_advanced_controls/` 演示了以下交互：

- `TEdit`：输入名称
- `TButton`：添加到列表
- `TListBox`：展示元素
- `TMemo`：输出操作日志
- `TCheckBox`：启用/禁用控件
- `TComboBox`：切换主题
- `TRadioGroup`：选择级别
- `TLabel`：更新状态信息

这类示例非常适合理解 Lazarus GUI 的事件驱动编程模型。

## 14. Lazarus 多窗体 / 菜单 / 对话框进阶篇

在完成基础窗体和高级控件学习后，真正的桌面应用重点通常落在窗口协作、菜单设计和对话框交互上。本章节以一个多窗口示例为核心，展示如何在 Lazarus 中组织更完整的应用流程。

### 14.1 多窗体结构的设计思想

桌面程序常常不是只有一个 `TForm`，而是由多个窗口共同配合：

- 主窗口：展示列表、状态和菜单
- 二级窗口：显示详细信息、设置或帮助内容
- 对话框：用于选择文件、确认操作、输入参数

这种结构让应用逻辑更清晰，也更容易扩展。核心思路是：

- 主窗口负责业务入口
- 子窗口负责特定任务
- 事件回调在不同窗口之间传递状态
- `ShowModal` 适合处理临时的模式窗口

### 14.2 菜单设计

Lazarus 最常见的菜单实现方式是使用 `TMainMenu` 与 `TMenuItem`。例如：

```pascal
FMainMenu := TMainMenu.Create(Self);
FMenuFile := TMenuItem.Create(FMainMenu);
FMenuFile.Caption := '&File';

FMenuOpen := TMenuItem.Create(FMainMenu);
FMenuOpen.Caption := '&Open';
FMenuOpen.OnClick := @MenuOpenClick;

FMenuExit := TMenuItem.Create(FMainMenu);
FMenuExit.Caption := 'E&xit';
FMenuExit.OnClick := @MenuExitClick;

FMenuFile.Add(FMenuOpen);
FMenuFile.Add(FMenuExit);
FMainMenu.Items.Add(FMenuFile);
Menu := FMainMenu;
```

这种设计让应用具有标准的“文件 / 帮助 / 退出”交互模式，非常适合桌面软件开发入门。

### 14.3 对话框

`TOpenDialog` 是最常用的文件选择对话框，可以在用户点击“打开”时出现：

```pascal
if FFileDialog.Execute then
  FMemoStatus.Lines.Add('Selected file: ' + FFileDialog.FileName)
else
  FMemoStatus.Lines.Add('Dialog canceled.');
```

除了打开文件之外，Lazarus 还支持：

- `TSaveDialog`：保存文件
- `TSelectDirectoryDialog`：选择目录
- `TColorDialog`：选择颜色
- `TFontDialog`：选择字体

### 14.4 多窗口交互案例

对应的示例工程 `15_lazarus_menus_dialogs/` 中，包含了以下行为：

- 主窗口有菜单栏和按钮
- 点击“Open”会弹出第二个窗口
- 通过 `ShowModal` 实现模式窗口
- 通过 `TOpenDialog` 选择文件
- 通过 `ShowMessage` 展示帮助信息

这类程序非常适合理解：

- `TForm` 的生命周期
- 事件驱动编程
- 模式窗口与非模式窗口
- 程序入口、主界面和工具栏/菜单的职责分工

### 14.5 实战建议

学习到这里，建议按照以下顺序再继续：

1. 仅保留一个主窗口，先练习菜单
2. 再增加一个子窗口用于展示详细信息
3. 再添加文件选择对话框
4. 最后将状态栏、日志区和事件处理整合成完整流程

### 14.6 进阶练习方向

如果想继续扩展，可以把次级窗口升级为：

- 多个不同的设置页
- 数据编辑对话框
- 记事本式文本编辑器
- 带状态栏的主窗口
- 多文档界面（MDI）风格布局

这些内容都可以在 Lazarus 的桌面应用开发中逐步落地。

## 15. 学习路径建议

建议按下面顺序学习：

1. 程序结构和输出
2. 变量与基本类型
3. 条件判断和循环
4. 过程/函数
5. 数组/记录
6. 文件 I/O
7. 指针与动态内存
8. 类与面向对象编程
9. Lazarus GUI 窗体与事件编程
10. Lazarus 高级控件与交互设计
11. Lazarus 多窗体、菜单与对话框应用设计

## 16. 本目录示例清单

本目录中的示例文件都已保存到 `examples/` 下，并在两套工具链上完成「编译 + 运行 / 构建」验证：
Windows（scoop 版 fpc + Lazarus）与 macOS（MacPorts 版 fpc 3.2.2 + Lazarus 4.8，cocoa 控件集）。
`15_lazarus_menus_dialogs/` 是当前的多窗口 / 菜单 / 对话框进阶展示项目，涵盖了真实桌面应用常见交互模式。

- `01_hello.pas`：Hello World
- `02_variables.pas`：变量声明与赋值
- `03_arithmetic.pas`：算术运算
- `04_if_case.pas`：if 与 case
- `05_loops.pas`：循环控制
- `06_procedures.pas`：过程与函数
- `07_records.pas`：record 结构
- `08_arrays.pas`：数组处理
- `09_strings_sets.pas`：字符串与集合
- `10_pointers.pas`：指针和动态分配
- `11_file_io.pas`：文件读写
- `12_classes.pas`：类与对象
- `13_lazarus_gui/`：最小 Lazarus GUI 项目，演示 `TForm`、`TButton` 和事件处理
- `14_lazarus_advanced_controls/`：高级控件演示，涵盖 `TEdit`、`TListBox`、`TComboBox`、`TCheckBox`、`TRadioGroup` 和 `TMemo`
- `15_lazarus_menus_dialogs/`：多窗体进阶演示，涵盖 `TMainMenu` 菜单、`ShowModal` 模态子窗口、`TOpenDialog` 文件对话框与 `ShowMessage` 提示

## 17. 本地验证方式

Windows（scoop 安装）：

```text
G:\scoop\apps\freepascal\current\bin\i386-win32\fpc.exe
G:\scoop\apps\lazarus\current\lazbuild.exe
```

```powershell
cd G:\code\guide\freepascal
.\build.ps1 -All
```

macOS（MacPorts 安装，已验证 fpc 3.2.2 + Lazarus 4.8）：

```text
/opt/local/bin/fpc
/opt/local/bin/lazbuild
```

```bash
cd /path/to/programming/freepascal
./run-all.sh              # 全部示例 + 3 个 Lazarus 工程
./run-all.sh 03 09        # 只跑指定编号
./run-all.sh -v 08        # 附带完整输出
./run-all.sh --gui        # 只构建 Lazarus 工程
./run-all.sh --clean      # 清理 build 目录

# 等价入口（自动探测工具链，产物后缀按平台决定）
pwsh -File ./build.ps1 -All
```

两个入口都会优先读环境变量 `FPC` / `LAZBUILD`，其次在 PATH 上找 `fpc` / `lazbuild`，
最后回落到上面列出的常见安装路径，所以换机器、换包管理器都不必改脚本。

本仓库统一采用“编译 + 运行”的方式验证示例，确保每个例子都是真实可执行的。判定标准四条：
退出码为 0、stderr 为空、stdout 里没有多余控制字符、输出里有结束标记。3 个 Lazarus 工程
（`13_lazarus_gui/`、`14_lazarus_advanced_controls/`、`15_lazarus_menus_dialogs/`）用 `lazbuild`
做编译验证，确认 LCL 窗体工程能被本地 Lazarus 正常构建。

两条实测事实值得记住：

- 每个示例都在 `-MObjFPC` 与 `-MDelphi` 两种语言模式下各跑一遍，两边输出逐字节一致。
  对照通道**不能**选 FPC 默认模式（`-MFPC`）：`11_file_io.pas` 找不到 `AssignFile`、
  `12_classes.pas` 连 `class` 都不认，这两种对象/单元扩展只在 objfpc 与 delphi 模式下可用。
- `lazbuild` 不指定控件集时会按宿主平台自动选择（Windows → win32，macOS → cocoa，Linux → gtk2），
  因此工程不需要为某个平台固定配置。产物目录 `examples/*/lib/<CPU>-<OS>/`（如 `x86_64-win64`、
  `x86_64-darwin`）只是编译中间产物，每次只生成当前平台那一个；历史的 win64 产物已从仓库清除，
  根 `.gitignore` 用 `freepascal/examples/*/lib/` 连同 `*.ppu`、`*.compiled` 一起忽略。

## 18. 使用 Lazarus 的建议

Lazarus 是 Free Pascal 的 IDE，适合开发 GUI 应用和面向组件的桌面程序：

- 窗口设计器
- 组件属性面板
- 事件处理习惯
- 更适合教学与桌面应用原型

但本教程仍以 Free Pascal 语法和命令行验证为主，便于在任何环境下复现和学习。
