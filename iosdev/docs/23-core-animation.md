# 23 · 核心动画：CALayer、显式动画与特殊图层

> 示例：`examples/23_core_animation/main.swift`
> 实测输出见 `build/23_core_animation/stdout.debug.txt`

前面几章都在「视图」这一层：第 14 章的 `frame/bounds/center/transform`、第 21 章的布局、
第 22 章的滚动与容器。这一章往下走一层——**动画真正作用的对象是 `CALayer`，不是 `UIView`**。
`UIView` 只是层的一个包装：它的动画方法最终都是往自己的层（或某个子层）上挂 `CAAnimation`。

```
层的几何         frame / position / anchorPoint / bounds 四个量怎么互相推导
model 与呈现层   动画期间「值应该是多少」和「此刻显示多少」是两个对象
隐式动画         裸层改属性就会自己补一段动画，以及怎么关掉它
CABasicAnimation 三条给值路数（from/to、只给 to、byValue）+ fillMode + 重复 + keyPath 家族
时间与曲线        CAMediaTimingFunction、speed / timeOffset / beginTime 的暂停与恢复
CAKeyframeAnimation  values + keyTimes / calculationMode / 沿 CGPath 运动
组、转场、弹簧    CAAnimationGroup、CATransition、CASpringAnimation、UIView 动画接口
特殊图层          gradient / shape / text / replicator / emitter / tiled / scroll / transform
CATransform3D    全套自由函数、2D↔3D 互转、m34 透视
CATransaction    批量提交、completionBlock、CAAnimationDelegate 的两个回调
CADisplayLink    跟屏幕同步的节拍器
```

headless 说明与本章的方法论：本仓库的示例用 `xcrun simctl spawn` 直接跑一个可执行文件，
没有触摸、没有「看动画」。这章偏偏全是动画，所以先解决「**怎么把插值变成能核对的数字**」这件事：

1. `layer.speed = 0` 把这一层的时钟掐停——动画不再按墙钟推进；
2. `layer.timeOffset = t` 把这层的本地时间推到第 t 秒；
3. 改完必须等**一次真正的显示周期**，Core Animation 才会重算 presentation 层。
   示例里挂了一条 `CADisplayLink` 当节拍器（`displayPass()`），拿它的回调确认「屏幕真的刷新过一轮」。

三步都做齐，读数才既准确又可复现。少了第 3 步，读到的永远是动画起点；少了第 1 步，
读到的是墙钟值——同一个动画连读三次，两次运行分别是 `2.309/2.334/2.344` 与
`2.821/5.776/8.731`，既没法核对也没法做 debug/release 的逐字节比对。
下面每一个插值数字都是这么来的。

## 1) 层的几何：四个量、一个派生关系

`CALayer` 的几何由三个「真值」决定：`position`（锚点在父层坐标系里的位置）、
`bounds`（自己的坐标系：`size` 是多大、`origin` 从哪里开始）、`anchorPoint`（单位归一化坐标，
指 `position` 对应到 `bounds` 里的哪个点）。`frame` 是**派生出来的**：

```
frame.origin = position - (anchorPoint × bounds.size)
frame.size   = bounds.size
```

第 14 章在 UIView 上验证过这个关系，这里在层上把它走到底，并且把两个最容易踩的行为分开看。

```swift
let g = UIView(frame: CGRect(x: 40, y: 60, width: 100, height: 50))
gl.anchorPoint = CGPoint(x: 0, y: 0)      // 锚点挪到左上角
gl.anchorPoint = CGPoint(x: 0.5, y: 0.5)  // 复原
gl.bounds.origin = CGPoint(x: 10, y: 10)  // 只改内容坐标系原点
```

```
== 1) CALayer 的几何：frame / position / anchorPoint / bounds ==
  UIView(frame: 40,60,100,50) 的层：frame=(40.0, 60.0, 100.0, 50.0) bounds=(0.0, 0.0, 100.0, 50.0)
  position=(90.0, 85.0) anchorPoint=(0.5, 0.5) zPosition=0.0
  ok   position = frame 原点 + anchorPoint × size（100×50 → (90,85)）
  ok   anchorPoint 默认 (0.5, 0.5)
  ok   bounds 的 size 就是 frame 的 size，origin 默认 (0,0)
  把 anchorPoint 改成 (0,0)：position=(90.0, 85.0) frame=(90.0, 85.0, 100.0, 50.0)
  ok   改 anchorPoint 不动 position
  ok   frame 的原点被挪到 position —— 视觉位置跟着跳，这是 anchorPoint 最常见的坑
  设 bounds.origin=(10,10) 之后：frame=(40.0, 60.0, 100.0, 50.0) position=(90.0, 85.0)
  同一个数字换到**裸 CALayer** 上：frame=(40.0, 60.0, 100.0, 50.0) position=(90.0, 85.0)
  ok   bounds.origin 不会写回 frame/position 的 getter —— 它挪的是层内部的坐标原点（内容偏移），别拿它当位移用
  zPosition=0.0 anchorPointZ=0.0（CALayer 没有 zIndex / sublayerStyle 这两个属性）
  两个同尺寸子层：sublayers 里 sub2 的下标=1（后加的在后面，重叠时盖住前一个）
  sub1.zPosition=5 之后 sublayers 顺序没变（下标仍是 0）—— zPosition 只改绘制次序，不重排数组
  ok   zPosition 不动 sublayers 数组本身
```

要点：

- **`anchorPoint` 改的是「层围绕哪个点摆」**。默认 `(0.5,0.5)` 时 `position` 是层中心；
  改成 `(0,0)` 后 `position` 仍是同一个点 `(90,85)`，但那个点现在代表左上角，于是 `frame.origin`
  跟着从 `(40,60)` 跳到 `(90,85)`——**层会在屏幕上跳一下**。做「绕某个角旋转」时要先想清楚这一点：
  改锚点会让位置变，补偿办法是改完锚点再把 `position` 挪回去。
- **`bounds.origin` 不写回 `frame`/`position`**。视图层和裸层实测都一样：`(10,10)` 设进去之后
  `frame` 仍读回 `(40.0, 60.0, 100.0, 50.0)`、`position` 仍是 `(90.0, 85.0)`。
  它改的是层内部坐标系的原点，效果是**内容相对边框偏移**，不是把层挪走。
  需要「挪层」就改 `position`；`bounds.origin` 是第 22 章里 `UIScrollView` 用 `contentOffset`
  滚内容的那个机制——探针实测把某个层 `bounds.origin` 设成 `(10,10)` 之后，
  包着它的滚动视图 `contentOffset` 正好读到 `(10.0, 10.0)`。
- **`zPosition` 只改绘制次序，不重排 `sublayers` 数组**。默认重叠子层是「后加的盖前面的」，
  给前面那个设 `zPosition = 5` 之后数组下标还是 0。所以别用 `sublayers` 的下标推断谁在上面。
- `CALayer` **没有** `zIndex`、`sublayerStyle` 这两个属性（Swift 里直接编译不过）。
  想控制遮挡次序只有 `zPosition`（CGFloat，可以是负数）和 `masksToBounds` 之类的结构性手段。

层的其它默认值一次读全，后面调动画时拿它当对照表：

```
    opacity=1.0 isHidden=false masksToBounds=false allowsGroupOpacity=true
    isDoubleSided=true isGeometryFlipped=false contentsAreFlipped()=true
    contentsGravity=resize contentsScale=1.0 contentsRect=(0.0, 0.0, 1.0, 1.0)
    minificationFilter=linear magnificationFilter=linear
    borderWidth=0.0 shadowOpacity=0.0 shadowRadius=3.0 shadowOffset=(0.0, -3.0)
    shouldRasterize=false rasterizationScale=1.0 contentsFormat=RGBA8
    cornerRadius=0.0 cornerCurve=continuous isOpaque=false style=nil
  ok   shadowRadius 默认 3、shadowOffset 默认 (0,-3)（但 shadowOpacity=0 所以看不见）
  ok   contentsFormat 默认 RGBA8Uint（rawValue 显示成 RGBA8），cornerCurve 默认 continuous（iOS 13 起）
    挂进 3× 屏的窗口并跑一轮显示之后：layer.contentsScale=1.0，UIScreen.main.scale=3.0
  ok   contentsScale 不会因为挂进窗口自动变成屏幕 scale，要画 3× 位图得自己设
  ok   UIView.center 与 layer.position 是同一个值
```

三个容易看漏的默认值：`shadowRadius` 默认是 3（不是 0）、`shadowOffset` 默认 `(0,-3)`
（向上偏！），只是 `shadowOpacity` 默认 0 才让它们看不见；`contentsScale` 默认 1.0，
**不会**因为挂进 3× 屏的窗口就自动变成 3——往层上贴位图时不设它，图就会糊。

> **坑**：`contentsAreFlipped()` 在裸层、视图层、视图层的子层上实测**都返回 true**，
> 别拿它当「我是不是在翻转坐标系里」的探针；判断坐标系方向要看 `isGeometryFlipped`（默认 false）
> 以及父层是不是 `UIScrollView` 这类会改 `bounds.origin` 的层。

## 2) model 层与 presentation 层：动画跑完为什么会弹回

这是 Core Animation 最核心的一张图：每个层都有两份几何。

- **model 层**：你读写的那个 `CALayer` 对象，存「这个值应该等于多少」。
- **presentation 层**：`layer.presentation()` 拿到的副本，存「这一帧实际显示成多少」。
  它只在动画进行中存在，且**只在显示周期里被重算**。

```swift
let m = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
host.addSubview(m)
displayPass()                                  // 先让它真的显示过一轮
UIView.animate(withDuration: 0.5) { m.center = CGPoint(x: 150, y: 150) }
// animate 返回之后立刻读
```

```
== 2) model / presentation：动画期间「真实值」与「显示值」不是一回事 ==
  UIView.animate 调用**返回之后**：model center=(150.0, 150.0)，layer.position=(150.0, 150.0)
  ok   animate 的 block 一执行完，model 层就已经是终点值
  此时 animationKeys=Optional(["position"])，presentation() 是否存在=true
  ok   UIView.animate 改 center → 层上挂的动画 key 是 position
  ok   已经显示过的层，animate 一返回就有 presentation 层（没显示过的层要等一轮显示才有，见下面第 3 段）
  跑一轮显示之后 presentation() 存在=true
    ↑ 中间值本身由墙钟决定（探针实测同一段代码两次运行分别是 20.2253 与 20.1564），所以这里不打印它
  ok   动画进行中 presentation 层在
  动画结束之后：animationKeys=nil presentation 存在=true
  ok   动画自然结束后 key 自动消失（isRemovedOnCompletion 默认 true）；注意要跑过显示周期才收尾
```

