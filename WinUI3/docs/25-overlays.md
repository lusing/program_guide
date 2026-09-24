# 25. TeachingTip、InfoBar 与 ToolTip

上一篇：[24 ContentDialog 与 Flyout](./24-dialogs-flyouts.md) ｜ 下一篇：[26 样式与控件模板](./26-styles-templates.md)

三种"不打断"的轻提示：TeachingTip（教学气泡）、InfoBar（条状通知）、ToolTip（悬停提示）。它们合起来覆盖了"要告诉用户点什么"的全部非模态场景。示例代码来自功能工程 `examples/07-settings-hub/`（设置中心：主题/密度/透明度即点即生效并持久化）。

## 25.1 TeachingTip：锚定的教学气泡

```xml
<Button x:Name="TipTarget" Content="Show teaching tip" Click="OnTipClicked"/>
<TeachingTip x:Name="Tip"
             Title="Did you know?"
             Subtitle="TeachingTip is non-modal: the app keeps working."
             CloseButtonContent="Got it"
             Target="{x:Bind TipTarget}"
             ActionButtonClick="OnTipAction"
             PreferredPlacement="Bottom"/>
```

```cpp
void OverlaysPage::OnTipClicked(IInspectable const&, RoutedEventArgs const&)
{
    Tip().IsOpen(!Tip().IsOpen());
    StatusText().Text(Tip().IsOpen() ? L"tip open" : L"tip closed");
}
```

- **`Target` 锚定**（`{x:Bind}` 指到任意控件）：气泡跟着目标元素走（窗口移动、布局变化）。不设 Target 则居中显示成"对话框形态"。
- **非模态**：应用照常可用（对照 24 章矩阵）。
- `Title`/`Subtitle`/`HeroContent`（顶部大图）/`ActionButtonContent + ActionButtonClick`（自定义动作按钮）/`CloseButtonContent`。
- **打开/关闭都是 `IsOpen`**——它常驻 XAML 树（对照 24 章 ContentDialog 的即建即销毁），"需要时开"是常规用法。
- **属性名是 `PreferredPlacement`**（元数据实测：`Placement` 不存在，XAML 编译器 WMC0011 Unknown member——本页开发时踩的原文）。

## 25.2 InfoBar：条状通知

```xml
<InfoBar x:Name="Notice" IsOpen="False" Title="Sync finished"
         Message="Everything is up to date." Severity="Success"
         IsClosable="True" CloseButtonClick="OnInfoBarClosed"/>
```

```cpp
// Cycle severity：Informational -> Success -> Warning -> Error
static InfoBarSeverity const severities[]{
    InfoBarSeverity::Informational, InfoBarSeverity::Success,
    InfoBarSeverity::Warning, InfoBarSeverity::Error,
};
m_severity = (m_severity + 1) % 4;
Notice().Severity(severities[m_severity]);
Notice().IsOpen(true);
```

- **`Severity` 四档**驱动左侧色条与图标（Informational 灰/Success 绿/Warning 黄/Error 红）——语义化通知的视觉语言，别拿它当装饰。
- `IsOpen` 控制显隐；`IsClosable` 给用户关闭叉；**常驻还是自动消失是 `IsOpen` 的事**（要自动消失自己起定时器关，35 章演示）。
- `ActionButton` 可以给一个响应动作（"重试"/"查看"）。
- `CloseButtonClick` 的 **args 是裸 `IInspectable`**（同 21 章 AddTabButtonClick——这族 Click 委托形状以生成代码为准）。

与 TeachingTip 的分工：**InfoBar 是"事件结果"**（同步完成、连接断开），**TeachingTip 是"能力介绍"**（教用户用功能）。

## 25.3 ToolTip：悬停提示

```xml
<TextBlock Text="hover me for a rich tooltip">
    <ToolTipService.ToolTip>
        <StackPanel MaxWidth="220" Spacing="4">
            <TextBlock FontWeight="SemiBold" Text="Rich tooltip"/>
            <TextBlock TextWrapping="Wrap" Opacity="0.7"
                       Text="A ToolTip can host any element tree, not just text."/>
        </StackPanel>
    </ToolTipService.ToolTip>
</TextBlock>
```

