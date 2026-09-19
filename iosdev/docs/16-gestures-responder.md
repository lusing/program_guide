# 16 · UIKit 手势、触摸与响应链：hitTest / Responder Chain / UIGestureRecognizer

> 示例：`examples/16_gestures_responder/main.swift`
> 实测输出见 `build/16_gestures_responder/stdout.debug.txt`

一次触摸在 UIKit 里走**两段路**：

1. **Hit-Testing（命中测试）**：从窗口往下递归，找出「这个点落在哪个**最深**的视图」——
   这决定了谁是事件的第一个接收者。
2. **响应链（Responder Chain）**：命中的视图若不处理事件，就沿 `next` 往上传
   （子视图 → 父视图 → viewController → … → UIApplication），直到有人处理或到顶丢弃。

手势识别器（`UIGestureRecognizer`）挂在视图上，从触摸流里识别 tap / pan / swipe 等高级
手势。这三样是 SwiftUI 手势（`.onTapGesture`、`DragGesture`、`.gesture`）的底层。

## headless 的边界（先说清楚）

- **hitTest 与响应链**：不需要窗口，给好 `frame` 就能确定性地跑——本章大量精确断言它们。
- **手势的配置 / 挂载 / 状态机**：也能断言（`numberOfTapsRequired`、`state`、
  `view.gestureRecognizers`）。
- **手势识别成功后触发 target-action**：**不能** headless 验证。本机实测，`sendActions(for:)`
  和手动把手势 `state` 改成 `.recognized` 都**不会**触发 action（`fired == 0`）——action
  派发依赖真实的 UIKit 事件系统（窗口 + run loop + 真实触摸）。所以本章只断言到「配置与
  状态」这一层，不假装能验证 action 派发。诚实划边界，是本教程一贯的纪律。

## 1) Hit-Testing：触摸落在哪个视图

`hitTest(_:with:)` 从接收者开始，**逆序**（从最上层子视图往下）遍历子视图，对每个
先判 `point(inside:with:)`，命中就递归进去，最终返回**最深**的那个包含该点的视图：

```swift
let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
let a = UIView(frame: CGRect(x: 10, y: 10, width: 80, height: 80));  a.tag = 1
let b = UIView(frame: CGRect(x: 100, y: 100, width: 80, height: 80)); b.tag = 2
root.addSubview(a); root.addSubview(b)

root.hitTest(CGPoint(x: 20, y: 20), with: nil)     // === a
root.hitTest(CGPoint(x: 150, y: 150), with: nil)   // === b
root.hitTest(CGPoint(x: 5, y: 150), with: nil)     // === root（不在任何子视图内）
a.point(inside: CGPoint(x: 5, y: 5), with: nil)    // true（在 a 自己坐标系里）
```

```
-- hitTest：从父到子，找最深的命中视图 --
  ok   点 (20,20) 命中 a（tag=1）
  ok   点 (150,150) 命中 b（tag=2）
  ok   点 (5,150) 不在 a/b 内，命中父 root
  ok   point(inside:) 判断点是否落在视图内
```

- `hitTest` 收到的点是**接收者坐标系**里的；它会把点转换到每个子视图坐标系再递归。
- `point(inside:)` 是判据：某点是否落在**自己 bounds** 内。`hitTest` 默认实现就是
  「先 `point(inside:)`，再逆序问子视图」。

## 2) hitTest 会跳过哪些视图

有三种视图**不参与**命中测试（`hitTest` 直接跳过它们，落到它们背后的视图）：

```swift
a.isUserInteractionEnabled = false   // 禁用交互
a.isHidden = true                    // 隐藏
a.alpha = 0.0                        // 近乎透明（< 0.01）
```

```
-- hitTest 跳过：禁用交互 / 隐藏 / 近乎透明 --
  ok   isUserInteractionEnabled=false → 被跳过，命中父视图
  ok   isHidden=true → 被跳过
  ok   alpha<0.01 → 被跳过（视为不可见）
  ok   恢复后又能命中 a
```

