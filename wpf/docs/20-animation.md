# 20 · 动画

> 对应示例：`examples/20_animation`（变宽/缩放/缓动对比/永续动画四个实验）

> **本章你将学会**：动画的 From/To/By 模型、Storyboard 的组织、缓动函数、RepeatBehavior 与 AutoReverse、动画布局属性的性能取舍。
> **前置章节**：[04 依赖属性](04-markup-extensions-dp.md)、[14 EventTrigger](14-triggers.md)、[19 变换](19-drawing.md)。

## 1. WPF 动画的心智模型

WPF 动画一句话：**在一段时间内，把某个依赖属性的值从 A 平滑地改到 B，由时钟驱动、逐帧插值**。

```xml
<DoubleAnimation Storyboard.TargetProperty="Width"
                 From="120" To="260" Duration="0:0:0.4"/>
```

这条声明说了：目标属性 Width，从 120 到 260，用 0.4 秒。启动后动画系统每帧算当前时刻该是多少，替你写进属性（优先级压过一切，第 04 章的值优先级表）。

三个前提帮你看穿"什么能动画"：

1. 目标必须是**依赖属性**（动画是值优先级的一层）
2. 属性类型要有对应的 Animation 类：double→`DoubleAnimation`、颜色→`ColorAnimation`、点→`PointAnimation`、3D 值→`ThicknessAnimation`……最常用的是 Double
3. From/To/By 三选二：`From→To`（明确两端）、`To`（从当前值出发）、`By`（当前值 + 增量）

## 2. Storyboard：动画的容器与启动器

动画不能裸奔，要装进 **Storyboard**（可同时装多条、并行播放），再配一个**触发时机**。XAML 的标准三件套（第 14 章 EventTrigger 的主场）：

```xml
<Button Content="点我变宽" Width="120">
    <Button.Triggers>
        <EventTrigger RoutedEvent="Click">
            <BeginStoryboard>
                <Storyboard>
                    <DoubleAnimation Storyboard.TargetProperty="Width"
                                     From="120" To="260" Duration="0:0:0.4"/>
                </Storyboard>
            </BeginStoryboard>
        </EventTrigger>
    </Button.Triggers>
</Button>
```

`Storyboard.TargetName` 指定动画别人（变换对象是常见目标，见下节）；不写 TargetName 就作用在触发器所在的元素自己。窗口级的（如 Loaded 淡入）写 `Window.Triggers`。

同样的动画纯 C# 也能跑（示例第 3 区的三个下落球）——动画本质是给依赖属性挂插值器：

```csharp
var anim = new DoubleAnimation(0, 150, TimeSpan.FromSeconds(1.6))
{
    EasingFunction = new BounceEase { Bounces = 3, Bounciness = 1.8 },
};
move.BeginAnimation(TranslateTransform.YProperty, anim);   // ★ 一行启动
```

XAML 与 C# 的等价关系（第 03 章的老话题）在这又复现一次：**Storybard 不神秘，BeginAnimation 才是底层**。

## 3. 两个高频模式：动画 Width vs 动画变换

示例第 1、2 区做了一组对照实验，同一效果两种实现：

**动画布局属性（Width）**——直观但有代价：

```xml
<DoubleAnimation Storyboard.TargetProperty="Width" From="120" To="260" Duration="0:0:0.4"/>
```

Width 变化 → 触发**整个布局系统重排**（第 05 章 Measure/Arrange 重跑）——每帧一次，邻居跟着动，开销大。

**动画变换（ScaleTransform）**——不扰布局：

```xml
<Button.RenderTransform>
    <ScaleTransform x:Name="GrowScale"/>
</Button.RenderTransform>

<DoubleAnimation Storyboard.TargetName="GrowScale"
                 Storyboard.TargetProperty="ScaleX" From="1" To="2" Duration="0:0:0.4"/>
<DoubleAnimation Storyboard.TargetName="GrowScale"
                 Storyboard.TargetProperty="ScaleY" From="1" To="2" Duration="0:0:0.4"/>
```

渲染结果变形、**占位尺寸不变**（邻居纹丝不动）、纯渲染层操作——性能标准姿势。**口诀：动效优先动画变换（RenderTransform），布局属性动画只在"真要推开别人"时用**。这也是第 19 章"变换对象可以 x:Name"的兑现处。

## 4. 缓动函数：动画的"手感"

匀速（Linear）的动画机械生硬——真实世界的东西有惯性、会弹。**EasingFunction** 改变插值曲线：

```xml
<DoubleAnimation ...>
    <DoubleAnimation.EasingFunction>
        <BounceEase Bounces="3" Bounciness="1.8"/>
    </DoubleAnimation.EasingFunction>
</DoubleAnimation>
```

