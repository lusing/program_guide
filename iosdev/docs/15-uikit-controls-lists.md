# 15 · UIKit 控件与列表：UITableView / 复用 / Diffable Data Source

> 示例：`examples/15_uikit_controls_lists/main.swift`
> 实测输出见 `build/15_uikit_controls_lists/stdout.debug.txt`

SwiftUI 的 `List` 底层就是 `UITableView`/`UICollectionView`。这一章讲清 UIKit 列表的
经典三件套——`dataSource` / `delegate` / cell 复用——以及现代的 **diffable data source**。
看懂它，你既读得懂老代码，也更能理解 SwiftUI `List` 的 `Identifiable`、行复用（第 11 章）
到底在做什么。

headless 说明：`UITableView` 给个 `frame`、`reloadData()` 之后，`numberOfSections`、
`numberOfRows`、`cellForRow(at:)`、diffable 的 `snapshot()` 都能**同步**读出来，不需要
挂窗口。控件的属性读写、选中状态同理。

## 1) 常用控件：属性读写

先把几个高频控件过一遍——都是设置属性、读属性：

```swift
let label = UILabel(); label.text = "标题"; label.numberOfLines = 0   // 0 = 不限行数

var config = UIButton.Configuration.filled(); config.title = "确定"
let button = UIButton(configuration: config)                          // 现代按钮写法

let field = UITextField(); field.text = "输入内容"; field.placeholder = "请输入"
let toggle = UISwitch(); toggle.isOn = true
let slider = UISlider(); slider.minimumValue = 0; slider.maximumValue = 100
slider.value = 42
slider.value = 999      // 超上限被夹到 maximumValue
```

```
-- 常用控件 --
  ok   UILabel：text / numberOfLines
  ok   UIButton：Configuration 里设 title
  ok   UITextField：text / placeholder
  ok   UISwitch：isOn
  ok   UISlider：value 在 min/max 之间
  ok   UISlider：value 超过 maximumValue 被夹到 100
```

要点：

- **`UIButton.Configuration`**（iOS 15+）是配置按钮的现代方式（标题、图片、内边距、
  样式一把梭），替代老的 `setTitle(_:for:)` 一堆分散调用。
- **`numberOfLines = 0`** 让 `UILabel` 不限行数（配合约束自动换行撑高）。
- **`UISlider.value` 会被夹到 `[minimumValue, maximumValue]`**——设 999 实际存 100。

## 2) UITableView：dataSource 决定「有多少行、每行内容」

`UITableViewDataSource` 是列表的**数据契约**，两个必须实现的方法：

```swift
final class MyDataSource: NSObject, UITableViewDataSource {
    let rows = ["苹果", "香蕉", "樱桃"]
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = rows[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
}
let table = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), style: .plain)
table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
table.dataSource = dataSource
table.reloadData()
```

```
-- UITableView：dataSource 决定行数与内容 --
  numberOfSections=1  numberOfRows=3
  ok   dataSource 报告 1 个 section
  ok   dataSource 报告 3 行
  第 0 行文本 = 苹果
  ok   cellForRowAt 配置出了第 0 行「苹果」
```

- `numberOfRowsInSection` / `numberOfSections`：告诉 tableView 有多少内容。tableView 的
  `numberOfRows(inSection:)` 就是转调你的 dataSource。
- `cellForRowAt`：给某个 `IndexPath` 返回一个**配置好**的 cell。tableView 只为**可见**
  的行调它。
- `reloadData()`：数据变了，让 tableView 重新问一遍 dataSource。
- `defaultContentConfiguration()`（iOS 14+）是配置 cell 文本/图片的现代方式，替代
  `cell.textLabel?.text`。

## 3) 单元格复用：dequeueReusableCell

这是 `UITableView` 能流畅滚动上万行的**核心机制**：

