# 09 · 数据绑定基础

> 对应示例：`examples/09_binding`（ElementName 直觉实验）

> **本章你将学会**：绑定要解决什么问题、绑定四要素、DataContext 继承、绑定方向与 UpdateSourceTrigger。
> **前置章节**：[04 依赖属性](04-markup-extensions-dp.md)、[07 核心控件](07-controls.md)。

## 1. 绑定解决什么问题

事件写法的死穴是**同步**：数据改了要手动刷新控件，控件改了要手动读回数据——每一处都要写，漏一处就是 bug。MFC 的 DDX 用 `UpdateData(TRUE/FALSE)` 手动触发两个方向的快照复制；WPF 的绑定则是一条**持续存在的管道**：

```text
        ┌──────────── TwoWay ────────────┐
        │                                ▼
   源（数据对象）                    目标（控件属性）
   Person.Name  ◄──────────────────  TextBox.Text
        ▲                                │
        └────────────────────────────────┘
   源变了 → 目标自动变；目标变了 → 源自动变。没有"触发"这个动作。
```

先做个零 ViewModel 的实验建立直觉（`09_binding` 示例）：两个 TextBlock 直接绑定到**别的控件**——

```xml
<TextBox x:Name="NameEntry" Text="Alice" />
<Slider x:Name="ValueSlider" Minimum="0" Maximum="100" Value="60" />

<TextBlock Text="{Binding ElementName=NameEntry, Path=Text, StringFormat='Hello, {0}!'}" FontSize="20" />
<TextBlock Text="{Binding ElementName=ValueSlider, Path=Value, StringFormat='{}{0}%'}" FontSize="18" />
```

拖动 Slider，数字实时变；在 TextBox 打字，问候实时变——**一行处理函数都没写**。Slider 的 Value 变化沿管道流进 TextBlock.Text，这就是绑定在"管数据"而不是"被打调"。

## 2. 绑定四要素

花括号里的完整语法（可全部缺省，但心里要有这张地图）：

```text
{Binding Path=..., Source=..., Mode=..., Converter=...}
```

| 要素 | 含义 | 缺省时 |
|---|---|---|
| `Path` | 源对象上的属性路径 | 绑定整个源对象 |
| `Source` | 源对象是谁 | 沿可视化树向上找 DataContext（第 3 节） |
| `Mode` | OneWay / TwoWay / OneTime / OneWayToSource | 由**目标属性**的元数据定默认值 |
| `Converter` | 两方向各自的值转换 | 直接类型转换 |

- **ElementName** 是 Source 的一种（绑定别的控件），另有 `RelativeSource`（绑定祖先/自身，第 17 章用例）和 `x:Static`
- **Path 支持子路径**：`Path=Address.City`；绑定自身元素用 `RelativeSource={RelativeSource Self}`
- **OneTime** 只取一次值，之后不再跟——性能最好的"静态绑定"

## 3. DataContext：绑定的隐形主角

不写 Source 时，绑定沿可视化树**向上找最近的 DataContext** 作为源：

```text
Window ── DataContext = MainViewModel ──────────────┐
 └─ Grid                                            │ DataContext 沿树继承
     └─ TextBox  Text="{Binding UserName}" ◄────────┘ 在 Window 上找到 VM，绑定 VM.UserName
```

所以实践中的标准姿势是：**窗口设一次 DataContext，整棵树都能绑**：

```csharp
public MainWindow()
{
    InitializeComponent();
    DataContext = new MainViewModel();   // 第 11 章的 MVVM 从这一行开始
}
```

DataContext 是依赖属性且支持值继承（第 04 章）——子元素可以覆盖它（列表条目里 DataContext 自动变成条目数据本身，第 15 章的关键机制）。

**绑定的目标必须是依赖属性，源可以是任何 .NET 属性**——控件端天然满足，数据端只要"会通知"（第 10 章 INPC）即可。

## 4. Mode：方向由目标属性决定

`Mode` 缺省值来自**目标属性注册时的元数据**（第 04 章的 PropertyMetadata）：

| 目标属性 | 默认方向 | 为什么 |
|---|---|---|
| `TextBlock.Text` | OneWay | 只展示，改它没意义 |
| `TextBox.Text` | **TwoWay** | 输入框要回写数据 |
| `ProgressBar.Value` | OneWay | 进度由数据驱动 |
| `CheckBox.IsChecked` | TwoWay | 勾选状态回写 |

