# 29. 动画：Storyboard 与过渡

上一篇：[28 VisualStateManager 与自适应](./28-vsm-adaptive.md) ｜ 下一篇：[30 图形与媒体](./30-drawing-media.md)

XAML 动画两条路：**Storyboard**（显式编排出帧）与 **Transitions**（隐式过场——属性变了自动播）。示例代码来自功能工程 `examples/26-theme-lab/`（主题实验室：预设换肤、自定义控件仪表盘、accent 即改、VSM、动画、Shape 图表）。

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

## 29.5 实战：换肤过渡动画（主题实验室）

预设切换时仪表盘跑一段 450ms 的"淡入+上移"，全程代码建 Storyboard：

```cpp
void MainWindow::PlaySkinTransition()
{
    anim::Storyboard storyboard;

    anim::DoubleAnimation fade;
    fade.From(0.2);
    fade.To(1.0);
    fade.Duration(Microsoft::UI::Xaml::Duration(
        Windows::Foundation::TimeSpan{ std::chrono::milliseconds(450) }));
    anim::Storyboard::SetTarget(fade, Dashboard());
    anim::Storyboard::SetTargetProperty(fade, L"Opacity");
    storyboard.Children().Append(fade);

    anim::DoubleAnimation slide;
    slide.From(18.0);
    slide.To(0.0);
    slide.Duration(Microsoft::UI::Xaml::Duration(
        Windows::Foundation::TimeSpan{ std::chrono::milliseconds(450) }));
    anim::Storyboard::SetTarget(slide, Dashboard());
    anim::Storyboard::SetTargetProperty(slide,
        L"(UIElement.RenderTransform).(TranslateTransform.Y)");
    storyboard.Children().Append(slide);

    // XAML 里没有 RenderTransform 占位，代码里补一个再动它
    Dashboard().RenderTransform(Microsoft::UI::Xaml::Media::TranslateTransform());

    storyboard.Begin();
}
```

七个实战级细节，全部实测：

1. **命名空间别名**：`namespace anim = Microsoft::UI::Xaml::Media::Animation;`——CppWinRTOptimized 裁投影后裸名 Storyboard 可能不存在（27.4），别名 + 全限定是最稳姿势。
2. **Duration 要三层包装**：`Duration(TimeSpan{ milliseconds(450) })`——Storyboard 的钟表是 `Microsoft::UI::Xaml::Duration`（结构体包 TimeSpan），直传 TimeSpan 编不过（C2665）。
3. **SetTargetProperty 吃 hstring 不吃装箱**：`L"Opacity"` 直传；`box_value(L"Opacity")` 反而 C2664。
4. **属性路径的圆括号语法**：`(UIElement.RenderTransform).(TranslateTransform.Y)`——先取 RenderTransform 属性再钻到 Y。XAML 里的等价写法是 `Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.Y)"`。
5. **RenderTransform 要先存在**：代码里给目标赋一个空 TranslateTransform 再动它——路径指向不存在的对象，动画静默不生效（不崩，就是没效果，最阴险的那种）。
6. **From/To 都给**：只给 To 时从当前值出发——连续快速换预设会从半途值起跳，视觉抖动；From 钉死起点，可重入。
7. **局部 storyboard 的生命周期**：栈上构造、Begin 后函数返回——Storyboard 持有动画的引用计数，Begin 后由时钟系统接管，不随局部变量销毁（这点与 WinRT 对象的默认计数语义一致，但值得点名，因为它反直觉）。

### 29.5.1 动画的两条路线怎么选

| | Storyboard（本节） | Transitions（隐式） |
|---|---|---|
| 触发 | 显式 `Begin()` | 属性被改即播 |
| 适用 | 一次性编排（换肤、入场） | 常态属性变化（Visibility/尺寸） |
| 代码量 | 多（逐动画建） | 一行 XAML（`<Grid.Transitions>`） |

**换肤为什么用 Storyboard 而不是 Transitions**：触发的不是单一属性变化（accent、主题、布局都可能变），Transitions 盯不住"一组变化"；Storyboard 是导演视角——"这 450ms 里仪表盘该干嘛"独立陈述，与换肤的具体内容解耦。

### 29.5.2 别动画的东西

动画的第一守则是**别动画用户没关心的东西**：换肤动画 450ms 讲"新皮肤到了"，但按钮 hover 变色加 300ms 就是拖累——高频微交互要即时。第二守则是**能停**：窗口关闭/页面导航时动画该打断就打断（Storyboard 的持有者销毁自然停），别为动画续命而续命。`.smoke/26-theme-lab/preset/tap-1.png` 捕捉在动画终点附近——终态即 29.5 的 From/To 里 To 的那一头。

### 29.5.3 缓动函数：动画的语气

`DoubleAnimation.EasingFunction` 决定中段曲线——线性（默认）是机器语气，人味的默认是 `CubeEase`（徐入徐出）。换肤动画没设缓动（450ms 短到线性无妨）；超过 600ms 的动画必须给 Ease（线性的长动画一眼假）。常用三件：`CircleEase`（圆滑收尾，入场）、`BackEase`（过冲回弹，强调）、`ExponentialEase`（急起缓收，退出）。口诀：**入场收着来、出场快着走、强调才弹**。

