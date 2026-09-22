# 8. TextBlock 与文本呈现

上一篇：[07 Button](./07-button.md) ｜ 下一篇：[09 TextBox](./09-textbox.md)

界面上绝大部分"字"都是 `TextBlock` 画的。它是最常出现也最被低估的控件：看起来只会 `Text("...")`，实际上换行、截断、富文本、可选中文本各有一套机制。本章把这些一次性讲清。示例来自画廊工程 `examples/07-controls-basic/` 的 `TextBlockPage`（左侧导航 **TextBlock** 项）。

## 8.1 TextBlock 的定位：呈现，不是编辑

XAML 世界里文本呈现与文本输入是两个控件：

| | TextBlock | TextBox |
|---|---|---|
| 职责 | 显示 | 输入 |
| 可编辑 | 否（可选中文本） | 是 |
| 内容模型 | `Text` 字符串 或 `Inlines` 富文本 | `Text` 字符串 |
| 模板复杂度 | 无模板（直接绘制） | 完整控件模板（光标/选区/边框） |

"只显示不输入"让 TextBlock 走了轻量路径：它继承 `FrameworkElement` 而不是 `Control`——**没有模板、没有 Padding、没有 Background**（要背景就套 Border，06 章）。这是理解它属性集为什么"缺东西"的钥匙。

## 8.2 富文本：Inlines 与 Run

一个 TextBlock 里可以有多个 `Run`，各自带字体属性：

```xml
<TextBlock FontSize="16" TextWrapping="Wrap">
    <Run FontWeight="Bold" Text="Bold lead. "/>
    <Run Foreground="Red" Text="Red middle. "/>
    <Run FontStyle="Italic" Text="Italic tail."/>
</TextBlock>
```

代码里拼接动态富文本同样直接：

```cpp
TextBlock tb;
tb.Inlines().Append(Run{ FontWeight{ FontWeights::Bold() }, Text{ L"Bold lead. " } });
tb.Inlines().Append(Run{ Foreground{ SolidColorBrush{ Colors::Red() } }, Text{ L"Red middle. " } });
```

**`Text` 与 `Inlines` 互斥**：设置 `Text` 会清空 Inlines 并放一个隐式 Run；反之亦然。想混排就全走 Inlines。

什么时候不用 TextBlock 拼字符串而用多 Run？**风格或交互按片段变化**时——高亮命中词、链接嵌在句中（`Hyperlink` 也是 Inline，点了走 NavigateUri）。整段一个样式，`Text` 一个属性最省。

## 8.3 换行与截断：TextWrapping 与 TextTrimming

TextBlockPage 的核心演示是这条固定宽度 360px 的文本：

```xml
<TextBlock x:Name="TrimDemo" Width="360"
           Text="The quick brown fox jumps over the lazy dog 0123456789"/>
<Button Content="Cycle trim mode" Click="OnCycleTrimClicked"/>
```

`TextTrimming` 有四个值（本机 1.8 元数据核对）：

| 值 | 行为 |
|----|------|
| `None`（默认） | 不截断，超出宽度直接**画出去**（被容器裁剪） |
| `CharacterEllipsis` | 按字符截断，尾部加 `…` |
| `WordEllipsis` | 按词边界截断，尾部加 `…` |
| `Clip` | 硬截断无省略号（WinUI 3 新增） |

`TextWrapping` 三个值：

| 值 | 行为 |
|----|------|
| `NoWrap`（默认） | 单行，超宽继续画 |
| `Wrap` | 任意字符处折行 |
| `WrapWholeWords` | 只在词间折行，长词可能仍超宽 |

**默认值是组合拳陷阱**：`NoWrap + None` 意味着长文本既不折行也不截断——在 `StackPanel` 里直接画出容器边界，在 `Grid` 里被裁。给用户看的内容文本，`TextWrapping="Wrap"` 几乎总要写；列表项标题要单行省略，就 `TextTrimming="CharacterEllipsis"`。两条都想要单行时先 Wrap 后 Trim 的语义要想清楚：单行截断是 **NoWrap + ellipsis**。

## 8.4 字体四件套与主题资源

