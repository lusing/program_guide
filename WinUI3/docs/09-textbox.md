# 9. TextBox 与文本输入族

上一篇：[08 TextBlock](./08-textblock.md) ｜ 下一篇：[10 CheckBox 与 RadioButton](./10-checkbox-radio.md)

用户往应用里"写字"的地方有三个控件：`TextBox`（纯文本）、`PasswordBox`（密码）、`RichEditBox`（富文本）。它们看起来像三兄弟，机制却各走各路——本章把三条路都走一遍，重点讲清"值怎么出来"（事件还是绑定）。示例代码来自功能工程 `examples/09-scratchpad/`（编辑器：多文档、加粗、查找、未保存确认、落盘回读）。

## 9.1 一张表先分家

| | TextBox | PasswordBox | RichEditBox |
|---|---|---|---|
| 内容属性 | `Text`（string，依赖属性） | `Password`（string，**1.8 元数据确认是 DP**） | **没有内容属性**，在 `Document()`（ITextDocument）里 |
| 变更事件 | `TextChanged` | `PasswordChanged` | 文档对象模型上的事件，通常不监听 |
| 绑定 | TwoWay 常用 | **能绑但不该绑**（9.4） | 不能直接绑（9.5） |
| 常见职责 | 表单字段、搜索框 | 登录口令 | 备注、编辑器 |

## 9.2 TextBox：属性三件套与 TextChanged

```xml
<TextBox x:Name="NameBox" Header="Task title" PlaceholderText="type here..."
         MaxLength="20" TextChanged="OnNameChanged"/>
```

三个属性各司其职，别混：

- **`Header`**：标签。渲染在输入框**上方**，是"这个框是什么"的正式说明，屏幕阅读器优先读它。
- **`PlaceholderText`**：占位提示。框内灰字，**用户一输入就消失**，提交数据时它不算内容。两者经常一起用：Header 说"任务标题"，Placeholder 说"20 字以内"。
- **`MaxLength`**：硬截断，输入到量后不再收字符。

```cpp
void TextBoxPage::OnNameChanged(IInspectable const&, TextChangedEventArgs const&)
{
    auto text = NameBox().Text();
    StatusText().Text(L"title len = " + winrt::to_hstring(text.size()));
}
```

`TextChanged` 的两个机制点：

1. **args 里没有旧值/新值**（`TextChangedEventArgs` 是空的）——触发时文本**已经**改完，你只能读 `Text()` 拿当前值。要旧值？自己存一份。这不是缺陷而是时序：等你能读到时，控件内部已提交。
2. **程序化改 `Text()` 也触发**。别在 handler 里无条件写回 `Text()`——会再触发自己，虽不至于死循环（值不变时不再触发），但逻辑会绕。

### 双向绑定的更新时机

`{x:Bind Text, Mode=TwoWay}` 的默认行为（UWP 沿袭）：**焦点离开时**才把值推回源属性（`UpdateSourceTrigger` 默认等效 LostFocus）。要每个键击都推回，监听 `TextChanged` 手动同步，或用 `UpdateSourceTrigger=PropertyChanged`（x:Bind 支持）。"边打边搜"用前者，"提交表单"用默认即可。

## 9.3 输入体验的细节旋钮

- `AcceptsReturn="True"` + `TextWrapping="Wrap"`：多行模式（缺一不可，只开 AcceptsReturn 会长出横向滚动）。
- `IsReadOnly="True"`：可复制不可改——展示协议文本、日志。
- `IsTextPredictionEnabled` / `IsSpellCheckEnabled`：输入预测与拼写检查，默认随系统；密码框永远关。
- `InputScope`：软键盘形态（触屏设备上"数字""邮件"键盘），桌面无感但写了不亏。

## 9.4 PasswordBox：为什么密码要"绕着走"

```xml
<PasswordBox x:Name="SecretBox" Header="Password"
             PasswordRevealMode="Peek" PasswordChanged="OnPasswordChanged"/>
```

```cpp
void TextBoxPage::OnPasswordChanged(IInspectable const&, RoutedEventArgs const&)
{
    StatusText().Text(L"password len = " + winrt::to_hstring(SecretBox().Password().size()));
}
```

先纠正一个流传甚广的旧结论：**UWP 时代"`Password` 不是依赖属性、不可绑定"——在 WinUI 3 1.8 的元数据里已经不成立**（`IPasswordBoxStatics` 里有 `get_PasswordProperty()`，本机 `.winmd` 核对）。但"能绑"不等于"该绑"：

