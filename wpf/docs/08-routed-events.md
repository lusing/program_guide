# 08 · 路由事件：事件沿树传播

> 对应示例：`examples/08_routed_events`（三层容器的隧道/冒泡可视化日志）

> **本章你将学会**：路由事件的三种策略、隧道与冒泡的传播路径、e.Handled 的截停语义、sender 与 OriginalSource 的区别。
> **前置章节**：[07 核心控件](07-controls.md)。

## 1. 为什么事件要"路由"

第 02 章的 `Button_Click` 里，`e` 的类型是 `RoutedEventArgs`——不是普通 EventArgs。因为 WPF 的多数事件是**路由事件（Routed Event）**：事件不在触发的元素上原地处理，而是**沿可视化树传播，途经的每个元素都有机会处理它**。

为什么这样设计？想一个问题：ListBox 里 1000 个条目，想响应"双击某条目"——给每个条目挂事件处理器？路由事件让**容器挂一次处理器，接住所有子元素的事件**：

```xml
<ListBox MouseDoubleClick="List_DoubleClick">...</ListBox>
```

双击发生在条目上，事件冒泡到 ListBox，处理器照常触发。1000 个条目，1 个处理器。

## 2. 三种路由策略

| 策略 | 命名规律 | 传播方向 | 例子 |
|---|---|---|---|
| 冒泡（bubbling） | 普通名 | 子 → 根，逐层上传 | `MouseDown`、`Click`、`MouseDoubleClick` |
| 隧道（tunneling） | `Preview` 前缀 | 根 → 子，提前到达 | `PreviewMouseDown`、`PreviewKeyDown` |
| 直接（direct） | 普通名 | 只到目标元素 | `TextBox.TextChanged`、`MouseEnter` |

隧道永远先于配对的冒泡触发（PreviewMouseDown → MouseDown），一对事件像"先侦察后行动"。

`08_routed_events` 示例把这个机制变成了肉眼可见的实验：Window → Border → Grid → StackPanel → Button 五层，每层都挂 `PreviewMouseDown`（隧道）和 `MouseDown`（冒泡），每次点击在日志里打出完整传播路径：

```text
隧道  Window.PreviewMouseDown   挂载点=MainWindow   源头=DeepButton
隧道  Border.PreviewMouseDown   挂载点=LayerBorder  源头=DeepButton
隧道  Grid.PreviewMouseDown     挂载点=LayerGrid    源头=DeepButton
隧道  Button.PreviewMouseDown   挂载点=DeepButton  源头=DeepButton
冒泡  Button.MouseDown          挂载点=DeepButton  源头=DeepButton
冒泡  Grid.MouseDown            挂载点=LayerGrid    源头=DeepButton
冒泡  Border.MouseDown          挂载点=LayerBorder  源头=DeepButton
冒泡  Window.MouseDown          挂载点=MainWindow   源头=DeepButton
路由  Button.Click              挂载点=DeepButton  源头=DeepButton
```

勾选示例里的"在中间层截停"复选框再点：日志停在 `Grid.PreviewMouseDown`——隧道在中间层被 `e.Handled = true` 截停，**后面所有阶段（含整个冒泡阶段）全部不再发生**。

## 3. sender 与 OriginalSource

同一次事件里两个"事件对象"不是一回事：

| | `sender` | `e.OriginalSource` |
|---|---|---|
| 是谁 | **挂处理器的元素** | **事件真正发生的元素**（可能是模板深处的零件） |
| 类型 | FrameworkElement | object（常是模板内部的 Border/TextBlock） |

在 ListBox 上挂 `MouseDoubleClick`：sender 是 ListBox，OriginalSource 是被双击的那行里的某个内部元素。定位"点了哪一行"的标准写法：

```csharp
private void List_DoubleClick(object sender, MouseButtonEventArgs e)
{
    var listBox = (ListBox)sender;
    // OriginalSource 可能是条目模板深处的零件，靠容器帮忙映射回条目
    var container = listBox.ContainerFromElement((DependencyObject)e.OriginalSource);
    var item = (Person)listBox.ItemContainerGenerator.ItemFromContainer(container);
    // ...
}
```

