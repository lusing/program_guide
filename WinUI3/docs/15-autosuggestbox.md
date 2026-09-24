# 15. AutoSuggestBox：搜索式输入

上一篇：[14 ComboBox](./14-combobox.md) ｜ 下一篇：[16 日期与时间族](./16-datetime.md)

`AutoSuggestBox` 是"能打字的下拉"：用户输入，你给建议。搜索框、@提及、命令面板都是它的形态。本章给出一套完整可抄的最小实现，并讲清防重入的关键机制。示例代码来自功能工程 `examples/07-settings-hub/`（设置中心：主题/密度/透明度即点即生效并持久化）。

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

## 15.5 实战：搜索真的跳页（设置中心）

NavigationView 自带一个 AutoSuggestBox 槽位——设置类应用把搜索放导航栏顶端是 Windows 11 的标准形态：

```xml
<NavigationView ...>
    <NavigationView.AutoSuggestBox>
        <AutoSuggestBox x:Name="SearchBox" QueryIcon="Find"
                        PlaceholderText="Search settings"
                        TextChanged="OnSearchChanged"
                        SuggestionChosen="OnSearchChosen"/>
    </NavigationView.AutoSuggestBox>
```

输入过滤与选中跳转：

```cpp
void MainWindow::OnSearchChanged(IInspectable const&,
    AutoSuggestBoxTextChangedEventArgs const& args)
{
    if (args.Reason() != AutoSuggestionBoxTextChangeReason::UserInput) { return; }
    auto box = Nav().AutoSuggestBox();
    std::wstring_view query(box.Text());
    auto hits = single_threaded_vector<IInspectable>();
    for (auto const& page : kPages)
    {
        std::wstring_view label(page[1]);
        if (query.empty() || label.find(query) != std::wstring_view::npos
            || query.find(label) != std::wstring_view::npos)
        {
            hits.Append(box_value(page[1] + L"|" + page[0]));
        }
    }
    box.ItemsSource(hits);
}

void MainWindow::OnSearchChosen(IInspectable const&,
    AutoSuggestBoxSuggestionChosenEventArgs const& args)
{
    // 建议格式 "Label|tag"：选了真的跳转对应分区
    std::wstring_view text(args.SelectedItem().as<hstring>());
    size_t bar = text.find(L'|');
    if (bar != std::wstring_view::npos)
    {
        NavigateTo(hstring(text.substr(bar + 1)));
    }
}
```

四个实战级细节：

- **`Reason()` 过滤是防重入的命门**：设置 `ItemsSource` 会再次触发 TextChanged（原因 `Programmatic`）——不过滤就是无限循环里闪死下拉。15.2 讲的机制在真实应用里不是优化，是正确性。
- **建议项是"显示|载荷"双段字符串**：用户看 Label，选中后拆出路由键。轻量做法不需要对象模型；建议变复杂时才升级成 runtimeclass（27 章）。
- **`hstring` 没有 find/substr**：一律 `std::wstring_view` 过桥（`std::wstring_view query(box.Text())` 零拷贝）。
- **键盘选中链路**：输入 → 下拉 → 方向键高亮 → 回车，`SuggestionChosen` 在回车时同样触发——鼠标用户和键盘用户汇合在同一个处理器。

`.smoke/07-settings-hub/search/tap-2.png`：输入 "Pref" → 建议列表出现 → 方向键+回车 → 页面真的切到 Preferences、导航选中项同步——搜索不是摆设，是第三条导航路径（另两条：点导航项、Ctrl+F 找设置名……好吧第三条是键盘 Tab，但搜索是唯一支持模糊意图的）。

### 15.5.1 QueryIcon 与空态

`QueryIcon="Find"`（放大镜）不只装饰——它是搜索框的可识别锚点，用户扫视页面时第一眼找它。没有图标的搜索框常被当成普通输入框。`PlaceholderText="Search settings"` 则回答"能搜什么"——**placeholder 写内容域，别写"请输入"**这种无信息量的客套。

### 15.5.2 与 ComboBox 的分界（14.5.3 的对侧）

AutoSuggestBox 不是"更好的 ComboBox"——它假设**选项集大到用户愿意打字**。设置中心三个分区本用不着搜索（一眼看完），放 AutoSuggestBox 是 Windows 11 设置形态的教学复刻；真实工程里它的启动条件是选项过十或记忆成本高（命令面板、@提及）。低于这条线，打字比点选贵——两三下的点击永远快于"切输入法-打字-选择"三段动作。

### 15.5.3 QuerySubmitted：回车不选建议时

用户打完字直接回车（没碰下拉）触发的是 `QuerySubmitted` 而非 SuggestionChosen——事件参数带 `Args.ChosenSuggestion()`（null 如果没选）。设置中心没处理它（回车=放弃搜索，可接受）；要做"回车选第一条"就在 QuerySubmitted 里 `if (!Args.ChosenSuggestion()) { 取 ItemsSource 首项走跳转; }`——浏览器地址栏就是这个行为。

### 15.5.4 防抖：搜索的节奏

设置中心三页的过滤瞬间完成，不用防抖；**真搜索（磁盘/网络）必须防抖**——每次击键都发起查询是自我 DDoS。模式：

```cpp
// TextChanged 里重置一个延迟任务，300ms 内的连续输入只留最后一个
m_searchDelay.Cancel();                       // 上一个待执行的作废
m_searchDelay = DispatchedAsync([&]{ ... });  // 32.7 协程版
```

协程版（`co_await resume_after(300ms)` + 检查代际标志）比 DispatcherTimer 干净；代际标志就是"我是第几次输入的查询"——await 回来时发现自己不是最新一代，直接 return。**防抖与 Reason 过滤互补**：Reason 挡程序化回环（15.2），防抖挡用户手速——两个都要。

## 15.6 练习与思考

1. 15.5.4 的防抖：给搜索加 300ms 延迟与代际检查。实测连打 "pref" 五个字符触发几次过滤？
2. 把建议项从 "Label|tag" 字符串升级成 runtimeclass（SearchHit{Name, Tag}）——模板怎么写？SuggestionChosen 里少了什么拆串代码？
3. QuerySubmitted（15.5.3）：实现"回车直接选第一条"，浏览器地址栏行为。

## 15.6 小结

| 环节 | API |
|------|-----|
| 过滤入口 | TextChanged + `Reason()==UserInput` |
| 给建议 | `ItemsSource(新集合)` |
| 收选择 | SuggestionChosen → `args.SelectedItem()` |
| 收提交 | QuerySubmitted → `args.QueryText()` |
| 自由文本 | QueryText 可能不在建议里，按搜索词处理 |

运行时证据：`.smoke/07-settings-hub/search/tap-2.png`——NavigationView 的内建 AutoSuggestBox 槽位输入 "Pref"，TextChanged 过滤出建议、方向键+回车触发 SuggestionChosen，真的导航到 Preferences 页（计数行显示跳转结果）。15.2 的 Reason 防重入机制在这里是真功能不是装饰。

---

上一篇：[14 ComboBox](./14-combobox.md) ｜ 下一篇：[16 日期与时间族](./16-datetime.md) ｜ 返回 [目录](../README.md)