> **调试利器**：「这个按钮点不到」十有八九是它或它的某个祖先 `isUserInteractionEnabled`
> 为 `false`、被 `isHidden`、或 `alpha` 太低，或有别的透明视图盖在上面挡住了 hitTest。
> 用 `hitTest` 打个断点看返回的是谁，一目了然。

## 3) 重写 point(inside:)：扩大触摸热区

小按钮（比如 20×20 的关闭叉）很难点中。标准做法是重写 `point(inside:)`，把命中区域
往外扩，**而不改变视觉大小**：

```swift
final class BigHitView: UIView {
    var inset: CGFloat = -20      // 负 inset = 往外扩 20pt
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: inset, dy: inset).contains(point)
    }
}
```

```
-- 重写 point(inside:)：扩大触摸热区 --
  扩大热区后，框外 10pt 的点命中 = small（热区生效）
  ok   重写 point(inside:) 后，frame 外的点也能命中（热区被扩大）
```

实测里一个 frame 只有 20×20 的视图，点在它 frame **外** 10pt 处，`hitTest` 仍返回了它
——因为 `point(inside:)` 把热区扩到了 60×60。Apple 建议可点击目标至少 44×44pt，这个技巧
让你在视觉不臃肿的前提下达到它。

## 4) 响应链：事件往上传

命中的视图成为**第一响应者**候选。如果它不处理某个事件（比如 `touchesBegan` 没实现或
调了 `super`），事件沿 `next` 往上传，这条链就是**响应链**：

```
子视图 → 父视图(superview) → 所在 viewController.view → viewController
       → 父 viewController → … → UIWindow → UIApplication → AppDelegate
```

```swift
a.next           // === root（子视图的 next 是 superview）
vc.view.next     // === vc（根视图的 next 是它的 viewController）
```

```
-- 响应链：view.next → 父视图 → viewController --
  ok   子视图的 next 是它的 superview
  ok   根视图的 next 是它的 viewController
  ok   viewController 再往上（无父时）不指向自己
  ok   没成为第一响应者时 isFirstResponder=false
  ok   普通 UIView 默认 canBecomeFirstResponder=false，becomeFirstResponder 返回 false
```

**第一响应者（first responder）** 是当前接收键盘输入和非触摸事件的那个对象。`UITextField`
成为第一响应者时弹出键盘。普通 `UIView` 的 `canBecomeFirstResponder` 默认是 `false`，
所以 `becomeFirstResponder()` 返回 `false`（实测）——只有文本输入类控件、以及重写了
`canBecomeFirstResponder` 返回 `true` 的视图才能成为第一响应者。

响应链还负责**动作消息**（`UIResponder` 的 `copy:`/`paste:`/自定义 `@objc` action）的
传递：`UIApplication.sendAction(_:to:nil, …)` 会沿响应链找第一个能响应的对象——这就是
「不指定 target 的 action 会自动找到该处理它的控制器」的原理。

## 5) UIGestureRecognizer：类型、配置、状态机

手势识别器把原始触摸流**识别**成高级手势。常用几种：

```swift
let tap = UITapGestureRecognizer()
tap.numberOfTapsRequired = 2       // 双击
tap.numberOfTouchesRequired = 1    // 单指
tap.state                          // .possible（刚建好，还没开始识别）

let swipe = UISwipeGestureRecognizer(); swipe.direction = .left
let pan = UIPanGestureRecognizer()          // 拖拽（连续）
let pinch = UIPinchGestureRecognizer()      // 捏合缩放（连续）
let longPress = UILongPressGestureRecognizer()   // 长按（连续）
```

```
-- UIGestureRecognizer：类型、配置、初始状态 --
  ok   Tap：可配置需要几次点击（双击=2）
  ok   Tap：可配置需要几根手指
  ok   刚建好的手势状态是 .possible（还没开始识别）
  ok   Swipe：可配置方向
  三种连续/离散手势类型 = UIPanGestureRecognizer, UIPinchGestureRecognizer, UILongPressGestureRecognizer
  状态值：possible=0 began=1 recognized/ended=3
  ok   .possible 的 rawValue 是 0
  ok   .recognized 与 .ended 是同一个值（离散手势用 recognized，连续手势用 ended）
```

