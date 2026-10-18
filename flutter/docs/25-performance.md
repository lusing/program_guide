# 25 · 性能优化与质量债

> 对应示例：examples/25_performance/

## 25.1 解决什么问题

"卡"有两类原因：**真性能问题**（构建/布局/绘制超帧预算）和**质量债**（状态残留、索引错位这类"功能正确性慢半拍"）。2020 年书的第 16 章（优化应用）通篇在还质量债——那份清单至今成立，先还债再谈性能，是正确的顺序。本章两部分：书的四件质量债 + Flutter 性能三板斧，示例工程用"重建计数实验室"把抽象的"重建开销"变成**肉眼可见、测试可断言**的数字。

### 帧预算：16ms 从哪来

屏幕 60Hz 刷新 = 每 16.7ms 出一帧；120Hz = 8.3ms。Flutter 的一帧分两个线程跑：

- **UI 线程**：跑 Dart 代码（build/layout）——你的 build 方法在这里
- **Raster 线程**：GPU 绘制（Skia/Impeller 指令）

任何一帧任一线程超预算，就是掉帧（jank）。性能优化的全部目标：**让两个线程都在预算内**。`P` 键开的 performance overlay 上红条是 UI 线程、下红条是 raster 线程——哪根红看哪根。

## 25.2 书的质量债四件套

1. **登出不清状态**：自动登出后 `_selectedNewsId` 残留，下次进编辑页拿到脏数据（书 16.1）。规矩：**会话级状态随登出重置**——23 章 `logout()` 里 timer、user、prefs 全清是完整示范。
2. **initialValue 丢值**：长表单滑出屏幕后提交，`onSaved` 拿不到值（书 16.2 的真实 bug）。解法：**controller 化**——值住在 controller 里不随滚动丢（第 11 章 controller 的进阶理由）。一战后书的改法就是给每个框补 controller、去掉 initialValue。
3. **索引错位**：过滤模式下"索引 1"其实是全量列表的"索引 3"，导航/删除指错人（书 16.2 第二个 bug）。解法：**id 寻址**——22 章的"按实体操作"正是同一教训的解法（`ValueKey(item)`、`remove(item)` 同一性匹配）。书当年改成 `'/news/' + news.id` 路由，思路一致。
4. **analyze 清零 + 密钥集中**：`flutter analyze` 报的 unused_import 逐一清掉；API key 收进独立配置文件，不散落硬编码（书 16.3）。本教程"零告警"标准就是这条的常态化。

## 25.3 构建性能三板斧

```dart
// ═══ 25.3 const 卡与非常量卡：同一次父级 setState，命运不同 ═══
Column(children: [
  const BuildCounterCard(key: ValueKey('const'), label: 'const 构造'),   // 永不重建
  BuildCounterCard(key: ValueKey('var'), label: '每次新建'),   // 每次 rebuild
])
```

### const 构造：跳过整棵子树

Widget 不可变（第 03 章）的直接收益：**const 构造的 Widget 在编译期被规范化（canonicalized）**——`const Text('a')` 在整棵树的任何地方都是同一个实例。框架 diff 时见到"新配置与旧配置 identical"，直接跳过这棵子树的 build 比较。示例里两张计数卡放同屏对比：点"重建父级"，const 卡计数纹丝不动，非常量卡逐次 +1（widget 测试锁死这个差值）。

日常含义：**能 const 的地方全 const**——尤其是 ListView item、长树里的静态子树。`flutter analyze` 的 `prefer_const_constructors` / `prefer_const_literals_to_create_immutables` 提示就是免费清单，全清。

### ListView.builder：懒构建

`ListView(children: [...])` 是全量构建——500 条数据 500 个 Widget 一次性全建，哪怕只看见 5 条。`ListView.builder` 只构建可视区 ± cacheExtent 的条目（12 章已用 40 条断言过"远处未构建"）。**长列表禁用 children 构造**，没有例外。

### build 拆小：缩小变化半径

巨型 build 方法里任何一处 setState 都全量重跑——哪怕只有一行 Text 变了。按"变化半径"拆组件：把"随数据变的部分"提取成独立 Widget，让 setState 只重建它。09 章的精确订阅、22 章的 Descendant builder 都是同一思想：**谁的数据变，谁重建**。配合 const 构造，可以把重建圈到最小范围。

## 25.4 重绘隔离与 Key 家族

### RepaintBoundary：绘制层隔离

构建（build）之外的另一个开销源是**绘制（paint）**——Widget 没变但内容在动（转圈的进度条、实时跳动的数字），整页重绘浪费。`RepaintBoundary` 把子树拆成独立的绘制层（Layer）：子树内部重绘不传染给父级，父级重绘也不重画它。

```dart
RepaintBoundary(
  child: AnimatedBuilder(
    animation: _spinController,
    builder: (_, child) => Transform.rotate(angle: _spinController.value * 2 * pi, child: child),
    child: const ComplexStaticWidget(),  // 静态部分也一起隔离
  ),
)
```

