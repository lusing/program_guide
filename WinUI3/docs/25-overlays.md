# 25. TeachingTip、InfoBar 与 ToolTip

上一篇：[24 ContentDialog 与 Flyout](./24-dialogs-flyouts.md) ｜ 下一篇：[26 样式与控件模板](./26-styles-templates.md)

三种"不打断"的轻提示：TeachingTip（教学气泡）、InfoBar（条状通知）、ToolTip（悬停提示）。它们合起来覆盖了"要告诉用户点什么"的全部非模态场景。示例来自画廊工程的 `OverlaysPage`（导航 **Overlays** 项）。

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

## 25.6 小结

| 控件 | 核心 API |
|------|----------|
| TeachingTip | Target/Title/Subtitle/IsOpen/PreferredPlacement/ActionButtonClick |
| InfoBar | Severity 四档/IsOpen/IsClosable/Title/Message |
| ToolTip | ToolTipService.ToolTip 附加属性 + 任意内容树 |

画廊 `OverlaysPage` 运行时证据：`.smoke/21-controls-shell/overlays/click-3.png`——TeachingTip 弹出锚定按钮，点击 Cycle severity 后 InfoBar 打开绿色 Success 条，状态行 **"severity = success"**。

---

上一篇：[24 ContentDialog 与 Flyout](./24-dialogs-flyouts.md) ｜ 下一篇：[26 样式与控件模板](./26-styles-templates.md) ｜ 返回 [目录](../README.md)
