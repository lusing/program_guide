# 13. NumberBox：数值输入

上一篇：[12 Slider、ProgressBar 族](./12-slider-progress.md) ｜ 下一篇：[14 ComboBox](./14-combobox.md)

"输入一个数"看似 TextBox 加一行解析就够，实际暗藏着解析、步进、校验、空态四件事——`NumberBox` 把它们一次做完。示例来自画廊工程的 `NumberBoxPage`（左侧导航 **NumberBox** 项）。

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

## 13.6 小结

| 需求 | 写法 |
|------|------|
| 数值输入 | NumberBox：Value(double) + Header |
| 空态处理 | `std::isnan(Value())` 判空 |
| 步进 | SmallChange/LargeChange + SpinButtonPlacementMode |
| 算式输入 | AcceptsExpression="True" |
| 程序化改值 | 直写 Value，事件自动跟随 |

画廊 `NumberBoxPage` 运行时证据：`.smoke/07-controls-basic/numberbox/click-2.png`——点击 "Double it"，状态行 **"quantity = 2"**（1 → 2 的程序化路径 + 事件回环）。

---

上一篇：[12 Slider、ProgressBar 族](./12-slider-progress.md) ｜ 下一篇：[14 ComboBox](./14-combobox.md) ｜ 返回 [目录](../README.md)
