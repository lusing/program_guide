# 8. TextBlock 与文本呈现

上一篇：[07 Button](./07-button.md) ｜ 下一篇：[09 TextBox](./09-textbox.md)

界面上绝大部分"字"都是 `TextBlock` 画的。它是最常出现也最被低估的控件：看起来只会 `Text("...")`，实际上换行、截断、富文本、可选中文本各有一套机制。本章把这些一次性讲清。示例代码来自功能工程 `examples/07-settings-hub/`（设置中心：主题/密度/透明度即点即生效并持久化）。

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

或者用事件处理器直写（设置中心的做法）：`StatusText().Text(L"theme = " + name)`。单窗应用直写更直观；状态多处复用就走绑定。

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

## 8.9 实战：一页里的四种 TextBlock（设置中心）

功能应用里 TextBlock 担着四种截然不同的角色，AppearancePage 一页全占：

**① 区块标题**——大、重、独占一行：

```xml
<TextBlock Text="Appearance" FontSize="26" FontWeight="Bold"/>
```

**② 说明文案**——换行 + 降不透明度，视觉上退到第二层：

```xml
<TextBlock Text="Theme, density and translucency apply immediately and are remembered."
           TextWrapping="Wrap" Opacity="0.7"/>
```

`Opacity="0.7"` 比 Foreground 写死灰色更对：它跟随亮暗主题自动适配（暗色下 0.7 白、亮色下 0.7 黑），不用为两套主题各写一色。

**③ 标签行**——`FontWeight="SemiBold"` 的短标签（"App theme"、"Panel density"），比正文重、比标题轻，构成页面的层级节奏。

**④ 状态行**——被代码反复改写的那一个：

```cpp
StatusText().Text(L"theme = " + name);        // 单选后
StatusText().Text(L"density = " + density);   // 下拉后
StatusText().Text(L"saved");                  // 保存后
```

同一个 TextBlock 接住全页所有动作的回声——这是"直写"路线（8.6 的左列）在单窗应用里的终态：状态只有一处、永远最新、不涉及绑定管线。

### 8.9.1 内联混排：Run 的实战位

DataExplorer 的详情条用 `Run` 把四个字段拼进一行，字段间以间隔符连接：

```xml
<TextBlock Opacity="0.8">
    <Run Text="{x:Bind Kind}"/>
    <Run Text="  ·  "/>
    <Run Text="{x:Bind Size}"/>
    <Run Text="  ·  "/>
    <Run Text="{x:Bind Date}"/>
</TextBlock>
```

注意写法差异：普通 TextBlock 的 `Text="字面量"` 与模板里的 `Text="{x:Bind Path}"` 可以混用，但 **`Run` 的 Text 同样两者都吃**——静态间隔符与动态字段在同一个 TextBlock 里各安其位，比拼四个 TextBlock 进 StackPanel 少三个元素、行距天然一致。

### 8.9.2 计数行：一处 Text，两路来源

DataExplorer 顶部的计数行是"代码直写"的另一个典型：它同时反映两个输入（类别 + 子串），每次过滤后整串重建：

```cpp
CountText().Text(to_hstring(m_view.Size()) + L" items · " + m_category
    + (query.empty() ? L"" : L" · '" + m_query + L"'"));
```

`.smoke/17-data-explorer/tree/tap-1.png` 里它显示 **"3 items · Images"**——TreeView 点一下，这行字是用户得到的第一层反馈（列表变化是第二层）。**反馈顺序的教训**：先更新轻量文本再更新列表，用户感知的响应更快；反过来会让重布局阻塞住"已经点了"的确认感。

### 8.9.3 TextBlock vs TextBox：一次性的选择错误

新手最常见的误用是拿 TextBox 显示只读文本（因为"能选中复制"）。代价清单：TextBox 有输入法挂载（移动端弹键盘）、有焦点环、光标闪烁抢注意力、屏幕阅读器朗读"可编辑"。**TextBlock 支持选中复制**：`IsTextSelectionEnabled="True"`——这才是"只读但可复制"的正确控件。设置中心的说明文案全部 TextBlock+Wrap；ScratchPad 的状态行是 TextBlock（会被代码改，但永远不可编辑）。判断只问一句：**用户会在这里打字吗**——不会就 TextBlock，会才 TextBox（9 章）。

### 8.9.4 字体度量与行高的隐形战场

TextBlock 默认行高由字体度量决定，中文（Segoe UI 回退到中文字体）与西文混排时基线对不齐是常态——标题行混排丑八成是这个。两个抓手：`TextBlock.LineHeight`（显式行高，配 `LineStackingStrategy="BlockLineHeight"`）钉死行距；段落间距用容器 Spacing 而不是空行 TextBlock（后者在辅助树里是噪音节点）。设置中心的 Spacing=18 段间距、LineHeight 未动（纯中文场景默认度量可接受）——**先量再调，不猜**。

## 8.10 小结

| 需求 | 属性 |
|------|------|
| 折行 | `TextWrapping="Wrap"`（词间用 WrapWholeWords） |
| 单行省略 | `TextTrimming="CharacterEllipsis"`（+NoWrap） |
| 混排样式 | `Inlines` + 多个 `Run` |
| 可复制 | `IsTextSelectionEnabled="True"` |
| 文本随数据变 | `x:Bind ... Mode=OneWay` 或事件直写 |
| 长文滚动 | 外套 `ScrollViewer` |

运行时证据：`.smoke/07-settings-hub/theme/tap-1.png`——AppearancePage 的区块标题（FontSize=26 SemiBold）、说明文案（TextWrapping=Wrap + Opacity 0.7）与底部 `StatusText` 状态行同帧可见；点击 Dark 后状态行即时显示 **"theme = Dark"**。

---

上一篇：[07 Button](./07-button.md) ｜ 下一篇：[09 TextBox](./09-textbox.md) ｜ 返回 [目录](../README.md)