拿不准就显式写 `Mode=`。特别的一档 `OneWayToSource`：目标 → 源单向，用于"把控件的只读状态喂给数据"这类反向场景。

## 5. UpdateSourceTrigger：TwoWay 回写时机

TwoWay 绑定里，**目标改了什么时候回写源**由 `UpdateSourceTrigger` 决定。多数属性默认 `PropertyChanged`（立即），但 `TextBox.Text` 默认 **LostFocus**（失焦才回写）——著名陷阱：

```xml
<!-- 默认：敲完字还要点一下别处，源才更新 -->
<TextBox Text="{Binding TaskName}"/>

<!-- 每敲一个字源立刻更新——"保存"按钮的状态、实时校验才跟得上 -->
<TextBox Text="{Binding TaskName, UpdateSourceTrigger=PropertyChanged}"/>
```

场景化理解：用户在 TextBox 打完字直接点"保存"，LostFocus 与 Click 几乎同时发生，你的保存命令读到的可能是**旧值**（回写还没发生）。第 16 章验证与第 25 章实战项目的输入框一律 `UpdateSourceTrigger=PropertyChanged`，就是防这个。

## 6. StringFormat：显示格式化

数据是数字/日期，显示要格式——不用写转换器，`StringFormat` 就是内置的 string.Format：

```xml
<TextBlock Text="{Binding Price, StringFormat='{}{0:N2}'}"/>          <!-- 1234.5 → 1,234.50 -->
<TextBlock Text="{Binding Price, StringFormat='￥{0:N2}'}"/>          <!-- ￥1,234.50 -->
<TextBlock Text="{Binding Ratio, StringFormat='{}{0:P1}'}"/>          <!-- 0.856 → 85.6% -->
<TextBlock Text="{Binding Born, StringFormat='{}{0:yyyy-MM-dd}'}"/>   <!-- 日期 -->
```

两条语法规则（第 04 章讲过转义）：格式串以 `{` 开头时前面加 `{}` 转义；整串含空格/花括号时外层单引号包住。类型对不上（给 Text 绑了个 List）时 StringFormat 救不了，显示的是 ToString 结果。

## 7. 常见坑

**绑定错误静默**：Path 拼错、DataContext 为 null——不抛异常，界面空白。先看输出窗口的 `BindingExpression path error`（第 10 章有完整排查清单）。

**以为 Mode 默认是 TwoWay**：不是。`TextBlock.Text` 默认 OneWay，把"显示框"当"输入框"绑 TwoWay 也常是误解。显式写 Mode 最稳。

**LostFocus 时机**：见第 5 节，输入框配命令一律加 `UpdateSourceTrigger=PropertyChanged`。

**`Text="{Binding}"`（无 Path）**：绑定整个 DataContext 对象——显示的是它的 ToString()。调试期可以这样偷看 DataContext 是谁，上线前删掉。

**ElementName 拼错**：与 Path 拼错一样静默——输出窗口找 `Cannot find source`。

## 8. 实战建议

- 学绑定的顺序建议：先把 `09_binding` 跑起来改改（加个 Slider 绑 ProgressBar）——**手感先行，理论跟上**
- 显示格式优先 StringFormat，类型转换才上转换器（第 10 章），数据端再造显示属性是最后手段
- 绑定表达式保持"短"：Path 超过两级（`A.B.C.D`）意味着中间任何一环为 null 都断链，考虑在 VM 层预加工
- 目标属性是不是依赖属性不用背——WPF 控件的公开属性几乎都是；自定义类要接绑定目标才需要自己注册（第 04 章选读节）

## 自测

1. **绑定与 DDX 式同步的本质区别？** —— 持续管道 vs 手动触发的快照复制。
2. **不写 Source 时绑定从哪找源？** —— 沿可视化树向上找最近的 DataContext。
3. **TextBox.Text 的两个"默认"分别是什么？各有什么坑？** —— Mode 默认 TwoWay（合理）；UpdateSourceTrigger 默认 LostFocus（输入框配命令/校验要改 PropertyChanged）。
4. **`StringFormat='{}{0:P1}'` 里的 `{}` 是干什么的？** —— 转义前缀：格式串以 `{` 开头时防止被解析成标记扩展。

---
上一章：[08 路由事件](08-routed-events.md) ｜ 下一章：[10 绑定进阶](10-binding-advanced.md)