于是能解释两个「教科书上说要弹回来」的现象：

1. `UIView.animate` 的 block 是**同步执行**的，所以 block 一跑完，model 层已经是终点值
   （`center=(150.0, 150.0)`），而屏幕上还在半路——这就是为什么在 `completion` 之前的任何时刻读
   `view.center` 都读到终点，而截图截到的是中间态。
2. 反过来，`CABasicAnimation`（下一节）是**只写 presentation 的**：动画跑完、被移除，
   presentation 消失，层回到 model 的值。model 从没被改过，所以画面「弹回原地」。
   要避免弹回，两条路：动画结束前把 model 也设成终点值（通常放在 `completion` 或事务里），
   或者设 `isRemovedOnCompletion = false` + `fillMode = .forwards` 让它保持终点。

`animationKeys()` 是这一节最实用的调试入口：它列出层上现在挂着哪些动画，`nil` 表示没有。
注意实测的两条边界：
`UIView.animate` 挂的 key 就是**被改的属性名**（改 `center` → `["position"]`），
而动画「跑完」这件事本身要等一个显示周期才会反映到 `animationKeys()` 上。

现在用冻结时钟把插值变成确定数字。先把层冻住（`speed = 0`）再加动画，然后逐个把 `timeOffset`
拨到 0 / 0.25 / 0.5 / 0.75 / 1.0：

```swift
let fz = animLayer { basic("position.x", 20.0, 300.0) }   // speed=0 + add + 预热两轮显示
for t in [0.0, 0.25, 0.5, 0.75, 1.0] {
    let x = sample(fz, at: t).position.x                  // 拨 timeOffset → 等一轮显示 → 读 presentation
}
```

```
  —— 把层的时钟冻住，插值就变成可以核对的确定数字 ——
    timeOffset=0.0 → presentation.position.x=20.0000（model 仍是 20.0000）
    timeOffset=0.25 → presentation.position.x=90.0000（model 仍是 20.0000）
    timeOffset=0.5 → presentation.position.x=160.0000（model 仍是 20.0000）
    timeOffset=0.75 → presentation.position.x=230.0000（model 仍是 20.0000）
    timeOffset=1.0 → presentation.position.x=299.9997（model 仍是 20.0000）
  ok   线性插值：0/0.25/0.5/0.75/1.0 → 20/90/160/230/≈300（终点是 299.9997，浮点插值差一点点）
  ok   显式动画不会改 model —— 这是「动画跑完就弹回」的根因
```

`20 → 300` 的动画，`duration=1`：t=0.25 应该走 25% 的距离，即 `20 + 280×0.25 = 90`——
实测逐点吻合，五个读数精确到四位小数。t=1.0 读到 `299.9997` 而不是 `300.0000`：
插值终点不保证正好落在 `toValue` 上，写断言时别要求绝对相等（本仓库统一按四位小数比字符串）。

第三步是这套方法里最容易被忽略的一环。示例专门用「四级台阶」把它的必要性演示了一遍：

```
  —— 为什么必须等一次真正的显示周期（四级台阶） ——
    第 1 级：add 完一次显示都没跑，presentation() 存在=false，
             同一行代码连读三次 → 1.0000 / 1.0000 / 1.0000（拿到的是 model 的 1.0，不是插值）
    第 2 级：预热两轮显示之后 presentation 存在=true，读回 0.2000
             —— 是动画起点（timeOffset 还是 0），说明 presentation 是被显示周期算出来的，不是被读出来的
    第 3 级：把 timeOffset 拨到 0.5 之后**立刻**读 → 0.2000（还是上一轮那帧的值）
    第 4 级：等一轮显示之后再读 → 0.5000（这才是 timeOffset=0.5 处的插值）
  ok   没跑过显示周期时只有 model 可读
  ok   预热完读到的是动画起点
  ok   拨完 timeOffset 立刻读到的仍是上一帧
  ok   改 timeOffset 之后必须再等一次显示周期
```

- 第 1 级：`presentation()` 是 `nil`。此时 `layer.presentation() ?? layer` 会退到 model 层，
  读到 1.0（动画根本没参与），这正是很多人写探针时「值一直不变」的原因。
- 第 3 级：**拨了时间不等于时间生效**。`timeOffset` 是个属性写入，重算发生在下一个显示周期。
- 实战对应：`layer.presentation()` 在真机上同样只在显示周期里更新。想读「此刻动画到哪了」，
  只能在 `CADisplayLink` 回调或 `animationDidStop` 这类跟帧同步的时机读，不要在普通代码路径里轮询。

> **坑**：`speed = 0` 之后**不要**再用 `CACurrentMediaTime()` 问「现在几点」。示例里演示了
> 顺序搞反的后果（第 5 节）：`convertTime` 的输出恒等于 `timeOffset`，你会拿到时间原点，
> 动画被拉回起点重播。

## 3) 隐式动画：裸层改属性会自己补动画

`CALayer` 有个对新手非常不友好的默认行为：**给它改一个属性，它会自动补一段动画**。
这叫隐式动画（implicit animation），只发生在**有 superlayer 的裸层**上。

```swift
let box = CALayer()
box.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
host.layer.addSublayer(box)
displayPass()
box.opacity = 0.3                      // 就这一行，没有任何 animate 调用
```

```
== 3) 隐式动画：改裸 CALayer 的属性，层自己会补一段动画 ==
  动作之前：animationKeys=nil
  改完 opacity 立刻（同一轮 runloop 内）：keys=Optional(["opacity"])
  ok   裸层的属性改动会挂上一个以属性名命名的隐式动画
  再跑四轮显示之后：keys=Optional(["opacity"]) model=0.3000
  ok   隐式动画的 key 不像显式动画那样跑完就自己消失，removeAnimation(forKey:) 才清得掉
  animation(forKey:) 取回真正在跑的这条：类型=CABasicAnimation
    duration=Optional(0.25) fillMode=backwards speed=1.0 repeatCount=0.0
```

隐式动画默认时长 **0.25 秒**（`duration=Optional(0.25)`，实测），所以你在 headless 里
「设完属性立刻读」是读不到中间态的——model 立刻就是 0.3，动画只是让画面慢慢过去。

三条屏蔽手段，从粗到细：

```swift
CATransaction.begin()
CATransaction.setDisableActions(true)
box2.opacity = 0.3
CATransaction.commit()

box3.actions = ["opacity": NSNull()]   // 按属性名逐个屏蔽
box3.opacity = 0.3

let lonely = CALayer()                 // 不在树里的层
lonely.opacity = 0.3
```

```
  CATransaction.setDisableActions(true) 之后：keys=nil
  ok   关掉隐式动画的标准做法：把属性改动包进一个 disableActions 的事务
  actions["opacity"] = NSNull() 之后：keys=nil
  ok   按属性名逐个屏蔽：actions 里放 NSNull
  没有 superlayer 的层改属性：keys=nil
  ok   层必须已经在树里，属性改动才有隐式动画
```

`action(forKey:)` 读「这个属性在发生改动时会用哪个动作对象」。它必须对**在树里的层**调用，
否则实测全部返回 `nil`；输出的类型也并不是统一的 `CABasicAnimation`：

```
  action(forKey:) 读默认动作对象（只打印类型，对象 description 里带指针地址）：
    树内的层 opacity → CABasicAnimation
    树内的层 hidden → CATransition
    树内的层 bounds → CABasicAnimation
    树内的层 position → CABasicAnimation
    树内的层 transform → CABasicAnimation
    树内的层 sublayers → CATransition
    树内的层 backgroundColor → nil
  ok   sublayers 的默认隐式动作是 CATransition，不是 CABasicAnimation
  ok   hidden 也是转场（层的出现/消失本身就被当成内容替换）
  ok   backgroundColor 没有默认动作 —— 改它不会自己补动画，得显式 add
    树外的层 opacity → nil
    树外的层 sublayers → nil
```

三件事值得记住：**`sublayers` 和 `hidden` 的默认动作是转场**（整块内容的替换动画），
不是数值插值——这就是为什么有人只是改了 `layer.hidden = true` 却看到一段淡入淡出；
**`backgroundColor` 没有默认动作**，改它是立即生效的（想淡入淡出得自己 `add` 一条）；
**树外的层没有隐式动画**，所以你单独 new 一个层做实验时看到的「没有动画」并不能代表它在树里的行为。

最后一条边界：`UIView` 自己的那个层不参与隐式动画。

```
  UIView 自己的 layer 改 opacity：keys=nil（视图的层由 UIKit 管，不参与隐式动画）
  ok   视图层改属性走 UIKit 的动画通道，裸层的隐式动画规则在这里不适用
```

这解释了日常经验：直接 `myView.layer.cornerRadius = 20` 不会自己动起来，
但从视图里 `addSublayer` 出来的自定义层就会乱动。**「层的动画不受控」几乎总是隐式动画在作怪**，
标准处理是：所有对裸层属性的写入都包在 `CATransaction` + `setDisableActions(true)` 里。

## 4) CABasicAnimation：数值/颜色/变换的点对点动画

先看新建对象的一堆默认值——它们决定了「你必须显式设哪些东西」：

```
== 4) CABasicAnimation：属性默认值与三种给值方式 ==
  duration=0.0 beginTime=0.0 speed=1.0 repeatCount=0.0 autoreverses=false
  isRemovedOnCompletion=true fillMode=removed timingFunction=nil
  fromValue=nil toValue=nil byValue=nil isAdditive=false isCumulative=false
  ok   新建动画 duration=0（等于不播）、结束后移除、fill 为 removed
  keyPath=Optional("opacity")（CABasicAnimation 继承自 CAPropertyAnimation，keyPath 就是这个层上的属性路径）
```

`duration` 默认 **0**、`repeatCount` 默认 **0**——只设 `fromValue/toValue` 而忘了 `duration`
的动画等于不存在。这是 Core Animation 第一大坑。

给值有三条路，实测三种读数：

```
  只给 toValue（0.0）：t=0/0.5/1 → 1.0000 / 0.5000 / 0.0000
  ok   缺 fromValue 时用「当前 model 值」当起点，所以 t=0 读回 1.0
  ok   中点正好是 (1.0 + 0.0)/2
  ok   终点干净地读到 0.0000 —— 但 position 那条的终点是 299.9997，别假设端点一定精确
  model.opacity=0.5 + byValue=0.2：t=1 → pres=0.7000（model=0.5000）
  ok   byValue 是「在当前值上加」
  同一时间的中点 t=0.5 → 0.6000（0.5 与 0.7 的中点）
  ok   byValue 一样受 timingFunction/时间影响，中间值照常插值
```