```xml
<TextBlock Text="Caption" FontFamily="Consolas" FontSize="12"
           FontStyle="Italic" FontWeight="SemiBold"/>
```

- `FontSize` 单位是**有效像素**（逻辑像素），不是物理像素——150% 缩放下 12 会画成 18 物理px，各种 DPI 屏幕上视觉一致。
- `FontWeight` 是结构体（`FontWeights::Bold()` 等预设），不是枚举；`FontStyle` 是枚举。
- 别在页面里硬编码字体：默认字体来自主题资源（`ContentControlThemeFontFamily`），跟系统走；等宽/特殊字体才显式指定。主题资源机制在 33 章展开。

## 8.5 可选中文本

```xml
<TextBlock IsTextSelectionEnabled="True" Text="This line is selectable."/>
```

TextBlock 不是编辑控件，但支持**选择复制**——文档页、错误详情、日志输出的标配。选中后 Ctrl+C 可复制，不需要任何额外代码。

## 8.6 与绑定：为什么改了 Text 界面不动

`Text` 是依赖属性，可绑定。最常见的坑来自 [32 章 32.3](./32-binding-mvvm.md) 的规则：**`x:Bind` 默认 OneTime**——求值一次就断开。给 TextBlock 绑了一个后来才变的属性，界面永远显示初值。修法两选一：

```xml
<TextBlock Text="{x:Bind Status, Mode=OneWay}"/>
```

或者用事件处理器直写（画廊的做法）：`StatusText().Text(L"trim = " + name)`。小页面直写更直观；状态多处复用就走绑定。

## 8.7 长文本与滚动

TextBlock **自己不滚动**。滚动是容器（`ScrollViewer`）的职责（[06 章 6.5](./06-layout.md)）：

```xml
<ScrollViewer MaxHeight="200" VerticalScrollBarVisibility="Auto">
    <TextBlock TextWrapping="Wrap" Text="{x:Bind LongDocument}"/>
</ScrollViewer>
```

判断口诀：**内容怎么画**（TextBlock 的 Wrap/Trim）与**内容怎么看**（ScrollViewer）是两层，别在一个属性上找齐。

## 8.8 实测坑位

1. **NoWrap+None 默认组合**：长文本画出容器。内容文本默认 `Wrap`。
2. **`Text` 与 `Inlines` 互斥**：XAML 里同时写 `Text=` 和子 Run，Text 生效或被覆盖，别混。
3. **MSVC 的 `constexpr` 数组坑**（代码层面，本章实现时实测）：函数内 `static constexpr std::array<hstring, 3>{{...}}` 在 MSVC 19.44 下报 C2131（"表达式的计算结果不是常数"）；改 `static hstring const modes[]{...}` 即可。写投影类型/`hstring` 的表驱动代码别迷信 constexpr。
4. **FontSize 物理像素混淆**：截图量坐标（ui-smoke 校准）时，150% DPI 下一个 FontSize=18 的行实际占约 40 物理px——视觉测量和属性值差一个 DPI 因子。
5. **TextBlock 没有 Background**：要背景/圆角/边框，套 `Border`（06 章 6.3），别找不存在的属性。

## 8.9 小结

| 需求 | 属性 |
|------|------|
| 折行 | `TextWrapping="Wrap"`（词间用 WrapWholeWords） |
| 单行省略 | `TextTrimming="CharacterEllipsis"`（+NoWrap） |
| 混排样式 | `Inlines` + 多个 `Run` |
| 可复制 | `IsTextSelectionEnabled="True"` |
| 文本随数据变 | `x:Bind ... Mode=OneWay` 或事件直写 |
| 长文滚动 | 外套 `ScrollViewer` |

画廊 `TextBlockPage` 运行时证据：`.smoke/07-controls-basic/textblock/click-2.png`——点击 Cycle trim mode 后状态行变 **"trim = CharacterEllipsis"**，演示行尾部出现省略号。

---

上一篇：[07 Button](./07-button.md) ｜ 下一篇：[09 TextBox](./09-textbox.md) ｜ 返回 [目录](../README.md)
