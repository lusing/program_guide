// ============================================================
// 11 - KVC、KVO 与 Cocoa Bindings
//   键值编码 / 键值观察 / @objc dynamic / bind:to:withKeyPath:options:
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name kvo_bindings main.swift -o 11_kvo_bindings \
//          -framework Foundation -framework AppKit
// 运行：
//   ./11_kvo_bindings
//
// Cocoa Bindings 是 macOS 独有的「零胶水」方案：把控件的某个属性和 model 的
// 某个 key path 绑起来，双向同步，不用写一行 target-action。它的地基就是
// KVC（按名字存取）+ KVO（按名字监听）。
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

// MARK: - 1) KVC：按字符串名字存取属性

print("== KVC ==")
final class Book: NSObject {
    // KVC 要能找到 Objective-C 的 getter/setter，所以属性必须是 @objc 的。
    // 继承 NSObject 的 Swift 类里，能被 ObjC 表示的属性默认就有 @objc。
    @objc var title: String = ""
    @objc var pageCount: Int = 0
    @objc var tags: [String] = []
}

let book = Book()
book.setValue("Cocoa 编程", forKey: "title")
book.setValue(320, forKey: "pageCount")
expect(book.title == "Cocoa 编程", "setValue(_:forKey:) 写入字符串")
expect(book.pageCount == 320, "写入数字时会自动做 NSNumber 转换")
expect(book.value(forKey: "title") as? String == "Cocoa 编程", "value(forKey:) 读回来")
expect(book.value(forKey: "pageCount") as? Int == 320, "数字也是 NSNumber 桥接回来的")

// key path：用点号穿过多层
final class Shelf: NSObject {
    @objc var name: String = "默认书架"
    @objc var featured: Book = Book()
}
let shelf = Shelf()
shelf.featured.title = "深入 Cocoa"
expect(shelf.value(forKeyPath: "featured.title") as? String == "深入 Cocoa", "keyPath 可以穿层读取")
shelf.setValue("科技", forKeyPath: "featured.title")
expect(shelf.featured.title == "科技", "keyPath 也能穿层写入")

// 坑：key 不存在时默认是**抛异常**（NSUndefinedKeyException），不是返回 nil。
// 想让它安静地失败，就重写 valueForUndefinedKey: / setValue:forUndefinedKey:
final class Lenient: NSObject {
    var store: [String: Any] = [:]
    override func value(forUndefinedKey key: String) -> Any? { store[key] }
    override func setValue(_ value: Any?, forUndefinedKey key: String) { store[key] = value }
}
let lenient = Lenient()
lenient.setValue("v", forUndefinedKey: "anything")
expect(lenient.value(forUndefinedKey: "anything") as? String == "v", "重写 UndefinedKey 就不会崩")

// 集合的 KVC 运算符：@count / @sum / @avg / @max
let books: [Book] = {
    let a = Book(); a.pageCount = 100
    let b = Book(); b.pageCount = 300
    return [a, b]
}()
let count = (books as NSArray).value(forKeyPath: "@count") as? Int
let total = (books as NSArray).value(forKeyPath: "@sum.pageCount") as? Int
let avg = (books as NSArray).value(forKeyPath: "@avg.pageCount") as? Double
print("  @count=\(count ?? -1) @sum=\(total ?? -1) @avg=\(avg ?? -1)")
expect(count == 2, "@count 是元素个数")
expect(total == 400, "@sum.pageCount 求和")
expect(avg == 200, "@avg.pageCount 求平均")

// MARK: - 2) KVO

print("")
print("== KVO ==")
final class Thermostat: NSObject {
    // 坑：Swift 的属性默认不发 KVO 通知。必须同时有 @objc 和 dynamic：
    // @objc 让它走 ObjC 的消息派发，dynamic 禁用 Swift 的直接派发优化。
    @objc dynamic var temperature: Double = 20.0
    // 这一行没有 dynamic —— 改它不会触发任何观察者
    @objc var label: String = "室温"
}

let thermostat = Thermostat()
var observed: [Double] = []
// 现代写法是闭包版，返回的 token 要自己持有；deinit 时失效
let token = thermostat.observe(\.temperature, options: [.new]) { object, change in
    if let value = change.newValue { observed.append(value) }
}
thermostat.temperature = 22.5
thermostat.temperature = 25.0
expect(observed.count == 2, "两次赋值触发了两次通知（实际 \(observed.count)）")
expect(observed == [22.5, 25.0], "回调里拿到的是新值（实际 \(observed)）")

// 反面：少了 dynamic 会怎样？这里用**旧式 KVO**（addObserver:forKeyPath:）来演示，
// 因为 Swift 的闭包版 observe(\.label) 碰到非 dynamic 属性会直接运行时崩
// （"Could not extract a String from KeyPath"），根本跑不到断言。
final class Recorder: NSObject {
    var hits: [String] = []
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if let k = keyPath { hits.append(k) }
    }
}
let recorder = Recorder()
thermostat.addObserver(recorder, forKeyPath: "label", options: [.new], context: nil)
thermostat.addObserver(recorder, forKeyPath: "temperature", options: [.new], context: nil)
thermostat.label = "书房"
thermostat.temperature = 21.0
print("  收到的通知 = \(recorder.hits)")
expect(recorder.hits == ["temperature"], "只有 dynamic 的属性发了通知")
expect(thermostat.label == "书房", "但 label 的值确实改了")
thermostat.removeObserver(recorder, forKeyPath: "label")
thermostat.removeObserver(recorder, forKeyPath: "temperature")