- `from + to`：最常用，两端都写死。
- 只给 `to`：起点自动取「当前 model 值」，做「从现在这个状态淡到某个状态」时很省事。
- 只给 `by`：在当前值上**加**一个增量（0.5 + 0.2 → 0.7），配合 `isAdditive`/`isCumulative`
  可以做叠加动画（默认两个都是 false）。

`fillMode` 只在「动画结束之后」区分表现，四种取值实测（`duration=1`，拨到 t=2 再读）：

```
  —— fillMode 四种，动画结束（t=2，duration=1）之后再读 ——
    fillMode=removed → pres.opacity=1.0000（model=1.0000，keys=Optional(["sample"])）
    fillMode=forwards → pres.opacity=0.8000（model=1.0000，keys=Optional(["sample"])）
    fillMode=backwards → pres.opacity=1.0000（model=1.0000，keys=Optional(["sample"])）
    fillMode=both → pres.opacity=0.8000（model=1.0000，keys=Optional(["sample"])）
  ok   结束后只有 forwards/both 保持终点值；removed/backwards 回到 model
  ok   fillMode 的 Swift 名字是 .removed/.forwards/.backwards/.both（没有 .none）
  ok   removed 与 forwards 只在「动画结束之后」有区别，播放期间完全一样
```

| fillMode | 动画开始前（有延迟时） | 动画结束之后 |
| --- | --- | --- |
| `.removed` | model 值 | model 值（弹回） |
| `.backwards` | `fromValue` | model 值 |
| `.forwards` | model 值 | `toValue`（保持） |
| `.both` | `fromValue` | `toValue` |

「动画开始前」这一列不是推导出来的，是把 `beginTime=1.0`（也就是延迟 1 秒）、
`duration=1`、`0.2→0.8` 的四种 `fillMode` 各做一份，拨到 t=0.5（还没开始）与
t=1.0（刚好开始）分别读出来的（model 的 opacity 始终是 1.0）：

```
  —— 反过来看**动画开始前**（beginTime=1.0，duration=1，0.2→0.8）——
    fillMode=removed → t=0.5（还没开始）pres.opacity=1.0000，t=1.0（刚好开始）pres.opacity=0.2000（model=1.0000）
    fillMode=forwards → t=0.5（还没开始）pres.opacity=1.0000，t=1.0（刚好开始）pres.opacity=0.2000（model=1.0000）
    fillMode=backwards → t=0.5（还没开始）pres.opacity=0.2000，t=1.0（刚好开始）pres.opacity=0.2000（model=1.0000）
    fillMode=both → t=0.5（还没开始）pres.opacity=0.2000，t=1.0（刚好开始）pres.opacity=0.2000（model=1.0000）
  ok   开始前只有 backwards/both 会显示起点值；removed/forwards 显示 model
  ok   t=1.0 四种 fillMode 已经一样 —— 动画正式开始后 fillMode 不参与
```

于是 `fillMode` 的四个名字可以这样记：`removed` = 两头都不 fill，
`forwards` = 只 fill 结束那头，`backwards` = 只 fill 开始那头，`both` = 两头都 fill。
**延迟期间（`beginTime` 还没到）画面显示什么是 `.backwards`/`.both` 才管得着的**——
这在做「一批动画按顺序排队」时很关键：延迟排队的动画如果不带 backwards，
动画真正开始前那一秒里对象会露出 model 值（比如该淡入的东西还是实心）。

注意这四种都要配合 `isRemovedOnCompletion = false` 才有意义（上面的示例就设了它）：
动画对象一旦被移除，`fillMode` 无从谈起。Swift 里枚举类型名是 `CAMediaTimingFillMode`，
**没有 `.none` 也没有 `.forward`**（很多人凭直觉写这两个名字，编译直接报错）。

重复与往返，`0→1`、`duration=1`、`autoreverses=true`、`repeatCount=2`：

```
  —— autoreverses + repeatCount：0→1，duration=1，autoreverses=true，repeatCount=2 ——
    t=0:0.0000 t=0.5:0.5000 t=1:1.0000 t=1.5:0.5000 t=2:0.0000 t=2.5:0.5000 t=3.5:0.5000 t=4:0.0000
  ok   往返两次都会经过中点 0.5
  ok   t=1 冲到顶、t=2 回到 0 —— 一次往返正好 2×duration
  ok   总时长 = duration×2×repeatCount = 4s，t=4 回到起点
    这几条时间属性的类型并不统一（同一段代码里读出的）：repeatCount=Float、speed=Float、duration=Double、beginTime=Double
    repeatCount 是 **Float**（不是 Double），设成 1.5 读回 1.5
  ok   非整数重复合法：1.5 表示走一轮半
    无限重复就是 .infinity：读回 inf，与 Float.infinity 相等=true
  ok   repeatCount = .infinity 是无限重复的标准写法
    弹簧的四个参数也各不一样：mass=CGFloat stiffness=CGFloat damping=CGFloat initialVelocity=CGFloat settlingDuration=Double
```

`autoreverses` 让一段动画变成去+回，所以**一次完整周期是 2×duration**，
总时长 = `duration × (autoreverses ? 2 : 1) × repeatCount`。
t=2.5 与 t=3.5 都读到 `0.5000`：第二轮在往回走的路上，读数完全按这个公式对上。

顺手记下类型分布——这是编译期报错的常见来源：`repeatCount`/`speed` 是 **Float**，
`duration`/`beginTime`/`timeOffset`/`settlingDuration` 是 **Double**，
弹簧的 `mass/stiffness/damping/initialVelocity` 是 **CGFloat**，层的 `opacity` 是 **Float**、
`cornerRadius` 是 **CGFloat**。同一个动画文件里混着写，Swift 会要求你明确字面量类型。

`keyPath` 是这一族的灵魂：它不只是属性名，还能指到结构体分量。

```swift
let txL = animLayer { basic("transform.translation.x", 0.0, 40.0) }
let rotL = animLayer { basic("transform.rotation.z", 0.0, Double.pi) }
let bsL = animLayer { basic("bounds.size.width", 40.0, 120.0) }
```

```
  —— keyPath 家族：同一个 CATransform3D 可以按分量拆着动 ——
    transform.translation.x t=0.5 → transform.m41=20.0000，position.x=20.0000
  ok   translation 走矩阵的第 4 行（m41），不动 position —— 和 position.x 动画是两回事
    transform.rotation.z 0→π：t=0/0.5/1 → m11=1.0000 / 0.0000 / -1.0000
      用 KVC 读分量：rotation.z=0.0000 / 1.5708 / 3.1416
  ok   弧度值可以直接按 keyPath 插值（CATransform3D 结构体本身没有 .rotation 成员）
  ok   转 90° 时 m11 为 0
    bounds.size.width 40→120：t=0.5 → pres.bounds=(0.0, 0.0, 80.0, 40.0)，model.bounds=(0.0, 0.0, 40.0, 40.0)
  ok   子属性 keyPath 只动 presentation（80），model 一点没变（还是 40）
    backgroundColor 用 CGColor 插值：t=0.5 时 presentation 层存在=true（CGColor 的 description 带地址，不打印）
  ok   颜色类属性可以动画，前提是给它 CGColor 而不是 UIColor
    拼错 keyPath：add 之后 keys=Optional(["sample"])，t=0.5 时 pres.frame=(0.0, 0.0, 40.0, 40.0)（与不动时完全一致）
  ok   非法 keyPath 不会报错，动画静静存在却什么都不动 —— 排错时最容易看漏
    布尔属性 masksToBounds 也能 add 动画：
      t=0.5 → pres.masksToBounds=true（布尔不插值，只在端点之间跳）
```

- `transform.rotation.z` 这类**点分路径**是 Core Animation 的私有约定，不是 KVC 的通用语法。
  能用的名字来自那份头文件里的 `transform.rotation.(z|x|y)`、`transform.scale`、
  `transform.translation.x` 等等。角度用**弧度**（`0→π` 实测中点 KVC 读回 `1.5708`）。
- `transform.translation.x` 动的是矩阵的 m41，`position` 一点不动；
  `position.x` 动的是几何位置。两者视觉效果对不懂 3D 的人一样，但**和别的 transform 叠加时结果不同**——
  绕锚点旋转+平移时，用 `translation` 会被旋转带跑。
- 颜色类属性（`backgroundColor` / `fillColor` / `shadowColor`）要传 **`CGColor`**，
  传 `UIColor` 编译不过。
- 拼错 keyPath **完全静默**：动画照样挂上、`animationKeys()` 照样有值、什么都不动。
  排查「动画没效果」时第一件事是把 keyPath 拿去和头的属性名对一遍。

> **坑**：布尔属性（`masksToBounds`、`isHidden`）不插值。实测 `0.0→1.0` 的动画在 t=0.5
> 读到 `true`——它是端点之间跳变，不是「半真」。想淡出请用 `opacity`，不要用 `hidden`。

## 5) 时间曲线与时钟：暂停、恢复与父层时钟

### 5.1 `CAMediaTimingFunction` 的五个内置曲线

曲线是一条三次贝塞尔，两个端点固定在 `(0,0)` 与 `(1,1)`，所以只有中间两个控制点是可变的。
`getControlPoint(at:)` 的下标是 0…3：

```
== 5) 时间曲线与时钟：CAMediaTimingFunction 与 speed / timeOffset / beginTime ==
    linear: (0.00,0.00) (0.00,0.00) (1.00,1.00) (1.00,1.00)
    easeIn: (0.00,0.00) (0.42,0.00) (1.00,1.00) (1.00,1.00)
    easeOut: (0.00,0.00) (0.00,0.00) (0.58,1.00) (1.00,1.00)
    easeInEaseOut: (0.00,0.00) (0.42,0.00) (0.58,1.00) (1.00,1.00)
    default: (0.00,0.00) (0.25,0.10) (0.25,1.00) (1.00,1.00)
  ok   getControlPoint 的下标范围是 0...3（头文件写明 'idx' is a value from 0 to 3 inclusive）
    自定义贝塞尔 (0.1,0.9,0.9,0.1) 的下标 1 = (0.10,0.90)，下标 0 恒为 (0,0)、下标 3 恒为 (1,1)
```

`default`（对应 `kCAMediaTimingFunctionDefault`）也是一条「两头慢、中间快」的 S 形，
但**不对称**：第二个控制点是 `(0.25,1.00)`，x 只走到 0.25 就把 y 顶到 1.00，
所以它比 `easeInEaseOut` 更早接近终点、尾巴拖得更长。

