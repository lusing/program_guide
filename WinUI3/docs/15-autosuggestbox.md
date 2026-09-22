# 15. AutoSuggestBox：搜索式输入

上一篇：[14 ComboBox](./14-combobox.md) ｜ 下一篇：[16 日期与时间族](./16-datetime.md)

`AutoSuggestBox` 是"能打字的下拉"：用户输入，你给建议。搜索框、@提及、命令面板都是它的形态。本章给出一套完整可抄的最小实现，并讲清防重入的关键机制。示例来自画廊工程的 `AutoSuggestPage`（左侧导航 **AutoSuggest** 项）。

## 15.1 三个事件，一条流水线

```text
用户输入 ──> TextChanged(Reason=UserInput) ──> 你过滤数据源 ──> 设 ItemsSource
                                                        │
用户点建议 ──> SuggestionChosen ──> 你收下选择            └─> 下拉自动弹出
用户回车   ──> QuerySubmitted ──> 你收下原文（可能没选任何建议）
```

```xml
<AutoSuggestBox x:Name="FruitBox" Header="Fruit" PlaceholderText="type 'ap'..."
                TextChanged="OnFruitTextChanged"
                SuggestionChosen="OnFruitChosen"
                QuerySubmitted="OnFruitQuerySubmitted"/>
```

## 15.2 过滤：Reason 是防重入的钥匙

```cpp
void AutoSuggestPage::OnFruitTextChanged(IInspectable const&,
    AutoSuggestBoxTextChangedEventArgs const& args)
{
    if (!FruitBox() || !m_allFruits) return;

    // 关键机制：Reason 区分用户输入与程序性变更（更新 ItemsSource 引发的
    // Text 变化是 Programmatic），防止"过滤 -> 设列表 -> 再过滤"的重入
    if (args.Reason() != AutoSuggestionBoxTextChangeReason::UserInput) return;

    auto text = FruitBox().Text();
    auto filtered = single_threaded_vector<hstring>();
    for (auto const& fruit : m_allFruits)
    {
        if (fruit.starts_with(text)) filtered.Append(fruit);
    }
    FruitBox().ItemsSource(filtered);
}
```

`AutoSuggestionBoxTextChangeReason` 三个值：`UserInput`（用户打字）、`Programmatic`（代码改 Text）、`SuggestionChosen`（选了建议后控件把建议文本填回框里）。

**为什么必须判 Reason**：选中建议时控件自动把建议文本写入 `Text` → 触发 TextChanged（Reason=SuggestionChosen）→ 如果你不过滤这个 Reason 再过滤一遍，会把刚选中的词当输入重新过滤，下拉又弹出来——"选完关不掉"的经典症状就是它。

过滤本身是普通集合操作：建一个新 `IVector<hstring>` 装命中项，整体替换 `ItemsSource`（不需要可观察集合——每次都是整体换）。

## 15.3 收结果：两个入口的语义差

```cpp
void AutoSuggestPage::OnFruitChosen(IInspectable const&,
    AutoSuggestBoxSuggestionChosenEventArgs const& args)
{
    if (!StatusText()) return;
    StatusText().Text(L"chosen = " + args.SelectedItem().as<hstring>());
}

void AutoSuggestPage::OnFruitQuerySubmitted(IInspectable const&,
    AutoSuggestBoxQuerySubmittedEventArgs const& args)
{
    if (!StatusText()) return;
    // 回车/提交：QueryText 是框里的原文（可能是没选建议的自由文本）
    StatusText().Text(L"query = " + args.QueryText());
}
```

- **SuggestionChosen**：用户点了某条建议，`args.SelectedItem()` 是你放进 ItemsSource 的那个对象（装箱 hstring 就 `as<hstring>()`）。
- **QuerySubmitted**：用户按了回车或点了搜索图标。`args.QueryText()` 是**框里的原文**——可能恰好等于某条建议（选完再回车会两个事件都走），也可能是不存在建议里的自由输入。**搜索场景以 QuerySubmitted 为主入口**，SuggestionChosen 用于"选完立即填充其他字段"。

## 15.4 与 ComboBox(IsEditable) 的最终分界

14 章的表格在这里落地：本页输 `ap` 弹出 apple/apricot——这是**数据在应用手里**的建议（前缀过滤）；ComboBox 的可编辑模式只是**定位已有项**。代码上的分野：AutoSuggestBox 的建议列表每次 TextChanged 你重新给；ComboBox 的项固定不变。

## 15.5 实测坑位

1. **不过滤 Reason = 重入循环**（15.2）：选完建议下拉复弹、"打一个字闪一下"。
2. **Chosen 后框内文本自动变**：控件帮你填了建议文本，别在 QuerySubmitted 里假设文本还是用户原打的。
3. **ItemsSource 整体替换**：别用可观察集合做增量增删——每次过滤都是全量结果，新集合最干净（17 章会讲什么时候才需要可观察）。
4. **自动化测试**：合成键盘输入（ui-smoke 的 `-TypeText`，VkKeyScanW + keybd_event）实测可驱动本控件——Text 事件带 Reason=UserInput 走真实路径。

## 15.6 小结

| 环节 | API |
|------|-----|
| 过滤入口 | TextChanged + `Reason()==UserInput` |
| 给建议 | `ItemsSource(新集合)` |
| 收选择 | SuggestionChosen → `args.SelectedItem()` |
| 收提交 | QuerySubmitted → `args.QueryText()` |
| 自由文本 | QueryText 可能不在建议里，按搜索词处理 |

画廊 `AutoSuggestPage` 运行时证据：`.smoke/07-controls-basic/autosuggest/click-2.png`——合成点击聚焦后键入 `ap`，下拉出现 **apple / apricot** 两条建议（TypeText 机制全链路验证）。

---

上一篇：[14 ComboBox](./14-combobox.md) ｜ 下一篇：[16 日期与时间族](./16-datetime.md) ｜ 返回 [目录](../README.md)