### 29.5.4 动画性能的边界

动画的帧率成本排在**布局类属性最贵**（Width/Height 触发整树重排）、**渲染类次之**（Opacity 走合成器）、**变换类最贱**（RenderTransform/TranslateTransform 纯矩阵）。换肤动画选 Opacity + TranslateTransform 正是按这个价目表点的菜——450ms 里零布局重排。反面教材是动画 Width：每帧全页 re-layout，低配机上动画本身变成卡顿源。**性能不是优化阶段的事，是选属性那一刻的事**。

### 29.5.5 Composition：动画的下下层

Storyboard 之下还有 Composition API（`ElementCompositionVisual`/`ScalarKeyFrameAnimation`）——在合成器线程跑、不走 UI 线程，适合永动动画（加载环、呼吸灯）与大量并行动画。分界：**交互驱动的属性动画用 Storyboard**（与布局系统协作），**装饰性高频动画用 Composition**（绕开 UI 线程）。31 章窗口篇的自定义标题栏按钮 hover 会碰到它的边缘；教程主线不深入——知道分界线在哪，需要时才知道往哪查。

### 29.5.6 From/To/By 的语义三角

三个属性给两个：From+To（绝对起终）、From+By（相对增量）、To+By（从当前到 To）——**只给 By = 每次从当前值再加**（可重入的累加动画，慎用）。全不给 = "回到基值"（动画逆放回 XAML 初值，做"弹出又收回"的另一半）。设置中心换肤动画给全 From+To（29.5 坑 6）是可重入的保险——连续换肤每次都从同一起点，视觉确定。

### 29.5.7 动画与数据绑定打架

动画临时改属性值，**期间绑定的 setter 不生效**（动画持锁）——To 动画结束后 HoldEnd（默认）会**永久占着属性**，绑定更新失效。解法：动画完播后手动清（`EnableDependentAnimation=false` 的独立动画不占）或动画只打"影子属性"（TranslateTransform 那种纯视觉层）再让布局属性归绑定管。换肤动画打 Opacity+Transform（都不绑数据）正是绕开此坑的选型——**绑定的属性交给绑定，动画打视觉层**，两世界互不越界。

### 29.5.8 关键帧与离散动画

`DoubleAnimation` 之外还有 `ObjectAnimationUsingKeyFrames`（离散值切换——状态点、图标替换）：KeyFrame 按 KeyTime 排布，到达即切值。**什么时候不用补间**：值空间不连续（图标 A→图标 B 没有"中间图标"）——补间属性（double/Color/Point 三种）之外全是离散域。主题实验室的柱子换色用 ColorAnimation 补间会很顺（red→blue 渐变），实测用了硬切（Fill 直接赋新画刷）——教学取舍：换肤的"啪"一下比 300ms 渐变更符合"应用了新预设"的确认感。**动画的品味问题最终是产品问题**。

## 29.6 练习与思考

1. 29.5.3 的缓动：给换肤动画加 CircleEase 与 BackEase 各跑一遍——哪个"更像系统"？把结论写成团队的动画规范一句话。
2. 29.5.7 的绑定打架：故意给 Dashboard.Opacity 加绑定再跑动画——观察 HoldEnd 后绑定失效，然后用手动清零修它。
3. Transitions 路线：把 InfoBar 的开合换成 Transitions（隐式）——一行 XAML 能替代你写的什么？

### 29.5.9 动画调试的三个抓手

动画"没跑"时按序查：①**Duration 为零或未设**（Begin 立即结束——换 3000ms 试）；②**属性路径错**（RenderTransform 路径打错不报错、静默不动——29.5 细节 5 的阴险面）；③**目标对象销毁**（页面导航走了，动画对着空引用播——get_strong 纪律）。第四个冷门：**EnableDependentAnimation**——动画影响布局（Width 类）时默认**被关**（省电策略），要 `EnableDependentAnimation(true)` 显式开。设置中心换肤动画打 Opacity/Transform（独立动画）不踩这条；动 Width 的人八成会莫名其妙一阵子。

## 29.5 小结

| 需求 | API |
|------|-----|
| 属性到值的动画 | Storyboard + DoubleAnimation（From/To/Duration/RepeatBehavior） |
| 时长 | `Xaml::Duration{ TimeSpan{ std::chrono::seconds(1) } }` |
| 进场/内容过场 | Transitions（ContentThemeTransition 等） |
| 页面切换过场 | Frame 上 NavigationThemeTransition |
| 性能 | Transform/Opacity 优先于布局属性 |

ThemeLab 换肤过渡是代码建 Storyboard 的活例：DoubleAnimation 一条管 Opacity 0.2→1.0、一条管 TranslateTransform.Y 18→0（450ms），CppWinRTOptimized 裁掉快捷名字后必须全限定 `Microsoft::UI::Xaml::Media::Animation::`（29 章实测坑）。运行时证据：`.smoke/26-theme-lab/preset/tap-1.png`。

---

上一篇：[28 VisualStateManager 与自适应](./28-vsm-adaptive.md) ｜ 下一篇：[30 图形与媒体](./30-drawing-media.md) ｜ 返回 [目录](../README.md)
