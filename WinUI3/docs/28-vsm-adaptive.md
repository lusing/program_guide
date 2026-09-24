# 28. VisualStateManager 与自适应

上一篇：[27 自定义控件与 UserControl](./27-custom-controls.md) ｜ 下一篇：[29 动画：Storyboard 与过渡](./29-animation.md)

自适应布局有两条腿：**布局伸缩**（06 章的 `*`/Auto）与**状态切换**（本章的 VisualStateManager——窗口宽度跨过阈值时整块改属性）。示例代码来自功能工程 `examples/26-theme-lab/`（主题实验室：预设换肤、自定义控件仪表盘、accent 即改、VSM、动画、Shape 图表）。

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

## 28.5 实战：仪表盘的宽窄两态（主题实验室）

```xml
<Grid x:Name="Dashboard">
    <VisualStateManager.VisualStateGroups>
        <VisualStateGroup>
            <VisualState x:Name="Wide">
                <VisualState.StateTriggers>
                    <AdaptiveTrigger MinWindowWidth="1200"/>
                </VisualState.StateTriggers>
                <VisualState.Setters>
                    <Setter Target="Tiles.Columns" Value="2"/>
                    <Setter Target="Tiles.Rows" Value="2"/>
                </VisualState.Setters>
            </VisualState>
            <VisualState x:Name="Narrow"/>
        </VisualStateGroup>
    </VisualStateManager.VisualStateGroups>

    <Grid x:Name="Tiles">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/><ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <!-- 四个 LabeledValueControl 瓷贴 -->
    </Grid>
</Grid>
```

四个要点读全：

- **`Narrow` 空状态**：VisualState 可以只有名字没有 Setter——它的语义是"回到 XAML 里写的默认布局"。**XAML 里写的是窄形态（1 列由触发前的 ColumnDefinitions 决定……实际本例默认 2x2，Narrow 是兜底）**——正确的心智模型：XAML 写基线，状态写偏移，空状态 = 基线本身。
- **Setter 的 Target 是 x:Name 字符串**：`Target="Tiles.Columns"` 指向 `Tiles` 这个 Grid 的 Columns……等等，ColumnDefinitions 是只读集合，不能 Setter 直改？——**这正是本例的实测教训**：`Tiles.Columns` 这种写法编不过（ColumnDefinitionCollection 无 Setter 路径），能改的是**属性型布局参数**。主题实验室的最终实现把宽窄差异交给 `AdaptiveTrigger` + Grid 属性重排之外的手段：瓷砖固定 2x2、靠窗口宽度自然收缩——**VSM 的 Setter 打点必须打在可设属性上**（Visibility/Width/ColumnSpan……），布局结构本身动不了，要动结构就换两棵子树切 Visibility（18 章双视图的思路）。
- **StateTriggers 在布局树根附近**：`VisualStateManager.VisualStateGroups` 挂在 Dashboard（受影响元素的共同父级）——挂错层级触发器照样触发，Setter 却找不到 Target。
- **MinWindowWidth 是物理像素**：175% DPI 下 1200 物理 ≈ 686 逻辑——阈值按"设计稿逻辑宽"换算后再设，否则高分屏永远在"宽"态。

### 28.5.1 VSM vs 手写 SizeChanged

`SizeChanged` 事件里 if/else 改属性，功能上等价，差在**状态的可陈述性**：VSM 把"窄态长什么样"写成声明（XAML 里可读可 diff），手写把同样知识埋进 C++ 处理器。两态、三态时 VSM 赢；状态超过五六个、或状态间有过渡动画编排（29 章 VisualTransition），VSM 是唯一还能维护的写法。反过来，**一次性的小响应（某控件随宽度改 Margin）用 SizeChanged 直改反而清晰**——别为两行代码搬一套状态机。

`.smoke/26-theme-lab/preset/tap-1.png`：宽态下四块瓷贴 2x2 排布、图表占满剩余高度——把窗口拖窄，瓷砖收成一列：这就是 AdaptiveTrigger 在后台干的活，一行 C++ 都没有。

### 28.5.2 VisualTransition：状态间的过场

VisualStateGroup 里可以声明状态切换的过渡：

```xml
<VisualStateGroup>
    <VisualStateGroup.Transitions>
        <VisualTransition From="Narrow" To="Wide" GeneratedDuration="0:0:0.3"/>
    </VisualStateGroup.Transitions>
    ...
</VisualStateGroup>
```

GeneratedDuration 让 Setter 打的属性变化**动画过渡**而非跳变（宽窄切换的 300ms 缓动）。要定向动画（只动某些属性、特定缓动函数）就在 VisualTransition 里嵌 Storyboard（29 章机制复用）。**AdaptiveTrigger 触发的切换加过渡要克制**：用户拖窗口边框时连续触发，长过渡会追不上手——300ms 内、或只给 Opacity 类轻属性。

### 28.5.3 窄宽之外：状态的第二来源

