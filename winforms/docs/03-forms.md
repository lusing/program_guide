# 03 · 窗体属性、生命周期与子窗体

> 对应示例：`examples/03_forms`（生命周期日志 + 模态输入框 + 非模态浮动窗）

> **本章你将学会**：窗体的常用属性、生命周期事件的先后顺序、模态与非模态两种子窗体、关闭确认、子窗体向主窗体传值。
> **前置章节**：[02 第一个程序](02-hello.md)。

## 1. 生命周期：事件触发的先后顺序

03 示例把每个事件记进日志列表，实测顺序：

```text
HH:mm:ss  构造函数执行完毕（此时窗体还不可见）
HH:mm:ss  Load：窗体首次显示前（做初始化的好地方）
HH:mm:ss  Shown：窗体已经显示出来（Load 之后必有一次）
HH:mm:ss  Activated：成为活动窗口（切回来也会再触发）
HH:mm:ss  Deactivate：失去焦点（点了别的窗口）
```

| 事件 | 触发时机 | 典型用途 |
|---|---|---|
| `Load` | 显示前一次 | 读配置、拉数据 |
| `Shown` | 显示后一次 | 依赖句柄的初始化、启动动画 |
| `Activated` / `Deactivate` | 每次焦点变化 | 刷新标题、暂停轮询 |
| `FormClosing` | **关闭前，还能反悔** | 确认未保存修改 |
| `FormClosed` | 关闭成定局 | 清理、释放 |

**记忆点**：`Load` 一次、`Activated` 多次；脏活干在 `Load`，句柄相关的活干在 `Shown`。

## 2. 关闭确认：FormClosing 里 `e.Cancel = true`

```csharp
FormClosing += (s, e) =>
{
    var r = MessageBox.Show($"日志里有 {_log.Items.Count} 条记录，确定退出？",
                            "关闭确认", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
    if (r == DialogResult.No)
        e.Cancel = true;              // 撤销关闭：FormClosed 不再触发
};
```

`FormClosing` 是最后一道闸门；`FormClosed` 里阻止为时已晚。

## 3. 模态子窗体：ShowDialog

```csharp
using var dlg = new NameDialog();
if (dlg.ShowDialog(this) == DialogResult.OK)      // this = owner
    Log($"模态返回 OK，姓名 = {dlg.UserName}");
```

模态 = **不关掉它，主窗体的代码就停在 `ShowDialog` 这一行**，主窗体也点不动。标准对话框写法（`NameDialog` 的骨架）：

```csharp
Text = "输入姓名";
FormBorderStyle = FormBorderStyle.FixedDialog;    // 对话框不该被拖大小
MaximizeBox = false; MinimizeBox = false;
StartPosition = FormStartPosition.CenterParent;   // 落在父窗体中央

var ok = new Button { Text = "确定", DialogResult = DialogResult.OK, … };
// DialogResult 属性是捷径：点击即关窗并把结果带回给 ShowDialog 的返回值
AcceptButton = ok;      // 回车 = 确定
CancelButton = cancel;  // Esc = 取消
```

`AcceptButton`/`CancelButton` 是用户手感的关键——回车/关掉的习惯都在这。

## 4. 非模态子窗体：Show + Owner + 事件汇报

```csharp
var win = new FloatingWindow { Owner = this };    // Owner：浮在主窗体之上、随之最小化
win.TitleChanged += msg => Log($"浮动窗口来消息：{msg}");
win.Show(this);                                    // 立即返回，两边都能操作
```

子窗体不认识主窗体，**靠自定义事件把消息递出去**（[11 章](11-events.md)细讲事件本身）：

```csharp
public event Action<string> TitleChanged;          // C#：一句话事件
…
TitleChanged?.Invoke($"第 {++_ticks} 次汇报");
```

| | 模态 `ShowDialog` | 非模态 `Show` |
|---|---|---|
| 返回 | `DialogResult`（阻塞到关闭） | 立即返回 |
| 主窗体 | 不可交互 | 正常使用 |
| 数据回传 | 读窗体属性 | 事件回调 |
| 典型场景 | 确认框、编辑对话框 | 工具窗、查找替换 |

## 5. 常用窗体属性速查

`Text`（标题）、`ClientSize`（**客户区**大小，布局真正关心的）/`Size`（含边框标题栏）、`MinimumSize`、`StartPosition`（五个值：Manual/CenterScreen/CenterParent/…）、`FormBorderStyle`（七种，对话框用 FixedDialog）、`TopMost`、`Opacity`、`Icon`、`Font`（**子控件默认继承**）。

## 6. 三语言差异

**F#**：窗体类写法（要自定义事件时值得用类）：

```fsharp
type FloatingWindow() as this =
    inherit Form()
    let titleChanged = Event<string>()
    do  …
    [<CLIEvent>]                                   // 暴露成真正的 .NET 事件
    member _.TitleChanged = titleChanged.Publish

    // 事件触发：titleChanged.Trigger "消息"
```

`type X() as this = inherit Form()` 的 `do` 块里写界面搭建，**用 `this.` 不用 `base.`**——`base.Text <- …` 报 FS0419（base 值只能用于调用重写成员的基实现）。

**C++/CLI**：自定义事件 + 触发：

```cpp
event Action<String^>^ TitleChanged;      // 编译器合成 add_/remove_/raise_
…
TitleChanged(msg);                        // 直接调用即触发（合成的 raise_ 自带空调用保护）
```

坑：**不能写 `if (TitleChanged != nullptr)`**——事件不是数据成员，报 C3918"用法要求是数据成员"。

**枚举遮蔽**：C++/CLI 在 Form 子类里写 `FormBorderStyle::FixedDialog` / `DialogResult::OK` 报 C2039（属性名遮蔽枚举类型），要 `System::Windows::Forms::FormBorderStyle::FixedDialog` 全限定。

## 坑位清单

1. `FormClosed` 里才想阻止关闭——晚了，反悔只能在 `FormClosing`。
2. 对话框没设 `AcceptButton`/`CancelButton`：回车没反应、Esc 关不掉（用户体验瞬间廉价）。
3. F# `base.` 赋属性报 FS0419——用 `as this` 自标识 + `this.`。
4. C++/CLI 事件判空 C3918——直接调用即安全触发。
5. C++/CLI 枚举被属性名遮蔽（FormBorderStyle/DialogResult/AutoScaleMode/…）——全限定。

## 自测

1. `Load` 与 `Shown` 各触发几次？`Activated` 呢？
2. 模态对话框把"确定"结果带回主窗体有几种写法？本章用了哪种？
3. `Owner` 与 `MdiParent`（[10 章](10-mdi.md)）的区别？
4. 关闭确认的 `e.Cancel` 写在哪个事件里？
5. F# 自定义事件对外暴露要加什么属性？
