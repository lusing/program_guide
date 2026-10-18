# 15 · 动画：隐式、Hero 与显式

> 对应示例：examples/15_animation/

## 15.1 解决什么问题

"界面切换时生硬地变了"和"平滑地变了"，用户感知差一个档次。Flutter 动画分三档，控制力与复杂度递增——先知道哪档解决什么，再按需学：

| 档 | 工具 | 一句话 |
|---|---|---|
| 隐式 | `AnimatedXxx` | **改属性值**，动画自动发生 |
| 转场共享 | `Hero` | 两个页面的同款元素飞过去 |
| 显式 | `AnimationController` | 亲自驱动 0→1 的时间线 |

选型口诀：**能用隐式不用显式**——隐式动画一行 duration 解决的事，显式要写 Controller + Tween + dispose 一整套。只有"隐式表达不了"（手势跟手、精确时序、多段组合）才上显式。

## 15.2 隐式动画：改值即动

```dart
          // ═══ 15.1 隐式动画：改属性值，动画自动发生 ═══
          // ListView 给子项的宽度约束是"紧"的，先 Center 放松，width 才生效
          GestureDetector(
            onTap: () => setState(() => _big = !_big),
            child: Center(
              child: AnimatedContainer(
                key: const Key('animated-box'),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                width: _big ? 160.0 : 80.0,
                height: 64,
                color: _big ? Colors.deepPurple : Colors.deepPurple.shade200,
              ),
            ),
          ),
```

AnimatedContainer 与 Container 用法完全一致，只多 `duration` 与 `curve`：setState 换了属性值，它**从旧值补间到新值**而不是跳变。`Curves` 选节奏：easeOutCubic（先快后缓，UI 最常用）、easeInOut、bounceOut（弹跳）。

示例里还埋了个布局课（第 04 章 Align 的隐藏用途）：ListView 给子项的宽度约束是紧的，AnimatedContainer 的 `width` 会被顶满——**套 Center 放松约束**，width 才听你的。测试直接量尺寸断言动画结果（80 → 160）。

### 隐式动画全家桶

| Widget | 动画的属性 | 典型场景 |
|---|---|---|
| `AnimatedContainer` | 宽高/颜色/边距/圆角/装饰 | 卡片展开、选中态 |
| `AnimatedOpacity` | opacity | 淡入淡出 |
| `AnimatedPadding` | padding | 展开时让位 |
| `AnimatedAlign` | alignment | 元素挪位 |
| `AnimatedPositioned` | Stack 里的位置/尺寸 | 浮动按钮移位 |
| `AnimatedSize` | 子树尺寸 | 内容展开收拢 |
| `AnimatedSwitcher` | 孩子切换 | 两个 Widget 交叉淡变 |

`AnimatedSwitcher` 值得单独说——别的 AnimatedXxx 是"同一 Widget 的属性渐变"，它是"**孩子换人了**"的过渡：旧孩子淡出、新孩子淡入，自动管理两个孩子的生命周期：

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: _loading
      ? const CircularProgressIndicator(key: ValueKey('loading'))
      : const Icon(Icons.check, key: ValueKey('done')),
)
```

注意两个孩子**必须 key 不同**——AnimatedSwitcher 靠 key 区分"是不是同一个孩子"，key 相同它认为没换、不做过渡。

### Curve 速查

| Curve | 节奏 | 场景 |
|---|---|---|
| `Curves.linear` | 匀速 | 机械进度 |
| `Curves.easeOut` / `easeOutCubic` | 快出缓停 | 元素进场（最常用） |
| `Curves.easeInOut` | 缓起缓停 | 属性来回切换 |
| `Curves.bounceOut` | 到底弹跳 | 俏皮的小元素 |
| `Curves.elasticOut` | 过冲回弹 | 强调出现 |

## 15.3 Hero：跨页共享元素

```dart
          Center(
            child: Hero(
              tag: 'logo',
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple.shade100,
                child: const Icon(Icons.flutter_dash),
              ),
            ),
          ),
```

两个页面各放一个 `Hero(tag: 相同, child: ...)`，push/pop 时框架把同 tag 元素"飞行过渡"（列表页小图 → 详情页大图）。规则：**tag 是匹配键**（同页冲突会抛错）；只有走 Navigator 转场才有效；child 首尾可以不同（飞行中变形——示例里 radius 24 → 64，圆头像平滑放大）。

### Hero 的边界

- **同 tag 多元素**：同一时刻树里两个同 tag 的 Hero 会抛"duplicate hero tag"——列表页 20 个条目就 `tag: 'item-${item.id}'` 保证唯一。
- **非 Navigator 转场不触发**：Tab 切换、对话框弹出都不走 Hero——它只监听路由 push/pop。
- **child 类型最好一致**：开头 Icon 结尾 Container 也能飞（飞行中渐变形状），但跨材质（图片 → 纯色块）视觉突兀——常见做法是首尾同 Widget 只改尺寸。

## 15.4 显式动画：AnimationController

```dart
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..addListener(() => setState(() {}));

  // …
          SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment(-0.9 + 1.8 * _controller.value, 0),
              child: const Icon(Icons.directions_run),
            ),
          ),
          FilledButton(
            onPressed: () {
              _controller.forward(from: 0); // 从头跑一次 0 → 1
            },
            child: const Text('跑一格'),
          ),
