// ============================================================
// 15 - UIKit 控件与列表：常用控件 / UITableView(dataSource+delegate) / 复用 / 差分数据源
//
// UIKit 的列表是 iOS 最经典的东西，SwiftUI 的 List 底层就是它。核心三件套：
//   UITableView       滚动列表容器
//   UITableViewDataSource  「有多少行、每行长什么样」——数据从哪来
//   UITableViewDelegate    「选中了、要显示了」——交互事件
//   UITableViewCell   一行；靠 **复用**（dequeue）避免为上万行各建一个视图
// 现代写法用 **diffable data source**：你只提交一份「快照」，它自己算增删动画。
//
// headless 验证：UITableView 给个 frame、reloadData 之后，numberOfSections/numberOfRows、
// cellForRow、diffable 的 snapshot 都能**同步**读出来（不需要挂窗口）。控件的属性
// 读写、选中状态也可直接断言。全程不建窗口、不弹窗。
// ============================================================

import Foundation
import UIKit

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

line("== 15 UIKit 控件与列表 ==")

// ---------------------------------------------------- 1) 常用控件：属性读写
line("")
line("-- 常用控件 --")
let label = UILabel()
label.text = "标题"
label.numberOfLines = 0                       // 0 = 不限行数
expect(label.text == "标题" && label.numberOfLines == 0, "UILabel：text / numberOfLines")

var config = UIButton.Configuration.filled()
config.title = "确定"
let button = UIButton(configuration: config)
expect(button.configuration?.title == "确定", "UIButton：Configuration 里设 title")

let field = UITextField()
field.text = "输入内容"
field.placeholder = "请输入"
expect(field.text == "输入内容" && field.placeholder == "请输入", "UITextField：text / placeholder")

let toggle = UISwitch()
toggle.isOn = true
expect(toggle.isOn == true, "UISwitch：isOn")

let slider = UISlider()
slider.minimumValue = 0; slider.maximumValue = 100
slider.value = 42
expect(slider.value == 42, "UISlider：value 在 min/max 之间")
slider.value = 999                            // 超上限会被夹到 max
expect(slider.value == 100, "UISlider：value 超过 maximumValue 被夹到 100")

// ---------------------------------------------------- 2) UITableView + dataSource
line("")
line("-- UITableView：dataSource 决定行数与内容 --")
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
let dataSource = MyDataSource()
table.dataSource = dataSource
table.reloadData()
line("  numberOfSections=\(table.numberOfSections)  numberOfRows=\(table.numberOfRows(inSection: 0))")
expect(table.numberOfSections == 1, "dataSource 报告 1 个 section")
expect(table.numberOfRows(inSection: 0) == 3, "dataSource 报告 3 行")
// cellForRow 触发 cellForRowAt，cell 被真正配置出来
let cell0 = table.cellForRow(at: IndexPath(row: 0, section: 0))
let cell0Text = (cell0?.contentConfiguration as? UIListContentConfiguration)?.text
line("  第 0 行文本 = \(cell0Text ?? "nil")")
expect(cell0Text == "苹果", "cellForRowAt 配置出了第 0 行「苹果」")

// ---------------------------------------------------- 3) 单元格复用
line("")
line("-- 单元格复用：dequeueReusableCell --")
let reused = table.dequeueReusableCell(withIdentifier: "Cell", for: IndexPath(row: 1, section: 0))
expect(reused.reuseIdentifier == "Cell", "dequeue 出来的 cell 带着注册时的 reuseIdentifier")
// 复用池的意义：滚动时离屏的 cell 被回收、重新配置后给新行用，而不是每行都 new
line("  复用池：离屏 cell 回收 → 重配 → 给新行用，避免为上万行各建一个视图")

