# 13. NumberBox：数值输入

上一篇：[12 Slider、ProgressBar 族](./12-slider-progress.md) ｜ 下一篇：[14 ComboBox](./14-combobox.md)

"输入一个数"看似 TextBox 加一行解析就够，实际暗藏着解析、步进、校验、空态四件事——`NumberBox` 把它们一次做完。示例代码来自功能工程 `examples/07-settings-hub/`（设置中心：主题/密度/透明度即点即生效并持久化）。

## 13.1 TextBox 做数值输入的痛

用 TextBox 收数值，你自己要处理：非数字输入过滤（或事后校验报错）、空字符串（`Text()` 是 `L""` 不是 0）、小数点/负号/千分位本地化、步进按钮、上下限。每一件都不难，合起来就是 NumberBox 存在的理由——**它是"带数值语义的输入框"**。

## 13.2 核心属性

```xml
<NumberBox x:Name="Quantity" Header="Quantity" Value="1"
           SmallChange="1" LargeChange="10"
           SpinButtonPlacementMode="Compact"
           AcceptsExpression="True"
           ValueChanged="OnQuantityChanged"/>
```

| 属性 | 作用 |
|------|------|
| `Value` | **double**。空输入不是 0，是 **NaN** |
| `SmallChange` / `LargeChange` | 微调步长（滚轮/上下箭头）与页步进 |
| `SpinButtonPlacementMode` | `Compact`（聚焦/悬停时显示 ±）/ `Inline`（常驻） |
| `AcceptsExpression` | 吃算式：输入 `2+3*4` 回车得 14 |
| `ValidationMode` | 非法输入的处理：`InvalidInputOverwritten`（回退到上一个合法值，默认）/ `KeepInvalid` |
| `PlaceholderText` / `Header` | 同 TextBox（09 章） |

## 13.3 Value 的三态读取与程序化写入

```cpp
void NumberBoxPage::OnQuantityChanged(IInspectable const&,
    NumberBoxValueChangedEventArgs const& args)
{
    if (!Quantity() || !StatusText()) return;   // 12.5 的解析期/析构期防御
    double v = args.NewValue();
    if (std::isnan(v))
    {
        StatusText().Text(L"quantity = (empty)");
    }
    else
    {
        StatusText().Text(L"quantity = " + winrt::to_hstring(v));
    }
}
```

要点：

- `args` 是 `NumberBoxValueChangedEventArgs`（有 `NewValue`/`OldValue`，走 RangeBase 风格而不是 Text 风格——因为它是值控件）。
- **NaN 是"空"的唯一表达**：清空输入框、点 Clear、程序置 NaN，都是这个态。判断用 `std::isnan`，别拿 `== NAN` 比（永远 false）。
- 程序化写 `Value` 与用户输入走同一套解析校验，并再次触发 `ValueChanged`——所以"Double it"按钮一行就够：

```cpp
void NumberBoxPage::OnDoubleClicked(IInspectable const&, RoutedEventArgs const&)
{
    double v = Quantity().Value();
    if (!std::isnan(v)) Quantity().Value(v * 2);   // 自动触发 OnQuantityChanged
}
```

## 13.4 与 Slider 的取舍

| | NumberBox | Slider（12 章） |
|---|---|---|
| 输入精度 | 任意值、可粘贴 | 受步长约束 |
| 速度 | 慢（打字） | 快（一拖） |
| 范围感知 | 无 | 有（轨道位置） |
| 典型场景 | 数量、金额、端口号 | 音量、透明度、缩放 |

两者常成对出现：Slider 调、NumberBox 精修，共享同一个数据源（绑定模式见 32 章）。

## 13.5 实测坑位

1. **空值 = NaN**：`Value()` 返回 NaN 而不是 0 或抛异常；下游计算前必须 `isnan` 检查，否则 NaN 悄悄传染整个算式。
2. **`to_hstring(NaN)` 的输出**：会打出 `nan(ind)` 之类的平台相关文本——**先判空再格式化**（本页 handler 的写法）。
3. **ValidationMode 默认覆盖**：默认模式下非法输入失焦即回滚，用户会以为"打字失灵"——要保留用户输入自己校验就显式设 `KeepInvalid`。
4. **Compact 模式的 spin 按钮**：悬停/聚焦才显示。自动化测试别依赖它常驻（要常驻用 `Inline`）。
5. **ValueChanged 解析期触发**：12.5 的通用坑在此同样适用，handler 判空开路。

## 13.5 实战：空输入的真实语义（设置中心）