```swift
let reused = table.dequeueReusableCell(withIdentifier: "Cell", for: IndexPath(row: 1, section: 0))
reused.reuseIdentifier   // "Cell"
```

```
-- 单元格复用：dequeueReusableCell --
  ok   dequeue 出来的 cell 带着注册时的 reuseIdentifier
  复用池：离屏 cell 回收 → 重配 → 给新行用，避免为上万行各建一个视图
```

流程：先 `register(...forCellReuseIdentifier:)` 注册一种 cell；`cellForRowAt` 里用
`dequeueReusableCell(withIdentifier:for:)` 从**复用池**拿一个（池里有回收的就复用，
没有才新建）；然后**重新配置**它的内容再返回。滚动时，划出屏幕的 cell 被回收进池，
划进来的行复用它。所以任意时刻只存在「可见行数 + 少量缓冲」个 cell，而不是上万行各一个。

> **坑**：复用的 cell 带着**上一行的残留状态**。`cellForRowAt` 里必须把**所有**会变
> 的属性都重设一遍（文本、图片、选中态、accessory、隐藏态……），否则会出现「滚动时
> 内容串台」的经典 bug。

## 4) UITableViewDelegate：交互事件

`dataSource` 管数据，`delegate` 管**交互**（选中、行高、滑动操作、显示时机）：

```swift
final class MyDelegate: NSObject, UITableViewDelegate {
    var selected: IndexPath?
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = indexPath
    }
}
table.delegate = delegate
table.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .none)
```

```
-- UITableViewDelegate：选中一行 --
  ok   selectRow 更新了 tableView 的选中行（第 2 行）
  ok   但 selectRow 不触发 didSelectRowAt（delegate 还没记录）
  模拟点击后 delegate 记录的选中行 = Optional([0, 2])
  ok   didSelectRowAt 被调用后，delegate 记录了第 2 行
```

**重要坑**：程序化调 `selectRow(at:)` **不会**触发 `didSelectRowAt`。`didSelectRowAt`
是**给用户点击**准备的。所以：

- `selectRow` 只更新 `tableView.indexPathForSelectedRow`（视觉选中态），delegate 收不到。
- 想「代码里选中一行并执行点击逻辑」，得 `selectRow` 之后**再手动调一次**你的选中处理
  （示例里直接调 `delegate.tableView(_:didSelectRowAt:)` 模拟用户点击，验证 delegate
  确实记录了 `[section 0, row 2]`）。

## 5) Diffable Data Source：提交快照，系统算增删

老的 `reloadData` 粗暴（整表刷新、无动画），手动 `insertRows/deleteRows` 又容易和数据
不同步导致崩溃。**Diffable data source**（iOS 13+）是现代答案：你只维护一份
**快照**（`NSDiffableDataSourceSnapshot`），`apply` 它，系统自己 diff 出增删移动、
跑动画。

```swift
enum Section: Hashable { case fruits }
var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
snapshot.appendSections([.fruits])
snapshot.appendItems(["西瓜", "葡萄", "桃子"], toSection: .fruits)

let diffable = UITableViewDiffableDataSource<Section, String>(tableView: diffTable) {
    tableView, indexPath, item in
    let cell = tableView.dequeueReusableCell(withIdentifier: "DCell", for: indexPath)
    var content = cell.defaultContentConfiguration(); content.text = item
    cell.contentConfiguration = content
    return cell
}
diffable.apply(snapshot, animatingDifferences: false)   // false → 同步应用，立即可读

// 更新：拷一份快照、改、再 apply —— 系统算出「加了一行」
var updated = diffable.snapshot()
updated.appendItems(["李子"], toSection: .fruits)
diffable.apply(updated, animatingDifferences: false)
```

```
-- Diffable Data Source：snapshot 驱动 --
  sections=1 items=["西瓜", "葡萄", "桃子"]
  ok   快照里有一个 section
  ok   三项按顺序进了快照
  ok   tableView 行数与快照一致（3）
  ok   追加一项后快照变成 4 项
  ok   tableView 行数跟着变 4
```