那 `UIView.animate` 不指定曲线时挂的是哪一条？很多人以为是 `.default`，
实际上把这个动画从层里取出来读控制点，看到的是 `easeInEaseOut`：

```
  —— UIView.animate 不写 options 时，实际往层上挂的是哪条曲线？把它从层里取出来读 ——
    duration=0.5 fillMode=both autoreverses=false
    控制点=(0.00,0.00) (0.42,0.00) (0.58,1.00) (1.00,1.00)
    对照 .default=(0.00,0.00) (0.25,0.10) (0.25,1.00) (1.00,1.00)  .easeInEaseOut=(0.00,0.00) (0.42,0.00) (0.58,1.00) (1.00,1.00)
  ok   UIKit 默认挂的是 easeInEaseOut（0.42,0 / 0.58,1），不是 .default 那条（0.25,0.1 / 0.25,1）—— 很多人以为 UIView.animate 走的是「系统默认曲线」
    fromValue=Optional(NSPoint: {-130, -130}) toValue=Optional(NSPoint: {0, 0})
  ok   UIKit 挂的动画 fillMode 是 both（开始前显示起点、结束后显示终点），而不是层动画默认的 removed
```

这段（改 `center`，`duration=0.5`）还有两个值得注意的细节：
- `fillMode=both`、`isRemovedOnCompletion` 由 UIKit 自己管，所以 UIKit 的动画跑完不会「弹回」——
  它在结束时把 model 也写成终点值（第 2 节已经看过：`UIView.animate` 一返回 model 就已经是终点了）。
- `fromValue`/`toValue` 是 **`NSPoint`**，而且内容是**相对量**（`{-130,-130}` 与 `{0,0}`），
  不是绝对坐标。想要别的曲线就显式传 `UIView.animate(withDuration:delay:options:animations:completion:)`
  的 `options`：`.curveLinear` / `.curveEaseIn` / `.curveEaseOut` / `.curveEaseInOut`。

拿同一条 `20→300`、`duration=1` 的动画分别配四种曲线，看 t=0.5 的读数：

```
  —— 用曲线做同一个动画（20→300，duration=1），中点值会不一样 ——
    linear 的 t=0.5 → 160.0000
    easeIn 的 t=0.5 → 108.2999
    easeOut 的 t=0.5 → 211.7001
    easeInEaseOut 的 t=0.5 → 160.0000
  ok   linear 的中点就是算术中点 160；easeIn 慢进（108.3）、easeOut 快进（211.7）；easeInEaseOut 对称所以中点仍是 160
```

`easeInEaseOut` 关于中点**中心对称**，所以中点恰好还是算术中点 160——
想验证一条曲线对不对，中点是不是 160 是个便宜的检查。

两个必须避免的写法，实测**当场抛异常并 SIGABRT**（不是返回 nil、不是静默忽略）：

```
// CAMediaTimingFunction(name: CAMediaTimingFunctionName(rawValue: "ease-in-out-back"))
*** Terminating app due to uncaught exception 'CAMediaTimingFunctionInvalid', reason: 'unknown timing function name: ease-in-out-back'

// fn.getControlPoint(at: 4, values: &pair)
*** Terminating app due to uncaught exception 'CAMediaTimingFunctionInvalidControlPoint', reason: 'no timing function control point with index: 4'
```

`CAMediaTimingFunctionName(rawValue:)` 不检查字符串合法性；
`linear/easeIn/easeOut/easeInEaseOut/default` 这五个名字之外的都会崩。
`getControlPoint` 只接受 0…3，index=4 直接崩，写循环时别写 `0...4`。

### 5.2 暂停与恢复一棵层树

标准的暂停/恢复是三步，顺序不能乱：

```swift
// 暂停：先问「现在几点」，再掐速度，最后把指针钉在那一刻
let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
layer.speed = 0
layer.timeOffset = pausedTime

// 恢复：三件事一起做
layer.speed = 1
layer.beginTime = CACurrentMediaTime() - pausedTime
layer.timeOffset = 0
```

```
  —— 暂停 / 恢复一棵层树（值由墙钟决定，所以只打印布尔与差值） ——
    暂停中隔三个显示周期两次读，差值=0.0000（墙钟确实走了，层钟被 speed=0 掐停）
  ok   speed=0 + timeOffset 冻结之后呈现值不再前进
  ok   暂停之前先 convertTime(CACurrentMediaTime(), from: nil) 拿到「当下是几点」
    恢复之后再读，比冻结点更大=true（恢复确实接上了，但每轮显示之间的推进量取决于墙钟，所以不打印数字）
  ok   恢复要三件事一起做：speed=1、beginTime 减去已走时间、timeOffset 归零
    model 在暂停/恢复期间一直是 10.0000（显式动画从不写回 model）
```

恢复那一行的原理：层的本地时间是
`localTime = (mediaTime - beginTime) × speed + ...`，
`speed` 归 1 之后必须让 `beginTime` 往前挪掉「已经走过的 `pausedTime`」，动画才从暂停点继续，
而不是从墙钟的绝对时间重新开始（那会一下跳到动画末尾）。

顺序搞反是这段代码最常见的 bug：

```
  —— 顺序搞反会怎样：先 speed=0，再问「现在几点」 ——
    speed=0 之后再 convertTime → 得到 0.0000（就是 timeOffset 自己，回到时间原点）
  ok   speed=0 时 convertTime 的输出恒等于 timeOffset，读不到「当下」
    于是动画被拉回原点附近重新开始，暂停在墙钟意义上的第 0 帧 —— 想停在当下必须**先取时间再掐速度**
```

`speed = 0` 之后 `convertTime(CACurrentMediaTime(), from: nil)` 的输出恒等于 `timeOffset`
（实测 `0.0000`），因为时钟已经不走了，任何外部时间换算进来都停在同一个刻度上。
所以**「先取时间、再掐速度」是唯一的顺序**。

### 5.3 时钟沿层树往下传

层的时间是从 `superlayer` 继承的，所以冻住一个父层就冻住了整棵子树。这个示例把父层冻住之后
去拨父层的 `timeOffset`，读数完全由父层驱动：

```
  —— 时钟是沿 superlayer 往下传的：冻父层，子层的动画跟着停 ——
    parent.timeOffset=0.0 → child pres.position.x=10.0000，child.convertTime 读回 0.0000，child.speed 仍是 1.0
    parent.timeOffset=0.5 → child pres.position.x=60.0000，child.convertTime 读回 0.5000，child.speed 仍是 1.0
    parent.timeOffset=1.0 → child pres.position.x=109.9999，child.convertTime 读回 1.0000，child.speed 仍是 1.0
  ok   子层的插值完全由父层的 timeOffset 驱动（子层自己 speed=1 也一样被冻住）
  ok   convertTime 给出的就是父层当前的 timeOffset —— 时钟沿树往下继承
```

实战含义：**「暂停整个界面」只需要在最外层容器视图的层上设一次 `speed = 0`**，
不需要遍历子层。想反过来做「暂停别人、只有这一层继续」，就得给它单独设 `speed`
并在它的父层时钟里换算时间（`convertTime(_:to:)`），这通常比想象中麻烦。

## 6) CAKeyframeAnimation：多关键帧、计算模式与沿路径运动

关键帧动画是「把一串值按时间分配给一次播放」。核心两个属性：`values` 与 `keyTimes`
（`keyTimes` 是 0…1 的归一化比例，正常写法是个数与 `values` 一致——不一致会怎样见下面实测）。

```swift
let kf = CAKeyframeAnimation(keyPath: "position.y")
kf.values = [0.0, 60.0, 20.0]
kf.keyTimes = [0.0, 0.2, 1.0].map { NSNumber(value: $0) }
kf.duration = 1.0
```

```
== 6) CAKeyframeAnimation：多关键帧、计算模式与沿路径运动 ==
  values=[0,60,20] keyTimes=[0,0.2,1] duration=1 calculationMode=linear
  linear：t=0:0.0000 t=0.1:30.0000 t=0.2:60.0000 t=0.6:40.0000 t=1:20.0000
  ok   keyTimes 决定分段：0→0.2 从 0 冲到 60，之后 0.8 段慢慢回到 20
  values 3 个但 keyTimes 只给 2 个（0 与 1）：t=0/0.5/1 → 0.0000 / 30.0000 / 60.0000，keys=Optional(["sample"])
  ok   不崩也不报警：多出来的 values[2]=20 被静默丢掉，前两个值被铺满整条 duration（读数是 0/30/60，不是 0/60/20）
  ok   keyTimes 与 values 个数不一致不会让动画被拒绝添加
  values 2 个但 keyTimes 给 3 个（0/0.2/1）：t=0/0.1/0.5/1 → 0.0000 / 30.0000 / 60.0000 / 60.0000，keys=Optional(["sample"])
  ok   反方向配错（keyTimes 多一个）同样不崩、动画照样挂上
```

`keyTimes=[0,0.2,1]` 把第一段（0→60）压缩在 0.2 秒内、第二段（60→20）拉长到 0.8 秒，
所以「冲上去慢回来」像一个弹跳。读数完全按分段线性推：t=0.1 是 0→0.2 的中点 30，
t=0.6 是 0.2→1.0 这段的 0.5 位置，即 `60 - 40×0.5 = 40`。

第二段是刻意把个数配错的实测：**不崩、不警告、动画照样挂上**（`keys=Optional(["sample"])`），
只是按**两者里较少的那个**配对。两个 keyTimes 只够描述一段（0→1），于是拿 `values` 的
前两项 `0→60` 铺满整条 duration，第三项 `20` 被静忽略——读数是 `0/30/60` 而不是原来的
`0/60/20`。第三段是反方向配错：3 个 keyTimes 配 2 个 values，只有 `(0→values[0], 0.2→values[1])`
这一段成立，所以 `0→60` 挤在前 0.2 秒里跑完（t=0.1 读到中点 30），后面 0.8 秒没值可插，
一直停在 60。这类「少一段却不报错」的 bug 在真机上的表现是「动画跑完停在不该停的值上」，
排错时把 `values.count` 与 `keyTimes?.count` 打出来对一遍最省事。

三种计算模式的对照实测：

```
  discrete（不设 keyTimes，默认均匀 0/0.5/1）：t=0/0.4/0.8 → 0.0000 / 60.0000 / 20.0000
  ok   discrete 直接跳到下一个值，中间不插值
  paced：t=0/0.5/1 → 0.0000 / 50.0000 / 100.0000（paced 按**等速**走完每段，忽略 keyTimes）
  ok   两段两值时 paced 与 linear 重合
```

