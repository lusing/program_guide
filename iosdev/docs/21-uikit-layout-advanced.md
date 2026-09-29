# 21 · UIKit 布局进阶：autoresizingMask / VFL / 优先级 / 反推尺寸 / UIStackView

> 示例：`examples/21_uikit_layout_advanced/main.swift`
> 实测输出见 `build/21_uikit_layout_advanced/stdout.debug.txt`

第 14 章把 UIKit 布局的地基讲完了：三个几何量、anchor 式约束、布局循环、固有尺寸、安全区。
这一章补实战里绕不开的五块进阶内容——它们也是老项目（以及 Masonry / `TTTAttributedLabel`
那一类库）天天在用的东西：

```
autoresizingMask                 Auto Layout 之前的自适应机制，今天还活在 scroll view 内容里
translatesAutoresizingMaskIntoConstraints   两套系统之间的开关：frame 到底要不要变成约束
NSLayoutConstraint 原始形式 + VFL   七个参数的老写法，和一行字符串生成一串约束的写法
布局优先级                          固有尺寸和你写的约束打架时，靠 priority 裁决
systemLayoutSizeFitting / UIStackView   由约束反推尺寸；把一串约束换成一个对象
```

headless 说明：给容器 `frame`/`bounds`，`setNeedsLayout()` + `layoutIfNeeded()` 之后约束
**同步**求解完毕，子视图 frame 可以直接读回来断言。本章全程不建窗口、不弹 UI。

## 1) autoresizingMask：只有六个位，弹性的按比例、固定的保持点数

Auto Layout 之前，自适应靠父视图上的一个位掩码：告诉系统「子视图的哪条边距、哪个尺寸是弹性的」。

```swift
let header = UIView(frame: CGRect(x: 10, y: 20, width: 300, height: 100))
header.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
parentV.addSubview(header)

parentV.bounds = CGRect(x: 0, y: 0, width: 320, height: 800)   // 父变高
parentV.setNeedsLayout(); parentV.layoutIfNeeded()
header.frame          // (10, 20, 300, 100) —— 没动
```

```
-- autoresizingMask：父视图 bounds 变化时，子视图怎么跟着变 --
  flexibleLeftMargin=1 flexibleWidth=2 flexibleRightMargin=4
  flexibleTopMargin=8 flexibleHeight=16 flexibleBottomMargin=32
  [.flexibleWidth, .flexibleBottomMargin].rawValue = 34
  [].rawValue = 0
  场景 A：parent bounds 320x480 → 320x800
  header.frame   = (10.0, 20.0, 300.0, 100.0)
  centered.frame = (130.0, 380.0, 60.0, 40.0)
  bottomBar.frame = (220.0, 760.0, 100.0, 40.0)
  growBar.frame   = (220.0, 733.3333333333333, 100.0, 66.66666666666674)
  ok   header 纹丝不动：上边距和高度都是固定的，弹性的只有宽和下边距（父的宽没变）
  ok   centered 垂直居中：(800-40)/2 = 380
  ok   centered 的 x 没变（父的宽没变，左右 margin 都固定不变）
  ok   bottomBar 贴住新底边：800-40 = 760（下边距固定 0、高度固定）
  ok   bottomBar 右边仍贴父右边缘（右下 margin 固定）
  ok   growBar 高度也弹性 → 按比例缩放：40 × 800/480 = 66.66666666666674
  ok   growBar 底边仍贴父底边（固定项保持 0 个点）
  场景 B：parent bounds 320x480 → 640x480
  stretchy.frame      = (8.0, 8.0, 420.0, 44.0)
  huggingRight.frame  = (540.0, 8.0, 92.0, 44.0)
  ok   flexibleWidth：多出来的 320 宽全给了它（100+320=420）
  ok   只有宽弹性 → 高度不受影响
  ok   flexibleLeftMargin：左边距按比例放大 220 × (640-92-8)/(320-92-8) = 540
  ok   flexibleLeftMargin 保住右边距（右边仍留 8）
```

要点（这几条全部是上面实测出来的）：