要点：

- 快照的 Section / Item 都必须 **`Hashable`**（item 的 hash 就是它的「稳定 id」，等价于
  SwiftUI 的 `Identifiable`）。**别用 `IndexPath` 或下标当 item**——增删后会错位。
- `apply(_:animatingDifferences:)`：`true` 带动画（默认，异步）；`false` 同步立即生效
  （本示例为了能马上读回行数用了 `false`）。还有 `applySnapshotUsingReloadData` 强制
  整表刷。
- 更新数据的正确姿势：`diffable.snapshot()` 拷一份 → 改 → `apply`。别自己另存一份数组，
  否则容易和快照不同步。

这就是 SwiftUI `List` + `Identifiable` + 自动增删动画（第 11 章）在 UIKit 层的对应物。

## 6) UICollectionView：网格 / 自定义布局

`UICollectionView` 和 `UITableView` 模型一致（dataSource / delegate / cell 复用 /
diffable 全都有），区别是它靠一个 **layout 对象**决定怎么摆，能做网格、瀑布流、
自定义布局：

```swift
let layout = UICollectionViewFlowLayout()
layout.itemSize = CGSize(width: 80, height: 80)
let collection = UICollectionView(frame: …, collectionViewLayout: layout)
collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CC")
collection.dataSource = collDS
collection.reloadData()
collection.numberOfItems(inSection: 0)   // 6
```

```
-- UICollectionView：另一种列表容器 --
  ok   UICollectionView：dataSource 报告 6 个 item
  ok   UICollectionView：1 个 section
```

现代写法用 `UICollectionViewCompositionalLayout`（分节、不同布局）+ diffable data source，
能力远超 `UITableView`。SwiftUI 的 `LazyVGrid`/`LazyHGrid` 对应的就是它。

## 心智模型小结

```
dataSource 管「有多少行、每行内容」；delegate 管「选中、显示等交互」
cell 复用：dequeueReusableCell 从池里拿，别每行都 new；每次都要重设全部可变属性
diffable：提交 snapshot，系统算增删动画；apply(animatingDifferences:false) 同步可读
UITableView（一列）/ UICollectionView（网格/自定义布局），二者模型一致
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 滚动时 cell 内容串台 | 复用的 cell 有残留状态；`cellForRowAt` 里没重设全部可变属性 |
| `dequeueReusableCell` 崩溃 | 没 `register` 或 reuseIdentifier 拼错 |
| 代码 `selectRow` 后点击逻辑没跑 | `selectRow` 不触发 `didSelectRowAt`，得手动调处理逻辑 |
| diffable `apply` 后行数没变 | 用了旧快照/没拷 `diffable.snapshot()` 再改 |
| diffable item 增删后错位 | item 用了 `IndexPath`/下标当标识；要用稳定 `Hashable` 主键 |
| `reloadData` 丢了选中态/动画生硬 | 改用 diffable `apply`，它保留状态并跑动画 |
| collectionView cell 尺寸不对 | layout 的 `itemSize` 没设，或没实现 `sizeForItemAt` |

## 小结

- 常用控件就是属性读写；`UIButton.Configuration`、`defaultContentConfiguration` 是现代写法。
- `UITableView` 三件套：`dataSource`（数据）、`delegate`（交互）、cell **复用**（性能）。
- 复用的 cell 必须在 `cellForRowAt` 里重设**所有**可变属性，否则串台。
- `selectRow` 不触发 `didSelectRowAt`——程序化选中和用户点击是两条路。
- **Diffable data source**：维护 `Hashable` 快照，`apply` 让系统算增删动画，是
  SwiftUI `List` 的 UIKit 对应物。
- `UICollectionView` 模型相同，靠 layout 做网格/自定义布局。下一章讲 **手势、触摸与
  响应链**。