演示页里 NumberBox 的 NaN 是个知识点；在设置中心它是**产品决策**——TaskFlow 的任务数上限，"没填"必须与"填 0"严格区分：

```xml
<NumberBox x:Name="DefaultCount" Header="Default task count (empty = unlimited)"
           PlaceholderText="no limit" Minimum="0" Maximum="99"
           SpinButtonPlacementMode="Inline" SmallChange="1" LargeChange="5"
           ValueChanged="OnCountChanged"/>
```

四个细节各有其位：**Header 把语义写进标签**（"empty = unlimited"——用户不用猜空框什么意思）；**PlaceholderText 是空态的第二次提示**；**Minimum/Maximum 收紧输入域**（0–99 之外的值连输入机会都没有）；**Inline 旋转按钮**给鼠标用户 ±1 的捷径（SmallChange/LargeChange 分别对应点击与按住）。

```cpp
void PreferencesPage::OnCountChanged(IInspectable const&,
    NumberBoxValueChangedEventArgs const& args)
{
    if (!StatusText()) { return; }
    double v = args.NewValue();
    if (std::isnan(v))
    {
        SettingsStore::Put(L"count", L"nan");
        StatusText().Text(L"default count = unlimited");
    }
    else
    {
        SettingsStore::Put(L"count", to_hstring(static_cast<int>(v)));
        StatusText().Text(L"default count = " + to_hstring(static_cast<int>(v)));
    }
}
```

注意 **`NewValue()` 是 double 且清空时是 NaN**——不是 0、不是空串、不是异常。用 `std::isnan` 分流后，"无限"与"0 个"成为两个可持久化的独立状态（消费端 TaskFlow 拿到 `nan` 字符串就走不限量路径）。

### 13.5.1 恢复：字符串回填要防"nan"

构造期把持久值读回来：

```cpp
hstring saved = SettingsStore::Get(L"count", L"");
if (!saved.empty() && saved != L"nan")
{
    try { DefaultCount().Value(std::stod(std::wstring(saved))); }
    catch (...) {}
}
```

三重防御各挡一层：空串（从未设过）不回填；**字面量 "nan" 不喂给 stod**（喂了会把 NaN 设回去——但这正是我们要显式跳过的路径：恢复语义是"回到空框"，不是"显示 NaN"）；解析异常静默（脏数据当年怎么存的已经不是现在能修的事，别让设置页起不来）。

**为什么不用 TextBox + 自己解析**：NumberBox 一并处理了非法输入拒收、上下限钳制、步进按钮、滚轮调节、还有 IME 数字键盘——自写 TextBox 版本每个都要手工做一遍，且每个都能做错。教程里"看似一个控件能解决"的题，背后几乎都真有一个这样的控件。

### 13.5.2 校验的三道门

NumberBox 的输入控制是三道闸：**拒收**（非法字符进不来）、**钳制**（超出 Min/Max 自动贴边，`Value` 永远在域内）、**NaN**（清空的显式空态）。演示页常只考第三道；产品里第一道最值钱——拒收让"错误状态"根本不发生，比"错了再提示"少一轮交互。设置中心的 0–99 域把"负数任务数"这个概念从 UI 里抹掉了，OnCountChanged 里不用写一行防御。

**LargeChange 的语义**：按住旋转按钮的加速步进（LargeChange=5 vs SmallChange=1）——键盘上对应 PgUp/PgDn 与方向键。参数不是装饰，是"粗调/细调"双速交互的实现位。

### 13.5.3 双向绑定的钩子（32 章预告）

NumberBox 的 `Value` 是依赖属性——`{x:Bind ... Mode=TwoWay}` 直挂视图模型，ValueChanged 就不用写了。设置中心走事件直写（教学显式），产品代码里绑定是常态。两者的分界在**副作用**：值变更要做的事不止"记住"（刷新依赖控件、触发重算）时，事件处理器里的命令式链条比绑定的隐式传播好排错；纯数据同步用绑定。32 章的 TaskFlow 把这条线走全。

### 13.5.4 旋转按钮的位置学问

`SpinButtonPlacementMode` 两档：`Inline`（常驻在框内右侧，设置中心用）与 `Compact`（聚焦才出现）。Inline 占宽约 60 逻辑 px——**窄表单里三个 NumberBox 各吃 180px**，横向空间紧时 Compact 更划算；触屏主导的界面 Inline 直观（手指不用长按）。设置中心单框横排无压力，Inline 的即时可见性赢。

### 13.5.5 一个框的国际化

