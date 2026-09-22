# 29. 动画：Storyboard 与过渡

上一篇：[28 VisualStateManager 与自适应](./28-vsm-adaptive.md) ｜ 下一篇：[30 图形与媒体](./30-drawing-media.md)

XAML 动画两条路：**Storyboard**（显式编排出帧）与 **Transitions**（隐式过场——属性变了自动播）。示例来自画廊工程的 `AnimationPage`（导航 **Animation** 项）。

## 29.1 Storyboard：显式动画

```cpp
void AnimationPage::OnAnimateClicked(IInspectable const&, RoutedEventArgs const&)
{
    if (!Bar() || !StatusText()) return;
    ++m_shots;

    winrt::Microsoft::UI::Xaml::Media::Animation::Storyboard sb;
    winrt::Microsoft::UI::Xaml::Media::Animation::DoubleAnimation widthAnim;
    widthAnim.From(40.0);
    widthAnim.To(320.0);
    widthAnim.Duration(winrt::Microsoft::UI::Xaml::Duration{
        winrt::Windows::Foundation::TimeSpan{ std::chrono::seconds(1) } });
    winrt::Microsoft::UI::Xaml::Media::Animation::Storyboard::SetTarget(widthAnim, Bar());
    winrt::Microsoft::UI::Xaml::Media::Animation::Storyboard::SetTargetProperty(widthAnim, L"Width");
    sb.Children().Append(widthAnim);
    sb.Begin();

    StatusText().Text(L"animated, shots = " + to_hstring(m_shots));
}
```

机制：

- **动画对象挂目标**：`SetTarget(anim, element)` + `SetTargetProperty(anim, L"Width")`（属性路径字符串）。XAML 里等价写法是 `Storyboard.TargetName/TargetProperty`。
- **`DoubleAnimation`**（double 属性）/`ColorAnimation`/`ObjectAnimationUsingKeyFrames`（离散关键帧，任意属性）；`From/To/By` 三选二，`RepeatBehavior`（次数/Forever）、`AutoReverse`、`EasingFunction`（缓动曲线）。
- **`Duration` 的类型是 `Microsoft.UI.Xaml.Duration`**——一个包着 TimeSpan 的结构（UWP 时代同名同构）。实测坑：直接塞 `Windows::Foundation::TimeSpan` 是 C2665（无重载可转换），必须外包一层 `Xaml::Duration{ TimeSpan{...} }`。
- 默认 **HoldEnd**：动画停在终值（本页 smoke 的判读依据——点击 2 秒后矩形仍宽 320）。

XAML 声明式等价物（动画作为资源，`BeginStoryboard` 由事件触发）在代码驱动场景用得少，C++ 工程按上面的事件构造最直接。

## 29.2 该不该动 Width？

**动画分"布局动画"与"渲染动画"两档**：

- **渲染档（优先）**：`RenderTransform`（平移/旋转/缩放）与 `Opacity`——合成器直出，不触发布局，60fps 无压力。
- **布局档**：`Width/Height/Margin`——每一帧都是布局重算。小元素、低频次可用（本页 40×320 的演示没问题），大范围持续动画会拖垮 UI 线程。

性能纪律：**能动 Transform 就不动布局属性**。

## 29.3 Transitions：隐式过场

```xml
<Border x:Name="FadeBox" ... Visibility="Collapsed">
    <Border.Transitions>
        <TransitionCollection>
            <ContentThemeTransition/>
        </TransitionCollection>
    </Border.Transitions>
    <TextBlock Text="transitions demo"/>
</Border>
```

`Transitions` 是"属性变化自动配戏"：`Visibility` 从 Collapsed 变 Visible，元素带主题过场出现——**不用写一行动画代码**。家族成员：`ContentThemeTransition`（内容出现）、`EntranceThemeTransition`（进场）、`NavigationThemeTransition`（Frame 页面切换过场，挂 Gallery 外壳的 Frame 上即得）、`PopupThemeTransition` 等。

与 Storyboard 的分工：**出场/进场/通用过场用 Transitions（白拿一致性）；精确控制时序用 Storyboard**。

## 29.4 实测坑位（本章工程实录密集）

1. **Duration 包 `Xaml::Duration`**（29.1，C2665）。
2. **`std::chrono_literals` 的 `1s` 字面量在本工程引发连锁解析失败**（C2760 系）——用 `std::chrono::seconds(1)` 显式构造最稳（工程级教训，可能与投影头交互有关）。
3. **`Media.Animation` 命名空间的 using 与 CppWinRTOptimized 投影裁剪**：冷门类型命名空间可能被裁掉（27.4 详述）——本页代码保留全限定名就是这道保险。
4. **动画目标属性必须是依赖属性**：普通 CLR 属性编不过（SetTargetProperty 校验）。
5. **Storyboard 可以重复 Begin**：第二次从头播；要做"只播一次"自己置标志。

## 29.5 小结

| 需求 | API |
|------|-----|
| 属性到值的动画 | Storyboard + DoubleAnimation（From/To/Duration/RepeatBehavior） |
| 时长 | `Xaml::Duration{ TimeSpan{ std::chrono::seconds(1) } }` |
| 进场/内容过场 | Transitions（ContentThemeTransition 等） |
| 页面切换过场 | Frame 上 NavigationThemeTransition |
| 性能 | Transform/Opacity 优先于布局属性 |

画廊 `AnimationPage` 运行时证据：`.smoke/26-customization/animation/click-2.png`——点击 Animate 约 2 秒后截图：矩形由 40 宽撑到 320（HoldEnd 终值），状态行 **"animated, shots = 1"**。

---

上一篇：[28 VisualStateManager 与自适应](./28-vsm-adaptive.md) ｜ 下一篇：[30 图形与媒体](./30-drawing-media.md) ｜ 返回 [目录](../README.md)
