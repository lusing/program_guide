# 28. VisualStateManager 与自适应

上一篇：[27 自定义控件与 UserControl](./27-custom-controls.md) ｜ 下一篇：[29 动画：Storyboard 与过渡](./29-animation.md)

自适应布局有两条腿：**布局伸缩**（06 章的 `*`/Auto）与**状态切换**（本章的 VisualStateManager——窗口宽度跨过阈值时整块改属性）。示例来自画廊工程的 `VsmPage`（导航 **VSM** 项）。

## 28.1 状态模型

```xml
<Grid>
    <VisualStateManager.VisualStateGroups>
        <VisualStateGroup x:Name="WidthStates">
            <VisualState x:Name="WideState">
                <VisualState.StateTriggers>
                    <AdaptiveTrigger MinWindowWidth="900"/>
                </VisualState.StateTriggers>
                <VisualState.Setters>
                    <Setter Target="LayoutPanel.Orientation" Value="Horizontal"/>
                    <Setter Target="SideBlock.Visibility" Value="Visible"/>
                </VisualState.Setters>
            </VisualState>
            <VisualState x:Name="NarrowState">
                <VisualState.StateTriggers>
                    <AdaptiveTrigger MinWindowWidth="0"/>
                </VisualState.StateTriggers>
                <VisualState.Setters>
                    <Setter Target="LayoutPanel.Orientation" Value="Vertical"/>
                    <Setter Target="SideBlock.Visibility" Value="Collapsed"/>
                </VisualState.Setters>
            </VisualState>
        </VisualStateGroup>
    </VisualStateManager.VisualStateGroups>

    <StackPanel x:Name="LayoutPanel" Orientation="Vertical">
        <!-- main block / side block -->
    </StackPanel>
</VisualStateManager.VisualStateGroups>
```

三件套：**VisualStateGroup**（互斥容器）→ **VisualState**（命名的一组 Setter，注意 `Target=` 指向的是 x:Name 元素而非属性宿主类型）→ **StateTriggers**（谁来自动切换）。

- **AdaptiveTrigger**：`MinWindowWidth`（**逻辑像素**）——窗口宽度 ≥ 值时该状态激活。一组内多个触发器，**最大匹配者胜**；至少要有一个 `MinWindowWidth="0"` 兜底，否则没有触发器匹配时停留在上一个状态。
- 窗口 resize 时触发器实时重新评估（22 章 NavigationView Auto 模式的内部就是这个机制——那章的"别赌 Auto"坑同样适用于自制阈值）。

## 28.2 手动切换：GoToState

```cpp
void VsmPage::OnForceNarrow(IInspectable const&, RoutedEventArgs const&)
{
    VisualStateManager::GoToState(*this, L"NarrowState", false);
    StatusText().Text(L"state = narrow (manual)");
}
```

`GoToState(control, name, useTransitions)` 与触发器并存——手动设的状态会在下一次触发器评估时被覆盖。它也是**自动化验证与教学演示的抓手**（本页的 smoke 点击走这条路，不依赖 resize）。

## 28.3 断点策略

三档是惯例（窄/中/宽），阈值参考 Fluent 设计（`641` 上下是分水岭）：

| 档 | 典型行为 |
|----|---------|
| 窄 <640 | 单列、侧栏收 NavigationView（22 章）、次要块 Collapsed |
| 中 | 双列 |
| 宽 >1000 | 三列 / 侧栏常驻 |

**能伸缩就别切状态**——`*` 行列、Wrap 换行、相对定位覆盖大多数自适应；VSM 留给"结构性增减"（整块显隐、方向翻转）。两条腿配合：06 章负责连续形变，本章负责档位跳变。

## 28.4 与模板内 VSM 的关系

控件**默认模板内部**也有 VisualStateGroups（CommonStates: Normal/PointerOver/Pressed...）——26 章说"hover 视觉走 VSM"指的就是它。页面级的自适应 VSM 与模板内的状态 VSM 是两套实例，互不干扰；自定义控件换肤（27 章）时新模板要自带这些状态，否则 hover 无反馈。

## 28.5 实测坑位

1. **`Setter Target=` 写元素名**：不是属性路径语法，`Target="LayoutPanel.Orientation"`（元素名.属性），与 Style 里 `Property=` 的形态不同。
2. **兜底状态**：`MinWindowWidth="0"` 的状态必须存在。
3. **GoToState 的第一参数是控件**：页面里传 `*this`（Page 也是 Control）。
4. **状态里改不了非依赖属性**：Setter 只打 DP。
5. **阈值是逻辑像素**（22 章 DPI 教训的换算同理）。

## 28.6 小结

| 需求 | API |
|------|-----|
| 宽度档位切换 | AdaptiveTrigger MinWindowWidth + VisualState.Setters |
| 手动/演示切换 | VisualStateManager::GoToState |
| 连续伸缩 | 回 06 章 Grid 星号 |
| 模板 hover 态 | 模板内 VisualStateGroups（26/27 章） |

画廊 `VsmPage` 运行时证据：`.smoke/26-customization/vsm/click-2.png`——点击 Force narrow，布局变纵向、side block 折叠，状态行 **"state = narrow (manual)"**。

---

上一篇：[27 自定义控件与 UserControl](./27-custom-controls.md) ｜ 下一篇：[29 动画：Storyboard 与过渡](./29-animation.md) ｜ 返回 [目录](../README.md)