- `.linear`（默认）：段内线性插值，尊重 `keyTimes`。
- `.discrete`：不插值，到点直接换下一个值——做逐帧动画（sprite）用它。
- `.paced`：**按速度**分配时间，`keyTimes` 被忽略，值之间的距离决定各自占多久。
- 还有 `.cubic` / `.cubicPaced`（样条插值，运动更顺滑）。枚举类型名是 `CAAnimationCalculationMode`。

沿 `CGPath` 运动是这一族最有用的用法：不给 `values`，只给 `path`。

```
  沿 CGPath(椭圆 100×50) 的 position：t=0/0.25/0.5 → (100.0000,25.0000) (30.5377,48.0354) (14.6447,7.3223)
  ok   CGPath 的椭圆从右端中点 (maxX, midY) 起画，所以 t=0 就在那
  设了 path 之后 keyTimes 会被忽略：kc.rotationMode=nil（默认 nil；设成 .auto 时对象会顺着切线转向）
  calculationMode 可选值：linear / discrete / paced / cubic / cubicPaced（Swift 名字是 CAAnimationCalculationMode）
```

起点是 `(100, 25)` = `CGRect` 椭圆的右端中点——`addEllipse` 的画法是「从 3 点钟方向起逆时针」，
所以别默认路径从左上角开始。想让对象**顺着切线转向**（沿路径开车的小车图标），
设 `rotationMode = CAKeyframeAnimationRotationMode.auto`（Swift 里是 `.auto`，字符串值 `"auto"`）；
默认 `nil` 表示对象不转，只平移。

> **坑**：给了 `path` 之后 `values`/`keyTimes` 都不起作用；反过来 `path` 和 `values` 同时给时
> 以 `path` 为准。想控制路径上的速度分布，用 `timingFunction` 或把路径拆成多段关键帧。

## 7) 组、转场、弹簧与 UIKit 的动画接口

### 7.1 `CAAnimationGroup`：一个 `duration` 管整组

```
== 7) CAAnimationGroup / CATransition / CASpringAnimation / UIView 动画接口 ==
  组 duration=2，子里 opacity 用满 1s、scale 只用 0.5s：
    t=0 → opacity=1.0000 scale(m11)=1.0000
    t=0.25 → opacity=0.7500 scale(m11)=1.5000
    t=0.75 → opacity=0.2500 scale(m11)=1.0000
    t=1.5 → opacity=1.0000 scale(m11)=1.0000
  ok   t=0.25 时 0.5s 的 scale 动画才走一半（1→2 的中点 1.5）
  ok   opacity 还在跑（t=0.75 读到 0.25），而 scale 那条早已按自己的 duration 结束 —— 组的 duration 只决定整组何时收尾
  ok   子里的动画跑完就各自回到 model
  grp.animations?.count=2（子动画对象本身可以被读回）
  ok   组里的子动画可以原样取回
```

关键认知：**组不是「同步器」，是「容器」**。组只有两个作用——给子动画提供一个共同的时间原点
（子动画的 `beginTime` 变成**相对组**的偏移），以及决定这组动画作为一个整体何时结束。
每条子动画仍按自己的 `duration` 跑完并回到 model：上面 t=0.75 时 `scale` 已经结束（m11 回到 1），
`opacity` 还在 0.25 处。想让它们同时结束，就把各条的 `duration` 分别设成组 `duration` 里想要的比例。

`beginTime` 相对组这一点实测：

```
  子动画 beginTime=1.0（相对组的时间）：t=0/0.8/1.0/1.25/1.5/2.0 → 1.0000 / 1.0000 / 0.0000 / 0.5000 / 1.0000 / 1.0000
  ok   组内前 1s 子动画还没开始，读到的仍是 model
  ok   1.0s 之后才开始插值，1.5s 就跑完了自己的 0.5s
```

注意 `t=1.0` 那一列读到 `0.0000`：那是子动画自己的起点（`fromValue = 0.0`）。
**动画的起点在 `beginTime` 那一刻就被采纳了**，而不是「开始插值之后才有值」——
所以 `fillMode` 是否包含 `.backwards`/`.both` 在组里格外有用。

### 7.2 `CATransition`：内容替换动画

```
  CATransition 默认：type=fade subtype=nil duration=0.0 startProgress=0.0 endProgress=1.0
  设成 moveIn/fromLeft 之后 add，读回 keys=Optional(["transition"])
  ok   转场的 type/subtype 都是字符串枚举，可读写
  ok   CATransition 也是 CAAnimation、能 add 到层上，但 forKey 传的名字会被换成 "transition" —— 想按自己的 key 管理就得自己记
  type 可用：fade / push / moveIn / reveal；subtype 可用：fromTop / fromBottom / fromLeft / fromRight
```

两个实测要点：**默认 `duration` 是 0**（跟所有 CAAnimation 一样必须自己设），
以及 `add(_:forKey:)` 时你传的 key 会被换成 `"transition"`（上面示例传的是 `"tr"`，
读回 `["transition"]`）。这跟第 3 节 `hidden`/`sublayers` 的默认动作是同一个对象类型，
所以「改 `sublayers` 出现淡入淡出」的修法就是把 `actions["sublayers"]` 换成 `NSNull()` 或自定义动画。

`type` 的四个值（Swift 里是 `CATransitionType`）：`fade`、`push`、`moveIn`、`reveal`；
`subtype` 四个方向。`startProgress`/`endProgress` 用来只做一段转场的中间部分（比如接续已有的动画）。

### 7.3 `CASpringAnimation`：会冲过头的动画

```
  CASpringAnimation 默认：mass=1.0 stiffness=100.0 damping=10.0 initialVelocity=0.0
  设 duration=1 之后 settlingDuration=1.4727（弹簧「停下来」所需的理论时长，不由 duration 决定）
  默认参数（damping=10）的采样：t=0:0.0000 t=0.1:34.0300 t=0.25:102.3360 t=0.5:107.4591 t=1:100.2170
  ok   t=0.25 已经**冲过头**到 102.34 —— 弹簧动画会越过终点再荡回来
  ok   duration=1 处仍在终点之上振着（100.217），并没有停在 100
  拨到 settlingDuration=1.4727 时读回 20.0000（动画已结束，回到 model）
  ok   超过 duration 之后这条弹簧就结束并移除，presentation 回到 model 的 20
  所以弹簧动画的 duration 应当直接取 settlingDuration，而不是自己拍一个数
  把 damping 提到 200（过阻尼）：t=0.25 → 71.2703，t=1 → 99.9501，settlingDuration=1.0000
```

四个物理参数（都是 CGFloat）：`mass` 质量、`stiffness` 劲度、`damping` 阻尼、`initialVelocity` 初速。
`settlingDuration` 是「振幅衰减到 1/1000 以内所需的理论秒数」，由这四个参数算出来
（默认参数算出 1.4727），**它不受 `duration` 影响**。上面 t=0.25 就冲过了终点（102.34），
t=0.5 还在 107.46 高位，到 t=1 仍有 100.217——如果这时动画被 `duration` 切断，
画面会在偏离终点的位置弹回，非常难看。标准写法：

```swift
let sp = CASpringAnimation(keyPath: "position.x")
sp.fromValue = 0; sp.toValue = 100
sp.damping = 10
sp.duration = sp.settlingDuration      // ← 用理论停留时长当 duration
```

阻尼调到 200（过阻尼）就不冲过头了：t=0.25 是 71.27、t=1 是 99.95，一路单调逼近终点。

### 7.4 `UIView` 的动画接口最终往层上挂什么

`UIView.animate` 是 Core Animation 的包装，这从挂上去的 key 名就能看出来：

```
  —— UIKit 给的动画接口（UIView.animate 一族）实际往层上挂什么 ——
    alpha 动画 → keys=Optional(["opacity"])
    center 动画 → keys=Optional(["position"])
    transform 动画 → keys=Optional(["transform"])
    frame 动画 → keys=Optional(["position", "bounds.size"])
  ok   UIView.alpha 对应层上的 opacity
  ok   center 只挂 position（改 center 不改 size，所以只有这一条）
  ok   视图的 transform 直接落到层的 transform
  ok   frame 被拆成两条：尺寸走 bounds.size、位置走 position —— 这就是「frame 是派生属性」的实锤
    usingSpringWithDamping 版 → keys=Optional(["position"])
    UIView.animateKeyframes → keys=Optional(["opacity"])
    UIView.transition(.transitionFlipFromLeft) → keys=Optional(["opacity", "transition"])
  ok   UIView.transition 同时挂上属性动画和一条 transition
  ok   弹簧版 UIView.animate 用的 key 与普通版相同（都是属性名）
  ok   关键帧版也是同一条 opacity，只是内部换成 CAKeyframeAnimation
    UIView.AnimationOptions 里可选的转场只有：flipFromLeft/Right/Top/Bottom、curlUp/Down、crossDissolve、none
```

`frame` 动画被拆成 **两条**（`bounds.size` + `position`）是这一节最有信息量的读数：
层没有 `frame` 这个「可动画属性」，`frame` 只是 `position`/`bounds`/`anchorPoint` 的派生量，
所以 UIKit 只能把它拆开挂。**同理，改 `bounds.origin` 想动画，keyPath 应该写 `bounds.origin`**，
`frame.origin` 是无效 keyPath（第 4 节那个静默失败的例子）。

另外几条实践约束：`UIView.transition(with:duration:options:animations:completion:)`
里的转场选项只有列出的那八种；`usingSpringWithDamping:` 那一路走的是 UIKit 的弹簧通道，
不需要你自己构造 `CASpringAnimation`。

还有一件事在第 5.1 节已经实测过，这里从「挂什么动画」的角度复述一遍：把 `UIView.animate`
挂上去的那条 `CABasicAnimation` 取出来读，曲线是 **`easeInEaseOut`**（控制点 `0.42,0 / 0.58,1`）、
`fillMode=both`、`fromValue`/`toValue` 是**相对量**的 `NSPoint`（`center` 那条读到 `{-130,-130}` → `{0,0}`）。
也就是说 UIKit 帮你做的三件事：选好曲线、跑完自己写回 model（所以不会弹回）、
并且按属性名拆好 keyPath。想换曲线就用带 `options` 的重载传 `.curveLinear` 之类的曲线选项。

## 8) 特殊图层族：配置对象

这些子类都是「用参数驱动内容」的层。headless 能读写的正是全部参数，
唯一看不到的是渲染结果，所以这一节逐条把默认值与设置后的读回打出来。