- **Swift 里只有六个 case**：`flexibleLeftMargin=1`、`flexibleWidth=2`、`flexibleRightMargin=4`、
  `flexibleTopMargin=8`、`flexibleHeight=16`、`flexibleBottomMargin=32`。ObjC 的
  `UIViewAutoresizingNone` / `…WidthSizable` / `…HeightSizable` 在 Swift 里**不可用**，
  「什么都不弹性」要写 `[]`。
- **规则一句话**：标了 flexible 的那一项**按比例缩放**，没标的**保持绝对点数不变**。
  `growBar` 的高度 40 → 66.67（= 40 × 800/480）就是「高度弹性」的按比例结果；
  `bottomBar` 高度没标弹性 → 仍 40，于是底边贴住新底边 760。
- **`[.flexibleWidth]` 的语义是「跟着父的宽一起变」**：父从 320 变 640，100 长的子视图变 420
  ——增量正好等于父的增量。想让子视图贴右边，要标的是 `flexibleLeftMargin`（+ 不标宽）。
- 今天它的用武之地：`UIScrollView.contentSize` 里的内容、cell 内部的手写布局、
  以及 UIKit 自己给 `UITableView` 的 header/footer 用的自适应。

> **坑**：`flexibleTopMargin` 和 `flexibleHeight` 同时标，父变高时子视图会被**按比例拉长**
> （实测 40 → 66.67），而不是「贴在底部」。想要「贴底 + 等高」，只标
> `[.flexibleWidth, .flexibleTopMargin]`。

## 2) translatesAutoresizingMaskIntoConstraints：谁负责生成约束

这个布尔开关决定** frame 要不要被翻译成约束**。默认是 `true`——这正是「你明明加了约束，
界面却毫无反应」的第一原因：Auto Layout 引擎看到的是一堆由 frame 自动生成的 required 约束。

```
-- translatesAutoresizingMaskIntoConstraints：谁负责生成约束 --
  新建 UIView 默认 translatesAutoresizingMaskIntoConstraints = true
  ok   默认 true：frame 会被翻译成约束
  加入 stack 之前：beforeAdd.translatesAutoresizingMaskIntoConstraints = true
  加入 stack 之后：beforeAdd.translatesAutoresizingMaskIntoConstraints = false
  ok   addArrangedSubview 自动把 TAMIC 置 false（stack 负责给它加约束）
  TAMIC=false 且零约束，layout 之后 frame = (12.0, 34.0, 66.0, 88.0)
  ok   没有任何约束时 Auto Layout 不动它，frame 保持原值
```

要点：

- **手工加约束的视图必须先置 `false`**；`addArrangedSubview` 会替你置（实测前后 true→false），
  `UITableView`/`UICollectionView` 的 cell 内容视图也走类似机制——这就是为什么这些容器里
  不用你操心开关。
- 置了 `false` 又**一条约束都不给**：Auto Layout 不会凭空安排位置，frame 保持原值
  （实测 `(12, 34, 66, 88)` 原样留着）。所以在真机上「约束没生效」和「什么都没发生」
  经常是同一件事：**它的 frame 从没被任何约束驱动过**。

## 3) NSLayoutConstraint 原始形式：七个参数、属性号、关系号

anchor 写法（第 14 章）是糖。糖下面的原始 API 有七个参数，读老代码、看 Masonry 生成的
约束时绕不开：

```swift
let ratio = NSLayoutConstraint(item: box, attribute: .width, relatedBy: .equal,
                               toItem: box, attribute: .height, multiplier: 2, constant: 0)
let height = NSLayoutConstraint(item: box, attribute: .height, relatedBy: .equal,
                               toItem: nil, attribute: .notAnAttribute,
                               multiplier: 1, constant: 50)
NSLayoutConstraint.activate([leading, top, ratio, height])
```

```
-- NSLayoutConstraint 原始形式（Masonry / 老代码的写法）--
  box.frame = (12.0, 20.0, 100.0, 50.0)
  ok   宽=高×2 生效：高 50 → 宽 100
  height 约束：relation.rawValue=0 constant=50.0 priority=1000.0
  relatedBy 等号第二个 item 为 nil 时（写自身尺寸）：height.secondItem == nil → true
  ok   自身尺寸约束没有第二个 item（secondItem 为 nil）
  加了一条 box.trailing <= host3.trailing-10 之后 box.frame = (12.0, 20.0, 100.0, 50.0)（仍满足，不参与改变解）
  Relation 的 rawValue：lessThanOrEqual=-1 equal=0 greaterThanOrEqual=1
  ok   不等式约束被满足
```