NumberBox 的解析**跟随系统区域**（小数点/千分位）——中文系统 "1.5" 合法、某些区域要 "1,5"。存储侧 13.5.1 的 `std::stod` 用 C locale（永远认点）——**显示与存储的解析器不一致**是国际化 bug 标准款：德区用户输入 "1,5" 框内合法（逗号小数），落盘 std::stod 解析成 15。修法要么全程 WinRT 的 `DoubleFormatter` 家族，要么存储也走区域感知解析。教学工程单区域无感——这条债记在国际化清单上（与 16.6.4 日期区域同款）。

### 13.5.6 与 TextBox 的造价对比

"TextBox 自己解析"路线的真实造价清单：拒非法字符（KeyDown 拦 + IME 绕过修补）、解析失败提示（状态行或 ErrorText）、上下限钳制、步进按钮、滚轮调节、可访问性（朗读"数字"而非文本）——六项各 10-30 行，还各能做错。NumberBox 一行 XAML。**判断一个"自制"值不值**：把清单列出来，每项都想清楚怎么测——列不完就别自制。这条判断法则适用于全章控件（14 章可编辑下拉、16 章日历、15 章搜索建议同理）。

### 13.5.7 单位与量纲的展示

数值框带单位（"px"、"ms"）时：`Header` 里写（"Width (px)"——朴素）或自定义模板尾部拼 TextBlock（精致）。**NumberBox 没有内建单位属性**——别用 PlaceholderText 冒充（它是空态提示，有值就消失，单位也跟着消失）。设置中心 "Default task count (empty = unlimited)" 用 Header 承载语义后缀——单位与语义说明都是 Header 的正当载荷。

### 13.5.8 空态的视觉表达

NaN（空）时 NumberBox 显示空白 + PlaceholderText——**但页面其余部分不知道它是"无限"**（设置中心状态行说 "default count = unlimited"，列表视图里呢？）。产品化方案：消费侧统一 NaN→"∞" 的显示转换（32 章值转换器的主场）。教学工程用状态行直说——**空态语义要么显式展示要么别让用户进空态**，半遮半掩最伤（空框 + 旁边一个不知情的合计数）。

## 13.6 练习与思考

1. 13.5.6 的造价清单法：为"可编辑下拉框"（14 章 IsEditable）列同样的清单，对比 ComboBox 原生能力与自制成本。
2. 给 NumberBox 加"超出 99 时钳回并状态行警告"——Min/Max 已经钳了，这个练习的真正考点是：警告属于数据层还是 UI 层？
3. 国际化雷区（13.5.5）：构造三组输入（1.5 / 1,5 / 1 500）在中文区域下的解析结果，写下你的存储格式决策。

### 13.5.9 多框联动：表单级校验

单框校验 NumberBox 全包了；**跨框规则**（"宽≤高"、"开始<结束"）在单框之外——监听两框的 ValueChanged，在任一变化时重算联合合法性，非法时状态行报错 + 禁提交按钮。**别在单框的 handler 里直接改另一框**（值回写再触发对方 handler，环）。联合校验的输出是"表单级状态"（valid/invalid + 原因），它属于页面/视图模型层——这是 32 章 MVVM 的前哨战。

## 13.7 上生产前的审查清单

- [ ] Min/Max/步长按产品域收紧（拒收优于提示）
- [ ] 空态（NaN）语义显式：Header 写明 + 消费侧统一处理
- [ ] 持久化与解析的区域一致性已评估（13.5.5）
- [ ] 旋转按钮位置（Inline/Compact）与表单宽度匹配
- [ ] 跨框校验不写进单框 handler（13.5.9 表单级）

## 13.6 小结

| 需求 | 写法 |
|------|------|
| 数值输入 | NumberBox：Value(double) + Header |
| 空态处理 | `std::isnan(Value())` 判空 |
| 步进 | SmallChange/LargeChange + SpinButtonPlacementMode |
| 算式输入 | AcceptsExpression="True" |
| 程序化改值 | 直写 Value，事件自动跟随 |

PreferencesPage 的 Default task count 用 NumberBox 承载"空输入=NaN=无限制"的真实语义：OnCountChanged 里 std::isnan 分支写 "default count = unlimited"，否则写具体数值；值随保存落盘。运行时证据见 `.smoke/07-settings-hub/save/tap-2.png`（NumberBox/DatePicker/TimePicker 同页可见）。

---

上一篇：[12 Slider、ProgressBar 族](./12-slider-progress.md) ｜ 下一篇：[14 ComboBox](./14-combobox.md) ｜ 返回 [目录](../README.md)