```
== 8) 特殊图层：属性读写表（headless 里只能核对配置，看不到画面） ==
  CAGradientLayer 默认：type=axial startPoint=(0.5, 0.0) endPoint=(0.5, 1.0) colors=nil locations=nil
  设 2 个颜色 + 3 个 locations：colors.count=2 locations.count=3 type=conic
  ok   颜色数与 locations 数不一致也不报错（运行时才按需要截断/补齐）
  ok   type 可用 axial / radial / conic（没有 circular；kCA… 常量在 Swift 3 就重命名了）
  ok   默认渐变从上边中点到下边中点，单位是层的归一化坐标
```

`CAGradientLayer`：`startPoint`/`endPoint` 是**归一化坐标**（0…1 相对层），默认从 `(0.5,0)` 到
`(0.5,1)`，即自上而下。`colors` 是 `[Any]`，放 `CGColor`。类型枚举是 `CAGradientLayerType`：
`.axial`（默认线性）、`.radial`、`.conic`（旧写作 `kCAGradientLayerRadial` 的常量形式在 Swift 里已重命名）。
颜色数与 `locations` 数不一致**不会报错**（实测 2 个颜色配 3 个 location 照样读回），
运行时才做截断/补齐——所以数错了不会有任何提示，只是渐变跟你想的不一样。

```
  CAShapeLayer 默认：lineWidth=1.0 lineCap=butt lineJoin=miter miterLimit=10.0
    fillRule=non-zero strokeStart=0.0 strokeEnd=1.0 lineDashPhase=0.0
  设 path 之后 boundingBoxOfPath=(0.0, 0.0, 60.0, 30.0) dashPattern=Optional([4, 2]) strokeEnd=0.7
  ok   path 是 CGPath，描边比例靠 strokeStart/strokeEnd
  ok   fillRule 默认 non-zero（另一个是 even-odd）
  fillColor/strokeColor 是 CGColor? 类型，默认 nil；注意它们和 backgroundColor 一样不能直接打 UIColor
  strokeEnd 0→1 是可动画 keyPath（真正的层）：t=0/0.25/0.5/1 → 0.0000 / 0.2500 / 0.5000 / 1.0000 —— 「描边进度/折线生长」动画就是这么做的
  ok   CAShapeLayer 的子属性同样能被显式动画插值，model 保持 0
  ok   动画期间 model.strokeEnd 仍是设进去的 0
```

`CAShapeLayer` 把 `CGPath` 变成一个可以填充/描边的层，省掉 `draw(_:)`。
`strokeStart`/`strokeEnd` 是路径的**比例**（0…1），把它们做成动画就是「手绘签名/进度环」那类效果
（上面实测四段读数精确等分）。`lineDashPattern` 是 `[NSNumber]`（长度/间隔交替）。
`fillColor`/`strokeColor` 默认 `nil`——**不设置就没有任何可见内容**，这是这个层最常见的「为什么是空的」。

```
  CATextLayer 默认：fontSize=36.0 alignmentMode=natural truncationMode=none isWrapped=false
  设 string 两行 / font 类型=Optional<AnyObject> / isWrapped=true
  ok   fontSize 默认 36（不是系统字号 17），忘了设就会得到巨大文字
  ok   string 是 id 类型，可以多行；换行靠 isWrapped 与 \n
  把 UIFont 塞进 font 也编得过（font 声明成 AnyObject?，编译器不检查）：读回类型=Optional<AnyObject>
  ok   CATextLayer.font 接受任意对象 —— 要的是 CGFont/CTFont，给错不会编译失败（headless 里看不出渲染差别）
```

`CATextLayer` 两个必踩点：`fontSize` 默认 **36**（`NSStringDrawing` 那套的默认值），
以及 `font` 属性声明成 `AnyObject?`，**填 `UIFont` 能编译通过但不会按预期工作**——
要 `CGFont`/`CTFont`，或者干脆用 `fontName`/`fontSize` 两个属性。
`string` 是 `Any?`（`NSAttributedString` 也收）。`alignmentMode`（不是 `aligned`）取
`natural/left/center/right/justified`，用的是 `CATextLayerAlignmentMode`。
还有一个 `contentsScale` 要记得设成屏幕 scale，否则文字发虚（第 1 节实测它不会自动变）。

```
  CAReplicatorLayer 默认：instanceCount=1 instanceDelay=0.0 instanceTransform 是单位阵=true
  设 3 份 / 每份 x+20 / 延迟 0.1s / alpha 递减 -0.15：读回 count=3 delay=0.1 alphaOffset=-0.1500 m41=20.0000
  ok   复制层靠 instanceCount/Transform/Delay 做阵列与错时动画
  ok   preservesDepth 默认 false（3D 复制时才会露出）
  注意：没有 instanceProgression / instanceAlphaRepeat 这类属性，能设的是 instanceRed/Green/Blue/AlphaOffset 与 instanceColor
```

`CAReplicatorLayer` 把它的子层阵列复制若干份，每份叠加一个 `instanceTransform`、
一组颜色偏移和一个**时间延迟**——`instanceDelay = 0.1` 意思是第 n 份的动画比前一份晚 0.1 秒开始，
这就是「一排依次亮起的灯泡」的实现方式（不需要写循环动画）。
能设的颜色偏移只有 `instanceRedOffset`/`GreenOffset`/`BlueOffset`/`AlphaOffset` 四个加
`instanceColor`；网上流传的 `instanceProgression`、`instanceAlphaRepeat` 在 SDK 里**不存在**。

```
  CAEmitterLayer 默认：shape=point mode=volume renderMode=unordered birthRate=1.0
    emitterSize=(0.0, 0.0) emitterPosition=(0.0, 0.0) emitterZPosition=0.0 cells=nil
  CAEmitterCell 默认：birthRate=0.0 lifetime=0.0 velocity=0.0 scale=1.0 spin=0.0 emissionRange=0.0
  设 cell 参数与 shape=line 之后：cells.count=1 shape=line cell.birthRate=10.0
  ok   发射器本身只管形状与速率，粒子属性都在 CAEmitterCell 上
  ok   层的 birthRate 默认 1、cell 的默认 0 —— 只建 CAEmitterLayer 是看不到任何粒子的
```

粒子系统分两层：`CAEmitterLayer` 管**发射器**（形状 `point/line/rectangle/cuboid/circle/ball`、
模式 `volume/surface`、渲染次序 `unordered/backToFront/frontToBack`），
`CAEmitterCell` 管**粒子**（寿命 `lifetime`、初速 `velocity`、加速度、缩放、旋转 `spin`、
发射角度范围 `emissionRange`、`contents` 贴图等）。
默认值分布解释了「为什么我建了发射器却什么都没有」：**层的 `birthRate` 是 1，
cell 的 `birthRate` 是 0**，两者相乘为 0；而 `cells` 默认还是 `nil`。

```
  CATiledLayer 默认：levelsOfDetail=1 levelsOfDetailBias=0 tileSize=(256.0, 256.0)
  设 bias=3 之后读回 3；没有 maxTiledContentDimensions 这个属性
  ok   瓦片层默认 1 级细节；tileSize 是屏幕相关的 256×256
  CAScrollLayer.scrollMode 默认=both（horizontal/vertical/both）
  CATransformLayer：anchorPoint=(0.5, 0.5) bounds=(0.0, 0.0, 0.0, 0.0)（专门给 3D 子层做透视分组，自身不画东西）
```

`CATiledLayer` 是大图/地图的做法：把内容切成瓦片按需、分级绘制，
`levelsOfDetail`/`levelsOfDetailBias` 控制细节级数，绘制靠 `draw(_:tile:)`（`CGContext` 版）。
`tileSize` 默认 256×256，且它是屏幕坐标系下的尺寸。SDK 里没有 `maxTiledContentDimensions`。
`CATransformLayer` 是 3D 分组的载体：它自己不画任何东西，但**它的子层会保留 3D 关系**
（普通层做子层容器时，子层的 3D 变换会被压平）。做立方体必须用它。

## 9) `CATransform3D`：全是自由函数，透视自己写 m34

第 14 章在 2D 的 `CGAffineTransform` 上做过对照，这里把 3D 这一族的名字读一遍：

```
== 9) CATransform3D：函数全家桶与 m34 透视 ==
  Identity: m11=1.0 m22=1.0 m33=1.0 m44=1.0 其余为 0
  IsIdentity=true IsAffine=true
  （注意是**自由函数**：CATransform3D 这个结构体没有 .isIdentity / .isAffine 成员）
  MakeTranslation(10,20,30) → m41=10.0000 m42=20.0000 m43=30.0000
  MakeScale(2,3,4) → m11=2.0000 m22=3.0000 m33=4.0000
  MakeRotation(π/2, z) → m11=0.0000 m12=1.0000 m21=-1.0000 m22=0.0000
  ok   绕 z 转 90°：m11 精确读到 0
  Concat(Translate,Scale) → m41=20.0000；Concat(Scale,Translate) → m41=10.0000
  ok   Concat 不满足交换律：先缩放后平移，平移量会被缩放
  Invert(Translate) → m41=-10.0000；Invert(Scale) → m11=0.5000
  Invert(零矩阵/奇异) → m11=0.0000 m44=0.0000（不报错，静默给全零）
  ok   不可逆矩阵的 Invert 没有任何提示，得自己判断
  EqualToTransform(t, t)=true，与 z 差 0.0001 的=false
  ok   EqualToTransform 是精确比较，浮点近似要用别的判法
  MakeAffineTransform(a,b,c,d,tx,ty) → m11=1.0000 m12=2.0000 m21=3.0000 m22=4.0000 m41=5.0000 m42=6.0000 m33=1.0000
  ok   2D→3D 的映射是 a→m11 b→m12 c→m21 d→m22 tx→m41 ty→m42
  GetAffineTransform(带 z=30 的平移) → a=1.0 b=0.0 c=0.0 d=1.0 tx=10.0 ty=20.0（z 分量直接丢）
  GetAffineTransform(非仿射的透视阵) → 返回 1.0000/0.0000/0.0000/1.0000 —— 未定义行为，别依赖
  IsAffine 的判据是**整个第三行和第三列**：z 平移（m43=30）就已经不算仿射
  ok   z=0 的 2D 平移是仿射
  ok   只把 z 从 0 改成 30，IsAffine 就变 false（m43≠0）
  ok   m34 透视当然也不是仿射
  透视没有专用函数：没有 CATransform3DPerspective，只能手改 m34（值 = -1/透视距离）
  sublayerTransform 默认是单位阵=true
  容器设 sublayerTransform(m34=-1/500)，子层绕 y 转 45°：m11=0.7071 m13=-0.7071
  ok   绕 y 旋转会把 z 分量的余弦/正弦放进 m11/m13
  层的 transform 与 UIView.transform（CGAffineTransform）是两套：层用 3D，视图只给 2D
```