- 绑定 = 把密码**同步进 ViewModel**，一个可以逃逸到日志/转储/子对象引用的普通 `hstring` 成员。明文密码在内存里多一份副本，就多一份泄漏面。
- 正确姿势是**事件读、即用即弃**：`PasswordChanged` 里读 `Password()`，立刻做哈希/送认证，不存成员。上面示例只报长度，就是这个纪律。

`PasswordRevealMode` 三值：`Hidden`（永远遮）、`Visible`（永远露，基本不用）、`Peek`（按住眼睛图标才露）——**Peek 是标配**。`PasswordChar` 可换遮蔽字符（默认圆点）。

## 9.5 RichEditBox：内容根本不是字符串

```cpp
TextBoxPage::TextBoxPage()
{
    InitializeComponent();
    // 内容在 Document()（Microsoft.UI.Text.ITextDocument），不是 Text 属性
    RichBox().Document().SetText(Microsoft::UI::Text::TextSetOptions::None,
        L"Hello from RichEditBox. Select a word, then click Bold selection.");
}
```

RichEditBox 的内容活在 `Document()` 返回的 `ITextDocument` 里（元数据在独立的 `Microsoft.UI.Text.winmd`），这是一个类 Word 的文档对象模型：

```cpp
// 读全文：元数据形状 Void GetText(TextGetOptions, String&)，C++/WinRT 原样保留双参数
hstring raw;
RichBox().Document().GetText(Microsoft::UI::Text::TextGetOptions::None, raw);
```

> **实测坑（编译级）**：这个 `GetText` 的 out 参数**不会**被 C++/WinRT 收成返回值——写 `auto s = doc.GetText(opts)` 编不过（C2660 "函数不接受 1 个参数"），必须 `hstring s; doc.GetText(opts, s);`。别按"Get 前缀必有返回值"的经验猜。

格式操作走**选区**：

```cpp
using Microsoft::UI::Text::FormatEffect;
// Bold 是 FormatEffect 枚举（Off/On/Toggle/Undefined），自带 Toggle 值（元数据核对）
RichBox().Document().Selection().CharacterFormat().Bold(FormatEffect::Toggle);
```

> 同一个坑的第二发（编译级）：选区加粗的 API 不是网上常写的 `GetBold()/Bold(Format::Boolean)`——1.8 元数据里 `ITextCharacterFormat.Bold` 的类型是 **`Microsoft.UI.Text.FormatEffect` 枚举**，`Toggle` 值一行完成"有则去、无则加"。`Format::Boolean` 类型不存在。

`TextGetOptions`/`TextSetOptions` 控制"读出/写入的是什么"：`None` 是纯文本，`FormatRtf` 是 RTF——存档用 RTF，检索用纯文本。

## 9.6 三框协作的表单模式

真实表单里三者经常同页（TextBoxPage 就是）：标题用 TextBox、口令用 PasswordBox、长备注用 RichEditBox。组织纪律：

1. **每个框的反馈走各自事件**，别轮询。
2. **提交时统一收集**：`Text()` / `Password()` / `GetText(...)` 各读一次，组装提交。校验放提交点，不放每次击键（实时校验留给"边打边搜"这类确有需要的字段）。
3. RichEditBox 的值**别想绑定**——它在文档对象里，包一层 ViewModel 方法（`hstring Notes() const` 内部调 `GetText`）是干净的做法。

## 9.7 实测坑位

1. **`GetText` 双参数**（9.5，C2660）。
2. **`FormatEffect` 不是 `Format::Boolean`**（9.5，元数据实测改写）。
3. **TextChanged 里改回 Text**：自我触发链，逻辑绕死。要规范化输入（如去空格），比较新旧、真变了再写。
4. **PlaceholderText 当默认值用**：占位不是值，提交时读 `Text()` 是空的。要默认值就在代码里 `Text(L"默认")`。
5. **密码绑进 ViewModel**：机制上可行（1.8 有 DP）、工程上别做（9.4）。
6. **多行只开 AcceptsReturn**：横向滚动条出来说明忘了 `TextWrapping="Wrap"`。

## 9.9 实战：一个真正的编辑器文本管线（ScratchPad）

演示页里 TextBox 的用法到 `Text()` 读值为止；ScratchPad 把 RichEditBox 放进了一条完整的"输入→标脏→取值→落盘→回读"管线。

### 9.9.1 编辑器的出生配置

每个页签的新文档都是代码里造的 RichEditBox：

```cpp
RichEditBox editor;
editor.AcceptsReturn(true);            // 多行：没有它回车不换行
editor.TextWrapping(TextWrapping::Wrap);
editor.IsSpellCheckEnabled(false);     // 代码/草稿场景关拼写线
editor.PlaceholderText(L"Type something, select it, then toggle Bold");
```