记法：**sender 是挂载点，OriginalSource 是源头**——写容器级处理逻辑时两个都要看。

## 4. e.Handled：截停与"偷看"

`e.Handled = true` 把路由截停，后续元素收不到。三条实用语义：

1. **屏蔽输入用隧道**：`PreviewKeyDown` 里 Handled=true，可以拦掉按键/粘贴——冒泡阶段根本不会开始
2. **Handled 后仍想处理**：某些控件（如 Button 吃掉 MouseDown 转发为 Click）会把事件标记已处理，导致外层收不到——附加处理时用 `AddHandler(MouseDownEvent, handler, handledEventsToo: true)` 强制接收
3. **Button 的 Click 是合成事件**：点按钮时 MouseDown 被 ButtonBase 拦下合成 Click——所以示例日志里点按钮能看到 `Button.Click`，却看不到 Grid/Border/Window 的冒泡 MouseDown（被按钮吃掉了）；右键点按钮则完整冒泡（右键不被 Button 处理）。这是初学者第一困惑源，跑一次示例就懂了

## 5. 事件还是命令？

第 02 章说过事件把界面和逻辑焊死，但不是所有事件都该消灭。分工口诀：**能想出对应"动词"的用命令，描述"状态变化"的用事件**。

- **"用户下了指令"**（点击保存、菜单打开文件）→ 命令（第 12 章）：命令带 CanExecute 自动置灰、可被多入口共享（按钮 + 菜单 + 快捷键）
- **"用户正在操作过程"**（拖动滑块、选择变化、双击某行）→ 事件，处理器保持薄：取参数 → 转发给逻辑

判断不了就先写事件（简单直接），等同一个动作出现第二个入口时再抽成命令——重构信号清晰。

## 6. 常见坑

**在事件里写业务逻辑**：`Click` 里算账存库——三个月后 300 行没法测试。事件函数只做"翻译"，不承载逻辑。

**搞混 sender 和 OriginalSource**：容器级处理器里用 sender 当"被点的元素"——拿到的是容器本身。见第 3 节的映射写法。

**TextChanged 不是路由事件**：它是普通 .NET 事件（直接路由），不能在父容器上统一处理；且委托类型不同，不能和 Click 共用处理器（示例画廊里专门有两个处理器对照）。路由事件才能容器统一挂。

**隧道里改 UI 状态又期望冒泡阶段看到**：隧道 Handled=true 后冒泡不发生，你在隧道处理器里改的状态"冒泡阶段永远看不到"——因为它不会来。

**订阅了没退订**：长生命周期对象（Application 级服务）订阅短生命周期控件的事件 → 控件被引用无法回收（内存泄漏）。反向订阅（窗口订阅服务）时在 `Closed` 里 `-=` 退订。

## 7. 实战建议

- 列表行级交互（双击、右键）一律挂容器级路由事件，条目模板保持零代码
- 拦截输入（热键、禁粘贴）用 Preview 系列 + Handled，比 KeyDown 事后补救干净
- 调试路由问题时学示例的做法：沿途每层打个日志，传播路径立刻显形
- 自定义控件需要对外通知时优先定义路由事件（`RoutedEvent.Register`），用户就能在任意层级挂——与依赖属性同为"控件级 API"的标配

## 自测

1. **隧道和冒泡各是什么方向、谁先触发？** —— 隧道根→子（Preview 前缀）先，冒泡子→根后。
2. **Grid.PreviewMouseDown 里 e.Handled=true 后会发生什么？** —— 路由在此截停：后续隧道元素与整个冒泡阶段都收不到该事件。
3. **sender 与 e.OriginalSource 各是什么？** —— sender 是挂处理器的元素；OriginalSource 是事件真正发生的元素（可能在模板深处）。
4. **为什么点 Button 看不到外层的 MouseDown 冒泡？** —— ButtonBase 拦截 MouseDown 合成 Click 事件，原事件被标记已处理。

---
上一章：[07 核心控件一览](07-controls.md) ｜ 下一章：[09 数据绑定基础](09-binding.md)