- `ToolTipService.ToolTip` 是**附加属性**：往任何元素上"贴"提示，不动元素本身的内容模型。
- **内容可以是任意元素树**（本页的富提示 = 标题 + 换行正文），不只是字符串——长解释、快捷键表都放得下。
- 时序由服务管理：悬停约 0.5s 出现（`InitialDelay` 等可调），鼠标移开即走。

> **自动化验证边界**：ToolTip 依赖真实悬停时序，ui-smoke 的合成点击不覆盖 hover；本节为"编译 + 元数据级"证据。TeachingTip/InfoBar 则已全程点击验证。

## 25.4 提示族总选型

| 要告诉用户… | 用 |
|-------------|-----|
| 必须做一个决定 | ContentDialog（24 章，模态） |
| 快捷操作入口 | Flyout（24 章） |
| 教一个功能 | TeachingTip（锚定 + 非模态） |
| 报告刚发生的事件 | InfoBar（severity 语义色） |
| 解释界面元素 | ToolTip（悬停） |
| 短暂 toast | 系统通知（超出控件范畴，34 章方向） |

## 25.5 实测坑位

1. **`PreferredPlacement` 不是 `Placement`**（25.1，WMC0011）。
2. **TeachingTip 不设 Target 会居中**——要"贴着控件讲"就别忘 Target。
3. **InfoBar 的 CloseButtonClick args 是 IInspectable**（25.2）。
4. **ToolTip 硬编码宽度**：富内容给 MaxWidth，不然长文本一条线拉到底。
5. **IsOpen 状态与视觉不同步**：程序化开关后读 `IsOpen()` 回报（本页 handler 的写法），别自己记账。

## 25.5 实战：两种轻提示都是真功能（设置中心）

### 25.5.1 InfoBar：保存反馈条

保存动作的确认不弹对话框（那是打断），而是浮层报平安：

```xml
<InfoBar x:Name="SavedBar" IsOpen="False" IsClosable="True"
         Severity="Success" Title="Saved"
         Message="Your changes are written to %LOCALAPPDATA%\SettingsHub\settings.json"/>
```

```cpp
void MainWindow::ShowSaved()
{
    SavedBar().IsOpen(true);
}
```

**IsOpen 是开关不是 Show()**——InfoBar 常驻布局位（收起时高度为零），开合是属性不是方法。调用方在 App 层（`Application::Current().as<App>().ShowSavedBar()`），三个页面共用一条反馈通道——**保存反馈的形态全应用统一**，这是"App 级方法 + 窗口级浮层"的小型分层。`IsClosable="True"` 给用户关掉的权利（不关也会在下次打开时重置）。`.smoke/07-settings-hub/save/tap-2.png`：进度充满 + 绿条 Saved 同帧。

**Severity 四档**（Success/Informational/Warning/Error）自带图标与配色，别手搓颜色——它们跟随主题且屏幕阅读器按 severity 朗读。

### 25.5.2 TeachingTip：只打扰一次

```xml
<Button x:Name="TipAnchor" Content="What is this page?" Click="OnTipClicked"/>
<TeachingTip x:Name="FirstRunTip"
             Title="Notification channels"
             Subtitle="Each channel can be turned on individually while the master switch is on."
             CloseButtonContent="Got it"
             Target="{x:Bind TipAnchor}"
             PreferredPlacement="Bottom"
             CloseButtonClick="OnTipClosed"/>
```

```cpp
// ctor：只在第一次进入时弹
if (SettingsStore::Get(L"seenTip", L"false") != L"true")
{
    FirstRunTip().IsOpen(true);
}

void NotificationsPage::OnTipClosed(IInspectable const&, IInspectable const&)
{
    SettingsStore::Put(L"seenTip", L"true");
    SettingsStore::Save();
}
```

**"只弹一次"是持久化状态**（seenTip 键 + 立即落盘）：重启不再打扰。关掉的认定放在 `CloseButtonClick`（点 Got it 才算看过）——light-dismiss（点外面）不落 seenTip，下次还教，这是教学语义的正确取舍。`Target` 锚定到按钮 + `PreferredPlacement="Bottom"`——气泡有明确指向物，不悬浮在真空里。

### 25.5.3 三件套的分工线

