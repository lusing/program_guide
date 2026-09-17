# 12 · NSTableView 与 NSOutlineView

> 示例：`examples/12_table_outline/main.swift`
> 实测输出见 `build/12_table_outline/stdout.clt.txt`

macOS 的列表控件比 iOS 的 `UITableView` 老，也因此**有两套并存的实现**。
搞清楚这个，你就不会在照抄网上代码时一会儿 `objectValueFor` 一会儿 `viewFor` 地困惑。

## 1) 两套实现

| | cell-based（老） | view-based（新） |
| --- | --- | --- |
| dataSource 方法 | `objectValueFor tableColumn:row:` | `viewFor tableColumn:row:` |
| 单元格 | 一个 `NSCell`，表格自己画 | 一个真的 `NSView`（通常 `NSTableCellView`） |
| 富文本/图片/按钮 | 很难 | 随便放 |
| 动画 / 自定义 | 基本不行 | 正常 |

**现在一律用 view-based。** Xcode 的 XIB 模板默认也是它。

示例里两个方法都实现了，用来对照：

```swift
// cell-based
func tableView(_ tableView: NSTableView,
               objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    switch tableColumn?.identifier.rawValue {
    case "title": return items[row].title
    ...
    }
}

// view-based
func tableView(_ tableView: NSTableView,
               viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = NSTableCellView()
    let field = NSTextField(labelWithString: items[row].title)
    field.translatesAutoresizingMaskIntoConstraints = false
    cell.addSubview(field)
    cell.textField = field
    return cell
}
```

实测：

```
== NSTableView ==
  ok   三列（实际 3）
  ok   第二列的标识符是 title
  ok   列标题是「任务」
  默认行高 = 24.0
  ok   默认行高是一个正值
  ok   行高可以改
  numberOfRows = 3
  ok   dataSource 报 3 行
  ok   返回的是 NSTableCellView
  第 1 行的单元格文字 = 改 bug
  ok   view-based 单元格的文字正确
```

> **坑**：`rowHeight` 的默认值**没有写死的标准**（本机 SDK 上是 24，
> 旧版 macOS 上是 17）。别拿具体数字做断言。

## 2) 组装一个表格

```swift
let table = NSTableView(frame: ...)
let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
col.title = "任务"
col.width = 140
table.addTableColumn(col)

// dataSource / delegate 都是 weak —— 必须自己持有！
let dataSource = TaskDataSource()
table.dataSource = dataSource
table.delegate = dataSource

let scroll = NSScrollView(frame: ...)
scroll.documentView = table
scroll.hasVerticalScroller = true
```

> **坑**：`dataSource` / `delegate` 是 **`weak`**。
> 写成 `table.dataSource = TaskDataSource()` 会让对象**当场释放**，
> 编译器还会给一条告警（`instance will be immediately deallocated`）。
> 必须用变量持有它。

`NSTableView` 必须装在 `NSScrollView` 里（它自己不滚动）。
Xcode 拖一个 Table View 进画布时会自动套好，手写要自己做。

## 3) 选择

```swift
table.selectRowIndexes(IndexSet(integer: 2), byExtendingSelection: false)
table.selectedRow            // 2
table.selectedRowIndexes     // IndexSet
table.deselectAll(nil)
```

实测：

```
== 选择 ==
  ok   选中第 2 行（实际 2）
  ok   选择集合里 1 项
  ok   按住扩展选择后变 2 项
  ok   第 0 行在选中集合里
  ok   全部取消选择
  ok   已完成的行不允许选中
  ok   未完成的行可以选中
```

「某行能不能选中」由 delegate 决定：

```swift
func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    !items[row].done
}
```

## 4) 排序

```swift
col.sortDescriptorPrototype = NSSortDescriptor(key: "title", ascending: true)
// delegate 里：
func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
    items.sort { ... }
    tableView.reloadData()
}
```

实测：

```
  ok   列头带排序描述符
  ok   升序
```

## 5) NSOutlineView：树形列表

`NSOutlineView` 是 `NSTableView` 的子类，dataSource 换了一套：

```swift
func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
func outlineView(_ outlineView: NSOutlineView,
                 objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any?
```

关键差别：**用 `item` 而不是 `row`**。
`item` 是你的数据对象（`nil` 表示根节点），`row` 是**扁平化后**的行号（由视图维护）。

实测：

```
== NSOutlineView ==
  ok   大纲视图一列
  ok   根有 3 个子项
  ok   第一个子项是「源码」
  ok   「源码」可展开
  ok   「源码」下有 2 个文件
  ok   取到显示用的值
  ok   README.md 是叶子节点
  ok   nil item 没有对应行
```

`row(forItem:)` / `item(atRow:)` 在两者之间换算。
**展开状态由视图自己维护**，所以 `row` 会随展开/折叠变化 ——
持久化选中状态时应该存 `item` 的标识，不是 row。

## 6) 刷新与性能

```swift
table.reloadData()                                   // 全量
table.reloadData(forRowIndexes: ..., columnIndexes: ...)  // 局部
table.beginUpdates() / table.endUpdates()            // 批量（带动画）
table.noteHeightOfRows(withIndexesChanged: ...)      // 行高变了要通知
```

> **坑**：`reloadData()` 只刷新**可见行**。
> 用 `viewFor` 造的视图会被复用（`makeView(withIdentifier:owner:)`），
> 所以**每次都要把内容设一遍**，不能依赖「上次设过」。

推荐的复用写法：

```swift
let id = NSUserInterfaceItemIdentifier("MyCell")
let cell = tableView.makeView(withIdentifier: id, owner: self) as? MyCell ?? MyCell()
cell.textField?.stringValue = items[row].title
return cell
```

## 7) 数据源 vs Cocoa Bindings

macOS 上表格还能完全用 `NSArrayController` + Bindings 驱动
（在 XIB 里把每一列的 Value 绑到 `arrangedObjects.xxx`）。
那种写法代码极少，但：

- 调试困难（静默失败）
- 复杂逻辑（动态行高、异步加载）不好塞

**建议**：原型/设置面板用 Bindings；正式列表用 dataSource。

## 8) 坑清单

| 现象 | 原因 |
| --- | --- |
| 表格一片空白 | dataSource 被释放（weak，没人持有） |
| `viewFor` 从没被调用 | 表格没装进 ScrollView，或宽度/高度为 0 |
| 单元格内容错行 | 视图被复用，没每次重设内容 |
| 行高改了但不生效 | 要调 `noteHeightOfRows(withIndexesChanged:)` |
| 大纲视图「取不到值」 | 用了 `row` 当 item（OutlineView 的 API 收 item） |
| 排序点了没反应 | 列没设 `sortDescriptorPrototype`，或没实现 delegate 回调 |
| 复制粘贴 `rowHeight == 17` 断言失败 | 默认值随系统版本变，只断言「> 0」 |

## 小结

- 用 **view-based**（`viewFor`），别用 cell-based。
- `dataSource` / `delegate` 是 weak，必须自己持有。
- `NSTableView` 必须装进 `NSScrollView`。
- `NSOutlineView` 用 `item` 而不是 `row`；`row` 随展开状态变。
- 单元格视图会被复用，每次都要重设内容。