要点：

- **`CATransform3D` 是结构体，操作全是自由函数**：
  `CATransform3DIdentity`、`MakeTranslation/MakeScale/MakeRotation`、
  `Translate/Scale/Rotate`（在已有矩阵上叠加）、`Concat`、`Invert`、
  `IsIdentity/IsAffine/EqualToTransform`、`MakeAffineTransform/GetAffineTransform`。
  结构体本身**没有** `.isIdentity`、`.isAffine` 成员，也**没有**
  `CATransform3D(a:b:c:d:tx:ty:)` 这种 2D 风格的构造器（只有 `m11...m44` 全 16 个参数的版本）。
  也没有 `CATransform3DPerspective` —— 透视只能手改 `m34`。
- `Concat` 不满足交换律：`Concat(Translate(10,20,30), Scale(2,3,4))` 的 m41 是 **20**，
  反过来是 **10**。记法：**后一个矩阵先作用**，所以「先缩放 2 倍再平移 10」写成
  `Concat(Translate, Scale)`，平移量会被缩放成 20。
- `IsAffine` 的判据比直觉宽：只要第三行/第三列有任何非仿射成分就是 `false`。
  实测把 z 平移从 0 改成 30（`m43=30`），`IsAffine` 立刻 `false`；
  `GetAffineTransform` 会**丢掉 z**（实测 `tx=10 ty=20` 还在、m43 消失），
  对非仿射矩阵调它返回的是没有定义的值（实测给出单位矩阵的 a/b/c/d）。
- `Invert` 对奇异矩阵静默返回全零、`EqualToTransform` 是精确比较（差 0.0001 就 `false`）——
  这两个函数都不给任何错误信号。
- **透视的做法**：给容器层的 `sublayerTransform` 设 `m34 = -1/透视距离`
  （常用 `-1/300`、`-1/500`），再让子层做 3D 旋转。值越大（分母越小）透视越强烈。
  单层旋转矩阵本身不含透视——绕 y 轴转 45° 实测只有 `m11=0.7071 / m13=-0.7071`。

## 10) `CATransaction`、动画代理与动画的拷贝/移除

### 10.1 事务：一次提交、一个完成回调

```
== 10) CATransaction、CAAnimationDelegate 与动画的拷贝/移除 ==
  commit 之后立刻：completionBlock 执行=false
  ok   setCompletionBlock 不会同步执行
  等 3 轮显示之后：执行=true
  ok   事务的 completionBlock 在显示周期之后被调用 —— 节拍器等三轮就够，不用盲跑 runloop
  CATransaction 只暴露 begin/commit/push/pop/setDisableActions/setCompletionBlock/setAnimationDuration —— 探针实测没有 getAnimationDuration
```

`CATransaction` 是隐式的：每次 runloop 里所有层的改动会被自动归到一段事务里，`commit` 时才
一起送去渲染。手动 `begin/commit` 的意义有两个——把一批改动打包成一次提交（原子性），
以及拿到 `setCompletionBlock`（这批改动**渲染完成之后**的回调）。
`setAnimationDuration` / `setAnimationDelay` 会给这一批里的隐式动画统一定时长。

注意 API 表：**没有 `getAnimationDuration`**（只有 setter）。
`setCompletionBlock` 的回调发生在显示周期之后，实测等 3 轮显示就到。

### 10.2 `CAAnimationDelegate`：start 与 stop 两个回调

```
  add 之后 delegate 日志=[]
  等它结束：日志=["start", "stop:true"] keys=nil
  ok   animationDidStart 先、animationDidStop(finished:true) 后
  ok   自然结束后 key 也被清掉
  手动 removeAnimation 之后**立刻**日志=["start"]（回调还没送到）
  再等两轮显示：日志=["start", "stop:false"]
  ok   被 removeAnimation 取消时 animationDidStop 的 finished 是 false，但回调要等显示周期
```

`finished` 参数是这一段最有用的信息：**`true` = 跑完了，`false` = 被打断**（被 `removeAnimation`、
被同 key 的新动画顶替、或层被移出树）。想做「动画结束才继续下一步，被打断则不继续」，
判断这个 flag 就够了。第二件事同样重要：**回调不是在 `removeAnimation` 那一刻同步送来的**，
要等显示周期——headless 里立刻断言会失败，实测连 `animationDidStart` 也要等一次显示才到
（上面第一行 `add 之后 delegate 日志=[]`）。

### 10.3 拷贝、多 key 与无 key

```
  copy() 之后：keyPath=Optional("opacity") fromValue=Optional(0.2) 副本 duration=5.0 原件 duration=2.0
  ok   copy() 是深拷贝，改副本不影响原件 —— 一个动画对象可以被多个层共用
  fromValue 的类型读回=Optional<Any>（Any?，所以塞错类型编译期不报错）
  同层两个 key：Optional(["p", "sample"])
  移除一个**不存在的 key**（"o"）之后：Optional(["p", "sample"])（没有异常）
  移除正确的 key 之后：Optional(["p"])
  removeAllAnimations 之后：nil
  ok   removeAllAnimations 清空所有 key
  forKey 传 nil：animationKeys=Optional(["sample"])（动画照样跑，但没有名字，只能靠 removeAllAnimations 收尾）
  ok   无 key 动画不出现在 animationKeys 里（这里只剩 animLayer 自己那条 sample）
```

- 动画对象遵守 `NSCopying`，`copy()` 是深拷贝，所以「一个动画对象挂到多个层」是安全的做法
  （反过来：**同一个对象被 add 两次会互相影响**，复用前请拷贝）。
- 同 key 再 `add` 一次会**替换**旧动画；`removeAnimation(forKey:)` 打不存在的 key 不报错。
- `forKey: nil` 的动画照样播，但**无法单独管理**——`animationKeys()` 里查不到它，
  只能 `removeAllAnimations()` 一把清。生产代码里永远给一个明确的 key。
- 一个视图/层上挂多少条动画都可以，它们各自作用在自己的 `keyPath` 上，互不冲突；
  冲突只发生在**同一个 keyPath 挂了两条**时。

## 11) `CADisplayLink`：跟屏幕同步的节拍器

本章前面所有插值读数都靠它，最后把它的参数读一遍。

```
== 11) CADisplayLink：跟屏幕同步的节拍器 ==
  新建：preferredFramesPerSecond=0 isPaused=false frameInterval? 已废弃
  新建时 duration=0.0 timestamp=0.0（都还是 0：还没有回调可供参考）；**没有 presentationTimestamp 这个属性**
  设 preferredFramesPerSecond=30 → 读回 30
  ok   默认 0 表示「按硬件原生刷新率」，设成 30 就是要求减半
  preferredFrameRateRange（iOS 15+）默认：minimum=30.0 maximum=30.0 preferred=Optional(30.0)
  设 30/60/45 → 读回 minimum=30.0 maximum=60.0 preferred=Optional(45.0)
  ok   新写法给的是一个区间，让系统在里面自适应
  再用老写法设 20 → range 变成 minimum=20.0 maximum=20.0 preferred=Optional(20.0)（两者互相覆盖）
  ok   preferredFramesPerSecond 相当于把区间两端设成同一个值
  isPaused=true 读回=true
  ok   isPaused 是「阻止回调」的开关，初始为 false
  想读 link 持有的 target？它**没有 target 这个属性**（探针里写 link.target 编译报 has no member 'target'），只能打印传进去的对象：core_animation.TickTarget
  头文件对 invalidate 的说明是「从所有 runloop mode 移除并释放 target 对象」——反过来说明 target 被强引用着，所以必须 invalidate
  本章开头那条 metronome 已经回调了 很多次 —— 它驱动了前面全部插值采样
  ok   CADisplayLink 的回调确实一次一次地把显示周期送过来（displayPass() 等的就是它）
  ok   invalidate 之后对象仍可读写，但不会再回调
  headless 说明：simctl spawn 起来的是**没有帧源**的进程，回调间隔约 15ms 但不保证，
  所以本章只用它判断「有没有刷新过一轮」，绝不打印 ticks 的具体数字。
```

- **`target` 被 link 强引用**：runloop 持有 link、link 持有 target，而 target 通常又持有视图，
  于是形成「谁都不会先释放」的环——这是 `CADisplayLink` 最经典的泄漏。头文件对 `invalidate`
  的说明正是「从所有 runloop mode 移除，并释放 target 对象」，所以**必须在停止时调用它**
  （`deinit` 里调用太晚，对象本来就释放不了）。另外注意：头文件里**没有 `target` 这个属性**，
  target 只能通过构造方法 `displayLinkWithTarget:selector:` 传进去，所以想验证它被谁持有，
  只能像本示例那样打印对象自己的类名。常用的解法是给 link 挂一个专职的转发对象
  （本示例的 `Beat`、`TickTarget` 就是这个角色）：它被强引用也不会牵住视图。
- 帧率设置两代 API：老的 `preferredFramesPerSecond`（`NSInteger`，默认 0 = 跟硬件原生刷新率）
  和 iOS 15+ 的 `preferredFrameRateRange`（`CAFrameRateRange`，字段是
  `minimum`/`maximum`/`preferred`，都是 Float，`preferred` 是 `Float?`）。
  实测两者互相覆盖：老写法设 20 会把区间的 min/max 都拉成 20。
  头文件里 `preferredFramesPerSecond` 已经标了
  `API_DEPRECATED_WITH_REPLACEMENT("preferredFrameRateRange", ios(10.0, API_TO_BE_DEPRECATED))`——
  「即将废弃」还没生效，所以现在用它不会有警告，但新代码应当直接写区间。
- `frameInterval`（`NSInteger`，含义是「隔多少帧回调一次」）在 iOS 10 起就已废弃，Swift 里
  读写它会报废弃警告，本仓库的构建判定要求零警告，所以示例只在文字里提到它。
- `duration` / `timestamp` 是「最近一次回调那一帧的时间和时长」，只有回调之后才有意义
  （本示例新建时读到 0.0）。回调里最有用的是 `targetTimestamp`：头文件说它是
  「客户端下一次渲染应当对准的时间戳」，用它做跟帧的自定义动画比用墙钟稳。

## 心智模型小结

