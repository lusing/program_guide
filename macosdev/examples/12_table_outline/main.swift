// ============================================================
// 12 - 列表：NSTableView 与 NSOutlineView
//   dataSource / delegate / NSTableColumn / NSTableCellView / 选择状态
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name table_outline main.swift -o 12_table_outline \
//          -framework Foundation -framework AppKit
// 运行：
//   ./12_table_outline
//
// 和 UIKit 的 UITableView 不同，NSTableView 有两套并存的实现：
//   - 基于 NSCell 的老式（cell-based）：只给字符串，表格自己画
//   - 基于 NSView 的新式（view-based）：每个单元格是一个真的 NSView
// 现在一律用 view-based，XIB/Storyboard 里的默认模板也是它。
//
// 自测里没法让 AppKit 自己去「问 dataSource 要数据」—— 那发生在绘制时。
// 所以这里把 dataSource 方法取出来直接调用，验证的是「同一份数据、同一套方法」。
// ============================================================

import AppKit
import Foundation

var failures = 0
func expect(_ condition: Bool, _ description: String) {
    if condition {
        print("  ok   \(description)")
    } else {
        print("  FAIL \(description)")
        failures += 1
    }
}

// MARK: - 1) 数据

struct Task {
    var title: String
    var done: Bool
    var owner: String
}

let tasks = [
    Task(title: "写文档", done: true, owner: "Ada"),
    Task(title: "改 bug", done: false, owner: "Grace"),
    Task(title: "做评审", done: false, owner: "Alan"),
]

// MARK: - 2) dataSource

final class TaskDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var items: [Task] = tasks

    func numberOfRows(in tableView: NSTableView) -> Int { items.count }

    // cell-based 时代留下的老方法：给一个「值」让表格自己画
    func tableView(_ tableView: NSTableView,
                   objectValueFor tableColumn: NSTableColumn?,
                   row: Int) -> Any? {
        guard let identifier = tableColumn?.identifier.rawValue else { return nil }
        let task = items[row]
        switch identifier {
        case "done": return task.done ? "✓" : ""
        case "title": return task.title
        case "owner": return task.owner
        default: return nil
        }
    }

    // view-based 的新方法：自己造（或从 nib 里取）一个视图
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier.rawValue else { return nil }
        let cell = NSTableCellView()
        let field = NSTextField(labelWithString: "")
        field.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(field)
        cell.textField = field
        let task = items[row]
        switch identifier {
        case "done": field.stringValue = task.done ? "✓" : "—"
        case "title": field.stringValue = task.title
        case "owner": field.stringValue = task.owner
        default: field.stringValue = ""
        }
        return cell
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        !items[row].done      // 已完成的不能选中
    }
}

// MARK: - 3) 组装表格

print("== NSTableView ==")
let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 320, height: 200))
let table = NSTableView(frame: NSRect(x: 0, y: 0, width: 320, height: 200))
let doneColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("done"))
doneColumn.title = "完成"
doneColumn.width = 40
let titleColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("title"))
titleColumn.title = "任务"
titleColumn.width = 140
let ownerColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("owner"))
ownerColumn.title = "负责人"
ownerColumn.width = 100
table.addTableColumn(doneColumn)
table.addTableColumn(titleColumn)
table.addTableColumn(ownerColumn)
scrollView.documentView = table

let dataSource = TaskDataSource()
table.dataSource = dataSource
table.delegate = dataSource

expect(table.numberOfColumns == 3, "三列（实际 \(table.numberOfColumns)）")
expect(table.tableColumns[1].identifier.rawValue == "title", "第二列的标识符是 title")
expect(table.tableColumns[1].title == "任务", "列标题是「任务」")
// 坑：默认行高没有写死的标准值（本机 SDK 上是 24，旧版 macOS 上是 17），
// 所以这里只断言性质，不断言具体数字。
print("  默认行高 = \(table.rowHeight)")
expect(table.rowHeight > 0, "默认行高是一个正值")
table.rowHeight = 32
expect(table.rowHeight == 32, "行高可以改")

// 直接调用 dataSource，验证数据的映射
let rows = dataSource.numberOfRows(in: table)
print("  numberOfRows = \(rows)")
expect(rows == 3, "dataSource 报 3 行")
expect(dataSource.tableView(table, objectValueFor: titleColumn, row: 1) as? String == "改 bug",
       "第 1 行的标题是「改 bug」")
expect(dataSource.tableView(table, objectValueFor: doneColumn, row: 0) as? String == "✓",
       "第 0 行已完成")