**手势状态机**（`UIGestureRecognizer.State`）：

```
离散手势（tap / swipe）：  possible → recognized(=ended)
连续手势（pan / pinch / longPress）：
                          possible → began → changed(反复) → ended
                                      ↘ failed / cancelled
```

- **离散手势**一次性识别成功，直接从 `.possible` 跳到 `.recognized`（`.ended` 是它的别名，
  rawValue 都是 3）。
- **连续手势**经历 `.began → .changed（多次）→ .ended`，你在 `.changed` 里持续读
  `translation`/`scale` 更新界面。
- `.failed` / `.cancelled` 表示识别失败或被取消。

## 6) 挂载手势到视图

```swift
let target = UIView(frame: …)
target.addGestureRecognizer(tap2)
target.gestureRecognizers?.count        // 1
target.addGestureRecognizer(pan2)
target.gestureRecognizers?.count        // 2
target.removeGestureRecognizer(tap2)
target.gestureRecognizers?.count        // 1
```

```
-- 把手势挂到视图上 --
  ok   addGestureRecognizer 后，视图持有 1 个手势
  ok   持有的正是刚加的那个 tap
  ok   再加一个 pan，视图持有 2 个手势
  ok   removeGestureRecognizer 后剩 1 个
```

手势挂在视图上，`view.gestureRecognizers` 是它的数组。一个视图可以挂多个手势。默认情况
下多个手势会互相竞争（一个识别成功会让别的 `.failed`）；要让它们**同时**识别，实现
`UIGestureRecognizerDelegate` 的 `gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)`
返回 `true`。还有 `require(toFail:)` 表达「先等某个手势失败我才识别」（比如单击等双击失败）。

## 心智模型小结

```
触摸两段路：hitTest 找最深命中视图 → 响应链沿 next 往上传递
被跳过的视图：isUserInteractionEnabled=false / isHidden / alpha<0.01
重写 point(inside:) 可扩大点击热区（小按钮友好）
手势识别器挂在视图上，从触摸流识别 tap/pan/swipe/pinch/longPress
action 派发需要真实事件系统；headless 只验证到配置/状态/挂载这一层
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 视图点不到 | 它或祖先 `isUserInteractionEnabled=false` / `isHidden` / `alpha<0.01`，或被透明视图挡住 |
| 小按钮难点中 | 重写 `point(inside:)` 扩大热区，或加约束到 ≥44×44 |
| 手势和 scrollView 滚动打架 | 用 delegate 的 `shouldRecognizeSimultaneouslyWith` 或 `require(toFail:)` |
| 双击手势永远只触发单击 | 让单击 `require(toFail: 双击)`，否则单击先赢 |
| 事件没到 viewController | 中间的视图把 `touchesBegan` 吃了没往上传（没调 `super`） |
| action 不触发（headless） | 正常——action 派发要真实事件系统；本章不测它 |
| 连续手势只收到一次 | 要在 `.changed` 状态持续处理，不是只在 `.ended` |

## 小结

- 触摸两段路：**hitTest** 找最深命中视图（跳过禁用/隐藏/透明的），**响应链**沿 `next`
  把未处理的事件往上传。
- 重写 `point(inside:)` 扩大热区，是小控件友好化的标准手法。
- 第一响应者接收键盘/非触摸事件；普通 `UIView` 默认不能成为第一响应者。
- `UIGestureRecognizer` 有类型（tap/swipe/pan/pinch/longPress）、配置（点击数、手指数、
  方向）和**状态机**（possible→began→changed→ended / recognized）。
- action 派发依赖真实事件系统，headless 只能验证到配置/状态/挂载。
- **第四篇（UIKit 补充，14–16）完成**。第五篇（17–20）进入系统能力与工程：网络与并发、
  数据持久化、权限与设备能力、打包签名上架。