要点（属性号/关系号都来自本章实测打印，见第 4 节的对照表）：

- **`multiplier` 是做宽高比的唯一手段**：`宽 == 高 × 2` → 高 50 解出宽 100。
- 写视图**自身尺寸**时 `toItem` 传 `nil`、`attribute` 传 `.notAnAttribute`（号 0）；
  断言 `height.secondItem == nil` 就是在确认这件事。
- **`relatedBy` 可以是不等式**，而且 `lessThanOrEqual` 的 rawValue 是 **-1**、
  `equal` 是 0、`greaterThanOrEqual` 是 1。别按「0/1/2」去猜——猜错就会把约束的
  方向写反，而反了方向的约束往往也能被满足，界面却全乱了。

## 4) VFL：一行字符串生成一串约束

Visual Format Language 把「一行/一列里的间距关系」写成一个字符串，一次生成多条约束。
`|` 是容器边缘，`[名字]` 是视图，`-数字-` 是间距，`metrics` 字典给数字起名。

```swift
let cs = NSLayoutConstraint.constraints(
    withVisualFormat: "|-16-[fa(==guideW)]-12-[fb(==40)]-16-|",
    options: [], metrics: ["guideW": 80], views: ["fa": fa, "fb": fb])
NSLayoutConstraint.activate(cs)
```

```
-- VFL：一行字符串生成一串约束 --
  水平串生成 5 条约束，垂直串 2 条
  fa 的那条：firstAttribute=.width relation.rawValue=0 constant=80.0 priority=1000.0
  容器宽正好 164：fa.frame = (16.0, 8.0, 80.0, 30.0)   fb.frame = (108.0, 0.0, 40.0, 0.0)
  ok   串里数字之和 == 容器宽 → 每条都被满足（含 V 串的 8/30）
  ok   fb 起点 16+80+12 = 108；高度完全没约束 → 解为 0
```

`metrics` 的两种写法 `(guideW)` 和 `(==guideW)` **实测等价**，都生成同一条
`width == 80`（优先级 1000）。真正的坑在下面两处。

### 坑一：串里的数字加起来不等于容器宽 → 某条约束被**悄悄打破**

同一条字符串，放进 320 宽的容器（16+80+12+40+16 = 164 ≠ 320）：

```
  同一个串放进 320 宽的容器：wa.frame = (16.0, 0.0, 236.0, 0.0)   wb.frame = (264.0, 0.0, 40.0, 0.0)
  ok   总长对不上时求解器打破其中一条（实测打破 wa 的 width==80，wa 被撑成 236）
  被打破的那条：constant=80.0 isActive=true priority=1000.0
  ok   约束对象既没被改也没被停用——它只是没被满足，这正是「布局错了却查不到报错」的根源
```

被打破的是 `wa.width == 80`，而 wa 被撑成 236；间距那一头也从 12 变成 32（264-232）。
**约束对象本身仍然是 `constant=80`、`isActive=true`、`priority=1000`**——它只是没被满足。

> **坑（很重要，且和常见说法相反）**：我们另外用两个探针单独验过——两条 required 硬冲突
> （同一视图 `width==100` 与 `width==200`），无论是在裸容器里还是在挂进 `UIWindow` 之后，
> UIKit **都没有往 stderr 打任何日志**（stderr 实测 0 字节），解出来的宽度是**先激活**的那条
> （100）。也就是说：本教程这种 headless 语境里，约束写错是**静默**的。别指望控制台帮你，
> 要靠断言（像本章这样把 frame 逐条打印出来）或 Xcode 的 Debug View Hierarchy。

补救办法：给一端留**弹性关系**，别把两端都钉成死数字——`-(>=12)-` 的意思是
「至少 12，多出来的空间归这一段」。