常用家族（示例第 3 区三个球并排下落，肉眼对比）：

| 缓动 | 手感 | 场景 |
|---|---|---|
| 无（Linear） | 匀速 | 进度条类"中性"动画 |
| `BounceEase` | 落地弹跳 | 掉落、投掷 |
| `ElasticEase` | 弹簧往复 | 强调、吸引注意 |
| `BackEase` | 先反向蓄力 | 按钮"弹出" |
| `CubicEase`/`QuadraticEase` 等幂曲线 | 先快后慢（EaseOut） | **默认推荐**：进出用 EaseOut/EaseIn |

`EasingMode`（EaseIn/EaseOut/EaseInOut）决定曲线用在哪段。经验法则：**进场 EaseOut、退场 EaseIn、转移 EaseInOut**，几乎不会错。

## 5. 重复、往返与永续

```xml
<!-- 永续循环：加载圈 -->
<DoubleAnimation Storyboard.TargetName="SpinAngle" Storyboard.TargetProperty="Angle"
                 From="0" To="360" Duration="0:0:1.2"
                 RepeatBehavior="Forever"/>

<!-- 往返脉冲：透明度 1↔0.3，Forever -->
<DoubleAnimation Storyboard.TargetName="PulseDot" Storyboard.TargetProperty="Opacity"
                 From="1" To="0.3" Duration="0:0:0.7"
                 AutoReverse="True" RepeatBehavior="Forever"/>

<!-- 指定次数 -->
RepeatBehavior="0:0:3"    <!-- 总时长 3 秒 -->
RepeatBehavior="2x"       <!-- 播 2 遍 -->
```

示例第 4 区的加载圈综合了第 19 章的形状 + 变换：两个同心 Ellipse，外圈的 `StrokeDashArray` 挖出弧段，`RotateTransform` 的 Angle 被 Forever 动画推着转——**"WPF 加载指示器"的最小实现**，值得背下来。

`FillBehavior="HoldEnd"`（默认）让动画停在终点值；`Stop` 则结束即还原。想"动画后值真的归你管"，用 HoldEnd 或代码里 SetValue。

## 6. 常见坑

**动画结束值"弹回去了"**：FillBehavior 默认就是 HoldEnd，但 `BeginStoryboard` 里动画被移除（如重复触发）时会还原——用 `x:Name` 的 Storyboard 手动控制，或动画后代码 SetValue 定格。

**动画 Width 卡顿**：布局属性每帧重排（第 3 节）。换 RenderTransform。

**Storyboard.TargetName 找不到变换对象**：变换对象定义在元素内部（如 `<Ellipse.RenderTransform>` 里）——同一名称作用域内 x:Name 可用，但模板内部的名字外面找不到（第 15 章），模板内动画要在模板内触发。

**缓动用在 From-By 模式上没反应**：缓动改的是"进度→值"的映射，From/To 正常生效；感觉"没反应"多半是 Duration 太短。

**动画与触发器打架**：属性正被动画驱动时，本地值/样式触发器改不动它（动画优先级最高，第 04 章）——先 `RemoveStoryboard`/`BeginAnimation(x, null)` 停动画再改。

**性能：满屏动画**。每条动画占用 UI 线程时钟；几十条并行 + 布局属性动画 = 掉帧。原则：能变换不布局、能短不长、能停不挂（不用就 Remove）。

## 7. 实战建议

- 动效三原则：**有目的**（引导注意力/提供反馈，不为炫）、**短**（0.2-0.4s 为主）、**可关闭**（系统"减少动画"设置应被尊重）
- 界面常用动画清单照抄：淡入（Opacity）、滑入（TranslateTransform）、展开（ScaleY）、加载圈（RotateTransform + Forever）——四个模板覆盖九成需求
- 状态切换优先 VisualStateManager/模板触发器（第 14、15 章）组织动画，EventTrigger 只做"一次性入场"
- 调动画时长时先改 Duration 再改缓动——多数"不舒服"是太长，不是曲线不对

## 自测

1. **动画能驱动什么属性？"To 动画"从哪出发？** —— 依赖属性；从当前值出发（From 省略时）。
2. **动画 Width 与动画 ScaleTransform 的本质差异？** —— 前者每帧触发布局重排；后者只变渲染不扰布局（推荐）。
3. **进场/退场/转移的缓动模式怎么选？** —— EaseOut / EaseIn / EaseInOut。
4. **加载圈的最小实现用到哪几件东西？** —— Ellipse + StrokeDashArray 弧段 + RotateTransform + Angle 的 Forever 动画。

---
上一章：[19 绘图与变换](19-drawing.md) ｜ 下一章：[21 异步与线程模型](21-async.md)