```
动画作用在 CALayer 上：model 层存「应该是多少」，presentation 层存「此刻显示多少」，显式动画从不写回 model
读插值的三步：speed=0 掐停层钟 → add 动画 → 拨 timeOffset → 等一次真正的显示周期（CADisplayLink）
frame 是派生量：position / bounds / anchorPoint 才是真值；改 anchorPoint 会让层跳位，改 bounds.origin 不写回 frame
隐式动画只在「有 superlayer 的裸层」上发生；视图的层不参与；屏蔽用 actions[名]=NSNull 或事务 setDisableActions(true)
默认动作不都是 CABasicAnimation：hidden / sublayers 是 CATransition，backgroundColor 根本没有默认动作
CABasicAnimation 三条给值路数：from+to、只给 to（起点取 model 现值）、byValue（在当前值上加）；duration 默认 0，忘了设等于没写
fillMode 两头各管一半：开始前看 backwards/both（显示 fromValue），结束后看 forwards/both（保持 toValue）；都要先关 isRemovedOnCompletion
总时长 = duration × (autoreverses ? 2 : 1) × repeatCount；repeatCount 是 Float，无限重复用 .infinity
CAKeyframeAnimation：values+keyTimes 或直接 path；calculationMode = linear/discrete/paced/cubic/cubicPaced
values 与 keyTimes 个数不一致不崩不警告，按较少的一方配对，多出来的值被静忽略
CAAnimationGroup 是容器不是同步器：组 duration 管整组收尾，子动画各按自己的 duration 跑，beginTime 是组内相对时间
CATransition 会被换成固定 key "transition"；CASpringAnimation 会冲过终点，duration 取 settlingDuration
UIView.animate 挂的 key 就是属性名；frame 会被拆成 bounds.size + position
UIView.animate 默认曲线是 easeInEaseOut（不是 .default）、fillMode=both、from/to 是相对量 NSPoint
CATransform3D 全是自由函数；Concat 不交换；2D↔3D 互转丢 z；透视只能手改 m34；IsAffine 看整个第三行/列
CATransaction 的 completionBlock、CAAnimationDelegate 的两个回调都发生在显示周期之后
CADisplayLink 的 target 是强引用，必须 invalidate；帧率设置分两代 API 且互相覆盖
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 动画跑完画面弹回原位 | 显式动画只写 presentation，从不改 model；要么在结束时写 model，要么 `isRemovedOnCompletion=false` + `fillMode=.forwards` |
| 设了 `fromValue/toValue` 却什么都不动 | 忘了 `duration`（默认 0.0，等于不播）；`repeatCount` 默认也是 0 |
| keyPath 拼错，没有任何报错 | 非法 keyPath 静默通过，动画存在但无效果；只能对照层属性名自查 |
| 给动画传 `UIColor` 编译不过 | 颜色类 keyPath 要 `CGColor` |
| 凭直觉写 `fillMode = .none` / `.forward` | 没有这两个 case；`CAMediaTimingFillMode` 只有 `.removed/.forwards/.backwards/.both` |
| 排了延迟（`beginTime`）的动画在等待期里露出model 值 | 开始前那一段只有 `.backwards`/`.both` 会显示 `fromValue`；`.removed`/`.forwards` 实测显示 model |
| 以为 `UIView.animate` 走的是「系统默认曲线」 | 实测挂的是 `easeInEaseOut`（`0.42,0 / 0.58,1`）；`.default` 是另一条（`0.25,0.1 / 0.25,1`），要别的曲线得传 `options` |
| 关键帧动画跑完停在不该停的值上，也没有任何报错 | `values` 与 `keyTimes` 个数不一致时按较少的一方配对，多出来的被静忽略；先断言两个 count 相等 |
| 改 `anchorPoint` 之后视图位置跳了一下 | `position` 不动、`frame.origin` 重算；要跳回来得同时补 `position` |
| 设 `layer.bounds.origin` 想移动层，结果 frame 读回来没变 | `bounds.origin` 不写回 `frame`/`position`，它只偏移层内坐标系（`UIScrollView` 正是靠这个滚内容） |
| `sublayers` 顺序改了以为遮挡也改了 | 数组次序只按加入先后绘制；遮挡靠 `zPosition`，它不重排数组 |
| 自定义层设个属性就自己动起来 | 隐式动画（默认 0.25s）；用 `CATransaction.setDisableActions(true)` 或 `actions[key] = NSNull()` |
| `layer.hidden = true` 出现淡入淡出 | `hidden`/`sublayers` 的默认动作是 `CATransition`，不是数值插值 |
| 改 `backgroundColor` 没有动画 | 它没有默认动作，得显式 `add` 一条 `CABasicAnimation` |
| 探针里读 `presentation()` 永远读到起点或 model | 没等显示周期；`presentation` 只在渲染时重算，用 `CADisplayLink` 同步后再读 |
| `speed=0` 之后 `convertTime` 永远是 0 | 时钟停了，`convertTime` 输出等于 `timeOffset`；暂停要「先取时间再掐速度」 |
| 恢复动画后直接跳到结尾 | 只改了 `speed=1`，没把 `beginTime` 往前挪 `pausedTime`、没把 `timeOffset` 归零 |
| 暂停整个界面要遍历所有层 | 时钟沿 `superlayer` 继承，冻住最外层一个 `speed=0` 就够 |
| 用 `Float.infinity` 之外的方式写无限重复 | `repeatCount` 是 Float；`.infinity` 才是标准写法（`Float.greatestFiniteMagnitude` 不对） |
| 拿 `m11...m44` 猜 `CATransform3DIsAffine` 只看 m34 | z 平移（m43≠0）就已经不是仿射（实测 `IsAffine=false`） |
| `GetAffineTransform` 转回 2D 后位置不对 | z 分量被直接丢掉；非仿射矩阵的转换结果未定义 |
| 动画结束回调里 `finished` 一直是 true | `false` 才是「被打断」；`removeAnimation`、同 key 顶替都会给 false |
| `removeAnimation` 后立刻断言代理回调 | 回调要等显示周期（实测 `remove` 那一刻日志只有 `start`） |
| `forKey: nil` 的动画取消不掉 | 无 key 动画不出现在 `animationKeys()`，只能 `removeAllAnimations()` |
| `CASpringAnimation` 结束时画面停在偏离终点处 | `duration=1` 时它还在振荡（实测 100.217）；用 `settlingDuration` 当 duration |
| 组里的两个动画不同时结束 | 组只管收尾，子动画各按自己的 `duration`；要同步得自己把 duration 对齐 |
| `add(CATransition, forKey: "myKey")` 后 `removeAnimation(forKey: "myKey")` 无效 | key 被换成 `"transition"`（实测） |
| 用 `UIView.animate` 动画 `layer.frame.origin` 没反应 | 层没有可动画的 `frame`；`frame.origin` 不是有效 keyPath，位置用 `position`、尺寸用 `bounds.size` |
| 只建了 `CAEmitterLayer` 看不到粒子 | cell 的 `birthRate` 默认 0（层的是 1），且 `cells` 默认 `nil` |
| `CATextLayer` 文字巨大 | `fontSize` 默认 36，不是系统字号 17 |
| `CATextLayer.font` 设了 `UIFont` 不生效也不报错 | `font` 声明成 `AnyObject?`，要 `CGFont`/`CTFont`，或用 `fontName`+`fontSize` |
| 层上的位图在 Retina 屏发虚 | `contentsScale` 默认 1.0，挂进窗口也不会自动变成屏幕 scale，要自己设 |
| 找不到 `CALayer.zIndex` / `sublayerStyle` / `CATiledLayer.maxTiledContentDimensions` | SDK 里没有这些属性；用 `zPosition`、`levelsOfDetail`/`levelsOfDetailBias` |
| `CATransaction.getAnimationDuration()` 编译不过 | 只有 setter，没有 getter |
| 写了 `fn.getControlPoint(at: 4, values:)` 进程崩了 | `CAMediaTimingFunctionInvalidControlPoint`：下标只接受 0…3 |
| `CAMediaTimingFunction(name:)` 传自定义名字崩了 | `CAMediaTimingFunctionInvalid`：五个内置名字之外一律抛异常 |
| `CADisplayLink` 的 target 释放不掉 | target 被 link 强引用，必须 `invalidate()`；或者传一个专职的转发对象 |
| 调试时想读 `link.target` | 头文件里没有这个属性，Swift 报 `value of type 'CADisplayLink' has no member 'target'`；target 只能从构造方法传入 |
| iOS 15 上还在用 `frameInterval` | 已废弃；老写法 `preferredFramesPerSecond`，新写法 `preferredFrameRateRange`（字段是 `minimum`/`maximum`/`preferred`） |

## 小结

- 这一章的地基是一句话：**model 层是「应该」，presentation 层是「此刻」**。
  动画跑完弹回、`UIView.center` 提前读到终点、探针里读不到中间值，全都能从这句话推出来。
- 为了在 headless 里把「此刻」变成可核对的数字，本章建了一套方法：
  `speed = 0` 冻住层钟 + 手动 `timeOffset` + `CADisplayLink` 等一次真正的显示周期。
  有了它，`20→300` 的线性插值可以精确到 `90.0000 / 160.0000 / 230.0000`，
  `keyTimes` 的分段、`fillMode` 的四种收尾、弹簧的过冲都能逐条断言。
- 三层结构记牢就够用了：**几何**（position/bounds/anchorPoint，frame 是派生的）、
  **时间**（duration/repeat/autoreverses/timingFunction/speed/timeOffset）、
  **对象**（basic/keyframe/group/transition/spring + 特殊图层）。
- UIKit 的动画接口不是另一套机制，只是把属性改动翻译成挂在层上的动画：
  `alpha → opacity`、`center → position`、`frame → bounds.size + position`。
  知道这一层映射，「为什么我的动画不对」就有了排查路径。
- 特殊图层都是「配置对象」：参数可读写、结果要上屏才看得到。
  本章把每个层的**默认值**打全了，因为它们的默认值几乎每个都反直觉
  （`fontSize=36`、`cell.birthRate=0`、`shadowOffset=(0,-3)`、`contentsScale=1`）。

下一章离开动画，进入 `AVFoundation`：用 `AVAudioPlayer` 播放本地音频、
`AVAudioRecorder` 录音、`AVPlayer` + `AVPlayerLayer` 放视频、
以及音频会话（`AVAudioSession`）的分类与打断处理。

---

上一章：[22 滚动视图、容器控制器与高级控件](22-scroll-containers-controls.md) · 下一章：[24 音频与视频](24-audio-video.md)