expect(dataSource.tableView(table, objectValueFor: ownerColumn, row: 2) as? String == "Alan",
       "第 2 行负责人是 Alan")

// view-based 的单元格：返回的是真的 NSView
let cellView = dataSource.tableView(table, viewFor: titleColumn, row: 1)!
expect(cellView is NSTableCellView, "返回的是 NSTableCellView")
let cellText = (cellView as? NSTableCellView)?.textField?.stringValue
print("  第 1 行的单元格文字 = \(cellText ?? "nil")")
expect(cellText == "改 bug", "view-based 单元格的文字正确")

// MARK: - 4) 选择状态

print("")
print("== 选择 ==")
// 表格自己维护选择集合，不依赖绘制
table.selectRowIndexes(IndexSet(integer: 2), byExtendingSelection: false)
expect(table.selectedRow == 2, "选中第 2 行（实际 \(table.selectedRow)）")
expect(table.selectedRowIndexes.count == 1, "选择集合里 1 项")
table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: true)
expect(table.selectedRowIndexes.count == 2, "按住扩展选择后变 2 项")
expect(table.selectedRowIndexes.contains(0), "第 0 行在选中集合里")
table.deselectAll(nil)
expect(table.selectedRowIndexes.isEmpty, "全部取消选择")

// 用 delegate 限制选择：只验证规则本身（AppKit 在点击时才去问 delegate）
expect(dataSource.tableView(table, shouldSelectRow: 0) == false, "已完成的行不允许选中")
expect(dataSource.tableView(table, shouldSelectRow: 1), "未完成的行可以选中")

// 排序：给列设 sortDescriptorPrototype，点列头就会回调 dataSource 的排序方法
let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
titleColumn.sortDescriptorPrototype = sortDescriptor
expect(titleColumn.sortDescriptorPrototype?.key == "title", "列头带排序描述符")
expect(titleColumn.sortDescriptorPrototype?.ascending == true, "升序")

// MARK: - 5) NSOutlineView

print("")
print("== NSOutlineView ==")

final class Node: NSObject {
    let name: String
    var children: [Node] = []
    init(_ name: String, children: [Node] = []) {
        self.name = name
        self.children = children
        super.init()
    }
}

let root = Node("项目", children: [
    Node("源码", children: [Node("main.swift"), Node("Model.swift")]),
    Node("资源", children: [Node("MainMenu.xib")]),
    Node("README.md"),
])

final class OutlineSource: NSObject, NSOutlineViewDataSource {
    var rootNode: Node = root

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        (item as? Node)?.children.count ?? (item == nil ? rootNode.children.count : 0)
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? Node { return node.children[index] }
        return rootNode.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !(item as? Node)!.children.isEmpty
    }

    func outlineView(_ outlineView: NSOutlineView,
                     objectValueFor tableColumn: NSTableColumn?,
                     byItem item: Any?) -> Any? {
        (item as? Node)?.name
    }
}

let outline = NSOutlineView(frame: NSRect(x: 0, y: 0, width: 240, height: 200))
let outlineColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
outlineColumn.title = "名称"
outline.addTableColumn(outlineColumn)
// 坑：dataSource / delegate 都是 weak，写成 outline.dataSource = OutlineSource()
// 会让对象当场释放（编译器会给告警）—— 一定要用一个变量持有它。
let outlineSource = OutlineSource()
outline.dataSource = outlineSource
let readBackSource = outline.dataSource as! OutlineSource

expect(outline.numberOfColumns == 1, "大纲视图一列")
expect(outlineSource.outlineView(outline, numberOfChildrenOfItem: nil) == 3, "根有 3 个子项")
let first = outlineSource.outlineView(outline, child: 0, ofItem: nil) as! Node
expect(first.name == "源码", "第一个子项是「源码」")
expect(outlineSource.outlineView(outline, isItemExpandable: first), "「源码」可展开")
expect(outlineSource.outlineView(outline, numberOfChildrenOfItem: first) == 2, "「源码」下有 2 个文件")
expect(outlineSource.outlineView(outline, objectValueFor: outlineColumn, byItem: first) as? String == "源码",
       "取到显示用的值")

let leaf = outlineSource.outlineView(outline, child: 2, ofItem: nil) as! Node
expect(outlineSource.outlineView(outline, isItemExpandable: leaf) == false, "README.md 是叶子节点")
// 大纲视图里「行」是扁平化后的序号，展开状态由视图自己维护
expect(outline.row(forItem: nil) == -1, "nil item 没有对应行")

print("==== 12 结束 ====")
exit(failures == 0 ? 0 : 1)