| | 打断吗 | 停留 | 关闭方 |
|---|---|---|---|
| ContentDialog（24 章） | 是——模态遮罩 | 直到用户三选一 | 按钮 |
| TeachingTip | 否 | 直到交互/关闭 | Got it / light-dismiss |
| InfoBar | 否 | 常驻到下次开合 | X（IsClosable） |

**信息紧急度走纵轴（打断力），解释义务走横轴（停留时长）**。"保存成功"不紧急且无需解释 → InfoBar；"这个页面怎么用"不紧急但需要读完 → TeachingTip；"有未保存修改，关闭吗"紧急且三选一 → ContentDialog。三者错位使用（拿对话框报成功、拿 InfoBar 问丢弃）都是对用户注意力的定价错误。

### 25.5.4 ToolTip 的延时与手势

ToolTip（本章第三件套）在功能应用里零代码出场——所有控件默认有内建提示（Button 显示 Label/Content）。自定义只有两种正当场景：**截断内容的完整版**（文件名 TextTrimming 后 ToolTip 给全文——DataExplorer 卡片该做没做，教学取舍）与**图标按钮的语义**（纯图标动作必配 ToolTip，否则图标是哑谜）。`ToolTipService.Placement` 控制方向；延时系统管（悬停 ~500ms）不用调。**别拿 ToolTip 传关键信息**——触屏没有 hover，它天然是桌面增强层。

### 25.5.5 通知的节流

InfoBar 若被高频触发（每次保存都弹）会训练出"自动无视"——反馈的价值随频率衰减。产品化方案：同类通知**合并**（"已保存 ×3"）或**静默降级**（保存成功只更新状态行，InfoBar 只在出错时弹）。设置中心的教学形态每次都弹——单用户低频场景无害；频次上来的产品里，25 章的三件套要配一条**通知策略**而不只是通知控件。

### 25.5.6 InfoBar 的自动超时（自制）

InfoBar 不内建自动关闭——常驻是默认语义（设置中心如此）。要"3 秒后自己消失"：打开时启协程 `co_await resume_after(3s)` 后 `IsOpen(false)`——**但错误类通知别自动关**（用户还没读完就消失是最差体验）。折衷：Info 类 3 秒、Success 5 秒、Warning/Error 常驻。协程持有 `get_strong()`（12.7.2 纪律）；页面销毁后回来时判空再操作。

### 25.5.7 通知的堆叠

多条通知同时到（连发保存）：InfoBar 单条覆盖——后到的顶掉先到的。要堆叠就自管 `StackPanel<InfoBar>`（列表化），或把频率降到自然单条（25.5.5 的节流）。**别用系统 Toast 凑数**：应用内状态用应用内通知（Toast 是"应用不在前台时的喊话"），混用会让用户在不同地方找同一件事的回声。

## 25.6 练习与思考

1. 25.5.6 的自动超时：实现 Info/Success 3-5 秒自关、Warning/Error 常驻。协程里页面销毁后回来判空的纪律（12.7.2）怎么写？
2. 给 TeachingTip 加"查看演示"按钮（ActionButtonContent）——点击后导航到示例页，Tip 关闭与 seenTip 落盘的顺序？
3. 统计设置中心一次完整操作流（改主题→改密度→保存）出现多少条反馈（状态行/InfoBar/视觉变化）——哪些冗余该删？

## 25.6 小结

| 控件 | 核心 API |
|------|----------|
| TeachingTip | Target/Title/Subtitle/IsOpen/PreferredPlacement/ActionButtonClick |
| InfoBar | Severity 四档/IsOpen/IsClosable/Title/Message |
| ToolTip | ToolTipService.ToolTip 附加属性 + 任意内容树 |

设置中心两种轻提示都是真功能：NotificationsPage 的 TeachingTip 只在首次进入弹（seenTip 键持久化，重启不打扰）；保存成功的 InfoBar（Severity=Success）由 ShowSavedBar 弹出。运行时证据：`.smoke/07-settings-hub/save/tap-2.png`——进度充满 + 绿条 "Saved" 同帧。

---

上一篇：[24 ContentDialog 与 Flyout](./24-dialogs-flyouts.md) ｜ 下一篇：[26 样式与控件模板](./26-styles-templates.md) ｜ 返回 [目录](../README.md)