判断时机：**DevTools 的 Performance 页看到某个子树频繁重绘**才加——RepaintBoundary 本身有层管理开销，滥用反而慢。先测量后优化。

### Key 家族

Key 决定 Element 与 Widget 的匹配规则（第 22 章 Dismissible 已强制过一次）：

| Key | 匹配依据 | 场景 |
|---|---|---|
| `ValueKey(v)` | 值相等 | 列表项业务 id |
| `ObjectKey(o)` | 同一性 | 同值不同物（两个同名条目） |
| `UniqueKey()` | 永不相等 | 强制每次重建（慎用） |
| `GlobalKey` | 全局注册表 | 跨树取 State/复用 State |

性能相关的 Key 用法：列表项的 Key 让框架识别"同一条目"——重排时 Element 跟着 Key 走，State（比如输入中的 TextField）不丢。漏 Key 或 Key 随索引变，过滤/排序后 Element 错配，输入框内容"跳"到别的行上。

## 25.5 测量先行

性能问题的第一步是**复现和观测**，不是改代码：

- `P` 键（`flutter run`）开 performance overlay：上红条=UI 线程超帧，下红条=raster 线程超帧（21 章键位表）。
- DevTools 的 Performance 视图：帧时间线 + 火焰图，定位是哪个 build 吃掉了 16ms。火焰图里横条越长 = 该函数耗时越久——找最长的横条，那就是瓶颈。
- 两个 debug 全局量（改完热重启）：

```dart
debugPrintRebuildDirtyWidgets = true;   // 每帧打印哪些 widget 被重建（找过度重建）
debugPrintLayouts = true;               // 布局风暴排查
```

示例工程把前者做成开关——打开后点"重建父级"，控制台立刻列出每次重建的 widget 名单，const 卡**不会出现在名单里**。

### DevTools Performance 页怎么看

1. 录制几秒交互（点按钮、滚动列表）
2. 时间线上**红色帧**就是超帧——点击它
3. 下方火焰图从下往上读：底部是 build 根，往上是逐级调用——**找最宽的非框架横条**（`package:flutter/...` 是框架代码，先看自己的 `package:myapp/...`）
4. 常见元凶：build 里做计算（排序/JSON 解析）、build 里建 Future、巨型 build 方法、未 const 的静态子树

## 25.6 图片与内存

- **解码尺寸**：`Image.asset/network(file)` 传 `cacheWidth`（或 24 章选取时的 `maxWidth`）——4000px 原图在 200px 的框里照样按全尺寸解码进内存，是移动端 OOM 常客。`cacheWidth` 让解码器直接产出目标尺寸，内存省两个数量级。
- **ImageCache 默认上限**：1000 张 / 100MB（`PaintingBinding.instance.imageCache`）——超限最久未用的被逐出。一般不用管；图片特别多的应用（相册类）可以调 `maximumSizeBytes` 或手动 `evict`。
- **precacheImage 预热**：`precacheImage(AssetImage('hero.png'), context)` 在 build 前解码进缓存——首屏关键图避免"白框一闪再出图"。
- **dispose 纪律**：controller/animationController/focusNode 用完即弃（第 08/15 章）。
- **数据拷贝最小化**：22 章"防御性拷贝"每次 getter 新建列表——读多改少的场景可回 `List.unmodifiable` 包一层（视图而非拷贝）。

## 25.7 什么时候不该优化

性能优化有成本（代码复杂度、可读性）。两条"别优化"的纪律：

- **没测量过的不优化**：凭感觉加的 RepaintBoundary、提前的 const、手动的缓存——大概率没用甚至负优化。先 DevTools 定位，再动手。
- **一次性操作不优化**：启动时的一次性重活（读配置、建模型）不在帧预算内——用户等半秒启动可以接受，不值得为它引入异步复杂度。优化对象是**重复发生**的操作（滚动、动画、每次输入）。

## 坑位清单

- **凭感觉优化**：先 overlay/DevTools 定位，再动手——大部分"卡"的锅在一两处具体代码。
- **长表单 initialValue**：滚动丢值是真实 bug（书 16.2 原案）——controller 化。
- **列表用索引寻址**：过滤/排序后索引错位——id 或实体寻址。
- **忘 const**：ListView item、静态子树全部补上；`flutter analyze` 的 `prefer_const_constructors` 提示就是免费清单。
- **图片全尺寸解码**：小框大图必传 `cacheWidth`。
- **登出不清会话状态**：残留数据在下次登录冒出来（书 16.1 原案）。
- **RepaintBoundary 滥用**：层本身有管理开销——DevTools 看到具体子树频繁重绘再加。
- **build 里做重活**：排序、JSON 解析、建 Future 都挪出去（initState/回调/缓存）——build 应该只是"描述"。
---

上一章：[24 · 相机与图库：媒体选取](24-camera-gallery.md) ｜ 下一章：[26 · Cupertino 与平台自适应](26-adaptive.md) ｜ 返回：[README](../README.md)