```

需要"按自己意志驱动"的动画（进度的任意位置、组合多属性、手势跟手）用 Controller：它是一条 0.0→1.0 的时间线（`value` 是当前位置），`vsync: this` 来自 `SingleTickerProviderStateMixin`（把动画与屏幕刷新同步、页面隐藏时暂停）。操作集：

| 方法 | 语义 |
|---|---|
| `forward({from})` | 从当前值（或 from）跑到 upperBound（默认 1.0） |
| `reverse({from})` | 反向跑回 lowerBound（默认 0.0） |
| `repeat({reverse: true})` | 循环（reverse: true 来回摆） |
| `animateTo(target)` | 跑到指定值 |
| `stop()` | 停在当时 |
| `reset()` | 值归 lowerBound（不启动） |
| `fling(velocity)` | 按物理初速度甩出去（跟手感的底层） |

`lowerBound`/`upperBound` 构造参数可改范围（比如 `-1.0 ~ 1.0` 的摆动）；`value` 也可写——`controller.value = 0.5` 直接跳到一半（手势拖拽跟手就是这么做的：`onPanUpdate` 里按拖动距离比例写 value）。

### Tween：0→1 到任意值域

Controller 的值永远是 0.0→1.0，实际动画要的是颜色、尺寸、偏移——`Tween` 做线性映射：

```dart
final _sizeTween = Tween<double>(begin: 24, end: 96);
// build 里：_sizeTween.evaluate(_controller) 得当前值
```

`Tween.animate(controller)` 返回一个 `Animation<T>`（值随 controller 走、类型是 T）；`Tween.evaluate(controller)` 一次性求值。常用子类：`ColorTween`（颜色渐变）、`SizeTween`、`OffsetTween`、`RectTween`（Hero 底层用它）、`IntTween`（整数步进，比如计数器滚动）。

### AnimatedBuilder：不重建整个 build

示例用 `addListener(() => setState(() {}))` 是最直白的写法，但每次 tick 都重建整个 build——页面复杂时浪费。`AnimatedBuilder` 把重建圈在局部：

```dart
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) => Transform.rotate(
    angle: _controller.value * 2 * pi,
    child: child,  // 静态孩子走这条通道，不重建
  ),
  child: const Icon(Icons.refresh, size: 48),  // 静态部分只建一次
)
```

`child` 参数是性能关键：builder 每次 tick 都跑，但 `child` 参数只 build 一次、原样传给 builder——把不随动画变的部分提到 child 里。多个动画监听同一个 controller 时，AnimatedBuilder 比 addListener+setState 的粒度优势更明显（每个 AnimatedBuilder 只重建自己的子树）。

### SingleTickerProviderStateMixin 还是 TickerProviderStateMixin

`vsync: this` 要求 State 混一个 TickerProvider：

- **一个** AnimationController → `SingleTickerProviderStateMixin`（示例用法）
- **多个** Controller → `TickerProviderStateMixin`

混错了编译期不报错、运行期才炸（"Multiple tickers were created" 或 "A SingleTickerProviderStateMixin can only be used once"）——按 Controller 数量选。

**dispose 纪律**：Controller 持有原生定时资源，State 的 dispose 里必放 `_controller.dispose()`（lint 不查这个，靠自觉）。

## 15.5 动画的测试策略

动画测试的核心是**假时钟**（widget 测试自动用 FakeAsync）：`pump(Duration)` 推进时间、`pumpAndSettle()` 推进到没有新帧。三个注意点：

- `pumpAndSettle` 等"所有动画完成"——`repeat()` 永不完成，测试里别用无限循环动画（改用 `forward` 或手动 `pump`）
- 隐式动画同样吃假时钟：`pump(400ms)` 后 AnimatedContainer 已到位，可以直接量尺寸断言
- 示例的测试就是这套：量 AnimatedContainer 的 Size（80 → 160）、pump 600ms 后断言 Align 的 alignment 到了终点

## 坑位清单

- **Controller 忘 dispose**：页面销毁后 ticker 还在跑——泄漏 + 测试炸"Timer is still pending"。
- **vsync 忘 with**：编译错（this 不是 TickerProvider）——`with SingleTickerProviderStateMixin`（多个动画用 TickerProviderStateMixin）。
- **repeat() 配 pumpAndSettle**：永不停止的动画让测试的 settle 等到超时——测试里用 forward() 或手动 pump。
- **AnimatedXxx 属性值没变**：值相同不触发（补间需要起止差）——检查是不是真的 setState 换了值。
- **AnimatedSwitcher 两个孩子同 key**：框架认为没换人，不做过渡——给两个孩子不同的 ValueKey。
- **addListener+setState 重建整个页面**：复杂页面用 AnimatedBuilder 圈住重建范围，静态孩子走 child 参数。
- **Hero tag 冲突**：列表页 N 个同 tag 直接抛错——tag 里带唯一标识（`item-${note.id}`）。
- **手势跟手直接改 value 忘了 stop**：`onPanEnd` 里不 `stop()` 的话 controller 还在按旧速度走——跟手拖拽的收尾要么 fling 要么 stop+animateTo。
---

上一章：[14 · 异步 UI：把 Future 画出来](14-async-ui.md) ｜ 下一章：[16 · 主题与响应式：一处定义，处处生效](16-theme.md) ｜ 返回：[README](../README.md)