四个属性对应四个真实决策：多行、换行策略、拼写检查的噪音、空态引导。**PlaceholderText 是最便宜的可用性投资**——空文档一眼知道能干什么。

### 9.9.2 标脏：TextChanged 的最小用法

页签标题旁的 `*`（未保存标记）由 TextChanged 驱动：

```cpp
editor.TextChanged([this, tab](IInspectable const&, IInspectable const&)
{
    if (auto entry = FindEntry(tab))
    {
        if (!entry->Dirty)
        {
            entry->Dirty = true;
            UpdateStatus(L"editing " + entry->Name);
        }
    }
});
```

注意两个细节：**lambda 按值捕获 `tab`**（TabViewItem 是引用计数对象，存副本安全，不用怕悬空）；**只在 false→true 的边沿做事**，每次击键都刷状态行是浪费。

### 9.9.3 取值：GetText 的两参形态（实测坑）

读 RichEditBox 内容的正确姿势：

```cpp
hstring text;
editor.Document().GetText(Microsoft::UI::Text::TextGetOptions::None, text);
```

**单参数版 `GetText(options)` 不存在**——投影里的签名是两参（选项 + 出参 hstring）。另一个 namespace 陷阱：`TextGetOptions`/`FormatEffect` 住在 **Microsoft**.UI.Text（不是 Windows.UI.Text），写错命名空间是一串 C2664/C2665 里最难看懂的那个。工程层面还要 pch 里 `#include <winrt/Microsoft.UI.Text.h>`——缺了它 RichEditTextDocument 的 consume 函数全是"返回 auto 但未定义"（C3779 连锁）。

### 9.9.4 富文本：选区格式化

加粗不改"整个文档的字体"，而是改**选区**的字符格式：

```cpp
editor.Document().Selection().CharacterFormat().Bold(
    on ? Microsoft::UI::Text::FormatEffect::On
       : Microsoft::UI::Text::FormatEffect::Off);
```

这就是"先选中再点 B"的机制本尊：`Selection()` 返回光标/选区对象，`CharacterFormat()` 是它的格式代理，`Bold(FormatEffect)` 三态（On/Off/Toggle——Toggle 交给 RichEditBox 原生 Ctrl+B 更省事）。**全选**没有 `SelectAll()` 直通车，用钳制法：

```cpp
editor.Document().Selection().SetRange(0, 0x7FFFFFFF);   // 末点超界自动夹到文尾
```

（投影里没有 `DocumentRange()`，这是它的替代写法。）

### 9.9.5 落盘与回读

保存走 UTF-8 写文件（WideCharToMultiByte），然后**立刻读回来**：

```cpp
DocStore::Save(entry->Name, text);
hstring check;
m_saveProbe = DocStore::Load(entry->Name, check)
    ? (L"verified on disk (" + to_hstring(check.size()) + L" chars)")
    : L"WRITE FAILED";
```

这不是测试代码，是产品决策：保存按钮的反馈从"调用成功"升级成"磁盘可证"——`.smoke/09-scratchpad/save/tap-2.png` 状态行的 **"verified on disk (15 chars)"** 就是它。写后回读的成本一次磁盘 IO，换来的是把"保存了但文件是空的"这类灾难在发生当场暴露。

## 9.8 小结

| 需求 | 控件 + 关键 API |
|------|----------------|
| 单行文本 | TextBox：Text / Header / PlaceholderText / MaxLength / TextChanged |
| 多行文本 | TextBox：AcceptsReturn + TextWrapping |
| 密码 | PasswordBox：PasswordChanged 里读 Password()，RevealMode=Peek |
| 富文本 | RichEditBox：Document()→ SetText / GetText(双参) / Selection().CharacterFormat() |
| 边打边搜 | TextChanged + InputScope |
| 提交读取 | 各读一次，集中校验 |

运行时证据：`.smoke/09-scratchpad/save/tap-2.png`——RichEditBox 收下整段输入，Ctrl+S 落盘后状态行 **"saved untitled-1.txt | verified on disk (15 chars)"**；`.smoke/09-scratchpad/find/tap-2.png`——Expander 里的查找 TextBox 输入 "a"，TextChanged 实时统计出 **"3 match(es) for 'a'"**。

---

上一篇：[08 TextBlock](./08-textblock.md) ｜ 下一篇：[10 CheckBox 与 RadioButton](./10-checkbox-radio.md) ｜ 返回 [目录](../README.md)
