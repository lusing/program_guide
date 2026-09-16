# 15 · 动画：隐式、Hero 与显式

> 对应示例：examples/15_animation/

## 15.1 解决什么问题

"界面切换时生硬地变了"和"平滑地变了"，用户感知差一个档次。Flutter 动画分三档，控制力与复杂度递增——先知道哪档解决什么，再按需学：

| 档 | 工具 | 一句话 |
|---|---|---|
| 隐式 | `AnimatedXxx` | **改属性值**，动画自动发生 |
| 转场共享 | `Hero` | 两个页面的同款元素飞过去 |
| 显式 | `AnimationController` | 亲自驱动 0→1 的时间线 |

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

AnimatedContainer 与 Container 用法完全一致，只多 `duration` 与 `curve`：setState 换了属性值，它**从旧值补间到新值**而不是跳变。全家桶：AnimatedOpacity（淡入淡出）、AnimatedPadding、AnimatedAlign、AnimatedSwitcher（孩子切换时自动过渡）。`Curves` 选节奏：easeOutCubic（先快后缓，UI 最常用）、easeInOut、bounceOut（弹跳）。

示例里还埋了个布局课（第 04 章 Align 的隐藏用途）：ListView 给子项的宽度约束是紧的，AnimatedContainer 的 `width` 会被顶满——**套 Center 放松约束**，width 才听你的。测试直接量尺寸断言动画结果（80 → 160）。

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

两个页面各放一个 `Hero(tag: 相同, child: ...)`，push/pop 时框架把同 tag 元素"飞行过渡"（列表页小图 → 详情页大图）。规则：**tag 是匹配键**（同页冲突会抛错）；只有走 Navigator 转场才有效；child 首尾可以不同（飞行中变形）。

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

需要"按自己意志驱动"的动画（进度的任意位置、组合多属性、手势跟手）用 Controller：它是一条 0.0→1.0 的时间线（`value` 是当前位置），`vsync: this` 来自 `SingleTickerProviderStateMixin`（把动画与屏幕刷新同步、页面隐藏时暂停）。消费 `value` 的两种姿势：addListener+setState（示例这样最直观）或 Tween/AnimatedBuilder（不重建整个 build）。操作集：`forward(from:)` / `reverse()` / `repeat()` / `stop()`。

**dispose 纪律**：Controller 持有原生定时资源，State 的 dispose 里必放 `_controller.dispose()`（lint 不查这个，靠自觉）。

## 坑位清单

- **Controller 忘 dispose**：页面销毁后 ticker 还在跑——泄漏 + 测试炸"Timer is still pending"。
- **vsync 忘 with**：编译错（this 不是 TickerProvider）——`with SingleTickerProviderStateMixin`（多个动画用 TickerProviderStateMixin）。
- **repeat() 配 pumpAndSettle**：永不停止的动画让测试的 settle 等到超时——测试里用 forward() 或手动 pump。
- **AnimatedXxx 属性值没变**：值相同不触发（补间需要起止差）——检查是不是真的 setState 换了值。
