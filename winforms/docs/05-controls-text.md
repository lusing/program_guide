# 05 · 文本类控件：TextBox、RichTextBox、NumericUpDown、LinkLabel

> 对应示例：`examples/05_text`（单行三件套 + 富文本工具条 + 超链接标签）

> **本章你将学会**：单行/多行/密码文本框、NumericUpDown、RichTextBox 的选区操作、LinkLabel 与打开网页。
> **前置章节**：[04 布局](04-layout.md)。

## 1. TextBox：单行输入

```csharp
_user.MaxLength = 12;                        // 限长
_user.CharacterCasing = CharacterCasing.Normal;   // Upper/Lower 自动转大小写
_pwd.UseSystemPasswordChar = true;           // 系统密码圆点；也可 PasswordChar='*'
```

**密码框的 `Text` 就是明文**——"不可见"只是呈现。真实系统别把密码放 `string` 里太久（见 17 章的生产化讨论），教学演示无妨。

## 2. 多行文本

```csharp
var tb = new TextBox
{
    Multiline = true,                 // 多行开关（RichTextBox 默认就是多行）
    ScrollBars = ScrollBars.Vertical, // Both/Horizontal/Vertical/None
    WordWrap = true,                  // 自动换行（关掉则横向滚动）
    AcceptsReturn = true,             // 回车换行而不是触发默认按钮
    AcceptsTab = true,                // Tab 缩进而不是跳焦点
};
```

`AcceptsReturn/AcceptsTab` 是"文本编辑器"与"表单"的分水岭。

## 3. NumericUpDown：自带校验的数字输入

```csharp
_age.Minimum = 1; _age.Maximum = 120;
_age.Value = 18;                      // Value 是 decimal
_age.ValueChanged += (s, e) => _status.Text = $"  年龄 = {_age.Value}";
```

上下箭头、范围钳制、直接输数字校验都是白送的——**要数字就用它，别用 TextBox + TryParse 折腾**（TextBox+TryParse 是老教材的写法，留给"必须允许空值"的场景）。

## 4. RichTextBox：带格式的文本

05 示例的彩色追加是经典套路：

```csharp
private void AppendColored(string text, Color color)
{
    _rich.SelectionStart = _rich.Text.Length;   // 插入点挪到末尾
    _rich.SelectionLength = 0;
    _rich.SelectionColor = color;               // 影响后续插入
    _rich.AppendText(text);
    _rich.SelectionColor = _rich.ForeColor;    // 恢复默认色
}
```

选区三属性 `SelectionStart/SelectionLength/Selection*` 是 RichTextBox 的操作语言：选中一段后可以改 `SelectionFont`（加粗）、`SelectionColor`、读 `SelectedText`。日志面板、聊天窗口的彩色输出全靠这个模式。

## 5. LinkLabel：可点链接

```csharp
var link = new LinkLabel { Text = "遇到问题？查阅 Microsoft Learn 的 WinForms 文档", … };
link.Links.Add(8, 15, "https://learn.microsoft.com/dotnet/desktop/winforms/");
//                      ↑ 第 8 字起 15 字 = "Microsoft Learn"（起止按字符数算）
link.LinkClicked += (s, e) =>
{
    Process.Start(new ProcessStartInfo { FileName = (string)e.Link.LinkData, UseShellExecute = true });
    link.LinkVisited = true;                   // 访问过的链接变紫色
};
```

`Links.Add(start, length, data)` 用**字符偏移**圈出可点区域，`data` 顺带塞 URL——一个 Label 可以有多段不同链接。

**.NET Core 起的注意点**：`Process.Start` 默认 `UseShellExecute = true`（Framework 时代默认 false），直接给 URL 就能用默认浏览器打开。

## 6. 三语言差异

**F# 插值字符串的规则差异**（本章起高频出现，先立规矩——都是实测）：

| 写法 | 结果 |
|---|---|
| `$"共 {rich.Text.Length} 字"` | ✔ 洞里可以放复杂表达式 |
| `$"{t:F1}"`（t 是简单标识符，字母开头格式） | ✔ |
| `$"{i:00}"`（数字开头格式） | ✘ FS0010 意外的整数文本 |
| `$"{d:yyyy-MM-dd}"`（格式含 `-`） | ✘ FS0010 |
| `$"{obj.Prop:F1}"`（点取表达式后跟冒号） | ✘ FS0010 |
| `$"{x.ToString(\"…\")}"`（洞里带引号） | ✘ FS3373 明确告诉你：先 let 绑定或用三引号外层 |
| `$"进度 {p}%"`（洞后跟百分号） | ✘ FS3376：`%` 是 printf 引导符，要写 `%%` |

**省心三招**：先 `let` 绑定再进洞；格式化用 `.ToString("…")` 拼好；百分号写 `%%`。

**F# 异构数组**：`AddRange` 要 `Control[]`，`[| label; textbox |]` 推断成第一个元素的类型——注解 `let items: Control[] = [| … |]` 才行。

**C++/CLI**：

```cpp
login->Controls->AddRange(gcnew array<Control^> { userLabel, _user, pwdLabel, _pwd });
// 位或后的枚举要 cast：static_cast<FontStyle>(style | FontStyle::Bold)
```

`AddRange` 的签名还会牵出 `System.Private.Windows.Core` 模块引用（Cpp.Common.props 已备）。

## 坑位清单

1. F# 插值洞里的格式串/引号/百分号——见上表，报错编号 FS0010/FS3373/FS3376。
2. F# `AddRange [| … |]` 异构数组 → 注解 `Control[]`。
3. NumericUpDown.Value 是 decimal，插值显示 `18` 而不是 `18.0` 是默认格式行为；参与计算要记得类型。
4. LinkLabel 的 `Links.Add` 偏移算上中文——一个汉字算一个字符，按显示数容易数错（示例里注释了起止）。
5. 密码框明文在内存——教学可用，生产要谨慎（17 章的口令讨论）。

## 自测

1. 让 TextBox 的回车换行而不是触发按钮，设什么？
2. NumericUpDown 相比 TextBox+int.Parse 省掉了哪三件事？
3. RichTextBox 追加指定颜色文本的套路是什么？（口述四步）
4. `Process.Start` 打开 URL 需要哪个属性？（.NET 10 默认值又是什么）
5. F# 里 `$"{p}%"` 为什么报错？两种修法？