```
  |-16-[fla(==80)]-(>=12)-[flb(==40)]-| 解出 fla.frame = (16.0, 0.0, 80.0, 0.0)  flb.frame = (272.0, 0.0, 40.0, 0.0)
  ok   用 >= 关系给多余空间留出口，两条宽度约束都被满足
  逐条看这串约束（打印 item 类型 + 属性号 + 关系号，不带对象地址）：
  属性号对照：top=3 leading=5 trailing=6 width=7 height=8 notAnAttribute=0
    UIView#5 0 UIView#5 c=16.0
    UIView#7 0 nil#0 c=80.0
    UIView#5 1 UIView#6 c=12.0
    UIView#7 0 nil#0 c=40.0
    UILayoutGuide#6 0 UIView#6 c=0.0
  ok   其中正好 1 条的另一端是 UILayoutGuide（即父视图的 layoutMarginsGuide），就是末端那个不带数字的 -|
  ok   所以右边缘只到 312 = 320-8（默认 layoutMargins 是 8），不是 320
```

### 坑二：不带数字的 `-|` 钉的是 layoutMarginsGuide，不是父视图的边

上面那串第五条约束是 `UILayoutGuide#6 == UIView#6 c=0.0`——`-|` 生成的约束另一端是
**`UILayoutGuide`**（父视图的 `layoutMarginsGuide`），所以 `flb` 只走到 312 就停了
（320 - 默认 margins 8）。要钉真正的边，把数字写出来：

```
  末端改成显式 -0-|：zb.frame = (280.0, 0.0, 40.0, 0.0)
  逐条看这串约束：
    UIView#5 0 UIView#5 c=16.0
    UIView#7 0 nil#0 c=80.0
    UIView#5 1 UIView#6 c=12.0
    UIView#7 0 nil#0 c=40.0
    UIView#6 0 UIView#6 c=0.0
  ok   带数字的 `-0-|` 两端都是 UIView，没有任何一条指向 UILayoutGuide
  ok   显式 -0-| → 贴住父视图右边缘 320
```

VFL 也能表达不等式；`options` 则用来一次对齐一串视图：

```
  |-12-[atLeast(>=60)]（只有下限）解出 atLeast.frame = (12.0, 0.0, 60.0, 20.0)
  ok   >= 只给下限；没有上限约束时，另一端被 trailing 关系解到贴边
  alignAllCenterY：r2a.frame=(4.0, 15.0, 288.0, 0.0)  r2b.frame=(296.0, 15.0, 20.0, 0.0)
  ok   alignAllCenterY 让同串里的视图垂直中心线对齐（15.0 == 15.0）
```

`alignAllCenterY` 这类 option（Swift 里名字是 `NSLayoutConstraint.FormatOptions.alignAllCenterY`，
**不是** ObjC 的 `NSLayoutFormatAlignAllCenterY`——那个名字在 Swift 3 就被标为 obsoleted 了）
只在多视图同串时才有意义；单视图串里写它不会报错，但也没有效果。

## 5) 优先级：固有尺寸 vs 你写的约束，谁赢看 priority

第 14 章说固有尺寸「参与约束」。它参与的方式就是两条默认优先级：
**content hugging（抗变大）250**、**content compression resistance（抗变小）750**。

```
-- 优先级：固有尺寸 vs 你写的约束，谁赢看 priority --
  UILabel 默认 contentHugging(水平) = 250.0
  UILabel 默认 contentCompressionResistance(水平) = 750.0
  intrinsicContentSize.width = 39.0
  A) 宽度约束 @240（低于 hugging 250）→ 实际宽 = 39.0
  ok   A：240 < 250，固有尺寸赢，宽度仍是 intrinsic
  B) 同一条约束 @260（高于 hugging 250）→ 实际宽 = 120.0
  ok   B：260 > 250，宽度约束赢，label 被拉到 120
  tough.frame.width = 140.0   soft.frame.width = 56.0
  ok   required 的 140 宽保住
  ok   soft 被压缩到剩下的 200-140-4 = 56（它的宽度约束只有 500）
  ok   高优先级 + 高抗压缩的一侧赢
```

要点：