// ---------------------------------------------------- 4) delegate：选中事件
line("")
line("-- UITableViewDelegate：选中一行 --")
final class MyDelegate: NSObject, UITableViewDelegate {
    var selected: IndexPath?
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = indexPath
    }
}
let delegate = MyDelegate()
table.delegate = delegate
// 坑：程序化 selectRow **不会**触发 didSelectRowAt（那是给用户点击准备的）。
table.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .none)
expect(table.indexPathForSelectedRow?.row == 2, "selectRow 更新了 tableView 的选中行（第 2 行）")
expect(delegate.selected == nil, "但 selectRow 不触发 didSelectRowAt（delegate 还没记录）")
// 用户点击走的是 didSelectRowAt。headless 下直接调这个方法，等价于「模拟一次点击」。
delegate.tableView(table, didSelectRowAt: IndexPath(row: 2, section: 0))
line("  模拟点击后 delegate 记录的选中行 = \(String(describing: delegate.selected))")
expect(delegate.selected == IndexPath(row: 2, section: 0), "didSelectRowAt 被调用后，delegate 记录了第 2 行")

// ---------------------------------------------------- 5) Diffable Data Source：提交快照
line("")
line("-- Diffable Data Source：snapshot 驱动 --")
enum Section: Hashable { case fruits }
var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
snapshot.appendSections([.fruits])
snapshot.appendItems(["西瓜", "葡萄", "桃子"], toSection: .fruits)

let diffTable = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), style: .insetGrouped)
diffTable.register(UITableViewCell.self, forCellReuseIdentifier: "DCell")
let diffable = UITableViewDiffableDataSource<Section, String>(tableView: diffTable) {
    tableView, indexPath, item in
    let cell = tableView.dequeueReusableCell(withIdentifier: "DCell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = item
    cell.contentConfiguration = content
    return cell
}
diffable.apply(snapshot, animatingDifferences: false)   // false → 同步应用，立即可读
line("  sections=\(diffable.snapshot().sectionIdentifiers.count) items=\(diffable.snapshot().itemIdentifiers(inSection: .fruits))")
expect(diffable.snapshot().sectionIdentifiers == [.fruits], "快照里有一个 section")
expect(diffable.snapshot().itemIdentifiers(inSection: .fruits) == ["西瓜", "葡萄", "桃子"], "三项按顺序进了快照")
expect(diffTable.numberOfRows(inSection: 0) == 3, "tableView 行数与快照一致（3）")

// 更新：再 append 一项，重新 apply —— diffable 自己算「加了一行」
var updated = diffable.snapshot()
updated.appendItems(["李子"], toSection: .fruits)
diffable.apply(updated, animatingDifferences: false)
expect(diffable.snapshot().itemIdentifiers(inSection: .fruits).count == 4, "追加一项后快照变成 4 项")
expect(diffTable.numberOfRows(inSection: 0) == 4, "tableView 行数跟着变 4")

// ---------------------------------------------------- 6) UICollectionView：网格
line("")
line("-- UICollectionView：另一种列表容器 --")
final class CollDataSource: NSObject, UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int { 6 }
    func numberOfSections(in cv: UICollectionView) -> Int { 1 }
    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        cv.dequeueReusableCell(withReuseIdentifier: "CC", for: ip)
    }
}
let layout = UICollectionViewFlowLayout()
layout.itemSize = CGSize(width: 80, height: 80)
let collection = UICollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), collectionViewLayout: layout)
collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CC")
let collDS = CollDataSource()
collection.dataSource = collDS
collection.reloadData()
expect(collection.numberOfItems(inSection: 0) == 6, "UICollectionView：dataSource 报告 6 个 item")
expect(collection.numberOfSections == 1, "UICollectionView：1 个 section")

// ---------------------------------------------------- 7) 小结
line("")
line("-- 心智模型 --")
line("  dataSource 管「有多少行、每行内容」；delegate 管「选中、显示等交互」")
line("  cell 复用：dequeueReusableCell 从池里拿，别每行都 new")
line("  diffable：提交 snapshot，系统算增删动画；apply(animatingDifferences:false) 同步可读")
line("  UITableView（一列）/ UICollectionView（网格/自定义布局），二者模型一致")
expect(true, "以上均由行数 / cell 内容 / 选中 / 快照断言支撑")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 15 结束 ====")
exit(failures == 0 ? 0 : 1)