// 手动发通知：批量改一堆相关属性时，手动包一层能少发很多次通知
final class Counter2: NSObject {
    @objc dynamic var value: Int = 0
    // 关掉自动通知，改成自己发
    override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        key == "value" ? false : super.automaticallyNotifiesObservers(forKey: key)
    }
    func bumpSilently() {
        willChangeValue(forKey: "value")
        value += 1
        didChangeValue(forKey: "value")
    }
}
let counter = Counter2()
var bumps = 0
let bumpToken = counter.observe(\.value, options: [.new]) { _, _ in bumps += 1 }
counter.bumpSilently()
expect(bumps == 1, "手动 will/didChange 也能触发通知")
expect(counter.value == 1, "值加了一")
// 验证自动通知确实被关掉了
bumps = 0
counter.value = 99
expect(bumps == 0, "关掉自动通知后直接赋值不再通知")
expect(counter.value == 99, "但值还是改了")
_ = bumpToken

// MARK: - 3) Cocoa Bindings

print("")
print("== Cocoa Bindings ==")
final class FormModel: NSObject {
    @objc dynamic var userName: String = "匿名"
    @objc dynamic var subscribed: Bool = false
}
let model = FormModel()

let nameField = NSTextField(string: "初始值")
nameField.bind(.value, to: model, withKeyPath: "userName", options: nil)
print("  绑定后 textField = \(nameField.stringValue)")
// 绑定是**立刻生效**的：绑上的那一刻控件就取到了 model 的值
expect(nameField.stringValue == "匿名", "绑定后控件立刻显示 model 的值")

// 单向（默认）方向是 model → view？其实默认就是双向：
// 改 model，控件跟着变
model.userName = "Ada"
print("  model 改成 Ada 之后 = \(nameField.stringValue)")
expect(nameField.stringValue == "Ada", "改 model 会同步到控件")

// 反向（view → model）：程序里直接改 stringValue **不会**回写 model。
// 那条路径走的是 field editor（用户敲键盘时 AppKit 临时插进来的编辑视图），
// 程序赋值根本不经过它，所以连 ContinuouslyUpdatesValue 也救不了。
nameField.stringValue = "Grace"
print("  程序改控件之后 model = \(model.userName)")
expect(model.userName == "Ada", "程序改 stringValue 不会回写 model")
expect(nameField.stringValue == "Grace", "控件自己的值已经改了")

nameField.unbind(.value)
nameField.bind(.value, to: model, withKeyPath: "userName",
               options: [.continuouslyUpdatesValue: true])
nameField.stringValue = "Grace2"
expect(model.userName == "Ada", "开了 continuouslyUpdatesValue 也不回写")

// unbind 之后控件不再跟随 model
nameField.unbind(.value)
model.userName = "回到 model"
expect(nameField.stringValue == "Grace2", "unbind 之后控件不再跟随 model")

// 复选框绑 Bool 最直观
let checkbox = NSButton(checkboxWithTitle: "订阅", target: nil, action: nil)
checkbox.bind(.value, to: model, withKeyPath: "subscribed", options: nil)
expect(checkbox.state == .off, "初始是 off")
model.subscribed = true
expect(checkbox.state == .on, "model 变 true 后勾选框变 on")

// 绑定的信息可以查回来 —— 调试「为什么没同步」时很有用
let info = nameField.infoForBinding(.value)
expect(info == nil, "unbind 之后查不到绑定信息")
let checkInfo = checkbox.infoForBinding(.value)
expect(checkInfo != nil, "还绑着的能查到信息")
expect(checkInfo?[NSBindingInfoKey.observedKeyPath] as? String == "subscribed",
       "infoForBinding 能读出被观察的 key path（实际 \(checkInfo?[NSBindingInfoKey.observedKeyPath] as? String ?? "nil")）")

// MARK: - 4) NSObjectController / NSArrayController

print("")
print("== 控制器对象 ==")
// 这两个是 Bindings 的常用中介：它们本身也是「可被绑定」的对象
// 坑：不要把控制器再 bind 回同一个对象（contentObject → keyPath "self"）。
// 控制器自己就会观察 content，重复绑定只会让 AppKit 去对一个
// Swift 数组发 addObserver:forKeyPath:，直接抛 NSInvalidArgumentException。
// content 用初始化器给就够了，绑的是**别人**（比如 File's Owner 上的属性）才用 bind。
let objectController = NSObjectController(content: model)
expect(objectController.content is FormModel, "NSObjectController 装着 model")
expect(objectController.selectedObjects.count == 1, "默认选中唯一那个对象")

let arrayController = NSArrayController(content: books)
expect((arrayController.content as? [Any])?.count == 2, "NSArrayController 装着数组")
arrayController.setSelectionIndex(0)
expect(arrayController.selectionIndex == 0, "可以设选中下标")
expect(arrayController.canSelectNext, "选中的不是最后一个，还能往后选")
arrayController.setSelectionIndex(1)
expect(arrayController.canSelectNext == false, "选到最后一个之后 canSelectNext 变 false")
expect(arrayController.canSelectPrevious, "但可以往前选")

print("==== 11 结束 ====")
exit(failures == 0 ? 0 : 1)