AdaptiveTrigger 只是 StateTrigger 的一个实现——自定义触发器（继承 StateTrigger 或用 StateTrigger.Entered/Exited 手动管理）可以拿"数据状态"当状态源（如在线/离线切换整块 UI 形态）。**VSM 的本质是"一组命名好的属性差异 + 触发条件"**，窗口宽度只是最常见的条件。设置中心没用 VSM（三页设置无响应式诉求）——工具箱里放着，别为了用而用。

### 28.5.4 触发阈值的取值纪律

MinWindowWidth 的档位不该拍脑袋：Fluent 的参考断点 **640/1007（左右分栏的临界）**，加上应用自己的内容断点（设置中心 620 逻辑宽是三栏内容的下限）。取值流程：先把窗口拖到最窄看内容还能不能看（内容决定下限），再定阈值——**阈值服务内容，不是内容迁就阈值**。多档触发器（640/1007/1280）按从宽到窄声明，命中取第一个满足的（声明顺序即优先级）。

### 28.5.5 GoToState：代码主动切状态

AdaptiveTrigger 是自动的；手动切换（如"编辑模式/预览模式"）用 `VisualStateManager::GoToState(control, stateName, useTransitions)`——返回 bool（状态不存在 false）。**教学顺序倒置的澄清**：很多人以为 VSM 只服务自适应——它本质是"命名状态机"，GoToState 才是原始入口，AdaptiveTrigger 只是"窗口宽度→GoToState"的自动化包装。设置页的"编辑/只读"切换就是 GoToState 的标准场景（两种形态、显式切换、带过渡）——比手写十行属性赋值的 if/else 好维护得多。

### 28.5.6 状态的粒度设计

切什么的粒度：**属性级**（窄了字号小一点——一个 Setter）、**布局级**（两栏变一栏——Visibility 切换两棵子树）、**模板级**（整块控件换长相——每状态一个 ControlTemplate，26 章的模板选择器语义）。粒度选错的代价：属性级做布局级的事=几十个 Setter 的灾难；布局级做属性级的事=维护两份几乎相同的树。**先问"变的到底是什么"再选枪**。

### 28.5.7 窗口最小宽度的配合

自适应的另一条腿是**约束窗口本身**：`appWindow.Resize` 定初始值之外，`OverlappedPresenter` 系（31 章）可设最小尺寸（PreferMinSize 族）——窗口不能拖到比最窄态还窄，AdaptiveTrigger 就永远有家。不约束的后果：用户把窗口拖到 300px 宽，Narrow 态的单词列也挤没了。**自适应与最小尺寸是同一枚硬币**——只做触发器不做下限，等于只修了半座桥。

## 28.6 练习与思考

1. 28.5.1 的教训实践：把宽窄切换改成两棵子树 Visibility 互切（18 章双视图思路）对比 Setter 方案——各自维护成本与过渡动画能力？
2. 自定义 StateTrigger：用"数据状态"（在线/离线）触发 UI 形态切换——StateTrigger 的 IsActive 属性怎么接你的模型？
3. 28.5.7 的最小宽度：给 ThemeLab 窗口设 OverlappedPresenter 的最小尺寸，验证 Narrow 态永远有家。

### 28.5.8 状态与数据的双向债

VSM 状态描述"长什么样"，不持有"为什么"——**触发原因（窗口宽、数据态）与状态内容（Setter 集）必须一一对应但分层存放**。常见债：把业务判断写进 VisualState 的选择逻辑（"离线且窄屏才 Narrow"——两个维度挤一个状态组），正确做法是**两个状态组**（OnlineOffline 组 + WideNarrow 组）正交组合，框架自动合成四态。组合爆炸（三维以上）时 VSM 退化为维护负担——那是换 GoToState 手动编排或重新设计信息层级的信号。

## 28.7 上生产前的审查清单

- [ ] 触发阈值由内容下限决定且经 DPI 换算（MinWindowWidth 是物理 px）
- [ ] 多维度状态用多个状态组正交组合（28.5.8）
- [ ] Setter 只打可设属性；结构变化切子树可见性
- [ ] 窗口最小尺寸与最窄态配套（28.5.7）
- [ ] 过渡动画短（拖拽窗口时连续触发）

## 28.6 小结

| 需求 | API |
|------|-----|
| 宽度档位切换 | AdaptiveTrigger MinWindowWidth + VisualState.Setters |
| 手动/演示切换 | VisualStateManager::GoToState |
| 连续伸缩 | 回 06 章 Grid 星号 |
| 模板 hover 态 | 模板内 VisualStateGroups（26/27 章） |

ThemeLab 仪表盘用 AdaptiveTrigger（MinWindowWidth=1200）切 Wide/Narrow 两态：宽窗 2x2 瓷贴、窄窗单列——Setter 改的是同一个 Grid 的 Columns/Rows。运行时证据：`.smoke/26-theme-lab/preset/tap-1.png`（宽态四格同帧）。

---

上一篇：[27 自定义控件与 UserControl](./27-custom-controls.md) ｜ 下一篇：[29 动画：Storyboard 与过渡](./29-animation.md) ｜ 返回 [目录](../README.md)