- **同一条约束只改 priority 就能翻盘**：240 时固有宽度 39 赢，260 时你写的 120 赢。
  这就是「让 label 优先贴文本、别被拉宽」的正解——把它的高度/宽度优先级调到 250 上下，
  而不是加一堆 required 约束再祈祷。
- **装不下时要有让步方**。例子里 `tough` 需要 140、`soft` 需要 120，容器只有 200：
  `soft` 的宽度约束只给 priority 500，于是它被压到 56，而 required 的 140 完好。
  若两条都给 required，就变成上一节那个**静默错乱**。
- 读 API 的名字要准：取是 `contentHuggingPriority(for:)` /
  `contentCompressionResistancePriority(for:)`，设是 `setContentCompressionResistancePriority(_:for:)`。
  **没有** `compressionResistancePriority(for:)` 这个 getter（编译不过）。

## 6) systemLayoutSizeFitting：由约束反推尺寸

正向是「给定约束 → 解出 frame」；这里问的是反向：「**锁死一个方向，问另一个方向该多大**」。
自适应行高（`UITableView` 的经典难题）就建在这一个方法上。

```swift
let fitting = cell.systemLayoutSizeFitting(
    CGSize(width: 200, height: UIView.layoutFittingCompressedSize.height),
    withHorizontalFittingPriority: .required,      // 宽度锁死
    verticalFittingPriority: .fittingSizeLevel)    // 高度自由作答
```

```
-- systemLayoutSizeFitting：让约束告诉我「该多高」 --
  宽锁 200（水平 required / 垂直 fittingSizeLevel）→ (200.0, 97.33333333333333)
  ok   水平 fitting priority = required → 宽度精确等于 200
  ok   垂直 fitting priority = fittingSizeLevel → 由内容撑出高度（97.33333333333333）
  layoutFittingCompressedSize（双向尽量小）→ (614.6666666666666, 36.333333333333336)
  ok   双向压缩时宽度不受限 → 文本排成一行，高度只剩一行
  layoutFittingExpandedSize（双向撑满）→ (614.6666666666666, 36.333333333333336)
  ok   撑满只是把无约束的方向放到 intrinsic 上限；垂直同受 intrinsic 单行限制 → 高度与压缩版相同
  同一套约束再算一次 = (200.0, 97.33333333333333)
  ok   反推是纯函数：同样的约束+宽度必然同样的高度（所以行高可以缓存）
  经典写法：cell 高度 = 探针 systemLayoutSizeFitting 的 97.33333333333333（本例：宽 200 的多行文本）
```

要点：

- 那 614.67 是「把这段中文排成一行」需要的宽度——**双向都问「最小」时，宽度是不受限的**，
  于是文本不折行，高度只剩一行（36.33）。想拿到多行高度，**必须**把水平 fitting priority
  提到 `.required` 并把宽度当作目标尺寸传进去。
- **反推是纯函数**：同样约束 + 同样宽度必然同样高度（实测两次完全相等）。这正是
  「用探针 cell 算一次、把高度缓存起来」能成立的依据。
- 自适应行高的标准配方（`UITableView` 时代）：
  1) 造一个和真实 cell 结构相同的探针视图（或直接用一个 offscreen cell），
  2) 给它完全一样的约束，
  3) `systemLayoutSizeFitting(width: 表宽, height: compressed)`，水平 required、垂直
     `fittingSizeLevel`，
  4) 把返回的高度交给 `heightForRowAt` / `estimatedRowHeight`。
  SwiftUI 的 `List`、`UICollectionViewSelfSizingInvalidation` 走的是同一套机制，只是不用你手写。

## 7) UIStackView：把一串约束换成一个对象

`UIStackView` 自己不画东西，它是一个**约束生成器**：`distribution` 管主轴怎么分配空间，
`alignment` 管交叉轴怎么对齐，`spacing` / `setCustomSpacing` 管段间距。

```
-- UIStackView：把一串约束换成一个对象 --
  arrangedSubviews.count = 3   subviews.count = 3
  stack.spacing = 10.0   distribution.rawValue = 0（0=fill 1=fillEqually 2=fillProportionally 3=equalSpacing 4=equalCentering）
  三个 UIView 的 contentHugging(水平) = 250.0/250.0/250.0
  fill（stack 两端钉死）：50.0/70.0/180.0
  ok   .fill：前面的视图保持自己的宽度约束
  ok   .fill：多余空间落到最后一个视图（90+90=180）
  fill（stack 只钉起点）：stack.frame=(0.0, 0.0, 130.0, 40.0)  50.0/70.0
  ok   起点钉住、宽度交给内容 → stack 宽 = 50+10+70 = 130，剩余空间是真的留白
  fillEqually：(320-2*10)/3 = 100.0，实际 100.0/100.0/100.0
  ok   .fillEqually：等宽，各自的宽度约束被覆盖
  equalSpacing：minX 0.0/105.0/230.0，宽 50.0/70.0/90.0
  ok   .equalSpacing：视图宽度不变，段间距相等（55.0 == 55.0）
  ok   .equalSpacing 不改变宽度
```

要点：

- **`.fill` 的「留白」取决于 stack 自己被怎么钉**：两端都被 required 钉成 320 宽时，
  内容只有 230，多出的 90 实测全部塞给了**最后一个**视图（90 → 180）；只钉起点时，
  stack 宽度交给内容（130），剩下的才是真留白。想留白就别把两端钉死。
- `.fillEqually` 会**覆盖**你给子视图写的宽度约束（实测三个 required 的 50/70/90 全变成 100）。
- `.equalSpacing` 只动间距、不动宽度（实测 50/70/90 原样，段间距都是 55）。

段间距、显隐、移除：

```
  setCustomSpacing(40, after: s1)：s1→s2 = 40.0，s2→s3 = 10.0
  ok   setCustomSpacing 只影响指定那个位置
  ok   其余位置仍用 stack.spacing
  s2.isHidden=true：arrangedSubviews.count=3 subviews.count=3 s3.minX=60.0
  ok   isHidden 不会把视图从 arrangedSubviews 摘掉
  ok   隐藏后 s3 前移：s2 既不占宽也不占间距（50+10=60）
  removeArrangedSubview(s3)：arrangedSubviews.count=2 subviews.count=3
  ok   removeArrangedSubview 只是不再管它，视图仍在 subviews 里（坑！它不会被移除，还会留在原位绘制）
  再 removeFromSuperview()：subviews.count=2
  ok   要真正移除必须 removeFromSuperview()
```

- **`isHidden = true` 才是「暂时不占位」的正确做法**（仍留在 `arrangedSubviews`，随时能恢复）。
- **`removeArrangedSubview` 不等于移除**：实测 `arrangedSubviews` 少一个、`subviews` 却没少——
  视图还挂在那里、还会被绘制，只是不再参与布局。两个都要调才算真删。

交叉轴上的对齐，以及「普通 UIView 在 stack 里会塌成 0」：

```
  无尺寸约束时：tall.frame=(0.0, 60.0, 200.0, 0.0) short.frame=(200.0, 60.0, 0.0, 0.0)
  ok   普通 UIView 无 intrinsicContentSize、又没给约束 → stack 里高度解为 0（看不见但不算报错）
  补上高度约束后：tall.frame=(0.0, 20.0, 200.0, 80.0) short.frame=(200.0, 50.0, 0.0, 20.0)
  ok   alignment=.center：交叉轴按中心线对齐（60.0 == 60.0）
  ok   stack 用的是自己 frame 给定的高度（这里由 frame 提供）
  alignment=.top：tItem.frame=(0.0, 0.0, 200.0, 30.0)
  ok   .top 把交叉轴贴到 stack 顶边
```

`UIView` 没有固有尺寸（`UILabel`/`UIButton`/`UIImageView` 才有），所以放进 stack 必须自己给
主轴或交叉轴的尺寸约束，否则解成 0——**不报错、不显示**，是最难查的一类「界面空白」。

内边距要显式打开开关：

```
  isLayoutMarginsRelativeArrangement=false（默认）：offItem.frame = (0.0, 0.0, 200.0, 100.0)
  ok   默认即使设了 layoutMargins 也不生效，首个 arranged subview 占满
  isLayoutMarginsRelativeArrangement=true：onItem.frame = (16.0, 12.0, 168.0, 76.0)
  ok   打开开关后才让出 16/12 边距（200-32=168 宽，100-24=76 高）
  fillProportionally：lab1.h=50.0 lab2.h=50.0
  ok   两个固有高度相同的 label 按比例分完 100 高
  改文本后：lab1.h=50.0 lab2.h=50.0
  ok   高度仍相等：固有**高度**没变，比例自然没变
```

`.fillProportionally` 是按**固有尺寸的比例**分配，所以只改文本内容（固有高度不变）
不会改变分配结果（实测仍是 50/50）。它和 `.fill` 的区别在容器装不下时才显现：
前者按固有尺寸比例压缩，后者直接压缩低 hugging 的那一个。

## 8) 布局时机与三种 guide

想知道「这一轮到底布局了没有」，Swift 里**没有公开的 `needsLayout` 属性**（ObjC 那个
`_needsLayout` 是私有 API）。可靠的办法是自己数 `layoutSubviews` 的次数：

```swift
final class LayoutCountingView: UIView {
    var passCount = 0
    override func layoutSubviews() { super.layoutSubviews(); passCount += 1 }
}
```

```
-- 布局时机：layoutIfNeeded 真的跑了几轮；三种 guide --
  host8.layoutMargins = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
  约束刚 activate、还没布局：v8.frame = (0.0, 0.0, 0.0, 0.0)，passCount=0
  第一次 layoutIfNeeded()：v8.frame = (8.0, 8.0, 44.0, 44.0)，passCount 0 → 1
  紧接着再来一次（中间没改任何东西）：passCount 1 → 1
  setNeedsLayout() + layoutIfNeeded()：passCount 1 → 2
  ok   activate 之后 layoutIfNeeded 真的跑了一轮布局（0→1）
  ok   没有脏标记时 layoutIfNeeded 不会重复布局（1→1）
  ok   setNeedsLayout 标脏之后才会再走一轮（1→2）
  ok   锚到 layoutMarginsGuide 时位置由 layoutMargins 决定（8.0）
  把 layoutMargins 改成 (24,32,24,32) 后 v8.frame = (32.0, 24.0, 44.0, 44.0)
  ok   layoutMargins 变 → layoutMarginsGuide 跟着变，子视图位置随之挪动
  readHost.layoutMargins = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
  锚到 readableContentGuide：readLabel.frame = (8.0, 0.0, 304.0, 20.0)
  ok   iPhone 竖屏下 readableContentGuide 基本等于整宽（iPad 上才会明显收窄）
  未挂窗口时：safeArea 锚点解出 g1.frame=(0.0, 0.0, 30.0, 30.0)   layoutMargins 锚点解出 g2.frame=(8.0, 8.0, 30.0, 30.0)
  ok   safeAreaInsets 与 layoutMargins 都为 0/未知时，safeArea 锚点从 (0,0) 起
  ok   layoutMarginsGuide 从 layoutMargins(8) 起，两者不是一回事
```

要点：

- `layoutIfNeeded()` **不是「强制重新布局」**，而是「**如果**这条子树脏了就把布局提前做掉」。
  实测第二次调用（中间没改任何东西）`passCount` 没变；标脏之后才 +1。想在改完约束后马上读
  frame，正确写法是 `setNeedsLayout()` + `layoutIfNeeded()`（或者约束激活后直接
  `layoutIfNeeded()`，实测它会跑第一轮）。
- **三种 guide 是三个不同的东西**：
  `safeAreaLayoutGuide`（让开刘海/Home 指示条，第 14 章）、
  `layoutMarginsGuide`（由 `layoutMargins` 决定，裸 `UIView` 默认四边 8）、
  `readableContentGuide`（正文可读宽度，iPhone 竖屏下几乎等于全宽，iPad 上才明显收窄）。
  实测同一父视图里锚到前两个的视图一个在 (0,0)、一个在 (8,8)——混用就会出现
  「明明没加边距却凭空偏了 8 个点」。

## 心智模型小结

```
autoresizingMask：六个 flexible* 位；弹性的按比例缩放，固定的保持绝对点数
TAMIC=true 时 frame 自己变成 required 约束；stack/table 会替你置 false
NSLayoutConstraint 原始形式 = 七个参数；relation 号是 -1/0/1，自身尺寸用 notAnAttribute(0)
VFL：串里的数字之和必须等于容器宽，否则某条 required 被**静默**打破；`-|` 钉 marginsGuide，`-0-|` 才钉边
priority：hugging 250 抗变大、compression resistance 750 抗变小；只调 priority 就能翻盘
systemLayoutSizeFitting：锁死一边问另一边；反推是纯函数，所以行高可缓存
UIStackView：distribution 管主轴、alignment 管交叉轴；留白要看 stack 自己被怎么钉
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 加了约束界面却不动 | `translatesAutoresizingMaskIntoConstraints` 还是 true，frame 生成的 required 约束压过你的约束 |
| VFL 排出来位置全乱，控制台干净 | 串里的数字之和 ≠ 容器宽，某条 required 被**静默**打破（实测 stderr 0 字节） |
| 视图右侧莫名少 8 个点 | VFL 末端用了不带数字的 `-|`，它钉的是 `layoutMarginsGuide`；改 `-0-|` |
| 用 `[.flexibleTopMargin, .flexibleHeight]` 想贴底，结果被拉长 | 两项都弹性时按比例缩放（实测 40→66.67）；贴底只标 `[.flexibleWidth, .flexibleTopMargin]` |
| `.fill` 的 stack 里最后一个视图变得很宽 | stack 两端被 required 钉死、内容总宽不足，多余空间落到最后一个视图 |
| `.fillEqually` 下自己写的宽度约束失效 | 被等宽分配覆盖（实测 50/70/90 全变 100） |
| 隐藏某个 arranged subview 后位置不回收 | 用了 `isHidden` 之外的做法；`isHidden=true` 才既不占宽也不占间距 |
| `removeArrangedSubview` 之后视图还在屏幕上 | 它只脱开布局管理，没离开 `subviews`；要再调 `removeFromSuperview()` |
| stack 里的 `UIView` 完全看不见 | 普通 `UIView` 无固有尺寸又没给约束 → 解为 0，且不报错 |
| 双向问 `layoutFittingCompressedSize` 得到怪异的巨大宽度 | 宽度方向没锁死，文本排成一行；把水平 fitting priority 设成 `.required` |
| 找不到 `compressionResistancePriority(for:)` | 真名是 `contentCompressionResistancePriority(for:)` |
| `.AlignAllCenterY` 编译不过 | Swift 3 起改名 `.alignAllCenterY`（ObjC 名已 obsoleted） |
| 以为有 `needsLayout` 可以读 | Swift 侧没有这个公开属性；自己数 `layoutSubviews` 次数 |
| 子视图凭空偏移 8 个点 | 混用了 `safeAreaLayoutGuide` 与 `layoutMarginsGuide`（后者默认 margins 8） |

## 小结

- `autoresizingMask` 的规则可以一句话讲完：**弹性项按比例缩放，固定项保持点数**；Swift 里
  只有六个 `flexible*` case，「固定」写 `[]`。
- `translatesAutoresizingMaskIntoConstraints` 是两套系统之间的开关；`addArrangedSubview`
  会替你置 `false`，裸视图用 Auto Layout 必须自己置。
- VFL 的两个静默陷阱（数字之和与容器宽不等、`-|` 钉 `layoutMarginsGuide`）在 headless
  语境里**不会有任何日志**——本章的断言方式（把解出的 frame 逐条打印）就是排查手段。
- 优先级是固有尺寸与人工约束之间的裁决机制；装不下一定要留一个非 required 的让步方。
- `systemLayoutSizeFitting` 把「约束 → frame」倒过来用，是自适应行高的全部原理，
  而且可缓存（实测纯函数）。
- `UIStackView` 是约束的封装：`distribution` / `alignment` / `spacing` 三者正交，
  内边距要额外开 `isLayoutMarginsRelativeArrangement`。

下一章离开「怎么摆」，进入「怎么滚、怎么组织整个界面」：**滚动视图、容器控制器与高级控件**。
